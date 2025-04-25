from flask import request, Blueprint, jsonify
import requests, json
from ..analyse.SQLSession import toJSON, get_session, toDataFrame
from ..advice import get_advice
from threading import Thread

boards_blue = Blueprint('boards', __name__)


@boards_blue.route('/get_board')
def get_board():

    Advice.reviews_count = analyze_reviews_for_business(review_df)

    res = {
        'business_details': business_df[business_df['business_id'] == business_id].to_dict(orient='records')[0],
        'reviews': review_df.to_dict(orient='records'),
        'star_count': star_count.to_dict(orient='records'),
        'business_rank': int(business_rank),
        'positive_reviews_count': int(Advice.reviews_count[0])
    }

    json_res = jsonify(res)
    return json_res
