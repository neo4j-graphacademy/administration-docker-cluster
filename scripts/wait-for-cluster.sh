#!/usr/bin/env bash
# Poll the cluster until all five servers report a state of Enabled.
set -euo pipefail

EXPECTED=5
ATTEMPTS=60
SLEEP=5

echo "Waiting for ${EXPECTED} servers to be Enabled..."

for _ in $(seq 1 "${ATTEMPTS}"); do
    count=$(docker exec core-1 cypher-shell \
        -u neo4j -p neo4j-password --format plain \
        "SHOW SERVERS YIELD state WHERE state = 'Enabled' RETURN count(*)" \
        2>/dev/null | tail -n1 | tr -d '[:space:]' || true)

    if [ "${count:-0}" = "${EXPECTED}" ]; then
        echo "Cluster is ready: ${EXPECTED} servers Enabled."
        exit 0
    fi

    echo "  ${count:-0}/${EXPECTED} enabled, retrying..."
    sleep "${SLEEP}"
done

echo "Timed out waiting for the cluster to form." >&2
exit 1
