#!/bin/bash

set -eu

: "${AEON_HOME:?Set AEON_HOME to the absolute Livo runtime directory}"

# Remote JMX is intentionally disabled by default. Operators who need it must
# provide authenticated, TLS-enabled settings through their deployment tooling.
exec java ${JAVA_OPTS:-} \
	-Duser.language=en \
	-Duser.country=US \
	"-Dfelix.fileinstall.dir=$AEON_HOME/conf/services" \
	"-Dfelix.cm.dir=$AEON_HOME/conf/services" \
	"-Dlivo.home=$AEON_HOME" \
	-jar bin/felix.jar
