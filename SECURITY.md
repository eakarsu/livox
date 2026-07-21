# Security status

Livox is a legacy enterprise mobile-provisioning codebase and is not ready for
an internet-facing production deployment. The verified file-delivery slice in
this repository reduces content-integrity and resource-exhaustion risks, but it
does not repair the wider platform's trust model.

## File-transfer boundary

`livo-server/thrift-shared/src/main/thrift/file.thrift` does not accept an
authentication token or authorization grant for `initiateSession`,
`fetchBucket`, or `destroySession`. Consequently, the Thrift file-transfer
endpoint must remain disabled or restricted to an authenticated, private
service network. Knowing a content hash is not authorization. Production use
requires a protocol change that binds each session to a validated tenant,
principal, and permitted file; that work is intentionally not claimed here.

The disk implementation accepts 40-character SHA-1 names only for compatibility
with the existing store. Publish all new content under a 64-character SHA-256
name. The local audit log is append-only and hash-chained, so accidental or
unsophisticated modification is detectable, but an attacker with write access
to the log can replace and recompute the chain. Forward events to an access-
controlled external audit system before treating them as durable evidence.

Keep the content directory immutable to the runtime identity while transfers
are active. The service rejects symbolic links and detects size or modification-
time changes, but filesystem controls remain part of the security boundary.

## Known launch blockers

- Mailchimp, Twitter, and Mashape API credentials and a reusable deployment password hash were
  committed historically. Their current-tree copies have been removed, but the
  values must be revoked/rotated and purged from reachable history and release
  artifacts. Deleting a source literal is not credential revocation.
- The newsletter servlet calls Mailchimp API 2.0, which Mailchimp says was
  [retired on June 1, 2023](https://mailchimp.com/developer/release-notes/export-api-1-0-and-api-2-0-no-longer-supported/).
  It now fails closed when `LIVO_MAILCHIMP_API_KEY` is absent, but the integration
  must be replaced and tested before enabling that variable.
- The repository vendors historical JAR, WAR, ZIP, and native artifacts without
  a checked-in SBOM or reproducible provenance. Inventory, replace, and scan
  them before release.
- The server targets Java 7-era libraries and includes Thrift 0.9.1 and other
  obsolete dependencies. A supported-runtime and dependency-upgrade program is
  required; the new bounded test does not certify the full distribution.
- Authentication, tenancy, provisioning, and administrative interfaces have
  not received an end-to-end security review. Do not infer their safety from
  the file-transfer test.
- Remote JMX had been enabled without authentication or TLS in the bundled
  launchers. It is now disabled by default. If operations require JMX, configure
  authentication, TLS, and network policy outside the repository launcher.

Do not report security defects through a public issue if a private maintainer
channel is available. This archive does not currently identify such a channel,
which is itself a release-process gap.
