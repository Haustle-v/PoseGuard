import 'package:flutter/material.dart';
import 'dart:math' as math;

class CustomWaveShape extends StatefulWidget {
  final double fillLevel; // 0.0 到 1.0 之间的值，表示填充水位

  const CustomWaveShape({
    super.key, 
    required this.fillLevel,
  });

  @override
  State<CustomWaveShape> createState() => _CustomWaveShapeState();
}

class _CustomWaveShapeState extends State<CustomWaveShape> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return CustomPaint(
          painter: CurvedPainter(
            fillLevel: widget.fillLevel,
            animationValue: _animationController.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class CurvedPainter extends CustomPainter {
  final double fillLevel;
  final double animationValue;

  CurvedPainter({
    required this.fillLevel,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 计算填充高度
    final fillHeight = size.height * (1 - fillLevel.clamp(0.0, 1.0));
    
    // 使用莫兰蒂色系的蓝色
    var paint = Paint()
      ..color = const Color(0xFF7B9AAF) // 莫兰蒂色系蓝色
      ..style = PaintingStyle.fill;

    var path = Path();
    
    // 起始点在底部
    path.moveTo(0, size.height);
    
    // 绘制到左侧填充高度位置
    path.lineTo(0, fillHeight);
    
    // 增加波浪的振幅
    final waveHeight = size.height * 0.05;
    
    // 使用动画值创建波浪效果
    final wavePhase = animationValue * 2 * math.pi;
    
    // 绘制波浪曲线 - 确保覆盖到右边界
    final step = 5.0; // 减小步长以获得更平滑的曲线
    for (double x = 0; x <= size.width + step; x += step) {
      final dx = x / size.width;
      final waveOffset = math.sin(dx * 4 * math.pi + wavePhase) * waveHeight;
      
      path.lineTo(x, fillHeight + waveOffset);
    }
    
    // 确保最后一个点是右边界
    path.lineTo(size.width, fillHeight);
    
    // 完成路径回到底部
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CurvedPainter oldDelegate) {
    return oldDelegate.fillLevel != fillLevel || 
           oldDelegate.animationValue != animationValue;
  }
} 