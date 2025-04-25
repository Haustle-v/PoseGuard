import math


# 头部左右前倾
def is_head_tilted(keypoints):
    """
    此代码采用关键点字典作为输入，其中每个关键点由名称（例如“left_eye”、“right_eye”等）标识，并具有（x，y）坐标。
    然后，计算连接眼睛的直线的水平位置以及直线与水平轴之间的角度。
    如果角度大于5度，会通过计算头部与水平轴之间的角度来检查头部是向左倾斜还是向右倾斜。
    如果角度小于5度，会通过比较鼻子和肩膀之间的距离以及脖子和肩膀之间距离来检查颈部是否向前倾斜。

    参数：
    keypoints：字典
        关键点字典，其中每个关键点由名称（例如“left_eye”、“right_eye”等）标识，并具有（x，y）坐标。
        例如，keypoints['nose'] == {鼻子关键点的x坐标, 鼻子关键点的y坐标}。

    返回值：
    字符串
         若头部左倾则返回"Head tilted left"，若头部右倾则返回"Head tilted right"，若头部不倾斜则返回"Head not tilted"。
         若颈部前倾则返回"Neck tilted forward"，若颈部不倾斜则返回"Neck not tilted forward"。
    """
    # 获取眼睛、鼻子和肩膀的关键点的坐标
    left_eye = keypoints['left_eye']
    right_eye = keypoints['right_eye']
    nose = keypoints['nose']
    left_shoulder = keypoints['left_shoulder']
    right_shoulder = keypoints['right_shoulder']
    neck = keypoints['neck']
    bad_poses = []

    # 计算两眼连线的斜率
    eye_line_slope = (right_eye[1] - left_eye[1]) / (right_eye[0] - left_eye[0])

    # 计算左右肩膀连线中点的纵坐标
    shoulder_midpoint_y = (left_shoulder[1] + right_shoulder[1]) / 2

    # 计算两眼连线与水平轴之间的角度
    eye_line_angle = math.atan(eye_line_slope) * 180 / math.pi

    # 检查头部是否向左或向右倾斜
    if abs(eye_line_angle) > 5:
        # 计算头部与水平轴之间的角度
        head_angle = math.atan((neck[1] - nose[1]) / (neck[0] - nose[0])) * 180 / math.pi

        # 返回头部是否向左或向右倾斜
        if head_angle > 15:
            bad_poses.append("head_left")
        elif head_angle < -15:
            bad_poses.append("head_right")

    else:
        # 检查颈部是否向前倾斜
        nose_shoulder_distance = abs(nose[1] - shoulder_midpoint_y)
        neck_shoulder_distance = abs(neck[1] - shoulder_midpoint_y)

        if neck_shoulder_distance < 0.8 * nose_shoulder_distance:
            bad_poses.append("neck_forward")

    return bad_poses


# 判断身体倾斜情况与高低肩
def is_body_tilted_and_shoulders_uneven(keypoints):
    """
    此函数采用关键点字典作为输入，其中每个关键点由名称（例如“left_eye”、“right_eye”等）标识，并具有（x，y）坐标。
    然后，计算连接眼睛的线的斜率和该线与肩膀中点相交的点的y坐标。如果直线的坡度大于0.2，则确定身体倾斜。
    否则，将计算肩部和每个肩部位置处的视线之间的高度差。如果高度差大于50个像素，则确定肩部不平。

    参数：
    keypoints：字典
        关键点字典，其中每个关键点由名称（例如“left_eye”、“right_eye”等）标识，并具有（x，y）坐标。
        例如，keypoints['nose'] == {鼻子关键点的x坐标, 鼻子关键点的y坐标}。

    返回值：
    字符串
         若身体倾斜则返回"Body tilted"，若身体不倾斜但肩部不平则返回"Shoulders uneven"，
         若正常则返回"Body not tilted and shoulders not uneven"。
    """
    bad_poses = []
    # 获取眼睛、鼻子和肩膀的关键点的坐标
    left_eye = keypoints['left_eye']
    right_eye = keypoints['right_eye']
    left_shoulder = keypoints['left_shoulder']
    right_shoulder = keypoints['right_shoulder']

    # 计算两眼连线的斜率
    eye_line_slope = (right_eye[1] - left_eye[1]) / (right_eye[0] - left_eye[0])

    # 计算将两眼连线平移到左右肩膀中点后的直线的截距
    shoulder_midpoint_y = (left_shoulder[1] + right_shoulder[1]) / 2
    eye_line_intercept_at_midpoint = shoulder_midpoint_y - eye_line_slope * (left_shoulder[0] + right_shoulder[0]) / 2

    # 检查身体是否倾斜
    if abs(eye_line_slope) > 0.2:
        bad_poses.append("body_left")

    else:
        # 检查肩部是否不平
        left_shoulder_height = left_shoulder[1] - (left_shoulder[0] * eye_line_slope + eye_line_intercept_at_midpoint)
        right_shoulder_height = right_shoulder[1] - (right_shoulder[0] * eye_line_slope + eye_line_intercept_at_midpoint)

        if abs(left_shoulder_height - right_shoulder_height) > 50:
            bad_poses.append("shoulder_right")

    return bad_poses


