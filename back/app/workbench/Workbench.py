
import threading
from datetime import time,datetime
from flask import Blueprint, jsonify,Flask
from ..openpose import OpenPoseWrapperclass
from .JudgePose import is_head_tilted,is_lateral_head,is_hunchback,is_chin_supported,is_body_tilted_and_shoulders_uneven
import time
import mysql.connector


app = Flask(__name__)

# 创建路由蓝图
workbench_blue = Blueprint('workbench', __name__)

@workbench_blue.route('/')
def workbench():
    with app.app_context():  # 手动创建应用上下文
        # 启动检测坐姿的线程
        print("坐姿检测已启动")
        threading.Thread(target=detect_pose,daemon=True).start()
        return jsonify({"status":"success","message":"坐姿检测已启动"})


def detect_pose():
    with app.app_context():  # 手动创建应用上下文
        from .. import socketio

        try:
            # 调用OpenPose
            openpose = OpenPoseWrapperclass()
            ### 获取标准坐姿
            standardPose = openpose.get_standard_pose(openpose.cap, openpose.numberToWord, num_samples=3)   # 采样次数

            while True:
                try:
                    #循环检测坐姿并判断
                    keyPoints = get_keyPoints(openpose, openpose.cap)
                    print(keyPoints)
                    bad_poses = judge_pose(standardPose, keyPoints)
                    print(bad_poses)
                    # 如果有不良坐姿向前端发送信息
                    if  bad_poses:
                        # socketio.emit('alert', bad_poses)
                        write_bad_posture_to_db(bad_poses)
                        # write_bad_posture_to_json(bad_poses)
                    # 每5秒检测一次
                    # await sleep(5)
                    time.sleep(3)

                except Exception as e:
                    # print(f"检测过程中出错: {str(e)}")
                    time.sleep(1)# 出错后暂停一下再继续

        except Exception as e:
            # print(f"姿势检测初始化失败: {str(e)}")
            return jsonify({'error': str(e)})



def get_keyPoints(openpose, cap):
    keyPoints = {}
    ret, oriImg = cap.read()
    candidate, subset = openpose.body_estimation(oriImg)

    if len(subset) > 0:
        for i in range(18):
            index = int(subset[0][i])
            if index == -1:
                continue
            x, y = candidate[index][0:2]
            if openpose.numberToWord[i] != '':
                keyPoints.update({openpose.numberToWord[i]: [x, y]})

    return keyPoints

def judge_pose(standardPose, keyPoints):
    # 定义不良坐姿的阈值
    bad_poses = []
    bad_poses.extend(is_head_tilted(keyPoints))
    bad_poses.extend(is_hunchback(keyPoints))
    bad_poses.extend(is_body_tilted_and_shoulders_uneven(keyPoints))
    # bad_poses.extend(is_chin_supported(keyPoints))
    bad_poses.extend(is_lateral_head(keyPoints))

    return bad_poses  # 返回不良坐姿类型列表，如果没有不良坐姿则返回空列表

# 将不良坐姿数据写入数据库
def write_bad_posture_to_db(bad_poses):
        head_left = 1 if 'head_left' in bad_poses else 0
        print(head_left)
        head_right = 1 if 'head_right' in bad_poses else 0
        print(head_right)
        hunchback=1 if 'hunchback' in bad_poses else 0
        print(hunchback)
        chin_in_hands=1 if 'chin_in_hands' in bad_poses else 0
        print(chin_in_hands)
        body_left=1 if 'body_left' in bad_poses else 0
        print(body_left)
        body_right=1 if 'body_right' in bad_poses else 0
        print(body_right)
        neck_forward=1 if 'neck_forward' in bad_poses else 0
        print(neck_forward)
        shoulder_left=1 if 'shoulder_left' in bad_poses else 0
        print(shoulder_left)
        shoulder_right=1 if 'shoulder_right' in bad_poses else 0
        print(shoulder_right)
        twisted_head=1 if 'twisted_head' in bad_poses else 0
        print(twisted_head)
        # 连接数据库
        conn = mysql.connector.connect(
            host="localhost",
            user="root",
            password="Hsj70750",
            database="db1"
        )
        # 创建游标
        cursor = conn.cursor()
        # 执行添加
        sql = "insert into posture_log(timestamp,head_left,head_right,hunchback,chin_in_hands,body_left,body_right,neck_forward,shoulder_left,shoulder_right,twisted_head) values(%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s);"
        # 获取当前时间戳
        current_time = datetime.now()
        formatted_time = current_time.strftime("%Y%m%d%H%M%S")
        values = (formatted_time,head_left,head_right,hunchback,chin_in_hands,body_left,body_right,neck_forward,shoulder_left,shoulder_right,twisted_head)
        cursor.execute(sql, params=values)
        # 提交
        conn.commit()
        # 关闭连接
        cursor.close()
        conn.close()

