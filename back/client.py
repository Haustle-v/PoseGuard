#!/usr/bin/env python

"""Client using the asyncio API."""

import asyncio
from websockets.asyncio.client import connect


async def main():
    async with connect("ws://localhost:8765",ping_interval=None) as websocket:
        print("Connected")
        while True:
            message = await websocket.recv()
            print('Received message:', message)


if __name__ == "__main__":
    asyncio.run(main())
