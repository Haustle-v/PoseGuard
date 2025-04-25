import 'package:flutter/material.dart';
import 'package:window_manager_plus/window_manager_plus.dart';
import 'dart:ui' as ui;
import 'dart:convert';
import 'package:screen_retriever/screen_retriever.dart';
import '../services/service_manager.dart';
import '../models/ai_advice_models.dart';
import '../widgets/animated_shadow_border.dart';
import '../services/websocket_service.dart';
import 'dart:async';

class TestPage extends StatefulWidget {
  const TestPage({Key? key}) : super(key: key);

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> with WindowListener {
  // 定义窗口高度作为类成员变量
  double _windowHeight = 40;
  double _windowWidth = 200;
  bool _isExpanded = false;
  
  // 添加内容显示状态控制
  bool _showContent = true;
  bool _isTransitioning = false;
  
  // 最新消息
  MessageItem? _latestMessage;
  
  // 添加消息状态
  int _unreadCount = 0;
  
  // 定时器
  Timer? _updateTimer;
  
  @override
  void initState() {
    super.initState();
    WindowManagerPlus.current.addListener(this);
    
    // 初始化WebSocket服务
    _initWebSocketService();
    
    // 添加定时器，每5秒检查一次最新消息
    _updateTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _checkLatestMessage();
    });
    
