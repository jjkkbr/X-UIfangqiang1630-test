"""Isolated shell regression tests; Docker and network calls never reach real services."""
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import tarfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
BASH = os.environ.get("BASH_EXE") or shutil.which("bash")


def shell_path(path):
    value = Path(path).resolve().as_posix()
    if os.name == "nt":
        return "/" + value[0].lower() + value[2:]
    return value


class DeploymentTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.directory = Path(self.temp.name)
        self.project = self.directory / "project with spaces"
        shutil.copytree(ROOT, self.project)
        self.destination = self.directory / "deployment"
        self.destination.mkdir()
        script = self.project / "scripts" / "deploy-xui.sh"
        source = script.read_text(encoding="utf-8")
        # Windows has no root UID. Shim the permission check and the legacy fixed
        # path in the test copy only; production files remain untouched.
        source = source.replace('"$EUID"', '"0"').replace('${EUID}', '0')
        source = source.replace('XUI_DIR="/opt/x-ui"', 'XUI_DIR="${XUI_DIR:-/opt/x-ui}"')
        with script.open("w", encoding="utf-8", newline="\n") as output:
            output.write(source)
        self.script = script

    def run_script(self, mode="running"):
        env = os.environ.copy()
        env.update(XUI_DIR=shell_path(self.destination), TEST_MODE=mode, LANG="en_US.UTF-8")
        if os.name == "nt":
            env["PATH"] = str(Path(BASH).parent) + os.pathsep + env["PATH"]
        bootstrap = r'''
docker() {
    case "$1" in
        info) return 0 ;;
        inspect)
            if [ "$TEST_MODE" = "stopped" ]; then printf 'exited\n'; else printf 'running\n'; fi ;;
        ps) printf 'unrelated-x-ui-container\n' ;;
        logs) return 0 ;;
        compose)
            case " $* " in
                *" version "*) return 0 ;;
                *" config "*) [ "$TEST_MODE" != "invalid-config" ] ;;
                *" up "*) printf 'started\n' > "$XUI_DIR/started.txt" ;;
                *) return 0 ;;
            esac ;;
        *) return 0 ;;
    esac
}
curl() { printf 'network attempted\n' > "$XUI_DIR/network.txt"; return 7; }
sleep() { :; }
script="$1"; shift; source "$script"
'''
        return subprocess.run([BASH, "--noprofile", "--norc", "-c", bootstrap, "test", shell_path(self.script)],
                              cwd=self.directory, env=env, capture_output=True, text=True, encoding="utf-8", timeout=15)

    def test_local_template_deploys_without_network(self):
        result = self.run_script()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual((self.destination / "docker-compose.yml").read_bytes(),
                         (self.project / "configs" / "docker-compose.yml").read_bytes())
        self.assertFalse((self.destination / "network.txt").exists())

    def test_existing_configuration_is_preserved(self):
        config = self.destination / "docker-compose.yml"
        config.write_text("services: {}\n# custom configuration\n", encoding="utf-8")
        before = config.read_bytes()
        result = self.run_script()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(config.read_bytes(), before)

    def test_invalid_configuration_never_starts_service(self):
        result = self.run_script("invalid-config")
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse((self.destination / "started.txt").exists())

    def test_unrelated_container_does_not_count_as_success(self):
        result = self.run_script("stopped")
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn("部署完成", result.stdout)

    def test_deployment_directory_with_spaces(self):
        self.destination = self.directory / "deployment with spaces"
        self.destination.mkdir()
        result = self.run_script()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertTrue((self.destination / "docker-compose.yml").is_file())


