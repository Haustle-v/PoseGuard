import 'package:control_style/control_style.dart';
import 'package:flutter/material.dart';

class AnimatedShadowBorder extends StatefulWidget {
  final Widget child;
  final BorderRadius borderRadius;
  final Duration duration;
  
  const AnimatedShadowBorder({
    super.key, 
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.duration = const Duration(seconds: 3),
  });

  @override
  State<AnimatedShadowBorder> createState() => _AnimatedShadowBorderState();
}

class _AnimatedShadowBorderState extends State<AnimatedShadowBorder>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Tween<double> tween;
  late Animation<double> animation;

  @override
  void initState() {
    controller = AnimationController(duration: widget.duration, vsync: this);
    tween = Tween<double>(begin: 0, end: 359);
    animation = controller.drive(tween);

    controller.forward();
    controller.repeat();
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final colors = _generateGradientColors(animation.value);
        return Container(
          decoration: ShapeDecoration(
            shape: DecoratedOutlinedBorder(
              shadow: [
                GradientShadow(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: colors,
                    stops: _generateGradientStops(),
                  ),
                  offset: const Offset(0, 0),
                  blurRadius: 15,
                  spreadRadius: 3.0,
                )
              ],
              child: RoundedRectangleBorder(
                borderRadius: widget.borderRadius,
                side: BorderSide(
                  width: 2.0,
                  color: colors[0].withOpacity(0.9),
                ),
              ),
            ),
          ),
          child: widget.child,
        );
      },
    );
  }

  List<Color> _generateGradientColors(double offset) {
    List<Color> colors = [];
    const int divisions = 10;
    for (int i = 0; i < divisions; i++) {
      double hue = (360 / divisions) * i;
      hue += offset;
      if (hue > 360) {
        hue -= 360;
      }
      final Color color = HSVColor.fromAHSV(1.0, hue, 1.0, 1.0).toColor();
      colors.add(color);
    }
    colors.add(colors[0]);
    return colors;
  }

  List<double> _generateGradientStops() {
    const int divisions = 10;
    List<double> stops = [];
    for (int i = 0; i <= divisions; i++) {
      stops.add(i / divisions);
    }
    return stops;
  }
} 