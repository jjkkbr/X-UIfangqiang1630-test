# Project Specification

## Objective

Provide a repeatable, reviewable deployment template for a self-hosted X-UI/Xray gateway. The project should demonstrate infrastructure automation, secure secret handling, operational safeguards, and isolated verification without requiring a live server for tests.

## Commands

```bash
# Validate shell syntax
for file in scripts/*.sh; do bash -n "$file"; done

# Run the isolated regression suite
python3 tests/test_scripts.py

# Validate the Compose template on a host with Docker
docker compose -f configs/docker-compose.yml config
```

## Structure

- `configs/`: Compose and Xray templates.
- `scripts/`: Docker installation, deployment, and backup automation.
- `clients/`: Sanitized client configuration examples.
- `docs/`: Architecture, setup, hardening, operations, and interview notes.
- `tests/`: Shell regression tests with Docker/network boundaries mocked.

## Testing strategy

- Shell syntax checks catch invalid Bash before deployment.
- Python `unittest` tests deployment success, local-template usage, configuration preservation, failure handling, path quoting, cron generation, and backup failure cleanup.
- Live deployment validation is separate from the offline suite and must never be represented as a unit-test result.

## Boundaries

- Always: keep secrets out of Git, validate Compose before startup, preserve existing state, and verify firewall rules.
- Ask first: public repository creation, public GitHub upload, changing a live firewall rule, or changing production credentials.
- Never: commit private keys, client share links, live panel credentials, or unreviewed generated database files.

## Success criteria

- A fresh checkout contains no live deployment state.
- `python3 tests/test_scripts.py` passes without network access.
- The deployment script uses the repository-local Compose template and never silently removes an existing Docker installation.
- The README explains architecture, security boundaries, limitations, and an interview-ready project narrative.
