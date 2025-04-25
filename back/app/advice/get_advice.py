from flask import Flask,make_response,json,jsonify,Blueprint,request
from openai import OpenAI
import mysql.connector
import datetime
from datetime import date,datetime
import websockets
import asyncio

from sympy.polys.polyconfig import query

app = Flask(__name__)

# 实时路由
# 处理 HTTP 请求（普通页面）
# 创建 Blueprint 实例
advice_blue = Blueprint('advice', __name__)

# 定义 Blueprint 中的路由
@advice_blue.route('/realtime')
def realtime_advice(bad_poses):

    print('开始生成警告')

    # 获取当前时间戳
    current_time = datetime.now()
    formatted_time = current_time.strftime("%Y%m%d%H%M%S")

    # 获取bad_poses字符串
    str_bad_poses = ''
    for bad_pose in bad_poses:
        if bad_pose == 'head_left':
            bad_pose = '头部左倾'
        elif bad_pose == 'head_right':
            bad_pose = '头部右倾'
        elif bad_pose == 'hunchback':
            bad_pose = '驼背'
        elif bad_pose == 'chin_in_hands':
            bad_pose = '托腮'
        elif bad_pose == 'body_left':
            bad_pose = '身体左倾'
        elif bad_pose == 'body_right':
            bad_pose = '身体右倾'
        elif bad_pose == 'neck_forward':
            bad_pose = '颈部前伸'
        elif bad_pose == 'shoulder_left':
            bad_pose = '左肩下沉'
        elif bad_pose == 'shoulder_right':
            bad_pose = '右肩下沉'
        elif bad_pose == 'twisted_head':
            bad_pose = '头部歪斜'
        str_bad_poses += bad_pose + ','
        # 去掉最后一个多余的逗号
        str_bad_poses = str_bad_poses.rstrip(',')

    # 生成返回字典
    res = {
        "advice_id": f"advice_{formatted_time}",
        "timestamp": f"{datetime.now()}",
        "warning": f'您{str_bad_poses},请改正',
    }

    print(res)

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
    sql = "insert into suggestions(date,warning_content) values(%s,%s);"
    # 获取当前日期
    today = date.today()
    # 获取年、月、日
    year = today.year
    month = today.month
    day = today.day
    values = (f"{year}年{month}月{day}日", res['warning'])
    cursor.execute(sql, params=values)
    # 提交
    conn.commit()
    # 执行查看
    cursor.execute("SELECT * FROM suggestions;")
    # 获取结果
    result = cursor.fetchall()
    print(result)

    return res

# 日总结路由
@advice_blue.route('/daily_summary')
def daily_advice():


    # 创建OpenAI实例
    client = OpenAI(
        api_key="sk-a81d67c339144afd9dd5f484613b4919", base_url="https://dashscope.aliyuncs.com/compatible-mode/v1"
    )

    # 封装获得AI回答
    def get_openai_response(client, prompt):
        response = client.chat.completions.create(
            model="qwen-max",
            messages=[
                {"role": "user", "content": prompt}
            ]
        )
        return response.choices[0].message.content


    # 接受用户信息
    # query_date = '2025年3月3日'
    query_date = request.args.get('query_date')  # 获取 URL 参数 query_data 的值
    # 连接数据库
    conn = mysql.connector.connect(
        host="localhost",
        user="root",
        password="Hsj70750",
        database="db1"
    )
    # 创建游标
    cursor = conn.cursor()
    # 执行查询
    cursor.execute(f"SELECT warning_content,advice_content FROM suggestions where date ='{query_date}';")
    # 获取结果
    info = cursor.fetchall()

    # 创建提示
    prompt = f'''
                你是一个办公室健康监测助手,负责根据用户每日的不良坐姿数据生成总结报告并给出相关建议,
                用户{query_date}的不良坐姿数据为{info},
                以JSON格式返回你的回答,"summary"包含生成的总结报告,"advice"包含对用户的健康建议,
                除JSON之外,不要输出任何额外的文本
                '''

    # 获得AI回答
    response = get_openai_response(client, prompt)
    content = json.loads(response)
    print(content)

    # 获取当前时间戳
    current_time = datetime.now()
    formatted_time = current_time.strftime("%Y%m%d%H%M%S")

    # 生成返回字典
    res = {

        "dailysum_id": f"summary_{formatted_time}",

        "timestamp":  f"{datetime.now()}",

        "title": f"{date}健康状况总结",

        "summary": f"{content['summary']}",

        "advice": f"{content['advice']}"

    }
    print(res)

    # 关闭连接
    cursor.close()
    conn.close()

    # 返回JSON格式
    return jsonify(res)


# 周总结路由
@advice_blue.route('/weekly_summary')
def weekly_advice():


    # 创建OpenAI实例
    client = OpenAI(
        api_key="sk-a81d67c339144afd9dd5f484613b4919", base_url="https://dashscope.aliyuncs.com/compatible-mode/v1"
    )


    # 封装获得AI回答
    def get_openai_response(client, prompt):
        response = client.chat.completions.create(
            model="qwen-max",
            messages=[
                {"role": "user", "content": prompt}
            ]
        )
        return response.choices[0].message.content


    # 接受用户信息
    user_info = {

       "week":"第十二周",

       "user_id": "user_001",

       "timezone": "Asia/Shanghai",

       "language": "zh_CN"
    }

    week = '第十二周'
    week_info=('周一驼背,周二高低肩,周三前倾,周四坐姿良好,周五坐姿良好')

    # 创建提示
    prompt = f'''
                你是一个办公室健康监测助手,负责根据用户每日坐姿数据生成相关总结报告并给出相关建议,
                用户的本周不良坐姿信息为{week_info},
                以JSON格式返回你的回答,"summary"包含生成的总结报告,"advice"包含对用户的健康建议,
                除JSON之外,不要输出任何额外的文本
                '''


    # 获得AI回答
    response = get_openai_response(client, prompt)
    content = json.loads(response)
    print(content)

    # 生成返回字典
    res = {

    "weeklysum_id": "summary_20250226",

    "timestamp":  f"{datetime.now()}",

    "title": f"2024年{week}健康状况总结",

    "summary": f"{content['summary']}",

    "advice": f"{content['advice']}"

    }
    print(res)


    # 返回JSON格式
    return jsonify(res)
