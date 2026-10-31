import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFFC7CDBC);
  static const header = Color(0xFFB9CEAB);
  static const card = Color(0xFFF3ECE4);
  static const dark = Color(0xFF3B3830);
  static const text = Color(0xFF2C3E35);
  static const accent = Color(0xFFB3C9A6);
}

/// Colour of the priority tag shown on each task.
Color priorityColor(String priority) {
  switch (priority) {
    case 'High':
      return const Color(0xFFDE9A8E);
    case 'Medium':
      return const Color(0xFFE8CF85);
    default:
      return AppColors.header;
  }
}
