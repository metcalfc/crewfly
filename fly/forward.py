#!/usr/bin/env python3
"""Relay Fly private-network (6PN, IPv6) connections to the Crew Gateway.

Why this exists: Fly's private network is IPv6-only, and `fly proxy` / WireGuard
peers dial the Machine's 6PN address. The gateway binds exactly one address
(KIROCREW_BIND). Binding `::` makes it IPv6-only (Crew sets IPV6_V6ONLY), which
breaks Crew's own CLI: `kirocrew token` and friends dial 127.0.0.1. So the
gateway stays on the image's IPv4 bind and this relay covers the 6PN side.

It listens ONLY on the 6PN address, never on the public interface, and on a
different port from the gateway so Crew's port-ownership checks never see a
second process on its port.

Upstream address: the Machine's own non-loopback IPv4, not 127.0.0.1. Crew
treats a loopback peer as "this machine" and unlocks secret-reveal and
credential-write pages for it. Dialing the interface address makes relayed
connections arrive as a non-loopback peer, so the dashboard treats them as
remote (read-only credential pages), which is the fail-closed choice.
"""

import asyncio
import os
import socket
import sys

GATEWAY_PORT = int(os.environ.get("KIROCREW_PORT", "5476"))
LISTEN_PORT = int(os.environ.get("CREWFLY_PRIVATE_PORT", "5477"))
BUFFER = 64 * 1024


def log(msg: str) -> None:
    print(f"[crewfly-forward] {msg}", file=sys.stderr, flush=True)


def private_listen_address() -> str:
    # Fly writes this Machine's 6PN address into /etc/hosts as fly-local-6pn.
    return socket.getaddrinfo("fly-local-6pn", None, socket.AF_INET6)[0][4][0]


def gateway_address() -> str:
    override = os.environ.get("CREWFLY_UPSTREAM", "").strip()
    if override:
        return override
    # Source address the kernel would pick for an outbound IPv4 packet. A UDP
    # connect() sends nothing; it only resolves the route.
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as probe:
        probe.connect(("192.0.2.1", 9))
        return probe.getsockname()[0]


async def pump(reader: asyncio.StreamReader, writer: asyncio.StreamWriter) -> None:
    try:
        while data := await reader.read(BUFFER):
            writer.write(data)
            await writer.drain()
    except (ConnectionError, asyncio.CancelledError):
        pass
    finally:
        writer.close()


async def main() -> None:
    listen = private_listen_address()
    upstream = gateway_address()

    async def handle(reader: asyncio.StreamReader, writer: asyncio.StreamWriter) -> None:
        try:
            up_reader, up_writer = await asyncio.open_connection(upstream, GATEWAY_PORT)
        except OSError as exc:
            log(f"gateway not reachable at {upstream}:{GATEWAY_PORT}: {exc}")
            writer.close()
            return
        await asyncio.gather(pump(reader, up_writer), pump(up_reader, writer))

    server = await asyncio.start_server(handle, listen, LISTEN_PORT, family=socket.AF_INET6)
    log(f"[{listen}]:{LISTEN_PORT} -> {upstream}:{GATEWAY_PORT}")
    async with server:
        await server.serve_forever()


if __name__ == "__main__":
    asyncio.run(main())
