import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class WorkNestLogo extends StatelessWidget {
  final double size;
  const WorkNestLogo({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    // Put your logo at assets/logo.png and register it in pubspec.yaml.
    // Until then, the green check icon is used as a fallback.
    return Image.asset(
      'assets/logo.png',
      width: size,
      height: size,
      errorBuilder: (_, __, ___) => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: AppColors.accent,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.check, size: size * 0.6, color: Colors.white),
      ),
    );
  }
}
