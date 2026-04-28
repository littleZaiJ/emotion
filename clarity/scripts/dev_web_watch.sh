#!/usr/bin/env bash
set -euo pipefail

# Flutter web dev server that rebuilds on Dart file changes so remote clients
# can see updates by refreshing the page.
#
# Usage:
#   cd clarity
#   bash scripts/dev_web_watch.sh
#
# Env:
#   HOST=0.0.0.0 PORT=8080 WATCH_DIRS="lib test"

HOST="${HOST:-0.0.0.0}"
PORT="${PORT:-8080}"
WATCH_DIRS="${WATCH_DIRS:-lib test}"
if [[ -f ".env.local" ]]; then
  set -a
  # shellcheck source=/dev/null
  source ".env.local"
  set +a
fi

LONGCAT_API_KEY="${LONGCAT_API_KEY:-}"
POLL_SECONDS="${POLL_SECONDS:-1}"
DEBOUNCE_SECONDS="${DEBOUNCE_SECONDS:-0.6}"
# Default to hot restart on web-server: hot reload often times out with remote clients.
RELOAD_CMD="${RELOAD_CMD:-R}"
FIFO="${FIFO:-/tmp/clarity_flutter_hot_reload.fifo}"

rm -f "$FIFO"
mkfifo "$FIFO"

cleanup() {
  exec 3>&- 3<&- || true
  rm -f "$FIFO"
}
trap cleanup EXIT

latest_mtime() {
  # macOS stat: -f %m prints mtime epoch seconds.
  # If no files match, print 0.
  local mt
  mt="$(
    find $WATCH_DIRS -type f -name '*.dart' -print0 2>/dev/null \
      | xargs -0 stat -f '%m' 2>/dev/null \
      | sort -n \
      | tail -n 1
  )"
  echo "${mt:-0}"
}

echo "[dev_web_watch] Starting Flutter web-server on ${HOST}:${PORT}"
echo "[dev_web_watch] Watching: ${WATCH_DIRS} (poll ${POLL_SECONDS}s)"
echo "[dev_web_watch] Reload command: ${RELOAD_CMD} (r=reload, R=restart)"
echo "[dev_web_watch] Refresh the page to see latest build."

# Hold FIFO open read+write to avoid blocking on open(2),
# but let Flutter read from its own read-only open of the FIFO.
exec 3<>"$FIFO"

ARGS=(run -d web-server --web-hostname "$HOST" --web-port "$PORT")
if [[ -n "${LONGCAT_API_KEY}" ]]; then
  ARGS+=(--dart-define="LONGCAT_API_KEY=${LONGCAT_API_KEY}")
fi

flutter "${ARGS[@]}" <"$FIFO" &
flutter_pid="$!"

trap 'kill "$flutter_pid" 2>/dev/null || true; cleanup' EXIT

last="$(latest_mtime)"
reloading=0
while true; do
  sleep "$POLL_SECONDS"
  now="$(latest_mtime)"
  if [[ "$now" != "$last" ]]; then
    last="$now"
    if [[ "$reloading" == "1" ]]; then
      continue
    fi

    reloading=1
    # Debounce bursts of file writes (e.g. save-all / build_runner).
    sleep "$DEBOUNCE_SECONDS"
    last="$(latest_mtime)"

    # Trigger hot reload so the next refresh pulls new JS.
    echo "[dev_web_watch] change detected -> trigger ${RELOAD_CMD}" >&2
    printf "%s\n" "$RELOAD_CMD" >"$FIFO" || true

    # Avoid piling up reload commands.
    sleep 1
    reloading=0
  fi
done
