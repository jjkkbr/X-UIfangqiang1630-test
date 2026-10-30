# Secure X-UI Deployment Toolkit

一个面向小规模自托管网络网关的部署模板。项目以 X-UI 管理 Xray，提供 VLESS + Reality + Vision 配置示例、Docker Compose 运行方式、UFW/SSH 隧道安全边界、数据库备份和隔离回归测试。

> 仅用于你拥有或明确获授权的网络。请遵守云厂商条款、当地法律和组织安全政策。本仓库不包含任何生产凭据，也不承诺上游镜像或客户端的长期安全性。

## Why This Is a Portfolio Project

它展示了几个可面试讨论的工程问题：

- 参数化、幂等的部署脚本，保留已有 Compose 和数据库状态。
- 管理面与代理面分离：面板默认通过 SSH 隧道访问，公共入口只开放实际代理端口。
- Docker 资源上限与日志轮转，适配 1 GiB 小型 VPS。
- SQLite 备份、恢复边界和失败清理。
- 在不触碰真实 Docker 或网络的情况下，使用 mock 边界回归部署失败路径。

架构图和请求流见 [docs/architecture.md](docs/architecture.md)，面试讲解见 [docs/interview-guide.md](docs/interview-guide.md)。

## Repository Layout

```text
configs/    Docker Compose and Xray templates
clients/    Sanitized Clash Meta and Hiddify guidance
docs/       Architecture, setup, hardening, operations, interview notes
scripts/    Docker install, deployment, and database backup scripts
tests/      Offline shell regression tests
```

## Quick Start

Prerequisites: a fresh Ubuntu/Debian host, SSH access, at least 1 GiB RAM, and a cloud firewall that can be reviewed before exposing ports.

```bash
chmod +x scripts/*.sh
bash scripts/install-docker.sh
bash scripts/deploy-xui.sh
```

The deployment script uses the repository-local Compose template, creates `/opt/x-ui` by default, preserves an existing Compose file, validates the configuration, and reports success only when the exact `x-ui` container is running. Set `XUI_DIR` to use another directory.

The Compose template pins the reference image by digest. Update it deliberately after reviewing the upstream release and re-running the checks.

## First Configuration

1. Set a random panel username, password, and web base path during first setup.
2. Keep the panel behind an SSH tunnel or a narrow management allowlist. Do not open its port to the whole Internet.
3. Create one VLESS + Reality + Vision client per person or device.
4. Open only the selected proxy port in UFW and the cloud security group.
5. Export client links from the panel. Never commit generated links, UUIDs, keys, or QR codes.

See [docs/01-environment-setup.md](docs/01-environment-setup.md), [docs/02-docker-deployment.md](docs/02-docker-deployment.md), [docs/03-panel-config.md](docs/03-panel-config.md), and [docs/05-security-hardening.md](docs/05-security-hardening.md).

## Verification

```bash
for file in scripts/*.sh; do bash -n "$file"; done
python3 tests/test_scripts.py
docker compose -f configs/docker-compose.yml config
```

The Python suite mocks Docker, network, and archive boundaries. It does not prove a live VPS handshake or Internet path. Run it on Linux or with Python 3 and Bash available; Windows PowerShell's `python` app stub is not sufficient.

## Backups

```bash
bash scripts/backup-db.sh
bash scripts/backup-db.sh --print-cron
```

The backup script archives the X-UI database directory and removes expired local archives. It warns that an online SQLite archive is not a transactional snapshot; stop the service during a maintenance-window backup and verify restoration before relying on it.

## Security

Read [SECURITY.md](SECURITY.md) before publishing or deploying. The project deliberately ignores databases, certificates, private keys, environment files, logs, generated client files, and backup output. Review `git diff` and `git status` before the first push.

## Upstream References

- [alireza0/x-ui upstream repository](https://github.com/alireza0/x-ui) (the Docker image is published as `alireza7/x-ui`)
- [X-UI v1.15.0 release](https://github.com/alireza0/x-ui/releases/tag/v1.15.0)
- [Xray documentation](https://xtls.github.io/)
- [Clash Meta documentation](https://wiki.metacubex.one/)

## License

This repository currently has no license. Add a license before accepting external contributions or reusing the material commercially.
