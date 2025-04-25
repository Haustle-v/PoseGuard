import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:window_manager_plus/window_manager_plus.dart';
import 'websocket_service.dart';

class ServiceManager {
  static final ServiceManager _instance = ServiceManager._internal();
  factory ServiceManager() => _instance;
  
  ServiceManager._internal();
  
  // 服务状态
  bool _isRunning = false;
  
  // WebSocket服务
  WebSocketService? _webSocketService;
  
  // WebSocket服务状态变化通知
  final StreamController<bool> _webSocketStatusController = StreamController<bool>.broadcast();
  
  // 最新消息
  RealtimeAdvice? _latestRealtimeAdvice;
  DailySummary? _latestDailySummary;
  WeeklySummary? _latestWeeklySummary;
  
  // 获取WebSocket服务
  WebSocketService? get webSocketService => _webSocketService;
  
  // WebSocket服务状态流
  Stream<bool> get webSocketStatusStream => _webSocketStatusController.stream;
  
  // 获取WebSocket服务状态
  bool get isWebSocketRunning => _webSocketService != null;
  
  // 获取WebSocket客户端连接状态
  bool get isWebSocketClientConnected => _webSocketService?.isClientConnected ?? false;

  // 获取最新的实时建议
  RealtimeAdvice? get latestRealtimeAdvice => _latestRealtimeAdvice;
  
  // 获取最新的日总结
  DailySummary? get latestDailySummary => _latestDailySummary;
  
  // 获取最新的周总结
  WeeklySummary? get latestWeeklySummary => _latestWeeklySummary;

  // 启动所有服务
  Future<void> startAllServices({int healthPort = 8001, int advicePort = 8002}) async {
    if (_isRunning) {
      debugPrint('服务已经在运行中');
      return;
    }
    
    try {
      // 生成会话ID
      final sessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';
      debugPrint('生成会话ID: $sessionId');
      
      // 启动健康分析服务
      debugPrint('正在启动健康分析服务...');
      debugPrint('健康分析服务已启动，端口: $healthPort');
      debugPrint('健康分析服务地址: http://localhost:$healthPort/health-analysis/input');
      debugPrint('健康分析日志查询: http://localhost:$healthPort/health-analysis/log/query');
      debugPrint('健康分析日志导出: http://localhost:$healthPort/health-analysis/log/export');
      
      // 启动AI建议服务
      debugPrint('正在启动AI建议服务...');
      debugPrint('AI建议服务已启动，端口: $advicePort');
      debugPrint('AI建议服务地址: http://localhost:$advicePort/ai-advice/push');
      debugPrint('AI建议轮询地址: http://localhost:$advicePort/ai-advice/poll');
      
      // 初始化WebSocket服务（但不连接）
      initWebSocketService();
      
      _isRunning = true;
      debugPrint('所有服务已启动，会话ID: $sessionId');
    } catch (e) {
      debugPrint('启动服务失败: $e');
      await stopAllServices();
      rethrow;
    }
  }
  
  // 初始化WebSocket服务（但不连接）
  void initWebSocketService() {
    if (_webSocketService != null) {
      debugPrint('WebSocket服务已经初始化');
      return;
    }
    
    _webSocketService = WebSocketService();
    debugPrint('WebSocket服务已初始化');
    _webSocketStatusController.add(false); // 初始状态为未连接
    
    // 监听实时建议
    _webSocketService!.realtimeAdviceStream.listen((advice) {
      _latestRealtimeAdvice = advice;
      _sendLatestMessageToTestPage();
    });
    
    // 监听日总结
    _webSocketService!.dailySummaryStream.listen((summary) {
      _latestDailySummary = summary;
      _sendLatestMessageToTestPage();
    });
    
    // 监听周总结
    _webSocketService!.weeklySummaryStream.listen((summary) {
      _latestWeeklySummary = summary;
      _sendLatestMessageToTestPage();
    });
    
    // 启动定时器，每5秒向测试页面发送一次最新消息
    Timer.periodic(const Duration(seconds: 5), (timer) {
      if (isWebSocketClientConnected) {
        _sendLatestMessageToTestPage();
      }
    });
  }
  
