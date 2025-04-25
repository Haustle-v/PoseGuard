import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:window_manager_plus/window_manager_plus.dart';
import 'pages/home_page.dart';
import 'pages/document_page.dart';
import 'pages/messages_page.dart';
import 'pages/settings_page.dart';
import 'pages/web_view_page.dart';
import 'pages/test_page.dart';
import 'dart:ui' as ui;
import 'package:screen_retriever/screen_retriever.dart';
import 'package:win32/win32.dart';
import 'package:ffi/ffi.dart';
import 'services/service_manager.dart';

// 添加全局 HttpServer 管理器
class HttpServerManager {
  static HttpServer? _server;
  
  static void setServer(HttpServer server) {
    _server = server;
  }
  
  static Future<void> closeServer() async {
    if (_server != null) {
      await _server!.close(force: true);
      _server = null;
      debugPrint('Global HTTP server closed');
    }
  }
}

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 移除自动启动服务的代码
  // 服务将在需要时由各个页面自行启动
  
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    // 初始化窗口管理器，使用命令行参数中的窗口ID或默认为0
    final windowId = args.isNotEmpty ? int.tryParse(args[0]) ?? 0 : 0;
    await WindowManagerPlus.ensureInitialized(windowId);
    
    // 检查是否是测试页面窗口
    final isTestPage = args.contains('test_page');
    debugPrint('窗口参数: windowId=$windowId, isTestPage=$isTestPage, args=$args');
    
    // 根据窗口类型设置不同的窗口选项
    WindowOptions windowOptions;
    
    if (isTestPage) {
      // 灵动岛窗口选项 - 小型圆角窗口
      windowOptions = const WindowOptions(
        size: Size(200, 40), // 灵动岛尺寸
        minimumSize: Size(160, 40),
        center: false, // 不居中，后面会手动设置位置
        backgroundColor: Colors.transparent,
        skipTaskbar: true, // 不在任务栏显示
        titleBarStyle: TitleBarStyle.hidden,
        alwaysOnTop: true, // 始终在顶部
      );
    } else {
      // 主窗口选项
      windowOptions = const WindowOptions(
        size: Size(1280, 720),
        minimumSize: Size(800, 600),
        center: true,
        backgroundColor: Colors.transparent,
        skipTaskbar: false,
        titleBarStyle: TitleBarStyle.hidden,
      );
    }
    
    await WindowManagerPlus.current.waitUntilReadyToShow(windowOptions, () async {
      await WindowManagerPlus.current.setAsFrameless();
      await WindowManagerPlus.current.setHasShadow(true);
      
      if (isTestPage) {
        // 灵动岛窗口特殊设置
        try {
          // 使用 screen_retriever 获取屏幕尺寸
          final primaryDisplay = await screenRetriever.getPrimaryDisplay();
          final screenSize = primaryDisplay.size;
          final windowWidth = windowOptions.size!.width;
          final windowHeight = windowOptions.size!.height;
          
          // 设置窗口位置为屏幕中间
          final xPosition = (screenSize.width - windowWidth) / 2;
          final yPosition = screenSize.height * 0.06; // 距离顶部为屏幕高度的6%
          
          debugPrint('设置测试页面位置: x=$xPosition, y=$yPosition, 屏幕宽度=${screenSize.width}, 屏幕高度=${screenSize.height}');
          
          await WindowManagerPlus.current.setPosition(Offset(xPosition, yPosition));
          
          // 设置窗口为药丸形状
          if (Platform.isWindows) {
            // 使用辅助函数设置窗口形状
            setWindowRoundedCorners(windowWidth, windowHeight, 'test_page');
          }
        } catch (e) {
          // 如果无法获取显示器信息，使用备用方法
          debugPrint('获取屏幕尺寸失败: $e，使用备用方法');
          
          final screenSize = ui.window.physicalSize;
          final screenWidth = screenSize.width / ui.window.devicePixelRatio;
          final screenHeight = screenSize.height / ui.window.devicePixelRatio;
          final windowWidth = windowOptions.size!.width;
          final windowHeight = windowOptions.size!.height;
          
          await WindowManagerPlus.current.setPosition(Offset(
            (screenWidth - windowWidth) / 2, // 屏幕中间
            screenHeight * 0.06, // 距离顶部为屏幕高度的6%
          ));
          
          // 设置窗口为药丸形状
          if (Platform.isWindows) {
            // 使用辅助函数设置窗口形状
            setWindowRoundedCorners(windowWidth, windowHeight, 'test_page');
          }
          
          debugPrint('使用备用方法设置测试页面位置: 屏幕宽度=$screenWidth, 屏幕高度=$screenHeight');
        }
        
        // 设置窗口为无边框
        await WindowManagerPlus.current.setAsFrameless();
        
        // 设置窗口始终在顶部
        await WindowManagerPlus.current.setAlwaysOnTop(true);
        
        // 设置窗口不在任务栏显示
        await WindowManagerPlus.current.setSkipTaskbar(true);
        
        // 设置窗口标题
        await WindowManagerPlus.current.setTitle('灵动岛');
        
        // 显示窗口
        await WindowManagerPlus.current.show();
        await WindowManagerPlus.current.focus();
      } else {
        // 主窗口正常显示
        await WindowManagerPlus.current.show();
        await WindowManagerPlus.current.focus();
      }
    });
    
    // 为防止在macOS上的nil解包错误，这里进行安全的初始化窗口效果
    try {
      if (!Platform.isMacOS) {
        // 只在非macOS平台使用Window.initialize
        await Window.initialize();
        await Window.setEffect(
          effect: WindowEffect.acrylic,
          color: const Color(0x45B0B0B0),
        );
      } else {
        // 在macOS上使用一种替代实现或跳过这些效果
        debugPrint('在macOS上跳过设置窗口效果，以避免nil解包错误');
      }
    } catch (e) {
      debugPrint('设置窗口效果失败: $e');
    }
    
    // 根据参数决定运行哪个应用
    if (isTestPage) {
      debugPrint('启动测试页面应用');
      runApp(const TestPageApp());
    } else {
      debugPrint('启动主应用');
      runApp(const ProHealthApp());
    }
  } else {
    runApp(const ProHealthApp());
  }
}

