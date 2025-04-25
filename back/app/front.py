import asyncio
import websockets

async def main():
    print("正在尝试连接到服务器...")
    try:
        async with websockets.connect('ws://localhost:8080') as websocket:
            print("已成功连接到服务器")
            while True:
                print("等待接收消息...")
                # 接收服务器发送的消息
                message = await websocket.recv()
                print(f"收到服务器消息: {message}")
    except Exception as e:
        print(f"发生错误: {str(e)}")
    finally:
        print("客户端已关闭")


# 运行客户端
if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("程序被用户中断")