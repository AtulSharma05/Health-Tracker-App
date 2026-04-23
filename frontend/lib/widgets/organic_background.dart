import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class NutritionBackground extends StatelessWidget {
  final Widget child;

  const NutritionBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -50,
          right: -40,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              color: AppTheme.mint.withOpacity(0.6),
              borderRadius: BorderRadius.circular(100),
            ),
          ),
        ),
        Positioned(
          bottom: -60,
          left: -30,
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              color: AppTheme.peach.withOpacity(0.6),
              borderRadius: BorderRadius.circular(120),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
