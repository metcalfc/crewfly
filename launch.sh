#!/usr/bin/env bash
# Deploy a Crew Gateway to Fly, sign in to Kiro, open the dashboard.
#
#   ./launch.sh                      # device-code sign-in
#   KIRO_API_KEY=... ./launch.sh     # API-key sign-in, no prompt
#   ./launch.sh --org my-org --region iad
#
# Extra arguments go to `fly launch`.
set -euo pipefail
cd "$(dirname "$0")"

args=(--copy-config --yes)
[ -n "${KIRO_API_KEY:-}" ] && args+=(--secret "KIRO_API_KEY=$KIRO_API_KEY")

fly launch "${args[@]}" "$@"

if [ -z "${KIRO_API_KEY:-}" ]; then
    echo
    echo "Sign in to Kiro: pick a method, then approve the code in your browser."
    fly ssh console -u kirocrew --pty -C "kiro-cli login --use-device-flow"
fi

exec ./dashboard.sh
