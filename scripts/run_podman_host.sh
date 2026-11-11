#!/usr/bin/env bash
# Run the benchmark ON the serving host, inside a throw-away container from the same image as the server
# (identical Python/aiohttp on every host, no network hop), with the server's log streamed in for the exclusivity check.
#   scripts/run_podman_host.sh <server-container> <label> [run.py args...]
# Example: scripts/run_podman_host.sh glm official --concurrency 16,32,64 --warmup 60 --duration 180
set -euo pipefail
CTR=$1; LABEL=$2; shift 2
HERE=$(cd "$(dirname "$0")/.." && pwd)
PODMAN=${PODMAN:-"sudo podman"}
IMG=$($PODMAN inspect "$CTR" --format '{{.ImageName}}')
PORT=${PORT:-30000}; MODEL=${MODEL:-zai-org/GLM-5.3-Flash}
LOG=$HERE/results/$LABEL/server.log; mkdir -p "$HERE/results/$LABEL"; : > "$LOG"
$PODMAN logs -f --since 1s "$CTR" > "$LOG" 2>&1 &
LP=$!; trap 'kill $LP 2>/dev/null || true' EXIT
$PODMAN run --rm --network host --entrypoint python3 -v "$HERE":/b:Z "$IMG" /b/bench/run.py \
  --url "http://127.0.0.1:$PORT" --model "$MODEL" --label "$LABEL" --out "/b/results/$LABEL" \
  --server-log-cmd "tail -n0 -F /b/results/$LABEL/server.log" "$@"
rm -f "$LOG"   # raw server log is not kept (it contains other users' request metadata if any); only the parsed check is
