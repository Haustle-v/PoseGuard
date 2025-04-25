from flask_socketio import SocketIO
from flask import Flask
from flask_cors import CORS
from app.analyse import checkin_blue
from app.workbench import workbench_blue
from app.advice import  advice_blue

socketio = None


def create_app(config):
    # 创建Flask实例
    app = Flask(__name__)
    # 不以ASCII码形式返回
    app.config['JSON_AS_ASCII'] = False
    CORS(app, supports_credentials=True)
    global socketio
    socketio = SocketIO(app)

    app.register_blueprint(workbench_blue, url_prefix='/workbench')  # 程序主界面，负责坐姿检测等逻辑
    app.register_blueprint(checkin_blue, url_prefix='/checkin')  # 数据分析与查看模块
    app.register_blueprint(advice_blue, url_prefix='/advice')  # 坐姿建议生成模块

    return app
