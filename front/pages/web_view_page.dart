import 'package:flutter/material.dart';
import 'package:webview_windows/webview_windows.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_static/shelf_static.dart';
import '../main.dart';  // 导入 HttpServerManager

class WebView3D extends StatefulWidget {
  final double? width;
  final double? height;
  
  const WebView3D({
    super.key,
    this.width,
    this.height,
  });

  @override
  State<WebView3D> createState() => _WebView3DState();
}

class _WebView3DState extends State<WebView3D> {
  final _controller = WebviewController();
  bool _isWebViewReady = false;
  String? _error;
  HttpServer? _server;
  String? _webDirectory;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  Future<void> _copyAsset(String assetPath, String targetPath) async {
    try {
      final targetFile = File(targetPath);
      await targetFile.parent.create(recursive: true);
      final byteData = await rootBundle.load(assetPath);
      await targetFile.writeAsBytes(byteData.buffer.asUint8List());
      debugPrint('Successfully copied: $assetPath -> $targetPath');
    } catch (e) {
      debugPrint('Error copying asset $assetPath: $e');
      rethrow;
    }
  }

  Future<void> _copyModelFiles(String webDirPath) async {
    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);
      
      final modelFiles = manifestMap.keys.where((String key) => 
        key.startsWith('assets/web/'));

      for (final assetPath in modelFiles) {
        final relativePath = assetPath.substring('assets/web/'.length);
        final targetPath = path.join(webDirPath, relativePath);
        await _copyAsset(assetPath, targetPath);
      }

      debugPrint('All files copied successfully');
    } catch (e) {
      debugPrint('Error copying files: $e');
      rethrow;
    }
  }

  Future<void> _startLocalServer() async {
    try {
      // 清理现有服务和资源
      await _cleanupResources();

      // 准备web目录
      final tempDir = await getTemporaryDirectory();
      _webDirectory = path.join(tempDir.path, 'web');
      final webDir = Directory(_webDirectory!);
      
      if (await webDir.exists()) {
        await webDir.delete(recursive: true);
      }
      await webDir.create(recursive: true);

      // 复制所有web资源
      await _copyModelFiles(_webDirectory!);

      // 创建静态文件处理器
      final handler = createStaticHandler(
        _webDirectory!,
        defaultDocument: 'three_scene.html',
      );

      // 创建中间件来处理CORS
      final pipeline = const shelf.Pipeline()
          .addMiddleware((innerHandler) {
            return (request) async {
              var response = await innerHandler(request);
              return response.change(headers: {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
                'Access-Control-Allow-Headers': 'Origin, Content-Type',
              });
            };
          })
          .addHandler(handler);

      // 启动服务器
      _server = await shelf_io.serve(
        pipeline,
        InternetAddress.loopbackIPv4,
        0, // 让系统自动选择可用端口
      );

      HttpServerManager.setServer(_server!);
      debugPrint('Server running on port ${_server!.port}');
    } catch (e) {
      debugPrint('Error starting server: $e');
      rethrow;
    }
  }

  Future<void> _cleanupResources() async {
    try {
      // 关闭现有服务器
      if (_server != null) {
        await _server!.close(force: true);
        _server = null;
        debugPrint('Existing server closed');
      }

      // 清理临时目录
      if (_webDirectory != null) {
        final dir = Directory(_webDirectory!);
        if (await dir.exists()) {
          await dir.delete(recursive: true);
          debugPrint('Temporary directory cleaned');
        }
        _webDirectory = null;
      }
    } catch (e) {
      debugPrint('Error during cleanup: $e');
    }
  }

  Future<void> initPlatformState() async {
    try {
      // 启动本地服务器
      await _startLocalServer();
      if (_server == null) {
        throw Exception('Failed to start local server');
      }

      // 初始化WebView
      await _controller.initialize();
      await _controller.setBackgroundColor(Colors.transparent);
      await _controller.setPopupWindowPolicy(WebviewPopupWindowPolicy.deny);
      
      // 设置透明背景
      await _controller.setBackgroundColor(Colors.transparent);
      
      // 加载本地服务器地址
      final serverUrl = 'http://localhost:${_server!.port}/three_scene.html';
      debugPrint('Loading URL: $serverUrl');
      
      await _controller.loadUrl(serverUrl);

      if (!mounted) return;
      setState(() {
        _isWebViewReady = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '初始化失败: $e';
      });
      debugPrint('初始化失败: $e');
    }
  }

  @override
  void dispose() {
    _cleanupResources();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (_error != null) {
      content = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _error!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (_error!.contains('WebView2 Runtime 未安装'))
              ElevatedButton(
                onPressed: () async {
                  final url = Uri.parse('https://developer.microsoft.com/microsoft-edge/webview2/');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  }
                },
                child: const Text('下载 WebView2 Runtime'),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _error = null;
                  _isWebViewReady = false;
                });
                initPlatformState();
              },
              child: const Text('重试'),
            ),
          ],
        ),
      );
    } else if (!_isWebViewReady) {
      content = Container(
        color: Colors.transparent,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('正在启动本地服务器...'),
            ],
          ),
        ),
      );
    } else {
      content = Webview(_controller);
    }

    return Container(
      color: Colors.transparent,
      width: widget.width,
      height: widget.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: content,
      ),
    );
  }
} 
