import 'package:flutter/material.dart';

import '../core/theme.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.background, required this.foreground});

  final String label;
  final Color background;
  final Color foreground;

  factory StatusChip.forRequestStatus(String status) {
    switch (status) {
      case 'APPROVED':
        return StatusChip(label: 'Đã duyệt', background: AppColors.greenBg, foreground: AppColors.greenFg);
      case 'REJECTED':
        return StatusChip(label: 'Từ chối', background: AppColors.redBg, foreground: AppColors.redFg);
      default:
        return StatusChip(label: 'Chờ duyệt', background: AppColors.amberBg, foreground: AppColors.amberFg);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(20)),
      child: Text(
        label,
        style: TextStyle(color: foreground, fontWeight: FontWeight.w700, fontSize: 11.5),
      ),
    );
  }
}
