from app import create_app
from config import config
import threading
import time

# 创建Flask实例
app = create_app(config)

def start_pose_detection():
    with app.app_context():  # 手动创建应用上下文
        # 直接在python内部启动姿势检测
        time.sleep(5)# 等待Flask应用完全启动
        from app.workbench.Workbench import workbench
        workbench()# 直接调用函数


def start_pose_check():
    with app.app_context():  # 手动创建应用上下文
        time.sleep(5)  # 等待Flask应用完全启动
        from app.analyse.Checkin import start_server
        start_server()  # 直接调用函数


if __name__ == "__main__":
    # 初始化线程
    detection_thread = threading.Thread(target=start_pose_detection)
    check_thread = threading.Thread(target=start_pose_check)

    # 设置为守护线程
    detection_thread.daemon = True
    check_thread.daemon = True

    # 启动线程
    detection_thread.start()
    check_thread.start()

    # 启动 Flask 应用
    app.run(debug=True, host='0.0.0.0', port=8002,use_reloader=False)

