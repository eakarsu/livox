#!/bin/bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if grep -Eq 'MAILCHIMP_API_KEY[[:space:]]*=[[:space:]]*"[^"[:space:]]+' \
	"$ROOT/livomobile.com/src/com/livomobile/NewsletterServlet.java"; then
	echo "A Mailchimp credential is embedded in NewsletterServlet.java." >&2
	exit 1
fi
if grep -Eq '^admin_password[[:space:]]*[:=][[:space:]]*"?\$' \
	"$ROOT/livo-ansible/group_vars/all"; then
	echo "A deployment password hash is embedded in group_vars/all." >&2
	exit 1
fi

if [ -n "${JAVA_HOME:-}" ] && [ -x "$JAVA_HOME/bin/javac" ]; then
	JAVAC="$JAVA_HOME/bin/javac"
	JAVA="$JAVA_HOME/bin/java"
elif [ -x /opt/homebrew/opt/openjdk/bin/javac ]; then
	JAVAC=/opt/homebrew/opt/openjdk/bin/javac
	JAVA=/opt/homebrew/opt/openjdk/bin/java
else
	JAVAC="$(command -v javac)"
	JAVA="$(command -v java)"
fi

OUTPUT="$(mktemp -d "${TMPDIR:-/tmp}/livo-file-transfer-verify.XXXXXX")"
trap 'rm -rf "$OUTPUT"' EXIT

SLF4J_API="$ROOT/livomobile.com/war/WEB-INF/lib/slf4j-api-1.7.7.jar"
SLF4J_BINDING="$ROOT/livomobile.com/war/WEB-INF/lib/slf4j-jdk14-1.7.7.jar"

"$JAVAC" --release 8 -Xlint:all,-options -Werror \
	-cp "$SLF4J_API" \
	-d "$OUTPUT" \
	"$ROOT/livo-server/filetransfer-spi/src/main/java/tr/com/eno/livo/server/file/File.java" \
	"$ROOT/livo-server/filetransfer-spi/src/main/java/tr/com/eno/livo/server/file/FileTransferSession.java" \
	"$ROOT/livo-server/filetransfer-spi/src/main/java/tr/com/eno/livo/server/file/FileTransferService.java" \
	"$ROOT/livo-server/filetransfer-disk/src/main/java/tr/com/eno/livo/server/file/disk/FileTransferAuditLog.java" \
	"$ROOT/livo-server/filetransfer-disk/src/main/java/tr/com/eno/livo/server/file/disk/DiskFileTransferService.java" \
	"$ROOT/livo-server/filetransfer-disk/src/test/java/tr/com/eno/livo/server/file/disk/DiskFileTransferServiceWorkflowTest.java" \
	"$ROOT/livo-server/thrift-proc-filetransfer/src/main/java/tr/com/eno/livo/server/thrift/processor/file/SessionRouteRegistry.java" \
	"$ROOT/livo-server/thrift-proc-filetransfer/src/test/java/tr/com/eno/livo/server/thrift/processor/file/SessionRouteRegistryTest.java"

"$JAVA" -cp "$OUTPUT:$SLF4J_API:$SLF4J_BINDING" \
	tr.com.eno.livo.server.file.disk.DiskFileTransferServiceWorkflowTest
"$JAVA" -cp "$OUTPUT" \
	tr.com.eno.livo.server.thrift.processor.file.SessionRouteRegistryTest
