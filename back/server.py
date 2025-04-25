#!/usr/bin/env python

"""Echo server using the asyncio API."""

import asyncio
from websockets.asyncio.server import serve


async def echo(websocket):
        await websocket.send('hello client')
        print('Message sent')


async def main():
    async with serve(echo, "localhost", 8765,ping_interval=None) as server:
        print("Server started.")
        await server.serve_forever()


if __name__ == "__main__":
    asyncio.run(main())
