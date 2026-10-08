#!/bin/sh
# Fly entrypoint for the Crew Gateway image. Runs as root, does the two things
# the upstream image cannot do for itself on Fly, then hands off to the
# upstream entrypoint as the unprivileged `kirocrew` user.
set -eu

CREW_USER=kirocrew
CREW_HOME=/home/kirocrew

# 1. Volume ownership. Fly mounts the volume with its mount point owned by
#    root (uid 0, mode 0755) on every boot, so uid 1000 cannot write to its own
#    home. Docker named volumes inherit the image's ownership, which is why
#    upstream never needed this. Only the mount point is chowned: everything
#    beneath it is created by `kirocrew` and keeps its ownership across boots.
chown "$CREW_USER:$CREW_USER" "$CREW_HOME"

as_crew() {
    setpriv --reuid="$CREW_USER" --regid="$CREW_USER" --init-groups \
        env HOME="$CREW_HOME" USER="$CREW_USER" "$@"
}

# 2. Private-network reachability. The gateway keeps the image's IPv4 bind
#    (0.0.0.0); Fly private networking is IPv6-only. The forwarder listens on
#    this Machine's 6PN address and relays to the gateway. See fly/forward.py.
if [ "${1:-gateway}" = "gateway" ]; then
    (
        while :; do
            as_crew crewfly-forward || true
            echo "[crewfly] forwarder exited; restarting in 2s." >&2
            sleep 2
        done
    ) &
fi

cd "$CREW_HOME"
exec setpriv --reuid="$CREW_USER" --regid="$CREW_USER" --init-groups \
    env HOME="$CREW_HOME" USER="$CREW_USER" kirocrew-entrypoint "$@"
