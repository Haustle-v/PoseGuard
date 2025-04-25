import 'package:flutter/material.dart';
import '../services/advice_service.dart';
import '../services/service_manager.dart';
import '../services/websocket_service.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> with AutomaticKeepAliveClientMixin {
  // 保持页面状态
  @override
  bool get wantKeepAlive => true; // 设置为true，保留状态
  
  // 建议服务
  final _adviceService = AdviceService();
  
  // WebSocket服务
  WebSocketService? _webSocketService;
  
  // 最新消息
  MessageItem? _latestMessage;
  
  // 终端日志
  final List<String> _logs = [];
  
  // 文本控制器
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _logScrollController = ScrollController();
  
  // 是否显示终端
  bool _showTerminal = false;
  
  // WebSocket连接状态
  bool _isConnected = false;
  
  // 用于控制模拟消息的标志
  static bool _hasSimulatedMessage = false;
  
  @override
  void initState() {
    super.initState();
    debugPrint('消息页面初始化');
    
    // 确保服务已启动
    _initializeServices();
    
    // 监听消息
    _listenToMessages();
    
    // 监听WebSocket连接状态
    ServiceManager().webSocketStatusStream.listen((isConnected) {
      setState(() {
        _isConnected = isConnected;
      });
    });
  }
  
  // 初始化服务
  Future<void> _initializeServices() async {
    // 确保WebSocket服务已初始化
    ServiceManager().initWebSocketService();
    
    // 获取WebSocket服务
    _webSocketService = ServiceManager().webSocketService;
    
    // 监听WebSocket日志
    if (_webSocketService != null) {
      _webSocketService!.logStream.listen((log) {
        setState(() {
          _logs.add(log);
          // 保持日志不超过100条
          if (_logs.length > 100) {
            _logs.removeAt(0);
          }
        });
        
        // 滚动到底部
        Future.delayed(const Duration(milliseconds: 50), () {
          if (_logScrollController.hasClients) {
            _logScrollController.animateTo(
              _logScrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          }
        });
      });
    }
    
    // 初始化建议服务
    await _adviceService.initialize();
    
    // 检查当前连接状态
    _isConnected = ServiceManager().isWebSocketClientConnected;
  }
  
  // 监听消息
  void _listenToMessages() {
    // 监听实时建议
    _adviceService.realtimeAdviceStream.listen((advice) {
      final newMessage = MessageItem(
        title: '实时建议',
        content: advice.warning,
        timestamp: advice.timestamp,
        type: MessageType.realtime,
      );
      
      setState(() {
        _latestMessage = newMessage;
      });
      
      // 通知测试页面更新消息
      ServiceManager().sendLatestMessageToTestPage();
      
      // 手动模拟一条消息，用于测试
      _simulateMessage();
    });
    
    // 监听日总结
    _adviceService.dailySummaryStream.listen((summary) {
      final newMessage = MessageItem(
        title: summary.title,
        content: '${summary.summary}\n\n建议: ${summary.advice}',
        timestamp: summary.timestamp,
        type: MessageType.daily,
      );
      
      setState(() {
        _latestMessage = newMessage;
      });
      
      // 通知测试页面更新消息
      ServiceManager().sendLatestMessageToTestPage();
      
      // 手动模拟一条消息，用于测试
      _simulateMessage();
    });
    
    // 监听周总结
    _adviceService.weeklySummaryStream.listen((summary) {
      final newMessage = MessageItem(
        title: summary.title,
        content: '${summary.summary}\n\n建议: ${summary.advice}',
        timestamp: summary.timestamp,
        type: MessageType.weekly,
      );
      
      setState(() {
        _latestMessage = newMessage;
      });
      
      // 通知测试页面更新消息
      ServiceManager().sendLatestMessageToTestPage();
      
      // 手动模拟一条消息，用于测试
      _simulateMessage();
    });
  }
  
  // 模拟一条消息，用于测试
  void _simulateMessage() {
    // 为避免无限循环，使用静态变量控制是否已经模拟过
    if (!_hasSimulatedMessage) {
      _hasSimulatedMessage = true;
      
      // 延迟1秒后模拟一条实时建议
      Future.delayed(const Duration(seconds: 1), () {
        debugPrint('模拟消息：手动触发模拟数据');
        
        // 直接调用ServiceManager的模拟方法
        ServiceManager().simulateTestData();
        
        // 10秒后重置标志，允许再次模拟
        Future.delayed(const Duration(seconds: 10), () {
          _hasSimulatedMessage = false;
          debugPrint('模拟消息：重置模拟标志，允许再次模拟');
        });
      });
    }
  }
  
  // 连接到WebSocket服务器
  Future<void> _connectToServer() async {
    try {
      await ServiceManager().connectToWebSocketServer();
    } catch (e) {
      debugPrint('连接到WebSocket服务器失败: $e');
    }
  }
  
  // 断开与WebSocket服务器的连接
  Future<void> _disconnectFromServer() async {
    try {
      await ServiceManager().disconnectFromWebSocketServer();
    } catch (e) {
      debugPrint('断开与WebSocket服务器的连接失败: $e');
    }
  }
  
  // 发送消息
  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      ServiceManager().sendWebSocketMessage(message);
      _messageController.clear();
    }
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _logScrollController.dispose();
    debugPrint('消息页面销毁');
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    super.build(context); // 必须调用super.build
    
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Text(
                  '消息中心',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 16),
                // 连接状态指示器
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _isConnected ? Colors.green.shade100 : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isConnected ? Icons.link : Icons.link_off,
                        size: 16,
                        color: _isConnected ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isConnected ? '已连接' : '未连接',
                        style: TextStyle(
                          color: _isConnected ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // 终端切换按钮
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _showTerminal = !_showTerminal;
                    });
                  },
                  icon: Icon(_showTerminal ? Icons.terminal : Icons.message),
                  label: Text(_showTerminal ? '查看消息' : '查看终端'),
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(
                      _showTerminal ? Colors.blue.shade100 : Colors.green.shade100,
                    ),
                    padding: MaterialStateProperty.all(
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    // 模拟发送测试数据
                    ServiceManager().simulateTestData();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('模拟数据'),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: _showTerminal
                ? _buildTerminal()
                : _buildMessageView(),
          ),
        ],
      ),
      // 悬浮连接按钮（仅在未连接且不在终端模式时显示）
      floatingActionButton: !_isConnected && !_showTerminal
          ? FloatingActionButton(
              onPressed: _connectToServer,
              backgroundColor: Colors.green,
              child: const Icon(Icons.link),
            )
          : null,
    );
  }
  
  // 构建消息视图
  Widget _buildMessageView() {
    if (_latestMessage == null) {
      return const Center(
        child: Text(
          '暂无消息',
          style: TextStyle(
            fontSize: 18,
            color: Colors.black54,
          ),
        ),
      );
    }
    
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '最新消息',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            LatestMessageCard(message: _latestMessage!),
          ],
        ),
      ),
    );
  }
  
  // 构建终端界面
  Widget _buildTerminal() {
    final isConnected = ServiceManager().isWebSocketClientConnected;
    
    return Column(
      children: [
        // 连接状态和控制按钮
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.grey.shade200,
          child: Row(
            children: [
              Text(
                '状态: ${isConnected ? '已连接' : '未连接'}',
                style: TextStyle(
                  color: isConnected ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '服务器: localhost:8765',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: isConnected ? _disconnectFromServer : _connectToServer,
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(
                    isConnected ? Colors.red.shade100 : Colors.green.shade100,
                  ),
                ),
                child: Text(isConnected ? '断开连接' : '连接服务器'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _logs.clear();
                  });
                },
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(Colors.grey.shade300),
                ),
                child: const Text('清空日志'),
              ),
            ],
          ),
        ),
        
        // 日志显示区域
        Expanded(
          child: Container(
            color: Colors.black87,
            padding: const EdgeInsets.all(8),
            child: ListView.builder(
              controller: _logScrollController,
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                return Text(
                  _logs[index],
                  style: const TextStyle(
                    color: Colors.lightGreenAccent,
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
        ),
        
        // 消息输入区域
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: '输入消息...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _sendMessage,
                style: ButtonStyle(
                  padding: MaterialStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
                child: const Text('发送'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// 消息类型
enum MessageType {
  realtime,
  daily,
  weekly,
}

// 消息项
class MessageItem {
  final String title;
  final String content;
  final String timestamp;
  final MessageType type;
  
  MessageItem({
    required this.title,
    required this.content,
    required this.timestamp,
    required this.type,
  });
}

// 最新消息卡片（带有动画效果）
class LatestMessageCard extends StatefulWidget {
  final MessageItem message;
  
  const LatestMessageCard({
    super.key,
    required this.message,
  });
  
  @override
  State<LatestMessageCard> createState() => _LatestMessageCardState();
}

class _LatestMessageCardState extends State<LatestMessageCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.forward();
  }
  
  @override
  void didUpdateWidget(LatestMessageCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当消息更新时，重新播放动画
    if (oldWidget.message.timestamp != widget.message.timestamp) {
      _controller.reset();
      _controller.forward();
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    // 根据消息类型设置不同的颜色
    Color cardColor;
    IconData iconData;
    
    switch (widget.message.type) {
      case MessageType.realtime:
        cardColor = Colors.red.shade100;
        iconData = Icons.warning_amber_rounded;
        break;
      case MessageType.daily:
        cardColor = Colors.blue.shade100;
        iconData = Icons.calendar_today;
        break;
      case MessageType.weekly:
        cardColor = Colors.green.shade100;
        iconData = Icons.date_range;
        break;
    }
    
    return FadeTransition(
      opacity: _animation,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        color: cardColor,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: cardColor.withOpacity(0.8),
            width: 2,
          ),
        ),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(
            maxWidth: 600,
            minHeight: 200,
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(iconData, color: Colors.black87, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.message.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _formatTimestamp(widget.message.timestamp),
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
              const Divider(thickness: 1.5),
              const SizedBox(height: 12),
              Text(
                widget.message.content,
                style: const TextStyle(
                  fontSize: 18,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // 格式化时间戳
  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return timestamp;
    }
  }
} 