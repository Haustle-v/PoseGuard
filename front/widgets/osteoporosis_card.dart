import 'package:flutter/material.dart';
import 'custom_step_counter.dart';
import 'custom_wave_shape.dart';
import 'slide_to_drink.dart';
import 'meteor_shower.dart';

class OsteoporosisCard extends StatefulWidget {
  const OsteoporosisCard({super.key});

  @override
  State<OsteoporosisCard> createState() => _OsteoporosisCardState();
}

class _OsteoporosisCardState extends State<OsteoporosisCard> with SingleTickerProviderStateMixin {
  int _targetCups = 8; // 默认目标杯数
  int _drankCups = 0; // 已喝杯数
  
  // 添加动画控制器
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  double _currentProgress = 0.0;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _progressAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _animationController.addListener(() {
      setState(() {
        _currentProgress = _progressAnimation.value;
      });
    });
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  double get _progress => _targetCups > 0 ? _drankCups / _targetCups : 0;

  void _updateTargetCups(int value) {
    final oldProgress = _progress;
    
    setState(() {
      _targetCups = value > 0 ? value : 1; // 确保目标杯数至少为1
    });
    
    // 更新动画
    _progressAnimation = Tween<double>(
      begin: oldProgress,
      end: _progress,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.forward(from: 0.0);
  }

  void _drinkWater() {
    final oldProgress = _progress;
    
    setState(() {
      _drankCups = (_drankCups + 1).clamp(0, _targetCups);
    });
    
    // 更新动画
    _progressAnimation = Tween<double>(
      begin: oldProgress,
      end: _progress,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.forward(from: 0.0);
  }
  
  // 撤回喝水操作
  void _undoDrinkWater() {
    if (_drankCups <= 0) return; // 如果已经是0，不执行撤回
    
    final oldProgress = _progress;
    
    setState(() {
      _drankCups = (_drankCups - 1).clamp(0, _targetCups);
    });
    
    // 更新动画
    _progressAnimation = Tween<double>(
      begin: oldProgress,
      end: _progress,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    // 使用当前动画进度或实际进度
    final displayProgress = _animationController.isAnimating 
        ? _currentProgress 
        : _progress;
    
    return MeteorShower(
      numberOfMeteors: 8,
      duration: const Duration(seconds: 6),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            // 水波效果
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: CustomWaveShape(fillLevel: displayProgress),
              ),
            ),
            
            // 内容
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final maxHeight = constraints.maxHeight;
                  final maxWidth = constraints.maxWidth;
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 标题行，包含标题和撤回按钮
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '每日饮水',
                            style: TextStyle(
                              fontSize: maxHeight * 0.08,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          // 撤回按钮
                          _drankCups > 0 
                            ? InkWell(
                                onTap: _undoDrinkWater,
                                child: Container(
                                  width: maxHeight * 0.1,
                                  height: maxHeight * 0.1,
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade800.withOpacity(0.3),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.undo_rounded,
                                      color: Colors.white,
                                      size: maxHeight * 0.06,
                                    ),
                                  ),
                                ),
                              )
                            : SizedBox(width: maxHeight * 0.1),
                        ],
                      ),
                      
                      SizedBox(height: maxHeight * 0.02),
                      
                      // 目标杯数选择器
                      Container(
                        height: maxHeight * 0.2,
                        padding: EdgeInsets.symmetric(vertical: maxHeight * 0.02),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              '目标杯数: ',
                              style: TextStyle(
                                fontSize: maxHeight * 0.06,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(
                              width: maxWidth * 0.6,
                              child: CustomStepCounter(
                                initialValue: _targetCups,
                                onChanged: _updateTargetCups,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const Spacer(),
                      
                      // 进度显示
                      Center(
                        child: Column(
                          children: [
                            Text(
                              '$_drankCups / $_targetCups',
                              style: TextStyle(
                                fontSize: maxHeight * 0.12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              '已完成 ${(_progress * 100).toInt()}%',
                              style: TextStyle(
                                fontSize: maxHeight * 0.05,
                                color: Colors.blue.shade300,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const Spacer(),
                      
                      // 滑动喝水
                      Container(
                        height: maxHeight * 0.18,
                        child: SlideToActWidget(onSlideComplete: _drinkWater),
                      ),
                    ],
                  );
                }
              ),
            ),
          ],
        ),
      ),
    );
  }
} 