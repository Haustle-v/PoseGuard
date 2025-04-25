import 'package:flutter/material.dart';
import '../widgets/adaptive_grid.dart';
import '../utils/layout_preferences.dart';
import '../models/layout_config.dart';
import 'web_view_page.dart';
import 'package:window_manager_plus/window_manager_plus.dart';
import 'test_page.dart';
import 'dart:ui' as ui; // 导入ui库以使用window

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const cardColor = Colors.white;
  static const primaryColor = Color(0xFF0066FF);
  LayoutConfig? _layoutConfig;

  @override
  void initState() {
    super.initState();
    _loadLayout();
  }

  Future<void> _loadLayout() async {
    final config = await LayoutPreferences.loadLayout();
    setState(() {
      _layoutConfig = config;
    });
  }

  // 创建新窗口的方法
  void _createNewWindow() async {
    print('开始创建新窗口...');
    try {
      print('获取当前窗口ID...');
      // 创建一个新窗口，使用当前窗口ID作为标识符的一部分
      final currentWindowId = WindowManagerPlus.current.id;
      print('当前窗口ID: $currentWindowId');
      
      // 获取屏幕尺寸
      final screenSize = ui.window.physicalSize;
      final screenWidth = screenSize.width / ui.window.devicePixelRatio;
      
      // 设置灵动岛窗口的尺寸
      final windowHeight = 40.0; // 固定高度为40像素
      final windowWidth = 200.0; // 固定宽度为200像素
      
      print('创建新窗口...');
      // 传递额外参数 'test_page' 表示这是一个测试页面窗口
      final newWindowId = await WindowManagerPlus.createWindow(
        ['$currentWindowId', 'test_page'],
      );
      print('新窗口创建结果: $newWindowId');
      
      if (newWindowId != null) {
        // 设置窗口尺寸
        await newWindowId.setSize(Size(windowWidth, windowHeight));
        
        // 设置窗口最小尺寸
        await newWindowId.setMinimumSize(Size(windowWidth * 0.8, windowHeight));
        
        // 设置窗口位置为屏幕中间
        await newWindowId.setPosition(Offset(
          (screenWidth - windowWidth) / 2, // 屏幕中间
          screenSize.height / ui.window.devicePixelRatio * 0.1, // 距离顶部为屏幕高度的10%
        ));
        
        // 设置窗口为无边框
        await newWindowId.setAsFrameless();
        
        // 设置窗口始终在顶部
        await newWindowId.setAlwaysOnTop(true);
        
        // 设置窗口不在任务栏显示
        await newWindowId.setSkipTaskbar(true);
        
        // 设置窗口标题
        await newWindowId.setTitle('灵动岛');
        
        // 显示窗口
        await newWindowId.show();
        await newWindowId.focus();
        
        print('成功创建新窗口，ID: $newWindowId');
      } else {
        print('创建新窗口失败，返回的ID为null');
      }
    } catch (e) {
      print('创建新窗口时出错: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // color: const Color(0xFFF5F5F5), // 移除这个背景色
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部标题和通知区域
          Padding(
            padding: const EdgeInsets.all(32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Overview",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const Text(
                      "Office Health Monitor",
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w300,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        // 添加新窗口按钮
                        IconButton(
                          icon: const Icon(Icons.add_box_outlined, size: 24),
                          tooltip: '创建新窗口',
                          onPressed: _createNewWindow,
                          style: ButtonStyle(
                            padding: MaterialStateProperty.all(const EdgeInsets.all(8)),
                            backgroundColor: MaterialStateProperty.resolveWith((states) {
                              if (states.contains(MaterialState.hovered)) {
                                return const Color(0x20000000);
                              }
                              return Colors.transparent;
                            }),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined, size: 24),
                          onPressed: () {},
                          style: ButtonStyle(
                            padding: MaterialStateProperty.all(const EdgeInsets.all(8)),
                            backgroundColor: MaterialStateProperty.resolveWith((states) {
                              if (states.contains(MaterialState.hovered)) {
                                return const Color(0x20000000);
                              }
                              return Colors.transparent;
                            }),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.notifications, size: 24),
                          onPressed: () {},
                          style: ButtonStyle(
                            padding: MaterialStateProperty.all(const EdgeInsets.all(8)),
                            backgroundColor: MaterialStateProperty.resolveWith((states) {
                              if (states.contains(MaterialState.hovered)) {
                                return const Color(0x20000000);
                              }
                              return Colors.transparent;
                            }),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 内容区域
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 左侧区域 - 45%
                Expanded(
                  flex: 45,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 0, bottom: 48),
                    child: Column(
                      children: [
                        // 上部空白区域 - 10%
                        const Spacer(flex: 10),
                        // 下部3D模型区域 - 90%
                        Expanded(
                          flex: 90,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const ClipRRect(
                              borderRadius: BorderRadius.all(Radius.circular(12)),
                              child: WebView3D(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // 右侧区域 - 55%
                Expanded(
                  flex: 55,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 32, bottom: 32),
                    child: _layoutConfig == null
                        ? const Center(child: CircularProgressIndicator())
                        : AdaptiveGrid(
                            config: _layoutConfig!,
                            cardColor: cardColor,
                            primaryColor: primaryColor,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 
