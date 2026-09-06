"""Local-only, ordered WebSocket latency/jitter/bandwidth test fixture.

TCP preserves messages: this models queuing, not independent datagram loss.
Never deploy this proxy in production.
"""
import argparse
import asyncio
import random

from websockets.asyncio.client import connect
from websockets.asyncio.server import serve
from websockets.exceptions import ConnectionClosed


async def forward(source, destination, latency, jitter, bytes_per_second):
    queue = asyncio.Queue(maxsize=128)
    rng = random.Random(42)

    async def receive():
        async for message in source:
            due = asyncio.get_running_loop().time() + max(0, latency + rng.uniform(-jitter, jitter))
            await queue.put((due, message))
        await queue.put(None)

    async def send():
        available_at = 0.0
        while True:
            item = await queue.get()
            if item is None:
                return
            due, message = item
            size = len(message.encode("utf-8")) if isinstance(message, str) else len(message)
            now = asyncio.get_running_loop().time()
            available_at = max(due, available_at, now) + size / bytes_per_second
            await asyncio.sleep(max(0, available_at - now))
            await destination.send(message)

    tasks = [asyncio.create_task(receive()), asyncio.create_task(send())]
    try:
        await asyncio.gather(*tasks)
    finally:
        for task in tasks:
            task.cancel()
        await asyncio.gather(*tasks, return_exceptions=True)


async def run(args):
    async def handle(client):
        tasks = []
        try:
            async with connect(args.upstream, compression=None, max_size=131072) as upstream:
                for source, destination in ((client, upstream), (upstream, client)):
                    tasks.append(asyncio.create_task(forward(source, destination, args.latency_ms / 1000,
                                                             args.jitter_ms / 1000, args.bandwidth_kbps * 125)))
                done, _ = await asyncio.wait(tasks, return_when=asyncio.FIRST_COMPLETED)
                for task in done:
                    task.result()
        except ConnectionClosed:
            pass
        finally:
            for task in tasks:
                task.cancel()
            await asyncio.gather(*tasks, return_exceptions=True)

    async with serve(handle, "127.0.0.1", args.port, compression=None, max_size=131072):
        print("TRAFFIC_PROXY: READY", flush=True)
        await asyncio.Future()


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", type=int, required=True)
    parser.add_argument("--upstream", required=True)
    parser.add_argument("--latency-ms", type=float, default=100)
    parser.add_argument("--jitter-ms", type=float, default=30)
    parser.add_argument("--bandwidth-kbps", type=float, default=512)
    options = parser.parse_args()
    if options.latency_ms < 0 or options.jitter_ms < 0 or options.bandwidth_kbps <= 0:
        parser.error("Latency/jitter must be nonnegative and bandwidth must be positive")
    asyncio.run(run(options))
