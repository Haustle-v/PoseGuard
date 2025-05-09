from math import radians, cos, sin, asin, sqrt

from sqlalchemy import text

from ..analyse.SQLSession import get_session


def cal_distance_fromSQL(user_location,business_id):
    user_longitude = user_location[0]
    user_latitude = user_location[1]

    business_longitude = 0
    business_latitude = 0

    with get_session() as session:
        query = text("select longitude,latitude from business where business_id = :business_id")
        res = session.execute(query, {"business_id": business_id})
        for row in res:
            business_longitude = row[0]
            business_latitude = row[1]

    return haversine(user_longitude, user_latitude, business_longitude, business_latitude)

def cal_distance(user_location,business_location):

    user_longitude = user_location[0]
    user_latitude = user_location[1]
    business_longitude = business_location[0]
    business_latitude = business_location[1]

    return haversine(user_longitude, user_latitude, business_longitude, business_latitude)

def haversine(lon1, lat1, lon2, lat2):
    lon1, lat1, lon2, lat2 = map(radians, [lon1, lat1, lon2, lat2])

    dlon = lon2 - lon1
    dlat = lat2 - lat1
    a = sin(dlat / 2) ** 2 + cos(lat1) * cos(lat2) * sin(dlon / 2) ** 2
    c = 2 * asin(sqrt(a))
    r = 6371
    return c * r * 1000