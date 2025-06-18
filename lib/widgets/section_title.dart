import 'package:flutter/material.dart';
import '../core/theme/app_text_styles.dart';

class SectionTitle extends StatelessWidget {
  final String title;
  final bool isLarge;
  const SectionTitle(this.title, {this.isLarge = false, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        title,
        style: isLarge ? AppTextStyles.bold20 : AppTextStyles.bold12,
      ),
    );
  }
} 