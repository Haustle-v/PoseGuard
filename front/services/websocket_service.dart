import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';

// 实时建议模型
class RealtimeAdvice {
  final String adviceId;
  final String timestamp;
  final String warning;

  RealtimeAdvice({
    required this.adviceId,
    required this.timestamp,
    required this.warning,
  });

  factory RealtimeAdvice.fromJson(Map<String, dynamic> json) {
    return RealtimeAdvice(
      adviceId: json['advice_id'] ?? '',
      timestamp: json['timestamp'] ?? '',
      warning: json['warning'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'advice_id': adviceId,
      'timestamp': timestamp,
      'warning': warning,
    };
  }
}

// 日总结模型
class DailySummary {
  final String dailysumId;
  final String timestamp;
  final String title;
  final String summary;
  final String advice;

  DailySummary({
    required this.dailysumId,
    required this.timestamp,
    required this.title,
    required this.summary,
    required this.advice,
  });

  factory DailySummary.fromJson(Map<String, dynamic> json) {
    return DailySummary(
      dailysumId: json['dailysum_id'] ?? '',
      timestamp: json['timestamp'] ?? '',
      title: json['title'] ?? '',
      summary: json['summary'] ?? '',
      advice: json['advice'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dailysum_id': dailysumId,
      'timestamp': timestamp,
      'title': title,
      'summary': summary,
      'advice': advice,
    };
  }
}

// 周总结模型
class WeeklySummary {
  final String weeklysumId;
  final String timestamp;
  final String title;
  final String summary;
  final String advice;

  WeeklySummary({
    required this.weeklysumId,
    required this.timestamp,
    required this.title,
    required this.summary,
    required this.advice,
  });

  factory WeeklySummary.fromJson(Map<String, dynamic> json) {
    return WeeklySummary(
      weeklysumId: json['weeklysum_id'] ?? '',
      timestamp: json['timestamp'] ?? '',
      title: json['title'] ?? '',
      summary: json['summary'] ?? '',
      advice: json['advice'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'weeklysum_id': weeklysumId,
      'timestamp': timestamp,
      'title': title,
      'summary': summary,
      'advice': advice,
    };
  }
}

// WebSocket客户端服务
class WebSocketService {
  // WebSocket客户端
  WebSocketChannel? _channel;
  bool _isClientConnected = false;
  
  // 流控制器
  final StreamController<RealtimeAdvice> _realtimeAdviceController = StreamController<RealtimeAdvice>.broadcast();
  final StreamController<DailySummary> _dailySummaryController = StreamController<DailySummary>.broadcast();
  final StreamController<WeeklySummary> _weeklySummaryController = StreamController<WeeklySummary>.broadcast();
  final StreamController<String> _logController = StreamController<String>.broadcast();

  // 获取流
  Stream<RealtimeAdvice> get realtimeAdviceStream => _realtimeAdviceController.stream;
  Stream<DailySummary> get dailySummaryStream => _dailySummaryController.stream;
  Stream<WeeklySummary> get weeklySummaryStream => _weeklySummaryController.stream;
  Stream<String> get logStream => _logController.stream;
  
  // 客户端状态
  bool get isClientConnected => _isClientConnected;
  
  // 连接到WebSocket服务器
  Future<void> connectToServer({String host = 'localhost', int port = 8765}) async {
    try {
      if (_isClientConnected) {
        await disconnectFromServer();
      }
      
      final uri = Uri.parse('ws://$host:$port');
      _log('正在连接到WebSocket服务器: $uri');
      
      _channel = IOWebSocketChannel.connect(uri);
      _isClientConnected = true;
      _log('已连接到WebSocket服务器: $uri');
      
      // 监听消息
      _channel!.stream.listen(
        (dynamic data) {
          _processMessage(data);
        },
        onDone: () {
          _isClientConnected = false;
          _log('与WebSocket服务器的连接已关闭');
        },
        onError: (error) {
          _isClientConnected = false;
          _log('WebSocket连接错误: $error');
        },
      );
    } catch (e) {
      _isClientConnected = false;
      _log('连接到WebSocket服务器失败: $e');
      rethrow;
    }
  }
  
  // 断开与WebSocket服务器的连接
  Future<void> disconnectFromServer() async {
    if (_channel != null) {
      _log('正在断开与WebSocket服务器的连接');
      await _channel!.sink.close();
      _channel = null;
      _isClientConnected = false;
      _log('已断开与WebSocket服务器的连接');
    }
  }
  
  // 发送消息到服务器
  void sendMessage(String message) {
    if (_isClientConnected && _channel != null) {
      _channel!.sink.add(message);
      _log('已发送消息: $message');
    } else {
      _log('无法发送消息，未连接到服务器');
    }
  }

  // 处理接收到的消息
  void _processMessage(dynamic data) {
    if (data is String) {
      try {
        _log('收到消息: $data');
        final jsonData = jsonDecode(data);
        _processJsonData(Map<String, dynamic>.from(jsonData));
      } catch (e) {
        _log('解析JSON数据失败: $e');
      }
    } else if (data is Map) {
      _log('收到Map数据');
      _processJsonData(Map<String, dynamic>.from(data));
    }
  }

  // 处理JSON数据
  void _processJsonData(Map<String, dynamic> data) {
    // 根据JSON数据中的字段判断消息类型
    if (data.containsKey('advice_id')) {
      final advice = RealtimeAdvice.fromJson(data);
      _realtimeAdviceController.add(advice);
      _log('收到实时建议: ${advice.warning}');
    } else if (data.containsKey('dailysum_id')) {
      final summary = DailySummary.fromJson(data);
      _dailySummaryController.add(summary);
      _log('收到日总结: ${summary.title}');
    } else if (data.containsKey('weeklysum_id')) {
      final summary = WeeklySummary.fromJson(data);
      _weeklySummaryController.add(summary);
      _log('收到周总结: ${summary.title}');
    } else {
      _log('收到未知类型的JSON数据: $data');
    }
  }
  
  // 记录日志
  void _log(String message) {
    final timestamp = DateTime.now().toString().substring(0, 19);
    final logMessage = '[$timestamp] $message';
    debugPrint(logMessage);
    _logController.add(logMessage);
  }
  
  // 释放资源
  Future<void> dispose() async {
    await disconnectFromServer();
    
    await _realtimeAdviceController.close();
    await _dailySummaryController.close();
    await _weeklySummaryController.close();
    await _logController.close();
    
    _log('WebSocket服务已释放资源');
  }
} 