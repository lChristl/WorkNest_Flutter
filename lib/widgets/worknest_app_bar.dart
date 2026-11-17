import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'worknest_logo.dart';

PreferredSizeWidget workNestAppBar({List<Widget>? actions}) {
  return AppBar(
    backgroundColor: AppColors.header,
    automaticallyImplyLeading: false,
    elevation: 0,
    scrolledUnderElevation: 0,
    titleSpacing: 16,
    actions: actions,
    title: const Row(
      children: [
        WorkNestLogo(size: 38),
        SizedBox(width: 8),
        Text(
          'WorkNest',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
      ],
    ),
  );
}