    // 初始化后立即检查一次最新消息
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLatestMessage();
    });
  }
  
  // 初始化WebSocket服务
  void _initWebSocketService() {
    // 确保WebSocket服务已初始化
    ServiceManager().initWebSocketService();
    
    // 获取WebSocket服务
    final webSocketService = ServiceManager().webSocketService;
    
    if (webSocketService != null) {
      // 监听实时建议
      webSocketService.realtimeAdviceStream.listen((advice) {
        setState(() {
          _latestMessage = MessageItem(
            title: _getPoseTypeTitle(advice.warning),
            content: advice.warning,
            time: '刚刚',
            alertLevel: 'HIGH',
          );
          _unreadCount++;
        });
      });
      
      // 监听日总结
      webSocketService.dailySummaryStream.listen((summary) {
        setState(() {
          _latestMessage = MessageItem(
            title: summary.title,
            content: '${summary.summary}\n\n建议: ${summary.advice}',
            time: '刚刚',
            alertLevel: 'MEDIUM',
          );
          _unreadCount++;
        });
      });
      
      // 监听周总结
      webSocketService.weeklySummaryStream.listen((summary) {
        setState(() {
          _latestMessage = MessageItem(
            title: summary.title,
            content: '${summary.summary}\n\n建议: ${summary.advice}',
            time: '刚刚',
            alertLevel: 'LOW',
          );
          _unreadCount++;
        });
      });
    }
    
    // 立即检查是否有最新消息
    _checkLatestMessage();
    
    // 如果没有任何消息，才设置默认消息
    if (_latestMessage == null) {
      _latestMessage = MessageItem(
        title: '颈部前伸',
        content: '您颈部前伸,请改正姿势',
        time: '刚刚',
        alertLevel: 'MEDIUM',
      );
    }
  }
  
  // 检查最新消息
  void _checkLatestMessage() {
    final serviceManager = ServiceManager();
    
    // 优先级：实时建议 > 日总结 > 周总结
    if (serviceManager.latestRealtimeAdvice != null) {
      final advice = serviceManager.latestRealtimeAdvice!;
      setState(() {
        _latestMessage = MessageItem(
          title: _getPoseTypeTitle(advice.warning),
          content: advice.warning,
          time: '刚刚',
          alertLevel: 'HIGH',
        );
      });
      debugPrint('定时器更新了实时建议: ${advice.warning}');
    } else if (serviceManager.latestDailySummary != null) {
      final summary = serviceManager.latestDailySummary!;
      setState(() {
        _latestMessage = MessageItem(
          title: summary.title,
          content: '${summary.summary}\n\n建议: ${summary.advice}',
          time: '刚刚',
          alertLevel: 'MEDIUM',
        );
      });
      debugPrint('定时器更新了日总结: ${summary.title}');
    } else if (serviceManager.latestWeeklySummary != null) {
      final summary = serviceManager.latestWeeklySummary!;
      setState(() {
        _latestMessage = MessageItem(
          title: summary.title,
          content: '${summary.summary}\n\n建议: ${summary.advice}',
          time: '刚刚',
          alertLevel: 'LOW',
        );
      });
      debugPrint('定时器更新了周总结: ${summary.title}');
    }
  }
  
  // 处理来自主窗口的消息
  @override
  Future<dynamic> onEventFromWindow(String eventName, int fromWindowId, dynamic arguments) async {
    debugPrint('收到来自窗口 $fromWindowId 的事件: $eventName, 参数: $arguments');
    
    if (eventName == 'updateLatestMessage' && arguments is String) {
      try {
        final Map<String, dynamic> messageData = jsonDecode(arguments);
        final String type = messageData['type'];
        final Map<String, dynamic> data = messageData['data'];
        
        setState(() {
          if (type == 'realtime_advice') {
            final advice = RealtimeAdvice.fromJson(data);
            _latestMessage = MessageItem(
              title: _getPoseTypeTitle(advice.warning),
              content: advice.warning,
              time: '刚刚',
              alertLevel: 'HIGH',
            );
          } else if (type == 'daily_summary') {
            final summary = DailySummary.fromJson(data);
            _latestMessage = MessageItem(
              title: summary.title,
              content: '${summary.summary}\n\n建议: ${summary.advice}',
              time: '刚刚',
              alertLevel: 'MEDIUM',
            );
          } else if (type == 'weekly_summary') {
            final summary = WeeklySummary.fromJson(data);
            _latestMessage = MessageItem(
              title: summary.title,
              content: '${summary.summary}\n\n建议: ${summary.advice}',
              time: '刚刚',
              alertLevel: 'LOW',
            );
          }
          _unreadCount++;
        });
        
        return '已更新最新消息';
      } catch (e) {
        debugPrint('解析消息数据失败: $e');
      }
    }
    
    return null;
  }
  
  // 处理方法调用
  @override
  Future<dynamic> onMethodCall(String methodName, dynamic arguments) async {
    debugPrint('收到方法调用: $methodName, 参数: $arguments');
    
    if (methodName == 'updateLatestMessage' && arguments is String) {
      try {
        final Map<String, dynamic> messageData = jsonDecode(arguments);
        final String type = messageData['type'];
        final Map<String, dynamic> data = messageData['data'];
        
        setState(() {
          if (type == 'realtime_advice') {
            final advice = RealtimeAdvice.fromJson(data);
            _latestMessage = MessageItem(
              title: _getPoseTypeTitle(advice.warning),
              content: advice.warning,
              time: '刚刚',
              alertLevel: 'HIGH',
            );
          } else if (type == 'daily_summary') {
            final summary = DailySummary.fromJson(data);
            _latestMessage = MessageItem(
              title: summary.title,
              content: '${summary.summary}\n\n建议: ${summary.advice}',
              time: '刚刚',
              alertLevel: 'MEDIUM',
            );
          } else if (type == 'weekly_summary') {
            final summary = WeeklySummary.fromJson(data);
            _latestMessage = MessageItem(
              title: summary.title,
              content: '${summary.summary}\n\n建议: ${summary.advice}',
              time: '刚刚',
              alertLevel: 'LOW',
            );
          }
          _unreadCount++;
        });
        
        return '已更新最新消息';
      } catch (e) {
        debugPrint('解析消息数据失败: $e');
      }
    }
    
    return null;
  }
  
  // 根据警告内容提取姿势类型标题
  String _getPoseTypeTitle(String warning) {
    if (warning.contains('驼背')) {
      return '驼背警告';
    } else if (warning.contains('头部左倾') || warning.contains('头部右倾')) {
      return '头部倾斜';
    } else if (warning.contains('颈部前伸')) {
      return '颈部前伸';
    } else if (warning.contains('托腮')) {
      return '托腮警告';
    } else if (warning.contains('身体左倾') || warning.contains('身体右倾')) {
      return '身体倾斜';
    } else if (warning.contains('左肩下沉') || warning.contains('右肩下沉')) {
      return '肩部不平';
    } else if (warning.contains('头部歪斜')) {
      return '头部歪斜';
    } else {
      return '姿势异常';
    }
  }

  @override
  void dispose() {
    // 取消定时器
    _updateTimer?.cancel();
    WindowManagerPlus.current.removeListener(this);
    super.dispose();
  }

  // 调整窗口位置到屏幕中间
  Future<void> _positionWindow() async {
    try {
      // 使用 screen_retriever 获取屏幕尺寸
      final primaryDisplay = await screenRetriever.getPrimaryDisplay();
      final screenSize = primaryDisplay.size;
      
      // 设置窗口位置为屏幕中间
      await WindowManagerPlus.current.setPosition(Offset(
        (screenSize.width - _windowWidth) / 2, // 屏幕中间
        screenSize.height * 0.06, // 距离顶部为屏幕高度的6%
      ));
      
      debugPrint('测试页面内部设置位置: 屏幕宽度=${screenSize.width}, 屏幕高度=${screenSize.height}');
    } catch (e) {
      // 如果无法获取显示器信息，使用备用方法
      debugPrint('测试页面内部获取屏幕尺寸失败: $e，使用备用方法');
      
      final screenSize = ui.window.physicalSize;
      final screenWidth = screenSize.width / ui.window.devicePixelRatio;
      final screenHeight = screenSize.height / ui.window.devicePixelRatio;
      
      // 设置窗口位置为屏幕中间
      await WindowManagerPlus.current.setPosition(Offset(
        (screenWidth - _windowWidth) / 2, // 屏幕中间
        screenHeight * 0.06, // 距离顶部为屏幕高度的6%
      ));
    }
  }

  // 展开灵动岛
  Future<void> _expandIsland() async {
    if (_isExpanded || _isTransitioning) return;
    
    // 标记正在过渡中
    setState(() {
      _isTransitioning = true;
      _showContent = false; // 先隐藏内容
    });
    
    // 等待一小段时间确保内容已隐藏
    await Future.delayed(const Duration(milliseconds: 50));
    
    // 展开窗口
    await WindowManagerPlus.current.setSize(Size(_windowWidth * 1.5, _windowHeight * 3));
    
    try {
      // 使用 screen_retriever 获取屏幕尺寸
      final primaryDisplay = await screenRetriever.getPrimaryDisplay();
      final screenSize = primaryDisplay.size;
      
      // 重新定位窗口，保持在屏幕中间
      await WindowManagerPlus.current.setPosition(Offset(
        (screenSize.width - _windowWidth * 1.5) / 2, // 屏幕中间
        screenSize.height * 0.06, // 距离顶部为屏幕高度的6%
      ));
      
      debugPrint('展开灵动岛: 屏幕宽度=${screenSize.width}, 屏幕高度=${screenSize.height}');
    } catch (e) {
      // 如果无法获取显示器信息，使用备用方法
      debugPrint('展开灵动岛获取屏幕尺寸失败: $e，使用备用方法');
      
      // 重新定位窗口，保持在屏幕中间
      final screenSize = ui.window.physicalSize;
      final screenWidth = screenSize.width / ui.window.devicePixelRatio;
      final screenHeight = screenSize.height / ui.window.devicePixelRatio;
      await WindowManagerPlus.current.setPosition(Offset(
        (screenWidth - _windowWidth * 1.5) / 2, // 屏幕中间
        screenHeight * 0.06, // 距离顶部为屏幕高度的6%
      ));
    }
    
    // 等待窗口调整完成
    await Future.delayed(const Duration(milliseconds: 300));
    
    // 更新状态并显示内容
    setState(() {
      _isExpanded = true;
      _showContent = true;
      _isTransitioning = false;
      _unreadCount = 0; // 清除未读计数
    });
  }

  // 收起灵动岛
  Future<void> _collapseIsland() async {
    if (!_isExpanded || _isTransitioning) return;
    
    // 标记正在过渡中
    setState(() {
      _isTransitioning = true;
      _showContent = false; // 先隐藏内容
    });
    
    // 等待一小段时间确保内容已隐藏
    await Future.delayed(const Duration(milliseconds: 50));
    
    // 收起窗口
    await WindowManagerPlus.current.setSize(Size(_windowWidth, _windowHeight));
    
    try {
      // 使用 screen_retriever 获取屏幕尺寸
      final primaryDisplay = await screenRetriever.getPrimaryDisplay();
      final screenSize = primaryDisplay.size;
      
      // 重新定位窗口，保持在屏幕中间
      await WindowManagerPlus.current.setPosition(Offset(
        (screenSize.width - _windowWidth) / 2, // 屏幕中间
        screenSize.height * 0.06, // 距离顶部为屏幕高度的6%
      ));
      
      debugPrint('收起灵动岛: 屏幕宽度=${screenSize.width}, 屏幕高度=${screenSize.height}');
    } catch (e) {
      // 如果无法获取显示器信息，使用备用方法
      debugPrint('收起灵动岛获取屏幕尺寸失败: $e，使用备用方法');
      
      // 重新定位窗口，保持在屏幕中间
      final screenSize = ui.window.physicalSize;
      final screenWidth = screenSize.width / ui.window.devicePixelRatio;
      final screenHeight = screenSize.height / ui.window.devicePixelRatio;
      await WindowManagerPlus.current.setPosition(Offset(
        (screenWidth - _windowWidth) / 2, // 屏幕中间
        screenHeight * 0.06, // 距离顶部为屏幕高度的6%
      ));
    }
    
    // 等待窗口调整完成
    await Future.delayed(const Duration(milliseconds: 300));
    
    // 更新状态并显示内容
    setState(() {
      _isExpanded = false;
      _showContent = true;
      _isTransitioning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: MouseRegion(
        onEnter: (_) => _expandIsland(),
        onExit: (_) => _collapseIsland(),
        child: AnimatedShadowBorder(
          borderRadius: BorderRadius.circular(_windowHeight / 2),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutQuad,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(_windowHeight / 2),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                // 内容区域
                AnimatedOpacity(
                  opacity: _showContent ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 150),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _isExpanded 
                      ? _buildExpandedContent() 
                      : _buildCollapsedContent(),
                  ),
                ),
                // 拖动区域
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onPanStart: (details) {
                      WindowManagerPlus.current.startDragging();
                    },
                    onDoubleTap: () async {
                      await WindowManagerPlus.current.close();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // 收起状态的内容
  Widget _buildCollapsedContent() {
    // 确保有最新消息
    _checkLatestMessage();
    
    return Center(
      key: const ValueKey('collapsed'),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(width: 12),
          // 左侧图标
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: _getAlertColor(_latestMessage?.alertLevel),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications,
              color: Colors.white,
              size: 14,
            ),
          ),
          const SizedBox(width: 8),
          // 中间文本
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _latestMessage?.title ?? '姿势提醒',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _latestMessage?.content ?? '保持良好姿势，预防颈椎病',
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.8),
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // 右侧按钮
          if (_unreadCount > 0)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                _unreadCount > 9 ? '9+' : '$_unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
  
  // 展开状态的内容
  Widget _buildExpandedContent() {
    // 确保有最新消息
    _checkLatestMessage();
    
    return Padding(
      key: const ValueKey('expanded'),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _getAlertColor(_latestMessage?.alertLevel),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _latestMessage?.title ?? '姿势提醒',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 详细内容
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _latestMessage?.content ?? '保持良好姿势，预防颈椎病',
                    style: TextStyle(
                      color: Colors.black.withOpacity(0.8),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 底部按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () async {
                  // 向主窗口发送消息
                  final result = await WindowManagerPlus.current.invokeMethodToWindow(
                    0, // 主窗口ID为0
                    'switchToPage',
                    2, // 切换到消息页面
                  );
                  debugPrint('向主窗口发送消息，结果: $result');
                  // 关闭当前窗口
                  await WindowManagerPlus.current.close();
                },
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(Colors.blue.withOpacity(0.3)),
                  shape: MaterialStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  padding: MaterialStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
                child: const Text(
                  '查看全部',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // 获取警告颜色
  Color _getAlertColor(String? alertLevel) {
    if (alertLevel == 'HIGH') {
      return Colors.red;
    } else if (alertLevel == 'MEDIUM') {
      return Colors.orange;
    } else if (alertLevel == 'LOW') {
      return Colors.yellow;
    } else {
      return Colors.blue.withOpacity(0.7);
    }
  }
}

// 消息项数据模型
class MessageItem {
  final String title;
  final String content;
  final String time;
  final String? alertLevel;
  
  MessageItem({
    required this.title,
    required this.content,
    required this.time,
    this.alertLevel,
  });
} 