  // 向测试页面窗口发送最新消息
  Future<void> _sendLatestMessageToTestPage() async {
    try {
      // 获取所有窗口ID
      final allWindowIds = await WindowManagerPlus.getAllWindowManagerIds();
      
      // 准备消息数据
      Map<String, dynamic> messageData = {};
      
      // 优先级：实时建议 > 日总结 > 周总结
      if (_latestRealtimeAdvice != null) {
        messageData = {
          'type': 'realtime_advice',
          'data': _latestRealtimeAdvice!.toJson(),
        };
      } else if (_latestDailySummary != null) {
        messageData = {
          'type': 'daily_summary',
          'data': _latestDailySummary!.toJson(),
        };
      } else if (_latestWeeklySummary != null) {
        messageData = {
          'type': 'weekly_summary',
          'data': _latestWeeklySummary!.toJson(),
        };
      } else {
        // 没有消息，不发送
        return;
      }
      
      // 查找测试页面窗口（非主窗口）
      for (final id in allWindowIds) {
        if (id != 0) { // 主窗口ID为0
          try {
            // 向测试页面窗口发送消息
            final jsonMessage = jsonEncode(messageData);
            debugPrint('准备向窗口 $id 发送消息: $jsonMessage');
            
            // 使用正确的方法发送消息
            await WindowManagerPlus.current.invokeMethodToWindow(
              id,
              'updateLatestMessage',
              jsonMessage,
            );
            debugPrint('向窗口 $id 发送最新消息成功');
          } catch (e) {
            debugPrint('向窗口 $id 发送消息失败: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('获取窗口ID列表失败: $e');
    }
  }
  
  // 手动发送最新消息到测试页面
  Future<void> sendLatestMessageToTestPage() async {
    await _sendLatestMessageToTestPage();
  }
  
  // 连接到WebSocket服务器
  Future<void> connectToWebSocketServer({String host = 'localhost', int port = 8765}) async {
    if (_webSocketService == null) {
      initWebSocketService();
    }
    
    try {
      await _webSocketService!.connectToServer(host: host, port: port);
      _webSocketStatusController.add(true);
      debugPrint('已连接到WebSocket服务器');
    } catch (e) {
      debugPrint('连接到WebSocket服务器失败: $e');
      _webSocketStatusController.add(false);
      rethrow;
    }
  }
  
  // 断开与WebSocket服务器的连接
  Future<void> disconnectFromWebSocketServer() async {
    if (_webSocketService == null) {
      debugPrint('WebSocket服务未初始化，无需断开连接');
      return;
    }
    
    try {
      await _webSocketService!.disconnectFromServer();
      _webSocketStatusController.add(false);
      debugPrint('已断开与WebSocket服务器的连接');
    } catch (e) {
      debugPrint('断开与WebSocket服务器的连接失败: $e');
      rethrow;
    }
  }
  
  // 切换WebSocket连接状态
  Future<void> toggleWebSocketConnection({String host = 'localhost', int port = 8765}) async {
    if (_webSocketService == null) {
      initWebSocketService();
    }
    
    if (_webSocketService!.isClientConnected) {
      await disconnectFromWebSocketServer();
    } else {
      await connectToWebSocketServer(host: host, port: port);
    }
  }
  
  // 发送消息到WebSocket服务器
  void sendWebSocketMessage(String message) {
    if (_webSocketService == null || !_webSocketService!.isClientConnected) {
      debugPrint('WebSocket未连接，无法发送消息');
      return;
    }
    
    _webSocketService!.sendMessage(message);
  }
  
  // 停止所有服务
  Future<void> stopAllServices() async {
    try {
      // 断开WebSocket连接
      if (_webSocketService != null) {
        await _webSocketService!.disconnectFromServer();
      }
      
      _isRunning = false;
      debugPrint('所有服务已停止');
    } catch (e) {
      debugPrint('停止服务失败: $e');
      rethrow;
    }
  }
  
  // 模拟测试数据
  void simulateTestData() {
    // 模拟发送骨骼数据
    debugPrint('模拟发送骨骼数据');
    
    // 模拟实时建议
    final advice = RealtimeAdvice(
      adviceId: 'advice_${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now().toString(),
      warning: '您颈部前伸,请改正姿势',
    );
    
    // 保存最新建议
    _latestRealtimeAdvice = advice;
    debugPrint('已设置模拟实时建议: ${advice.warning}');
    
    // 如果WebSocket已连接，则发送消息
    if (_webSocketService != null && _webSocketService!.isClientConnected) {
      // 将建议转换为JSON字符串并发送
      final jsonData = advice.toJson();
      sendWebSocketMessage(jsonEncode(jsonData));
      debugPrint('已发送模拟实时建议到WebSocket');
    } else {
      debugPrint('WebSocket未连接，但已更新本地数据');
    }
    
    // 无论WebSocket是否连接，都发送到测试页面
    _sendLatestMessageToTestPage();
  }
  
  // 释放资源
  Future<void> dispose() async {
    await stopAllServices();
    
    if (_webSocketService != null) {
      _webSocketService = null;
    }
    
    await _webSocketStatusController.close();
  }
} 