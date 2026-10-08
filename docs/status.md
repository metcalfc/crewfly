# Status

Crew 0.7.2, kiro-cli 2.25.0, flyctl 0.4.102. Last tested 2026-10-06.

## Tested on a live deploy

- [x] `fly launch --copy-config --yes` gives one Machine, one volume, no IPs
- [x] Gateway healthy about 10 s after start
- [x] Crew's sandbox backend is available
- [x] `./dashboard.sh` gives an authenticated session
- [x] Builder ID device-code sign-in
- [x] Cron job calls the model and runs a shell command on schedule
- [x] Sign-in, state and cron survive restart and redeploy

## Not tested

- [ ] `./launch.sh` in one run (each step was run by hand)
- [ ] Dashboard in a real browser, including WebSocket
- [ ] Credential pages are read-only through the relay
- [ ] Sandbox hides gateway credentials from agent commands
- [ ] Any messaging channel
- [ ] `KIRO_API_KEY` sign-in
- [ ] Memory and CPU under real session load

## Known rough edges

- `fly launch --copy-config` rewrites `fly.toml` and drops its comments.
- `fly machine restart` sends SIGINT regardless of `kill_signal`. The gateway still exits cleanly.
- The image's startup banner says `docker exec <container> ...`.
- `kirocrew chat -m` auto-denies tool calls. Use the dashboard, or a cron with `--approval-mode auto`.
- `kirocrew doctor` exits non-zero: the image has no ffmpeg or speech dependencies.

## Questions for the Crew team

1. Can the gateway bind loopback plus a second address? Removes the relay.
2. Can the entrypoint start as root, chown, and drop privileges? With 1, removes the Dockerfile.
3. Can webhooks get their own port?
4. Is a remote provisioner the route to a real 1-click? What would a Fly connection method need?
5. What does a gateway need once sessions run elsewhere?
6. Is `KIRO_API_KEY` supported for a hosted gateway?
7. Is replacing the image over an existing home a supported upgrade path?
8. The repo is Apache 2.0; the image label says MIT.
