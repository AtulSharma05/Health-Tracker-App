import 'package:flutter/material.dart';

class NutritionChip extends StatelessWidget {
  final String label;

  const NutritionChip({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text(label));
  }
}
