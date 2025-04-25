import 'package:flutter/material.dart';
import 'package:slide_to_act/slide_to_act.dart';

class SlideToActWidget extends StatefulWidget {
  final VoidCallback onSlideComplete;

  const SlideToActWidget({
    super.key,
    required this.onSlideComplete,
  });

  @override
  State<SlideToActWidget> createState() => _SlideToActWidgetState();
}

class _SlideToActWidgetState extends State<SlideToActWidget> with SingleTickerProviderStateMixin {
  final GlobalKey<SlideActionState> _slideKey = GlobalKey();
  late AnimationController _animationController;
  bool _isResetting = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _slideKey.currentState?.reset();
        _isResetting = false;
      }
    });
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SlideAction(
        text: '滑动喝水',
        textStyle: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        outerColor: Colors.blue.shade800.withOpacity(0.8),
        innerColor: Colors.white,
        sliderButtonIcon: const Icon(
          Icons.local_drink,
          color: Colors.blue,
        ),
        key: _slideKey,
        onSubmit: () {
          // 调用回调
          widget.onSlideComplete();
          
          // 启动重置动画
          setState(() {
            _isResetting = true;
          });
          
          // 延迟重置，添加动画效果
          _animationController.forward(from: 0.0);
          
          return null;
        },
        sliderRotate: false,
        animationDuration: const Duration(milliseconds: 300),
      ),
    );
  }
} 