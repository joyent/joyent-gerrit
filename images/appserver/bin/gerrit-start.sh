#!/bin/bash

set -o xtrace
set -o errexit
set -o pipefail

echo "Starting Gerrit."
exec su -s /bin/bash \
    -c "set -o xtrace; $GERRIT_SITE/bin/gerrit.sh daemon" ${GERRIT_USER}
