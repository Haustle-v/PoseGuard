import 'package:flutter/material.dart';
import 'package:window_manager_plus/window_manager_plus.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';
import '../services/service_manager.dart';

class BackendService {
  Process? _process;
  final void Function(String) onLog;
  final void Function(bool) onStateChange;
  
  BackendService({required this.onLog, required this.onStateChange});
  
  Future<void> startServer() async {
    try {
      onLog('正在启动后端服务...');
      
      // 设置环境变量
      final Map<String, String> environment = {
        'OPENCV_VIDEOIO_MSMF_ENABLE_HW_TRANSFORMS': '0',
        ...Platform.environment,
      };
      
      _process = await Process.start(
        'powershell',
        ['-Command', 'cd assets/backend; .\\venv\\Scripts\\Activate.ps1; python run.py'],
        workingDirectory: Directory.current.path,
        environment: environment,
      );
      
      onLog('后端服务启动命令已执行');
      onLog('正在初始化姿态检测服务...');
      onLog('默认HTTP端口: 5000');
      onLog('姿态检测服务地址: http://127.0.0.1:5000/pose-detection');
      onLog('姿态检测控制地址: http://127.0.0.1:5000/pose-detection/control');
      
      _process!.stdout.transform(utf8.decoder).listen((data) {
        onLog('服务输出: $data');
      });
      
      _process!.stderr.transform(utf8.decoder).listen((data) {
        onLog('服务错误: $data');
        if (data.contains('error status: -1072873821')) {
          onLog('检测到视频设备错误，尝试使用备用配置...');
        }
      });
      
    } catch (e) {
      onLog('启动服务失败: $e');
      onStateChange(false);
    }
  }

  Future<void> stopServer() async {
    if (_process != null) {
      try {
        // 在 Windows 上使用 taskkill 命令强制终止进程树
        if (Platform.isWindows) {
          onLog('正在停止服务...');
          // 终止 Python 进程
          await Process.run('taskkill', ['/F', '/T', '/PID', '${_process!.pid}']);
          onLog('已终止服务进程');
        } else {
          _process!.kill();
        }
        
        _process = null;
        onStateChange(false);
        onLog('后端服务已完全停止');
      } catch (e) {
        onLog('停止服务时出错: $e');
        // 即使出错也要更新状态
        _process = null;
        onStateChange(false);
      }
    }
  }

