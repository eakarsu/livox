# Verified file delivery

This is the one bounded workflow hardened by the 2026-07-20 completeness pass.
It delivers an already-published content-addressed file in ordered buckets. It
does not upload content, decide who may access it, or make the full Livox
distribution production-ready.

## Acceptance contract

A transfer succeeds only when all of the following are true:

1. The requested identifier is a 40-character SHA-1 legacy hash or a
   64-character SHA-256 hash, and a regular non-symbolic-link file with exactly
   that lowercase name exists in the configured content directory.
2. The file bytes match the name before a session is created. The server reports
   the measured size rather than trusting client metadata.
3. The bucket size is positive and does not exceed the configured limit.
   Exact-multiple sizes do not create an extra empty bucket, and a configurable
   active-session ceiling bounds open channels.
4. The server owns the session's file, bucket size, cursor, and idle expiry.
   Clients may request the next bucket or replay the immediately preceding
   bucket; skipped, negative, expired, destroyed, and unknown sessions fail.
5. Every session start, bucket delivery/replay, completion, expiry, and explicit
   destruction is appended to a locally locked SHA-256 hash chain. A malformed
   or modified existing chain prevents service startup and future appends.
6. Each session owns and closes its file channel. The service uses positional
   reads, so concurrent sessions do not share a mutable channel cursor.
7. The Thrift processor returns the server-measured file metadata, removes
   routing entries on destruction or provider removal, and bounds abandoned
   least-recently-used routing entries to 4,096.

The regression harness covers invalid hashes, digest mismatch, bucket bounds,
authoritative session state, replay, out-of-order rejection, exact-multiple
bucket counts, reconstruction, destruction, idle expiry, audit verification,
audit-tamper startup failure, and bounded Thrift session routing.

## Configuration

OSGi Configuration Admin properties take precedence over environment values.
When explicit paths are absent, `AEON_HOME/files` and
`AEON_HOME/audit/file-transfer.log` are used.

| Purpose | OSGi property | Environment value | Default |
| --- | --- | --- | --- |
| Content store | `file.storage` | `LIVO_FILE_STORAGE` | `$AEON_HOME/files` |
| Audit file | `audit.file` | `LIVO_FILE_TRANSFER_AUDIT` | `$AEON_HOME/audit/file-transfer.log` |
| Maximum active sessions | `max.active.sessions` | `LIVO_FILE_TRANSFER_MAX_ACTIVE_SESSIONS` | `256` |
| Maximum bucket bytes | `max.bucket.bytes` | `LIVO_FILE_TRANSFER_MAX_BUCKET_BYTES` | `8388608` |
| Idle session seconds | `session.ttl.seconds` | `LIVO_FILE_TRANSFER_SESSION_TTL_SECONDS` | `300` |

The service creates missing directories, refuses symbolic-link content/audit
roots, and attempts to restrict a newly created audit directory to mode `0700`
and the audit file to `0600` on POSIX filesystems. It does not change the mode
of a pre-existing shared parent directory. Deployment policy should enforce
equivalent permissions and make published content read-only to the runtime
identity.

## Verification

Run the dependency-free workflow check from the repository root:

```sh
bash scripts/verify-file-transfer.sh
```

It compiles the file-transfer SPI, disk implementation, workflow test, and
dependency-free Thrift routing registry test against the tracked SLF4J API. It
executes in a temporary directory and removes all generated classes and test
data on exit. It also rejects reintroduction of the two credential forms removed
during this pass. CI runs the same command on Java 17. The generated Thrift
processor and legacy full Maven reactor remain separate modernization checks.

## Authorization and audit warning

The current Thrift file-transfer contract has no authentication or authorization
argument. Restrict or disable that endpoint until the protocol binds a validated
tenant/principal grant to the server-side session. See `SECURITY.md` for the
remaining launch blockers. The local hash chain is tamper-evident, not immutable;
export it to an independently controlled audit sink for production evidence.
