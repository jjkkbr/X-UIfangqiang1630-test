# Interview Guide

## One-minute summary

“I built a repeatable self-hosted network gateway around X-UI and Xray. The repository separates management traffic from proxy traffic, keeps the panel behind SSH forwarding, provisions VLESS + Reality + Vision clients, adds UFW defaults, and backs up the SQLite state. I also wrote isolated shell regression tests that mock Docker and network boundaries, so failure paths can be tested without touching a real VPS.”

## Engineering points to discuss

- **Threat model:** the panel is an administrative surface, so it is not exposed by default; the proxy listener is the only public application port.
- **State preservation:** deployment copies a local Compose template only when one is absent and never overwrites an existing database or Compose file.
- **Failure handling:** startup checks Docker, Compose, config validity, and exact container state before reporting success.
- **Per-user lifecycle:** each person/device gets an independent UUID and traffic policy, allowing targeted revocation and limits.
- **Operational boundaries:** backups are separate from live state, and restore procedures stop the service before replacing SQLite files.
- **Resource awareness:** a 1 GiB host requires memory limits, log rotation, and explicit limits on expected concurrent users.

## Trade-offs

- X-UI is convenient for a small deployment but adds a privileged management layer and a mutable upstream image unless the image digest is pinned.
- Host networking simplifies port ownership but reduces container isolation.
- SQLite keeps the footprint small but requires careful backup and restore procedures.
- Multiple public IPs help with separation or failover; they do not increase the server's total CPU, RAM, or purchased bandwidth.

## Honest limitations

- The offline tests do not prove client handshake success or Internet reachability.
- The example does not include a cloud-provider Terraform module, HA, centralized identity, or company-wide capacity planning.
- Production use requires a domain/certificate strategy, a documented access policy, monitoring, and a provider/compliance review.
