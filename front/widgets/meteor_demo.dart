import 'dart:math';
import 'package:flutter/material.dart';
import 'meteor_shower.dart';

class MeteorDemo extends StatelessWidget {
  const MeteorDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        MeteorShower(
          numberOfMeteors: 10,
          duration: const Duration(seconds: 5),
          child: Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(
                color: const Color.fromARGB(255, 96, 96, 96),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Meteor shower',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    foreground: Paint()
                      ..shader = LinearGradient(
                        colors: [
                          Colors.white,
                          Colors.white.withOpacity(0.2)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
} 