# pose_detection/OpenPoseWrapper.py
import cv2
import os
import time
# from PyOpenPose.src.body import models
from .body import Body

keyPoints = {}

class OpenPoseWrapperclass:
    def __init__(self):
        # 获取当前文件所在目录
        current_dir = os.path.dirname(os.path.abspath(__file__))
        # 构建相对路径
        model_path = 'body_pose_model.pth'
        # 使用相对路径构建绝对路径
        model_path = os.path.join(current_dir, model_path)
        self.body_estimation = Body(model_path)
        # self.body_estimation = Body('./PyOpenPose/openpose/models/body_pose_model.pth')
        self.cap = cv2.VideoCapture(0)
        self.cap.set(cv2.CAP_PROP_FRAME_WIDTH, 128)
        self.cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 96)
        self.numberToWord = ['nose', 'neck', 'right_shoulder', '', 'left_wrist', 'left_shoulder', '', 'right_wrist', '', '', '', '',
                '', '', 'right_eye', 'left_eye', '', '']

    def get_standard_pose(self, cap, numberToWord, num_samples):
        standard_poses = {}

        for sample_count in range(num_samples):
            keyPoints = {}
            ret, oriImg = cap.read()
            candidate, subset = self.body_estimation(oriImg)

            if len(subset) > 0:
                for i in range(18):
                    index = int(subset[0][i])
                    if index == -1:
                        continue
                    x, y = candidate[index][0:2]
                    if numberToWord[i] != '':
                        if numberToWord[i] not in keyPoints:
                            keyPoints[numberToWord[i]] = []
                        keyPoints[numberToWord[i]].append([x, y])

            # 打印或存储每个采样的中间关键点，如果需要的话
            print(f"第 {sample_count + 1} 次采样: {keyPoints}")

            # 等待一秒
            time.sleep(1)

            # 累积用于平均的关键点
            for key, values in keyPoints.items():
                if key not in standard_poses:
                    standard_poses[key] = []
                standard_poses[key].extend(values)

        # 计算每个关键点的平均值
        for key, values in standard_poses.items():
            average_x = sum(point[0] for point in values) / num_samples
            average_y = sum(point[1] for point in values) / num_samples
            standard_poses[key] = [average_x, average_y]

        return standard_poses
