#!/usr/bin/env bash
set -euo pipefail

PORT="${PORT:-3000}"
HOST="${HOST:-127.0.0.1}"

if [[ -f ".env.local" ]]; then
  set -a
  # shellcheck source=/dev/null
  source ".env.local"
  set +a
fi

LONGCAT_API_KEY="${LONGCAT_API_KEY:-}"

detect_lan_ip() {
  if command -v ipconfig >/dev/null 2>&1; then
    # macOS
    ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || true
    return
  fi

  if command -v ifconfig >/dev/null 2>&1; then
    # macOS fallback (and some BSDs)
    ifconfig en0 2>/dev/null | awk '/inet /{print $2; exit}' && return
    ifconfig en1 2>/dev/null | awk '/inet /{print $2; exit}' && return
    return
  fi

  if command -v hostname >/dev/null 2>&1; then
    # Linux (many distros)
    hostname -I 2>/dev/null | awk '{print $1}' || true
    return
  fi
}

echo "Starting Flutter web server..."
echo "  HOST=$HOST"
echo "  PORT=$PORT"
echo
echo "Open:"
if [[ "$HOST" == "0.0.0.0" ]]; then
  echo "  http://localhost:$PORT/  (this device)"
  LAN_IP="$(detect_lan_ip || true)"
  if [[ -n "${LAN_IP:-}" ]]; then
    echo "  http://$LAN_IP:$PORT/  (LAN devices)"
  else
    echo "  http://<your-lan-ip>:$PORT/  (LAN devices)"
  fi
else
  echo "  http://$HOST:$PORT/"
fi
echo

ARGS=(run -d web-server --web-port "$PORT" --web-hostname "$HOST")
if [[ -n "${LONGCAT_API_KEY}" ]]; then
  ARGS+=(--dart-define="LONGCAT_API_KEY=${LONGCAT_API_KEY}")
fi

flutter "${ARGS[@]}"
