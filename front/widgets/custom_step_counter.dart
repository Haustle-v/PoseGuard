import 'package:flutter/material.dart';
import 'package:stepper_touch/stepper_touch.dart';

class CustomStepCounter extends StatelessWidget {
  final int initialValue;
  final ValueChanged<int> onChanged;

  const CustomStepCounter({
    super.key,
    this.initialValue = 0,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: StepperTouch(
        initialValue: initialValue,
        direction: Axis.horizontal,
        withSpring: false,
        onChanged: onChanged,
      ),
    );
  }
} 