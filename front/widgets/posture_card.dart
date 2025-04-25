import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/service_manager.dart';
import '../services/websocket_service.dart';
import '../services/advice_service.dart';
import 'dart:async';

class PostureCard extends StatefulWidget {
  final Color cardColor;
  final Color primaryColor;

  const PostureCard({
    super.key,
    required this.cardColor,
    required this.primaryColor,
  });

  @override
  State<PostureCard> createState() => _PostureCardState();
}

class _PostureCardState extends State<PostureCard> {
  RealtimeAdvice? _latestAdvice;
  Timer? _refreshTimer;
  bool _isConnected = false;
  
  // 建议服务
  final _adviceService = AdviceService();
  
  // 姿势异常类型映射
  final Map<String, String> _postureIssues = {
    'head_left': '头部左倾',
    'head_right': '头部右倾',
    'hunchback': '驼背',
    'chin_in_hands': '手撑下巴',
    'body_left': '身体左倾',
    'body_right': '身体右倾',
    'neck_forward': '颈部前倾',
    'shoulder_left': '左肩高',
    'shoulder_right': '右肩高',
    'twisted_head': '头部扭曲',
  };
  
  // 当前检测到的姿势问题
  String? _detectedIssue;

  @override
  void initState() {
    super.initState();
    _initializeServices();
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
    
    // 初始化建议服务
    await _adviceService.initialize();
    
    // 检查当前连接状态
    setState(() {
      _isConnected = ServiceManager().isWebSocketClientConnected;
    });
    
    // 获取当前最新建议
    _latestAdvice = _adviceService.latestRealtimeAdvice;
    if (_latestAdvice != null) {
      debugPrint('初始化时获取到最新建议: ${_latestAdvice!.warning}');
      _analyzePostureIssue(_latestAdvice!.warning);
      setState(() {});
    } else {
      debugPrint('初始化时未获取到最新建议');
    }
  }
  
  // 监听消息
  void _listenToMessages() {
    // 监听实时建议
    _adviceService.realtimeAdviceStream.listen((advice) {
      _analyzePostureIssue(advice.warning);
      setState(() {
        _latestAdvice = advice;
      });
    });
  }
  
  // 分析姿势问题
  void _analyzePostureIssue(String warning) {
    _detectedIssue = null;
    
    // 检查警告消息中是否包含已知的姿势问题
    for (var entry in _postureIssues.entries) {
      if (warning.toLowerCase().contains(entry.value.toLowerCase())) {
        _detectedIssue = entry.key;
        break;
      }
    }
    
    // 特殊情况处理
    if (_detectedIssue == null) {
      if (warning.contains('颈部前倾')) {
        _detectedIssue = 'neck_forward';
      } else if (warning.contains('驼背')) {
        _detectedIssue = 'hunchback';
      } else if (warning.contains('头部左倾')) {
        _detectedIssue = 'head_left';
      } else if (warning.contains('头部右倾')) {
        _detectedIssue = 'head_right';
      } else if (warning.contains('手撑下巴')) {
        _detectedIssue = 'chin_in_hands';
      }
    }
    
    // 调试输出
    debugPrint('姿势警告: $warning');
    debugPrint('检测到的姿势问题: $_detectedIssue');
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 获取可用空间的宽度和高度
        final double width = constraints.maxWidth;
        final double height = constraints.maxHeight;
        
        // 计算各元素的尺寸比例
        final double paddingRatio = 0.025; // 内边距
        
        return Container(
          decoration: BoxDecoration(
            color: widget.cardColor,
            borderRadius: BorderRadius.circular(width * 0.04),
          ),
          padding: EdgeInsets.all(width * paddingRatio),
          child: Stack(
            children: [
              // 主要内容
              _latestAdvice == null
                  ? _buildNoDataView(width, height)
                  : _buildPostureStatusView(width, height),
              
              // 右上角连接状态指示
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: width * 0.02, 
                    vertical: height * 0.01
                  ),
                  decoration: BoxDecoration(
                    color: _isConnected ? Colors.green.shade100 : Colors.red.shade100,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(width * 0.03),
                      topRight: Radius.circular(width * 0.04),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isConnected ? Icons.link : Icons.link_off,
                        size: width * 0.04,
                        color: _isConnected ? Colors.green : Colors.red,
                      ),
                      SizedBox(width: width * 0.01),
                      Text(
                        _isConnected ? '已连接' : '未连接',
                        style: TextStyle(
                          color: _isConnected ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: width * 0.035,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  // 无数据视图
  Widget _buildNoDataView(double width, double height) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isConnected ? Icons.hourglass_empty : Icons.signal_wifi_off,
            size: width * 0.15,
            color: Colors.grey,
          ),
          SizedBox(height: height * 0.03),
          Text(
            _isConnected ? '等待姿势数据...' : '未连接到监测服务',
            style: TextStyle(
              color: Colors.grey,
              fontSize: width * 0.05,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // 姿势状态视图
  Widget _buildPostureStatusView(double width, double height) {
    // 根据是否检测到姿势问题来判断姿势状态
    bool isGoodPosture = _detectedIssue == null && 
                         (_latestAdvice?.warning.isEmpty == true || 
                          _latestAdvice?.warning.toLowerCase().contains('正确') == true);
    
    debugPrint('姿势状态: ${isGoodPosture ? '正确' : '异常'}');
    
    // 计算各元素的尺寸比例
    final double iconContainerRatio = 0.2; // 图标容器大小
    final double iconRatio = 0.12; // 图标大小
    final double statusFontRatio = 0.055; // 状态文本字体大小
    final double contentFontRatio = 0.045; // 内容文本字体大小
    final double timestampFontRatio = 0.03; // 时间戳字体大小
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 左侧状态区域 - 占40%宽度
        Expanded(
          flex: 40,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 姿势状态图标
              Container(
                width: width * iconContainerRatio,
                height: width * iconContainerRatio,
                decoration: BoxDecoration(
                  color: isGoodPosture ? Colors.green.shade100 : Colors.red.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isGoodPosture ? Icons.check_circle : Icons.warning_amber_rounded,
                  color: isGoodPosture ? Colors.green : Colors.red,
                  size: width * iconRatio,
                ),
              ),
              SizedBox(height: height * 0.02),
              // 姿势状态文本
              Text(
                isGoodPosture ? '姿势正确' : _getPostureIssueName(),
                style: TextStyle(
                  fontSize: width * statusFontRatio,
                  fontWeight: FontWeight.bold,
                  color: isGoodPosture ? Colors.green : Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        
        // 右侧警告内容和时间戳区域 - 占60%宽度
        Expanded(
          flex: 60,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 警告内容 - 占90%高度
              Expanded(
                flex: 90,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: width * 0.02,
                    right: width * 0.02,
                  ),
                  child: Center(
                    child: SingleChildScrollView(
                      child: Text(
                        _latestAdvice!.warning,
                        style: TextStyle(
                          fontSize: width * contentFontRatio,
                          color: Colors.black87,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              // 时间戳 - 占10%高度
              Expanded(
                flex: 10,
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: EdgeInsets.only(right: width * 0.02),
                    child: Text(
                      _formatTimestamp(_latestAdvice!.timestamp),
                      style: TextStyle(
                        fontSize: width * timestampFontRatio,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  // 获取姿势问题名称
  String _getPostureIssueName() {
    if (_detectedIssue == null) return '姿势异常';
    return _postureIssues[_detectedIssue] ?? '姿势异常';
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