// 测试页面应用
class TestPageApp extends StatelessWidget {
  const TestPageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.transparent,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        dividerTheme: const DividerThemeData(
          color: Colors.transparent,
          space: 0,
        ),
        canvasColor: Colors.transparent,
        shadowColor: Colors.transparent,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: Scaffold(
        backgroundColor: Colors.transparent,
        body: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: const TestPage(),
        ),
      ),
    );
  }
}

class ProHealthApp extends StatefulWidget {
  const ProHealthApp({super.key});

  @override
  State<ProHealthApp> createState() => _ProHealthAppState();
}

class _ProHealthAppState extends State<ProHealthApp> with WindowListener {
  int _selectedIndex = 0;

  @override
  void initState() {
    WindowManagerPlus.current.addListener(this);
    _setupWindowCommunication();
    
    // 初始化服务管理器
    _initializeServices();
    
    super.initState();
  }

  // 初始化服务
  Future<void> _initializeServices() async {
    try {
      // 启动服务管理器
      await ServiceManager().startAllServices();
      debugPrint('服务管理器已初始化');
    } catch (e) {
      debugPrint('初始化服务管理器失败: $e');
    }
  }
  
  // 设置窗口间通信
  void _setupWindowCommunication() {
    // 不需要特别设置方法处理器，WindowListener 已经提供了 onEventFromWindow 方法
    // 可以在这里添加其他初始化代码
  }

  @override
  Future<dynamic> onEventFromWindow(String eventName, int fromWindowId, dynamic arguments) async {
    // 处理来自其他窗口的事件
    debugPrint('收到来自窗口 $fromWindowId 的事件: $eventName, 参数: $arguments');
    
    if (eventName == 'switchToPage' && arguments is int) {
      setState(() {
        _selectedIndex = arguments;
      });
      return '已切换到页面 $arguments';
    } else if (eventName == 'navigateTo' && arguments is int) {
      setState(() {
        _selectedIndex = arguments;
      });
      return '已导航到页面 $arguments';
    }
    return null;
  }

