#!/usr/bin/env bash
# Open the Crew dashboard: private tunnel + fresh login link.
#
#   ./dashboard.sh
#   FLY_APP=my-app ./dashboard.sh    # if fly.toml has no app name
#
# Leave it running; Ctrl+C closes the tunnel.
set -euo pipefail
cd "$(dirname "$0")"

LOCAL_PORT=5476   # must match the gateway's port: the login link points here
REMOTE_PORT=5477  # the 6PN relay, see fly/forward.py

fly proxy "$LOCAL_PORT:$REMOTE_PORT" -q &
proxy=$!
trap 'kill "$proxy" 2>/dev/null || true' EXIT

url=""
for _ in $(seq 1 20); do
    url=$(fly ssh console -u kirocrew -C "kirocrew token --ttl 6h" 2>/dev/null |
        tr -d '\r' | grep -m1 -o 'http://localhost[^[:space:]]*' || true)
    [ -n "$url" ] && break
    sleep 3
done
if [ -z "$url" ]; then
    echo "Could not mint a login link. Is the gateway up? Try: fly logs" >&2
    exit 1
fi

echo
echo "Dashboard (link is good for a few minutes, the session for 6h):"
echo "  $url"
echo
if [ -z "${CREWFLY_NO_BROWSER:-}" ]; then
    if command -v open >/dev/null 2>&1; then
        open "$url"
    elif command -v xdg-open >/dev/null 2>&1; then
        xdg-open "$url" >/dev/null 2>&1 || true
    fi
fi

echo "Tunnel open on localhost:$LOCAL_PORT. Ctrl+C to close."
wait "$proxy"
