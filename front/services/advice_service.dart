import 'dart:async';
import 'package:flutter/foundation.dart';
import 'service_manager.dart';
import 'websocket_service.dart';

class AdviceService {
  static final AdviceService _instance = AdviceService._internal();
  factory AdviceService() => _instance;
  
  AdviceService._internal();
  
  // 最新的实时建议
  RealtimeAdvice? _latestRealtimeAdvice;
  // 最新的日总结
  DailySummary? _latestDailySummary;
  // 最新的周总结
  WeeklySummary? _latestWeeklySummary;
  
  // 流控制器
  final _realtimeAdviceController = StreamController<RealtimeAdvice>.broadcast();
  final _dailySummaryController = StreamController<DailySummary>.broadcast();
  final _weeklySummaryController = StreamController<WeeklySummary>.broadcast();
  
  // 获取流
  Stream<RealtimeAdvice> get realtimeAdviceStream => _realtimeAdviceController.stream;
  Stream<DailySummary> get dailySummaryStream => _dailySummaryController.stream;
  Stream<WeeklySummary> get weeklySummaryStream => _weeklySummaryController.stream;
  
  // 获取最新数据
  RealtimeAdvice? get latestRealtimeAdvice => _latestRealtimeAdvice;
  DailySummary? get latestDailySummary => _latestDailySummary;
  WeeklySummary? get latestWeeklySummary => _latestWeeklySummary;
  
  // 初始化服务
  Future<void> initialize() async {
    final webSocketService = ServiceManager().webSocketService;
    
    if (webSocketService != null) {
      // 订阅实时建议流
      webSocketService.realtimeAdviceStream.listen((advice) {
        _latestRealtimeAdvice = advice;
        _realtimeAdviceController.add(advice);
        debugPrint('收到新的实时建议: ${advice.warning}');
      });
      
      // 订阅日总结流
      webSocketService.dailySummaryStream.listen((summary) {
        _latestDailySummary = summary;
        _dailySummaryController.add(summary);
        debugPrint('收到新的日总结: ${summary.title}');
      });
      
      // 订阅周总结流
      webSocketService.weeklySummaryStream.listen((summary) {
        _latestWeeklySummary = summary;
        _weeklySummaryController.add(summary);
        debugPrint('收到新的周总结: ${summary.title}');
      });
      
      debugPrint('建议服务已初始化');
    } else {
      debugPrint('WebSocket服务未启动，无法初始化建议服务');
    }
  }
  
  // 请求日总结
  Future<DailySummary?> requestDailySummary(String date) async {
    // 这里可以实现HTTP请求来获取日总结
    // 示例实现，实际应用中需要替换为真实的HTTP请求
    debugPrint('请求日期为 $date 的日总结');
    return _latestDailySummary;
  }
  
  // 请求周总结
  Future<WeeklySummary?> requestWeeklySummary(String week) async {
    // 这里可以实现HTTP请求来获取周总结
    // 示例实现，实际应用中需要替换为真实的HTTP请求
    debugPrint('请求周数为 $week 的周总结');
    return _latestWeeklySummary;
  }
  
  // 释放资源
  void dispose() {
    _realtimeAdviceController.close();
    _dailySummaryController.close();
    _weeklySummaryController.close();
    debugPrint('建议服务已释放资源');
  }
} 