  @override
  void onWindowClose([int? windowId]) async {
    // 关闭当前窗口的 HTTP 服务器（只关闭WebView相关的服务）
    await HttpServerManager.closeServer();
    
    // 停止所有服务
    await ServiceManager().stopAllServices();
    
    // 如果是主窗口 (ID 为 0)，则销毁所有窗口
    if (WindowManagerPlus.current.id == 0) {
      // 获取所有窗口ID
      final allWindowIds = await WindowManagerPlus.getAllWindowManagerIds();
      // 关闭所有非主窗口
      for (final id in allWindowIds) {
        if (id != 0) {
          try {
            final window = WindowManagerPlus.fromWindowId(id);
            await window.destroy();
          } catch (e) {
            debugPrint('关闭窗口 $id 时出错: $e');
          }
        }
      }
      // 最后关闭主窗口
      await WindowManagerPlus.current.destroy();
    } else {
      // 如果是子窗口，只关闭当前窗口
      await WindowManagerPlus.current.destroy();
    }
  }

  @override
  void dispose() {
    // 只关闭WebView相关的HTTP服务
    HttpServerManager.closeServer();
    WindowManagerPlus.current.removeListener(this);
    super.dispose();
  }

  final List<Widget> _pages = [
    const HomePage(),
    const DocumentPage(),
    const MessagesPage(),
    const SettingsPage(),
    const WebView3D(),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.transparent,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        dividerTheme: const DividerThemeData(
          color: Colors.transparent,
          space: 0,
        ),
        canvasColor: Colors.transparent,
        shadowColor: Colors.transparent,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black87),
          bodyMedium: TextStyle(color: Colors.black87),
          titleLarge: TextStyle(color: Colors.black),
        ),
      ),
      home: Scaffold(
        body: Stack(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onPanStart: (details) {
                WindowManagerPlus.current.startDragging();
              },
              onDoubleTapDown: (details) async {
                final screenHeight = MediaQuery.of(context).size.height;
                if (details.globalPosition.dy <= screenHeight * 0.1) {
                  if (await WindowManagerPlus.current.isMaximized()) {
                    await WindowManagerPlus.current.restore();
                  } else {
                    await WindowManagerPlus.current.maximize();
                  }
                }
              },
              child: Column(
                children: [
                  TopNavigationBar(
                    selectedIndex: _selectedIndex,
                    onIndexChanged: (index) {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                  ),
                  // 使用IndexedStack替代直接显示页面，这样可以保持页面状态
                  Expanded(
                    child: IndexedStack(
                      index: _selectedIndex,
                      children: _pages,
                    ),
                  ),
                ],
              ),
            ),
            // 窗口缩放区域
            Positioned(
              left: 0,
              top: 2,  // 从顶部留出2像素的空间
              bottom: 0,
              width: 2,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onPanStart: (details) => WindowManagerPlus.current.startResizing(ResizeEdge.left),
                child: Container(color: Colors.transparent),
              ),
            ),
            Positioned(
              right: 0,
              top: 2,  // 从顶部留出2像素的空间
              bottom: 0,
              width: 2,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onPanStart: (details) => WindowManagerPlus.current.startResizing(ResizeEdge.right),
                child: Container(color: Colors.transparent),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 2,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onPanStart: (details) => WindowManagerPlus.current.startResizing(ResizeEdge.bottom),
              ),
            ),
            // 角落缩放区域
            Positioned(
              right: 0,
              bottom: 0,
              width: 12,
              height: 12,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onPanStart: (details) => WindowManagerPlus.current.startResizing(ResizeEdge.bottomRight),
                child: MouseRegion(
                  cursor: SystemMouseCursors.resizeDownRight,
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TopNavigationBar extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onIndexChanged;

  const TopNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onIndexChanged,
  });

  @override
  State<TopNavigationBar> createState() => _TopNavigationBarState();
}

class _TopNavigationBarState extends State<TopNavigationBar> {
  bool _isWebSocketRunning = false;

  @override
  void initState() {
    super.initState();
    // 检查WebSocket服务状态
    _checkWebSocketStatus();
    
    // 监听WebSocket服务状态变化
    ServiceManager().webSocketStatusStream.listen((isConnected) {
      setState(() {
        _isWebSocketRunning = isConnected;
      });
    });
  }

