import 'dart:convert';

// 实时建议请求模型
class RealtimeAdviceRequest {
  final EventData eventData;
  final AdviceContext context;

  RealtimeAdviceRequest({
    required this.eventData,
    required this.context,
  });

  Map<String, dynamic> toJson() => {
    'event_data': eventData.toJson(),
    'context': context.toJson(),
  };

  factory RealtimeAdviceRequest.fromJson(Map<String, dynamic> json) {
    return RealtimeAdviceRequest(
      eventData: EventData.fromJson(json['event_data']),
      context: AdviceContext.fromJson(json['context']),
    );
  }
}

// 事件数据模型
class EventData {
  final String eventType;
  final String timestamp;
  final String postureType;
  final double angleValue;
  final int duration;

  EventData({
    required this.eventType,
    required this.timestamp,
    required this.postureType,
    required this.angleValue,
    required this.duration,
  });

  Map<String, dynamic> toJson() => {
    'event_type': eventType,
    'timestamp': timestamp,
    'posture_type': postureType,
    'angle_value': angleValue,
    'duration': duration,
  };

  factory EventData.fromJson(Map<String, dynamic> json) {
    return EventData(
      eventType: json['event_type'],
      timestamp: json['timestamp'],
      postureType: json['posture_type'],
      angleValue: json['angle_value'].toDouble(),
      duration: json['duration'],
    );
  }
}

// 建议上下文模型
class AdviceContext {
  final List<dynamic> recentEvents;
  final double userResponseRate;

  AdviceContext({
    required this.recentEvents,
    required this.userResponseRate,
  });

  Map<String, dynamic> toJson() => {
    'recent_events': recentEvents,
    'user_response_rate': userResponseRate,
  };

  factory AdviceContext.fromJson(Map<String, dynamic> json) {
    return AdviceContext(
      recentEvents: json['recent_events'] ?? [],
      userResponseRate: json['user_response_rate'].toDouble(),
    );
  }
}

// 实时建议响应模型
class RealtimeAdviceResponse {
  final String adviceId;
  final String timestamp;
  final String adviceType;
  final AdviceContent content;
  final String status;
  final int code;

  RealtimeAdviceResponse({
    required this.adviceId,
    required this.timestamp,
    required this.adviceType,
    required this.content,
    required this.status,
    required this.code,
  });

  Map<String, dynamic> toJson() => {
    'advice_id': adviceId,
    'timestamp': timestamp,
    'advice_type': adviceType,
    'content': content.toJson(),
    'status': status,
    'code': code,
  };

  factory RealtimeAdviceResponse.fromJson(Map<String, dynamic> json) {
    return RealtimeAdviceResponse(
      adviceId: json['advice_id'],
      timestamp: json['timestamp'],
      adviceType: json['advice_type'],
      content: AdviceContent.fromJson(json['content']),
      status: json['status'],
      code: json['code'],
    );
  }

  String toJsonString() => jsonEncode(toJson());
}

// 建议内容模型
class AdviceContent {
  final String alertLevel;
  final String message;
  final List<String> actionItems;

  AdviceContent({
    required this.alertLevel,
    required this.message,
    required this.actionItems,
  });

  Map<String, dynamic> toJson() => {
    'alert_level': alertLevel,
    'message': message,
    'action_items': actionItems,
  };

  factory AdviceContent.fromJson(Map<String, dynamic> json) {
    return AdviceContent(
      alertLevel: json['alert_level'],
      message: json['message'],
      actionItems: List<String>.from(json['action_items']),
    );
  }
}

// 轮询请求模型
class PollRequest {
  final String userId;
  final String? lastAdviceId;

  PollRequest({
    required this.userId,
    this.lastAdviceId,
  });

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    if (lastAdviceId != null) 'last_advice_id': lastAdviceId,
  };

  factory PollRequest.fromJson(Map<String, dynamic> json) {
    return PollRequest(
      userId: json['user_id'],
      lastAdviceId: json['last_advice_id'],
    );
  }
}

// 轮询响应模型
class PollResponse {
  final bool hasNewAdvice;
  final RealtimeAdviceResponse? advice;
  final String status;
  final int code;

  PollResponse({
    required this.hasNewAdvice,
    this.advice,
    required this.status,
    required this.code,
  });

  Map<String, dynamic> toJson() => {
    'has_new_advice': hasNewAdvice,
    if (advice != null) 'advice': advice!.toJson(),
    'status': status,
    'code': code,
  };

  factory PollResponse.fromJson(Map<String, dynamic> json) {
    return PollResponse(
      hasNewAdvice: json['has_new_advice'],
      advice: json['advice'] != null ? RealtimeAdviceResponse.fromJson(json['advice']) : null,
      status: json['status'],
      code: json['code'],
    );
  }

  String toJsonString() => jsonEncode(toJson());
}

// 建议反馈请求模型
class FeedbackRequest {
  final String adviceId;
  final String userId;
  final String feedbackType;
  final String? comment;

  FeedbackRequest({
    required this.adviceId,
    required this.userId,
    required this.feedbackType,
    this.comment,
  });

  Map<String, dynamic> toJson() => {
    'advice_id': adviceId,
    'user_id': userId,
    'feedback_type': feedbackType,
    if (comment != null) 'comment': comment,
  };

  factory FeedbackRequest.fromJson(Map<String, dynamic> json) {
    return FeedbackRequest(
      adviceId: json['advice_id'],
      userId: json['user_id'],
      feedbackType: json['feedback_type'],
      comment: json['comment'],
    );
  }
}

// 建议反馈响应模型
class FeedbackResponse {
  final String status;
  final String message;
  final int code;

  FeedbackResponse({
    required this.status,
    required this.message,
    required this.code,
  });

  Map<String, dynamic> toJson() => {
    'status': status,
    'message': message,
    'code': code,
  };

  factory FeedbackResponse.fromJson(Map<String, dynamic> json) {
    return FeedbackResponse(
      status: json['status'],
      message: json['message'],
      code: json['code'],
    );
  }

  String toJsonString() => jsonEncode(toJson());
} 