# 判断托腮
def is_chin_supported(keypoints):
    """
    此函数以一个关键点字典作为输入，其中每个关键点都由一个名称（例如“left_wrist”、“right_writ”、“nose”、“neck”等）标识，并具有（x，y）坐标。
    然后，计算手腕、鼻子和颈部关键点之间的距离，并检查这两个距离是否都小于阈值。如果是，则确定下巴受到支撑。

    参数：
    keypoints：字典
        关键点字典，其中每个关键点由名称（例如“left_wrist”、“right_writ”、“nose”、“neck”等）标识，并具有（x，y）坐标。
        例如，keypoints['nose'] == {鼻子关键点的x坐标, 鼻子关键点的y坐标}。
    threshold：浮点数
        手腕与鼻子、手腕与颈部关键点之间的距离的阈值。

    返回值：
    bool
         若托腮则返回True，否则返回False。
    """
    bad_poses = []
    # 获取手腕、鼻子和颈部关键点的坐标
    wrist = keypoints['left_wrist'] if keypoints.get('left_wrist') else keypoints['right_wrist']
    nose = keypoints['nose']
    neck = keypoints['neck']

    # 分别计算手腕与鼻子、手腕与颈部关键点之间的距离
    nose_wrist_dist = math.sqrt((nose[0] - wrist[0])**2 + (nose[1] - wrist[1])**2)
    neck_wrist_dist = math.sqrt((neck[0] - wrist[0])**2 + (neck[1] - wrist[1])**2)

    # 检查距离是否小于阈值
    if nose_wrist_dist < 30 and neck_wrist_dist < 30:
        bad_poses.append("chin_in_hands")

    return bad_poses


# 判断侧头
def is_lateral_head(keypoints):
    """
    此函数以关键点字典作为输入，其中每个关键点由名称（例如“nose”、“neck”等）标识，并具有（x，y）坐标。
    然后，计算鼻子和颈部关键点之间的横向距离差，并检查它是否大于阈值。如果是，则确定头部是横向倾斜的。

    参数：
    keypoints：字典
        关键点字典，其中每个关键点由名称（例如“nose”、“neck”等）标识，并具有（x，y）坐标。
        例如，keypoints['nose'] == {鼻子关键点的x坐标, 鼻子关键点的y坐标}。
    threshold：浮点数
        鼻子和颈部关键点在水平方向的距离差的阈值。

    返回值：
    bool
         若侧头则返回True，否则返回False。
    """
    bad_poses = []
    # 获取鼻子和颈部关键点的坐标
    nose = keypoints['nose']
    neck = keypoints['neck']

    # 计算鼻子和颈部关键点在水平方向的距离差
    lateral_diff = abs(nose[0] - neck[0])

    # 检查距离差是否大于阈值
    if lateral_diff > 30:
        bad_poses.append("head_left")

    return bad_poses

    # 判断驼背
def is_hunchback(keypoints):
    """
    此函数以关键点字典作为输入，其中每个关键点由名称（例如“nose”、“neck”、“left_shoulder”、“right_shoulder”等）标识，并具有（x，y）坐标。
    在这个函数中，首先检查鼻子和颈部的关键点是否低于肩部的两个关键点，表明肩部降低，颈部下沉。
    然后，计算肩部关键点之间的正常和当前水平距离，以及鼻子和颈部关键点的中点与肩部关键点的垂直距离。
    如果当前的水平距离小于正常距离，而垂直距离小于设定的阈值，则确定该人驼背。否则，返回False。

    参数：
    keypoints：字典
        关键点字典，其中每个关键点由名称（例如“nose”、“neck”、“left_shoulder”、“right_shoulder”等）标识，并具有（x，y）坐标。
        例如，keypoints['nose'] == {鼻子关键点的x坐标, 鼻子关键点的y坐标}。
    normal_distance：浮点数
        肩部关键点之间非驼背状态下的正常水平距离。
    threshold：浮点数
        鼻子与颈部的中点和肩部关键点的竖直距离的阈值。

    返回值：
    bool
        若驼背则返回True，否则返回False。
    """
    bad_poses = []
    # 获取鼻子、颈部和肩膀关键点的坐标
    nose = keypoints['nose']
    neck = keypoints['neck']
    left_shoulder = keypoints['left_shoulder']
    right_shoulder = keypoints['right_shoulder']
    # 检查鼻子和脖子是否低于肩膀
    if nose[1] < left_shoulder[1] and nose[1] < right_shoulder[1] and \
            neck[1] < left_shoulder[1] and neck[1] < right_shoulder[1]:

        # 计算肩部关键点之间的当前水平距离
        current_distance = abs(left_shoulder[0] - right_shoulder[0])

        # 计算鼻子与颈部的中点和肩部关键点的竖直距离
        midpoint = [(nose[0] + neck[0]) / 2, (nose[1] + neck[1]) / 2,
                    (nose[2] + neck[2]) / 2]
        vertical_distance = abs(midpoint[1] - left_shoulder[1])

        # 检查当前水平距离是否小于正常距离，竖直距离是否小于设定的阈值（表示肩部降低，颈部下沉）
        if current_distance < 130 and vertical_distance < 30:
            bad_poses.append("hunchback")

    return bad_poses
