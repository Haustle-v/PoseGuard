import json
import time
from datetime import datetime
from flask import Blueprint, Flask
import mysql.connector
from websockets.asyncio.server import serve
import asyncio

app = Flask(__name__)
checkin_blue = Blueprint('checkin', __name__)

async def check_posture(websocket):
    print("坐姿检查已启动")
    while True:
        await asyncio.sleep(1)
        # await websocket.send('hello client')
        # print('Message sent')

        bad_poses = []
        bad_poses_list = ['head_left', 'head_right', 'hunchback', 'chin_in_hands', 'body_left', 'body_right',
        'neck_forward', 'shoulder_left', 'shoulder_right', 'twisted_head']

        await asyncio.sleep(30)

        conn = mysql.connector.connect(
                host="localhost",
                user="root",
                password="Hsj70750",
                database="db1"
            )

        cursor = conn.cursor()

        current_time = datetime.now()
        formatted_time = current_time.strftime("%Y%m%d%H%M%S")

        for i in range(10):

            bad_pose = bad_poses_list[i]
            check_sql = f"""
                SELECT SUM({bad_pose}) AS total_sum
                FROM (
                    SELECT {bad_pose}
                    FROM posture_log
                    WHERE timestamp <= '{formatted_time}'
                    ORDER BY timestamp DESC
                    LIMIT 10
                ) AS subquery
            """
            cursor.execute(check_sql)
            result = cursor.fetchone()
            total_sum = result[0] if result[0] is not None else 0

            if total_sum >= 5:
                bad_poses.append(bad_pose)

        if bad_poses:
            # 调用realtime_advice获取建议
            from app.advice.get_advice import realtime_advice
            advice_result = realtime_advice(bad_poses)
            # 发送WebSocket消息
            await websocket.send(json.dumps(advice_result,ensure_ascii=False))
            print(f'已发送{advice_result}')

        cursor.close()
        conn.close()


async def start_websocket_server():
    async with serve(check_posture, "localhost", 8765,ping_interval=None) as server:
        print("WebSocket服务器已启动在 ws:// 0.0.0.0:8765")
        await server.serve_forever()

@checkin_blue.route('/')
def start_server():
    with app.app_context():
        asyncio.run(start_websocket_server())