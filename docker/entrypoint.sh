#!/bin/bash
# Sn1per Docker entrypoint
set -e

echo "========================================"
echo "  Sn1per Docker Environment"
echo "  Version: $(cat /opt/sniper/lib/bootstrap.sh | grep ^VER= | cut -d'"' -f2)"
echo "========================================"

service postgresql start 2>/dev/null || true

if [[ -z "$1" || "${1:0:1}" == "-" ]]; then
  exec /opt/sniper/sniper "$@"
else
  exec "$@"
fi
