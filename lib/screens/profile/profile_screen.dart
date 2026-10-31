import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../widgets/pill_button.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const CircleAvatar(
            radius: 48,
            backgroundColor: AppColors.card,
            child: Icon(Icons.person, size: 56, color: AppColors.dark),
          ),
          const SizedBox(height: 12),
          const Text(
            'Your Name', // TODO: load from user data
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 4),
          const Text('email@example.com'),
          const SizedBox(height: 32),
          PillButton(
            label: 'Log out',
            onPressed: () => Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            ),
          ),
        ],
      ),
    );
  }
}