  bool get isRunning => _process != null;
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with AutomaticKeepAliveClientMixin {
  final TextEditingController _logController = TextEditingController();
  final TextEditingController _httpLogController = TextEditingController();
  late final BackendService _backendService;
  bool _isServerRunning = false;
  final String _workbenchUrl = 'http://127.0.0.1:5000/workbench/workbench';
  Timer? _healthCheckTimer;
  bool _isInitialized = false;
  
  // HTTP服务相关变量
  bool _isHttpServiceRunning = false;
  final TextEditingController _healthPortController = TextEditingController(text: '8001');
  final TextEditingController _advicePortController = TextEditingController(text: '8002');

  // 保持页面状态
  @override
  bool get wantKeepAlive => false;

  Future<void> _initializeWorkbench() async {
    if (!mounted || !_isInitialized) return;
    
    try {
      final response = await http.get(Uri.parse(_workbenchUrl));
      if (response.statusCode == 200) {
        onLog('工作台初始化成功');
      } else {
        onLog('工作台初始化失败: HTTP ${response.statusCode}');
      }
    } catch (e) {
      if (mounted && _isInitialized) {
        onLog('工作台初始化错误: $e');
      }
    }
  }

  Future<bool> _checkServerHealth() async {
    if (!mounted || !_isInitialized) return false;
    
    try {
      final response = await http.get(Uri.parse(_workbenchUrl));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  void _startHealthCheck() {
    if (!mounted || !_isInitialized) return;
    
    _healthCheckTimer?.cancel();
    _healthCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (!_isServerRunning || !mounted || !_isInitialized) {
        timer.cancel();
        return;
      }
      
      final isHealthy = await _checkServerHealth();
      if (!isHealthy && _isServerRunning && mounted && _isInitialized) {
        onLog('检测到服务异常，尝试重新初始化...');
        await _initializeWorkbench();
      }
    });
  }

  void onLog(String message) {
    if (!mounted || !_isInitialized) return;
    
    setState(() {
      _logController.text = '${_logController.text}\n$message';
    });
    // 自动滚动到底部
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted && _isInitialized) {
        _logController.selection = TextSelection.fromPosition(
          TextPosition(offset: _logController.text.length),
        );
      }
    });
  }
  
  void onHttpLog(String message) {
    if (!mounted || !_isInitialized) return;
    
    setState(() {
      _httpLogController.text = '${_httpLogController.text}\n$message';
    });
    // 自动滚动到底部
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted && _isInitialized) {
        _httpLogController.selection = TextSelection.fromPosition(
          TextPosition(offset: _httpLogController.text.length),
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _isInitialized = true;
    
    _backendService = BackendService(
      onLog: onLog,
      onStateChange: (bool isRunning) {
        if (mounted && _isInitialized) {
          setState(() {
            _isServerRunning = isRunning;
          });
          if (isRunning) {
            _startHealthCheck();
          }
        }
      },
    );
    
    // 检查HTTP服务状态
    _checkHttpServiceStatus();
  }
  
  // 检查HTTP服务状态
  Future<void> _checkHttpServiceStatus() async {
    if (!mounted || !_isInitialized) return;
    
    try {
      final healthPort = _healthPortController.text;
      final advicePort = _advicePortController.text;
      
      // 尝试连接健康分析服务
      final healthResponse = await http.get(
        Uri.parse('http://localhost:$healthPort/health-analysis/log'),
      ).timeout(const Duration(seconds: 1), onTimeout: () {
        throw Exception('连接超时');
      });
      
      // 尝试连接AI建议服务
      final aiResponse = await http.get(
        Uri.parse('http://localhost:$advicePort/ai-advice/poll'),
      ).timeout(const Duration(seconds: 1), onTimeout: () {
        throw Exception('连接超时');
      });
      
      if (mounted && _isInitialized) {
        setState(() {
          _isHttpServiceRunning = healthResponse.statusCode == 200 || 
                                 aiResponse.statusCode == 200;
        });
      }
    } catch (e) {
      if (mounted && _isInitialized) {
        setState(() {
          _isHttpServiceRunning = false;
        });
        onHttpLog('检查HTTP服务状态失败: $e');
      }
    }
  }
  
  // 启动HTTP服务
  Future<void> _startHttpService() async {
    try {
      final healthPort = int.tryParse(_healthPortController.text) ?? 8001;
      final advicePort = int.tryParse(_advicePortController.text) ?? 8002;
      
      onHttpLog('正在启动HTTP服务...');
      onHttpLog('健康分析服务端口: $healthPort');
      onHttpLog('AI建议服务端口: $advicePort');
      
      // 设置日志监听
      FlutterError.onError = (FlutterErrorDetails details) {
        onHttpLog('Flutter错误: ${details.exception}');
        FlutterError.presentError(details);
      };
      
      // 重定向debugPrint输出到HTTP日志
      final originalDebugPrint = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null && message.contains('健康分析') || message != null && message.contains('AI建议')) {
          onHttpLog(message);
        }
        originalDebugPrint(message, wrapWidth: wrapWidth);
      };
      
      await ServiceManager().startAllServices(
        healthPort: healthPort,
        advicePort: advicePort
      );
      
      // 恢复原始debugPrint
      debugPrint = originalDebugPrint;
      
      setState(() {
        _isHttpServiceRunning = true;
      });
      
      onHttpLog('HTTP服务已启动成功');
      onLog('HTTP服务已启动，健康分析服务端口: $healthPort，AI建议服务端口: $advicePort');
    } catch (e) {
      onHttpLog('启动HTTP服务失败: $e');
      onLog('启动HTTP服务失败: $e');
    }
  }
  
  // 停止HTTP服务
  Future<void> _stopHttpService() async {
    try {
      onHttpLog('正在停止HTTP服务...');
      
      await ServiceManager().stopAllServices();
      
      setState(() {
        _isHttpServiceRunning = false;
      });
      
      onHttpLog('HTTP服务已停止');
      onLog('HTTP服务已停止');
    } catch (e) {
      onHttpLog('停止HTTP服务失败: $e');
      onLog('停止HTTP服务失败: $e');
    }
  }

  @override
  void dispose() {
    // 清理资源
    _logController.dispose();
    _httpLogController.dispose();
    _healthPortController.dispose();
    _advicePortController.dispose();
    _healthCheckTimer?.cancel();
    
    // 确保不会在页面销毁后尝试更新状态
    _isInitialized = false;
    
    super.dispose();
  }

  // 修改HTTP服务控制区域
  Widget _buildHttpServiceControl() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'HTTP服务监听',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text('服务状态: ', style: Theme.of(context).textTheme.bodyLarge),
                Text(
                  _isHttpServiceRunning ? '监听中' : '已停止',
                  style: TextStyle(
                    color: _isHttpServiceRunning ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('健康分析服务端口:'),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _healthPortController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: '8001',
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                        enabled: !_isHttpServiceRunning,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('AI建议服务端口:'),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _advicePortController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: '8002',
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                        enabled: !_isHttpServiceRunning,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _isHttpServiceRunning ? null : _startHttpService,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('开始监听'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: _isHttpServiceRunning ? _stopHttpService : null,
                  icon: const Icon(Icons.stop),
                  label: const Text('停止监听'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            if (_isHttpServiceRunning) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'HTTP服务信息',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      '健康分析服务地址: http://localhost:${_healthPortController.text}/health-analysis/input',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      'AI建议服务地址: http://localhost:${_advicePortController.text}/ai-advice/push',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      '健康分析日志查询: http://localhost:${_healthPortController.text}/health-analysis/log/query',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      '健康分析日志导出: http://localhost:${_healthPortController.text}/health-analysis/log/export',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            const Text(
              'HTTP服务日志',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 150,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18),
                          onPressed: () {
                            setState(() {
                              _httpLogController.clear();
                            });
                          },
                          tooltip: '清除HTTP日志',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    Expanded(
                      child: TextField(
                        controller: _httpLogController,
                        maxLines: null,
                        readOnly: true,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(8),
                        ),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 后端服务控制区域
  Widget _buildBackendServiceControl() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '后端服务控制',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _isServerRunning
                      ? null
                      : () async {
                          setState(() {
                            _isServerRunning = true;
                          });
                          await _backendService.startServer();
                          // 等待服务启动
                          await Future.delayed(const Duration(seconds: 2));
                          // 静默初始化工作台
                          await _initializeWorkbench();
                        },
                  child: const Text('启动服务'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isServerRunning
                      ? () async {
                          setState(() {
                            _isServerRunning = false;
                          });
                          await _backendService.stopServer();
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: const Text('停止服务'),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _isServerRunning ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _isServerRunning ? '服务运行中' : '服务已停止',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                if (_isServerRunning)
                  ElevatedButton.icon(
                    onPressed: () async {
                      onLog('正在初始化工作台...');
                      await _initializeWorkbench();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('初始化工作台'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
            if (_isServerRunning) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '后端服务信息',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '提示：如果服务启动后工作台未响应，请点击"初始化工作台"按钮手动初始化',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      '工作台地址：$_workbenchUrl',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      '姿态检测服务地址：http://127.0.0.1:5000/pose-detection',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      '姿态检测控制地址：http://127.0.0.1:5000/pose-detection/control',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '系统设置',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            // 后端服务控制区域
            _buildBackendServiceControl(),
            const SizedBox(height: 20),
            
            // HTTP服务控制区域
            _buildHttpServiceControl(),
            const SizedBox(height: 20),
            
            // 调试日志区域
            SizedBox(
              height: 300, // 给日志区域一个固定高度
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '调试日志',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () {
                              setState(() {
                                _logController.clear();
                              });
                            },
                            tooltip: '清除日志',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextField(
                            controller: _logController,
                            maxLines: null,
                            readOnly: true,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20), // 底部添加一些空间
          ],
        ),
      ),
    );
  }
} 