class BackupCronTests(unittest.TestCase):
    def setUp(self):
        self.env = os.environ.copy()
        if os.name == "nt":
            self.env["PATH"] = str(Path(BASH).parent) + os.pathsep + self.env["PATH"]

    def backup_script(self, *args, bootstrap=None):
        command = [BASH, "--noprofile", "--norc"]
        if bootstrap:
            command += ["-c", bootstrap, "test"]
        command += [shell_path(ROOT / "scripts" / "backup-db.sh"), *args]
        return subprocess.run(command, env=self.env, capture_output=True, text=True,
                              encoding="utf-8", timeout=10)

    def test_cron_uses_actual_script_location_and_root_crontab(self):
        result = self.backup_script("--print-cron")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn(shell_path(ROOT / "scripts" / "backup-db.sh"), result.stdout)
        self.assertNotIn("/opt/x-ui-deployment/", result.stdout)
        self.assertTrue(result.stdout.startswith("0 2 * * * "))

    def test_cron_preserves_custom_paths_and_escapes_percent(self):
        self.env.update(XUI_DIR="/opt/x ui's data", BACKUP_DIR="/opt/backups%2026")
        result = self.backup_script("--print-cron")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("BACKUP_DIR='/opt/backups\\%2026'", result.stdout)
        self.assertIn("XUI_DIR='/opt/x ui'\\''s data'", result.stdout)

    def test_cron_rejects_newline_path(self):
        self.env["XUI_DIR"] = "/opt/data\ninvalid"
        result = self.backup_script("--print-cron")
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(result.stdout.startswith("0 2 * * * "))

    def test_backup_archive_contains_database_in_spaced_directory(self):
        with tempfile.TemporaryDirectory() as temp:
            directory = Path(temp)
            source = directory / "data with spaces"
            backup = directory / "backups with spaces"
            (source / "db").mkdir(parents=True)
            database = source / "db" / "x-ui.db"
            database.write_bytes(b"offline test database")
            self.env.update(XUI_DIR=shell_path(source), BACKUP_DIR=shell_path(backup))
            # The bundled Windows tar fails on -C in this host. Replace that
            # external boundary with Python's tarfile; Linux uses its real tar.
            bootstrap = None
            if os.name == "nt":
                adapter = directory / "tar_adapter.py"
                adapter.write_text(
                    'import sys, tarfile\nfrom pathlib import Path\n'
                    'def native(value):\n'
                    '    return value[1] + ":" + value[2:] if value.startswith("/c/") else value\n'
                    'assert sys.argv[1] == "-czf" and sys.argv[3] == "-C"\n'
                    'with tarfile.open(native(sys.argv[2]), "w:gz") as output:\n'
                    '    output.add(Path(native(sys.argv[4])) / sys.argv[5], arcname=sys.argv[5])\n',
                    encoding="utf-8")
                self.env.update(TEST_PYTHON=shell_path(sys.executable), TEST_TAR_ADAPTER=shell_path(adapter))
                bootstrap = 'tar() { "$TEST_PYTHON" "$TEST_TAR_ADAPTER" "$@"; }; script="$1"; shift; source "$script"'
            result = self.backup_script(bootstrap=bootstrap)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            archives = list(backup.glob("*.tar.gz"))
            self.assertEqual(len(archives), 1)
            with tarfile.open(archives[0]) as archive:
                self.assertEqual(archive.extractfile("db/x-ui.db").read(), database.read_bytes())

    def test_failed_archive_preserves_old_backups(self):
        with tempfile.TemporaryDirectory() as temp:
            directory = Path(temp)
            source = directory / "data"
            backup = directory / "backup"
            (source / "db").mkdir(parents=True)
            (source / "db" / "x-ui.db").write_bytes(b"database")
            backup.mkdir()
            old = backup / "x-ui-db-old.tar.gz"
            old.write_bytes(b"existing backup")
            os.utime(old, (1, 1))
            self.env.update(XUI_DIR=shell_path(source), BACKUP_DIR=shell_path(backup))
            result = self.backup_script(bootstrap='tar() { printf broken > "$2"; return 2; }; script="$1"; shift; source "$script"')
            self.assertNotEqual(result.returncode, 0)
            self.assertNotIn("用法:", result.stdout)
            self.assertEqual(list(backup.iterdir()), [old])
            self.assertEqual(old.read_bytes(), b"existing backup")


if __name__ == "__main__":
    if not BASH:
        raise SystemExit("Set BASH_EXE to a Bash executable, or install Bash on the test machine.")
    unittest.main(verbosity=2)
