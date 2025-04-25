# 如何实现无边框子窗口

## 问题描述
在使用 `window_manager_plus` 创建子窗口时，需要确保子窗口与主窗口有相同的无边框效果和行为。

## 失败的尝试

### 尝试1：直接在子窗口中初始化
最初的尝试是在子窗口的 `TestPage` 中直接初始化窗口效果：
```dart
class _TestPageState extends State<TestPage> {
  Future<void> _initWindow() async {
    await Window.initialize();
    await Window.setEffect(
      effect: WindowEffect.acrylic,
      color: const Color(0x45B0B0B0),
    );
  }
}
```
这种方式失败的原因是：
1. 窗口效果的初始化应该在窗口创建时就完成
2. 在 widget 中初始化可能会导致时序问题

### 尝试2：独立的 MaterialApp
第二次尝试是在子窗口中使用独立的 MaterialApp：
```dart
runApp(MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: ThemeData(...),
  home: const TestPage(),
));
```
这种方式的问题是：
1. 创建了不必要的 MaterialApp 嵌套
2. 主题和样式与主窗口不一致
3. 窗口行为可能不一致

## 成功的实现

### 1. 修改主应用以支持子窗口
在 `ProHealthApp` 中添加子窗口支持：
```dart
class ProHealthApp extends StatefulWidget {
  final bool isTestPage;
  const ProHealthApp({super.key, this.isTestPage = false});
  
  @override
  State<ProHealthApp> createState() => _ProHealthAppState();
}
```

### 2. 在主应用中根据参数选择显示内容
```dart
home: widget.isTestPage ? const TestPage() : Scaffold(...)
```

### 3. 正确的窗口初始化顺序
在 `main.dart` 中：
```dart
if (args.isNotEmpty && args[1] == 'test_page') {
  // 1. 设置窗口选项
  WindowOptions windowOptions = const WindowOptions(
    size: Size(800, 600),
    minimumSize: Size(600, 400),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
  );
  
  // 2. 等待窗口准备就绪
  await WindowManagerPlus.current.waitUntilReadyToShow(windowOptions, () async {
    await WindowManagerPlus.current.setAsFrameless();
    await WindowManagerPlus.current.setHasShadow(true);
    await WindowManagerPlus.current.show();
    await WindowManagerPlus.current.focus();
  });
  
  // 3. 初始化毛玻璃效果
  await Window.initialize();
  await Window.setEffect(
    effect: WindowEffect.acrylic,
    color: const Color(0x45B0B0B0),
  );
  
  // 4. 运行应用
  runApp(const ProHealthApp(isTestPage: true));
  return;
}
```

### 4. 子窗口页面结构
在 `TestPage` 中：
1. 不要包含 MaterialApp
2. 使用与主窗口相同的 Stack 结构
3. 实现相同的窗口拖拽和缩放行为

```dart
return Scaffold(
  body: Stack(
    children: [
      // 主要内容
      Column(...),
      // 窗口拖动区域
      Positioned(...),
      // 窗口缩放区域
      Positioned(...),
    ],
  ),
);
```

## 关键点总结

1. 窗口初始化顺序很重要：
   - 先设置窗口选项
   - 然后等待窗口准备就绪
   - 最后初始化特效

2. 避免重复的 MaterialApp：
   - 使用同一个 MaterialApp 实例
   - 通过参数控制显示内容

3. 保持一致的窗口行为：
   - 使用相同的窗口选项
   - 实现相同的拖拽和缩放功能
   - 保持相同的视觉效果

4. 正确的组件层级：
   - 避免不必要的嵌套
   - 保持清晰的组件结构
   - 共享主题和样式

## 注意事项

1. 确保在 `main.dart` 中正确处理参数
2. 子窗口应该继承主窗口的主题和样式
3. 窗口管理器的监听器要在适当的时机添加和移除
4. 保持代码结构的一致性和可维护性
