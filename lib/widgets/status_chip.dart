import 'package:flutter/material.dart';
import '../core/utils/app_colors.dart';

class StatusChip extends StatelessWidget {
  final String status;
  final Color? color;

  const StatusChip({
    super.key,
    required this.status,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    Color chipColor;
    
    if (color != null) {
      chipColor = color!;
    } else {
      switch (status.toLowerCase()) {
        case 'paid':
        case 'active':
        case 'good':
          chipColor = AppColors.success;
          break;
        case 'credit':
        case 'pending':
          chipColor = AppColors.warning;
          break;
        case 'overdue':
        case 'critical':
        case 'disease':
          chipColor = AppColors.error;
          break;
        case 'layer':
          chipColor = AppColors.accentYellow;
          break;
        case 'broiler':
          chipColor = AppColors.accentOrange;
          break;
        default:
          chipColor = Theme.of(context).colorScheme.primary;
      }
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: chipColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
