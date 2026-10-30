# Security Policy

This repository is a deployment template for a self-hosted X-UI/Xray lab. It is not a managed VPN service.

## Never commit

- Private keys, certificates, panel passwords, API cookies, client UUIDs, Reality keys, or share links.
- X-UI databases, backups, logs, or generated client files.
- Public IPs or hostnames that identify a live deployment unless the owner explicitly intends to publish them.

The repository `.gitignore` covers common secret and runtime paths, but review `git diff` and `git status` before every push.

## Deployment security baseline

- Keep the X-UI panel behind an SSH tunnel or a tightly scoped management allowlist.
- Expose only the proxy port required by the selected inbound.
- Use one client UUID per person or device so access can be revoked independently.
- Pin or record the exact image digest used in each deployment.
- Back up the X-UI database only to a permission-restricted directory and test restoration.
- Keep Ubuntu, Docker, X-UI, and Xray updated using their official release channels.

## Reporting

Do not open a public issue containing a credential, private key, live share link, or production address. Revoke the credential first, then report the issue privately to the repository owner.