  // 检查WebSocket服务状态
  Future<void> _checkWebSocketStatus() async {
    try {
      final serviceManager = ServiceManager();
      final isConnected = serviceManager.isWebSocketClientConnected;
      setState(() {
        _isWebSocketRunning = isConnected;
      });
    } catch (e) {
      debugPrint('检查WebSocket状态失败: $e');
    }
  }

  // 切换WebSocket服务状态
  Future<void> _toggleWebSocketService() async {
    try {
      await ServiceManager().toggleWebSocketConnection();
    } catch (e) {
      debugPrint('切换WebSocket连接状态失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 0, top: 4, bottom: 8),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                const Icon(Icons.sunny, size: 24, color: Colors.black87),
                const SizedBox(width: 8),
                const Text(
                  'ProHealth',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(flex: 1),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildNavButton('Overview', 0),
                _buildNavButton('异常姿势', 1),
                _buildNavButton('Messages', 2),
                _buildNavButton('Settings', 3),
                _buildNavButton('WebView', 4),
              ],
            ),
          ),
          const Spacer(flex: 1),
          // Windows 控制按钮
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // WebSocket服务开关
              Tooltip(
                message: _isWebSocketRunning ? '关闭WebSocket服务' : '开启WebSocket服务',
                child: Switch(
                  value: _isWebSocketRunning,
                  onChanged: (value) => _toggleWebSocketService(),
                  activeColor: Colors.green,
                  activeTrackColor: Colors.green.withOpacity(0.5),
                  inactiveThumbColor: Colors.grey,
                  inactiveTrackColor: Colors.grey.withOpacity(0.5),
                ),
              ),
              const SizedBox(width: 8),
              _buildWindowButton(
                Icons.remove,
                () async => await WindowManagerPlus.current.minimize(),
                Colors.black54,
              ),
              _buildWindowButton(
                Icons.crop_square,
                () async {
                  if (await WindowManagerPlus.current.isMaximized()) {
                    await WindowManagerPlus.current.restore();
                  } else {
                    await WindowManagerPlus.current.maximize();
                  }
                },
                Colors.black54,
              ),
              _buildWindowButton(
                Icons.close,
                () async => await WindowManagerPlus.current.close(),
                Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton(String text, int index) {
    final isActive = widget.selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: TextButton(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.resolveWith<Color>(
            (Set<MaterialState> states) {
              if (isActive) return Colors.white;
              if (states.contains(MaterialState.hovered)) return const Color(0x45A0A0A0);
              return const Color(0x35A0A0A0);
            },
          ),
          padding: MaterialStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50),
            ),
          ),
        ),
        onPressed: () => widget.onIndexChanged(index),
        child: Text(
          text,
          style: TextStyle(
            color: isActive ? Colors.black : Colors.black87,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildWindowButton(IconData icon, VoidCallback onPressed, Color hoverColor) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: IconButton(
        icon: Icon(icon, size: 16),
        onPressed: onPressed,
        style: ButtonStyle(
          padding: MaterialStateProperty.all(const EdgeInsets.all(8)),
          backgroundColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.hovered)) {
              return hoverColor.withOpacity(0.1);
            }
            return Colors.transparent;
          }),
          foregroundColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.hovered)) {
              return hoverColor;
            }
            return Colors.black45;
          }),
        ),
      ),
    );
  }
}

// 使用辅助函数设置窗口形状为药丸形状
void setWindowRoundedCorners(double width, double height, String windowTitle) {
  if (!Platform.isWindows) return;
  
  try {
    debugPrint('尝试设置窗口形状: 宽度=$width, 高度=$height, 标题=$windowTitle');
    
    // 使用 WindowManagerPlus 设置窗口为无边框和透明背景
    WindowManagerPlus.current.setAsFrameless();
    
    // 注意：实际的圆角效果是通过 Flutter 的 ClipRRect 实现的
    // 这里只是确保窗口没有边框，以便 ClipRRect 的效果能够正确显示
    
    debugPrint('已设置窗口为无边框，圆角效果由 Flutter 的 ClipRRect 提供');
  } catch (e) {
    debugPrint('设置窗口形状失败: $e');
  }
}
