import 'package:flutter/material.dart';
import 'dart:async';

class BreathingCard extends StatefulWidget {
  final Color cardColor;
  final Color primaryColor;

  const BreathingCard({
    super.key,
    required this.cardColor,
    required this.primaryColor,
  });

  @override
  State<BreathingCard> createState() => _BreathingCardState();
}

class _BreathingCardState extends State<BreathingCard> with SingleTickerProviderStateMixin {
  // 呼吸设置
  int _inhaleSeconds = 4;
  int _holdSeconds = 4;
  int _exhaleSeconds = 4;
  int _cycles = 3;
  
  // 呼吸状态
  bool _isBreathing = false;
  String _currentState = "准备";
  int _currentCycle = 0;
  int _remainingSeconds = 0;
  double _remainingSecondsDecimal = 0.0; // 添加小数部分，用于平滑过渡
  
  // 动画控制器
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  // 计时器
  Timer? _timer;
  Timer? _colorUpdateTimer; // 添加颜色更新计时器
  
  @override
  void initState() {
    super.initState();
    
    // 初始化动画控制器
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _inhaleSeconds),
    );
    
    // 初始化动画
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut)
    );
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _timer?.cancel();
    _colorUpdateTimer?.cancel(); // 取消颜色更新计时器
    super.dispose();
  }
  
  // 开始呼吸练习
  void _startBreathing() {
    if (_isBreathing) return;
    
    setState(() {
      _isBreathing = true;
      _currentCycle = 1;
      _currentState = "吸气";
      _remainingSeconds = _inhaleSeconds;
      _remainingSecondsDecimal = _inhaleSeconds.toDouble();
    });
    
    // 设置动画时长为吸气时间
    _animationController.duration = Duration(seconds: _inhaleSeconds);
    _animationController.forward();
    
    // 启动计时器 - 每秒更新一次倒计时
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remainingSeconds--;
      });
      
      if (_remainingSeconds <= 0) {
        _nextBreathingState();
      }
    });
    
    // 启动高频率颜色更新计时器 - 每0.1秒更新一次颜色
    _colorUpdateTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!_isBreathing) return;
      
      setState(() {
        // 每0.1秒减少0.1
        _remainingSecondsDecimal -= 0.1;
        if (_remainingSecondsDecimal < 0) _remainingSecondsDecimal = 0;
      });
    });
  }
  
  // 切换到下一个呼吸状态
  void _nextBreathingState() {
    if (!_isBreathing) return;
    
    if (_currentState == "吸气") {
      // 吸气结束，切换到屏息
      setState(() {
        _currentState = "屏息";
        _remainingSeconds = _holdSeconds;
        _remainingSecondsDecimal = _holdSeconds.toDouble();
      });
      // 保持动画在扩大状态
      _animationController.stop();
    } else if (_currentState == "屏息") {
      // 屏息结束，切换到呼气
      setState(() {
        _currentState = "呼气";
        _remainingSeconds = _exhaleSeconds;
        _remainingSecondsDecimal = _exhaleSeconds.toDouble();
      });
      // 反向动画，缩小
      _animationController.reverse();
    } else if (_currentState == "呼气") {
      // 呼气结束，检查是否完成所有周期
      if (_currentCycle >= _cycles) {
        // 完成所有周期，结束练习
        _stopBreathing();
      } else {
        // 进入下一个周期
        setState(() {
          _currentCycle++;
          _currentState = "吸气";
          _remainingSeconds = _inhaleSeconds;
          _remainingSecondsDecimal = _inhaleSeconds.toDouble();
        });
        // 正向动画，扩大
        _animationController.forward();
      }
    }
  }
  
  // 停止呼吸练习
  void _stopBreathing() {
    _timer?.cancel();
    _timer = null;
    _colorUpdateTimer?.cancel(); // 取消颜色更新计时器
    _colorUpdateTimer = null;
    _animationController.reset();
    
    setState(() {
      _isBreathing = false;
      _currentState = "准备";
      _currentCycle = 0;
      _remainingSeconds = 0;
      _remainingSecondsDecimal = 0.0;
    });
  }
  
  // 获取当前状态的颜色
  List<Color> _getGradientColors() {
    if (!_isBreathing) {
      return [
        widget.primaryColor.withOpacity(0.3),
        widget.primaryColor.withOpacity(0.1),
      ];
    }
    
    switch (_currentState) {
      case "吸气":
        return [
          Colors.blue.shade200,
          Colors.blue.shade50,
        ];
      case "屏息":
        return [
          Colors.purple.shade200,
          Colors.purple.shade50,
        ];
      case "呼气":
        return [
          Colors.teal.shade200,
          Colors.teal.shade50,
        ];
      default:
        return [
          widget.primaryColor.withOpacity(0.3),
          widget.primaryColor.withOpacity(0.1),
        ];
    }
  }
  
  // 获取当前状态的指导文字
  String _getInstructionText() {
    if (!_isBreathing) {
      return "设置您的深呼吸参数，然后点击开始";
    }
    
    switch (_currentState) {
      case "吸气":
        return "缓慢吸气，感受空气充满肺部";
      case "屏息":
        return "保持呼吸，感受平静";
      case "呼气":
        return "缓慢呼气，释放所有压力";
      default:
        return "";
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final gradientColors = _getGradientColors();
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.9),
            Colors.white.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.air,
                      color: widget.primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "深呼吸练习",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // 呼吸动画区域
            Expanded(
              child: _isBreathing 
                ? _buildBreathingAnimation(gradientColors)
                : _buildSetupView(),
            ),
            
            // 控制区域
            _isBreathing 
              ? Center(
                  child: ElevatedButton.icon(
                    onPressed: _stopBreathing,
                    icon: const Icon(Icons.stop_circle_outlined),
                    label: const Text("停止练习"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade400,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                )
              : Column(
                  children: [
                    // 呼吸设置
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.arrow_circle_down, size: 16, color: Colors.blue.shade700),
                                        const SizedBox(width: 4),
                                        const Text(
                                          "吸气 (秒)",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Slider(
                                      value: _inhaleSeconds.toDouble(),
                                      min: 2,
                                      max: 8,
                                      divisions: 6,
                                      label: _inhaleSeconds.toString(),
                                      activeColor: Colors.blue.shade400,
                                      onChanged: (value) {
                                        setState(() {
                                          _inhaleSeconds = value.toInt();
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.pause_circle_outline, size: 16, color: Colors.purple.shade700),
                                        const SizedBox(width: 4),
                                        const Text(
                                          "屏息 (秒)",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Slider(
                                      value: _holdSeconds.toDouble(),
                                      min: 0,
                                      max: 8,
                                      divisions: 8,
                                      label: _holdSeconds.toString(),
                                      activeColor: Colors.purple.shade400,
                                      onChanged: (value) {
                                        setState(() {
                                          _holdSeconds = value.toInt();
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.arrow_circle_up, size: 16, color: Colors.teal.shade700),
                                        const SizedBox(width: 4),
                                        const Text(
                                          "呼气 (秒)",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Slider(
                                      value: _exhaleSeconds.toDouble(),
                                      min: 2,
                                      max: 8,
                                      divisions: 6,
                                      label: _exhaleSeconds.toString(),
                                      activeColor: Colors.teal.shade400,
                                      onChanged: (value) {
                                        setState(() {
                                          _exhaleSeconds = value.toInt();
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.repeat, size: 16, color: Colors.amber.shade700),
                                        const SizedBox(width: 4),
                                        const Text(
                                          "周期数",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Slider(
                                      value: _cycles.toDouble(),
                                      min: 1,
                                      max: 10,
                                      divisions: 9,
                                      label: _cycles.toString(),
                                      activeColor: Colors.amber.shade400,
                                      onChanged: (value) {
                                        setState(() {
                                          _cycles = value.toInt();
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // 开始按钮
                    ElevatedButton.icon(
                      onPressed: _startBreathing,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text("开始深呼吸"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.primaryColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 46),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(23),
                        ),
                      ),
                    ),
                  ],
                ),
          ],
        ),
      ),
    );
  }
  
  // 呼吸设置视图
  Widget _buildSetupView() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.spa_outlined,
              size: 60,
              color: widget.primaryColor.withOpacity(0.7),
            ),
            const SizedBox(height: 16),
            const Text(
              "设置您的深呼吸参数",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "调整滑块设置吸气、屏息和呼气时间，\n然后点击开始按钮",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // 呼吸动画视图
  Widget _buildBreathingAnimation(List<Color> gradientColors) {
    return Stack(
      children: [
        // 中央呼吸圆圈
        Center(
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              // 根据当前状态动态计算颜色
              List<Color> currentColors = _getCurrentAnimationColors();
              
              return Container(
                width: MediaQuery.of(context).size.width * 0.15 * _animation.value,
                height: MediaQuery.of(context).size.width * 0.15 * _animation.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: currentColors,
                    stops: const [0.4, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: currentColors[0].withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        
        // 右侧状态指示器（竖排）- 收窄并往右挪
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          child: Center(
            child: _buildVerticalStateIndicator(gradientColors),
          ),
        ),
      ],
    );
  }
  
  // 获取当前动画的颜色（平滑过渡）
  List<Color> _getCurrentAnimationColors() {
    if (!_isBreathing) {
      return [
        widget.primaryColor.withOpacity(0.3),
        widget.primaryColor.withOpacity(0.1),
      ];
    }
    
    // 定义三个阶段的基础颜色
    final inhaleColor1 = Colors.blue.shade200;
    final inhaleColor2 = Colors.blue.shade50;
    
    final holdColor1 = Colors.purple.shade200;
    final holdColor2 = Colors.purple.shade50;
    
    final exhaleColor1 = inhaleColor1; // 呼气结束颜色与吸气开始颜色相同
    final exhaleColor2 = inhaleColor2; // 呼气结束颜色与吸气开始颜色相同
    
    // 计算当前阶段的进度 (0.0 到 1.0)
    double progress = 0.0;
    Color color1;
    Color color2;
    
    if (_currentState == "吸气") {
      // 吸气阶段：从蓝色渐变到紫色
      progress = (_inhaleSeconds - _remainingSecondsDecimal) / _inhaleSeconds;
      color1 = Color.lerp(inhaleColor1, holdColor1, progress)!;
      color2 = Color.lerp(inhaleColor2, holdColor2, progress)!;
    } 
    else if (_currentState == "屏息") {
      // 屏息阶段：保持紫色
      color1 = holdColor1;
      color2 = holdColor2;
    } 
    else if (_currentState == "呼气") {
      // 呼气阶段：从紫色渐变回蓝色
      progress = (_exhaleSeconds - _remainingSecondsDecimal) / _exhaleSeconds;
      color1 = Color.lerp(holdColor1, exhaleColor1, progress)!;
      color2 = Color.lerp(holdColor2, exhaleColor2, progress)!;
    }
    else {
      // 默认颜色
      color1 = inhaleColor1;
      color2 = inhaleColor2;
    }
    
    return [color1, color2];
  }
  
  // 竖排状态指示器
  Widget _buildVerticalStateIndicator(List<Color> gradientColors) {
    // 获取当前状态的颜色，与呼吸圆圈保持一致
    final currentColors = _getCurrentAnimationColors();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1.5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          bottomLeft: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 状态文字
          Text(
            _currentState,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: currentColors[0],
            ),
          ),
          const SizedBox(height: 8),
          // 倒计时圆圈
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: currentColors[0].withOpacity(0.2),
              border: Border.all(
                color: currentColors[0],
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                "$_remainingSeconds",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: currentColors[0],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // 当前周期
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: currentColors[0].withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: currentColors[0].withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              "$_currentCycle/$_cycles",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: currentColors[0],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // 指导文字 - 不再使用，保留方法以备将来需要
  Widget _buildInstructionText() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Text(
        _getInstructionText(),
        style: const TextStyle(
          fontSize: 16,
          fontStyle: FontStyle.italic,
          color: Colors.black87,
        ),
      ),
    );
  }
} 