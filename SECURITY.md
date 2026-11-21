# Security policy

Star is a **technical-preview project**. Successful GitHub Actions builds do not imply that the applications or self-hosted server have completed a production security review.

## Supported versions

| Version | Security maintenance |
| --- | --- |
| Current `main` development tree | Best-effort review and fixes |
| Historical prerelease installers and OCI images | No guaranteed security updates |
| Public self-hosted deployment | Not an approved configuration |

For evaluation, use the latest source commit and review the published component manifests before selecting an installer or image.

## Report a vulnerability

If you discover an authentication bypass, secret exposure, remote execution flaw, unsafe server behavior, or other security defect:

1. **Do not open a public issue** or disclose reproduction details in public comments.
2. On the [repository Security page](https://github.com/ls-matheus/Star/security), use the private vulnerability reporting option if it is enabled.
3. If that option is not available, request a private contact method from the [repository maintainer](https://github.com/ls-matheus) without including exploit details in a public message.
4. Share the affected version/commit, component, impact, and minimal reproduction through the agreed private channel.

No public security response service-level agreement is currently published; do not assume an emergency response time.

## Deployment and secrets

- Never commit `Docker/.env`, production credentials, signing identities, tokens, or private key material.
- The provided Compose configuration binds services to localhost and is intended for development.
- Public exposure requires a separate security review covering HTTPS/TLS, access controls, domains, firewall, key rotation, backups, abuse protection, and voice infrastructure.
- The Android APK is debug-only, and Windows/macOS installers do not carry commercial signing/notarization.
- Preserve published Release asset checksums and OCI digests when distributing or verifying a build.

For current technical limitations, read the [engineering audit](docs/engineering-audit.md).
