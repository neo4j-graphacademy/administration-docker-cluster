#!/usr/bin/env bash
# Poll the cluster until all five servers have joined and report Available.
# Note: fresh secondaries show state Free until they are allocated to a
# database (see the lesson on allocating secondaries), so this waits on
# health, not the Enabled state.
set -euo pipefail

EXPECTED=5
ATTEMPTS=60
SLEEP=5

echo "Waiting for ${EXPECTED} servers to be Available..."

for _ in $(seq 1 "${ATTEMPTS}"); do
    count=$(docker exec core-1 cypher-shell \
        -u neo4j -p neo4j-password --format plain \
        "SHOW SERVERS YIELD health WHERE health = 'Available' RETURN count(*)" \
        2>/dev/null | tail -n1 | tr -d '[:space:]' || true)

    if [ "${count:-0}" = "${EXPECTED}" ]; then
        echo "Cluster is ready: ${EXPECTED} servers Available."
        exit 0
    fi

    echo "  ${count:-0}/${EXPECTED} available, retrying..."
    sleep "${SLEEP}"
done

echo "Timed out waiting for the cluster to form." >&2
exit 1
