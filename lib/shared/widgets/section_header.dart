import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.action, this.icon});

  final String title;
  final Widget? action;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}
