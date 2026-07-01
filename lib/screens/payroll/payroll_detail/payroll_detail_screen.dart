import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme.dart';
import '../../../providers/payroll_provider.dart';

final _currency = NumberFormat.decimalPattern('vi_VN');

class PayrollDetailScreen extends ConsumerWidget {
  const PayrollDetailScreen({super.key, required this.year, required this.month});
  final int year;
  final int month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(payrollDetailProvider((year: year, month: month)));

    return Scaffold(
      appBar: AppBar(title: Text('Phiếu lương tháng $month/$year')),
      body: detailAsync.when(
        data: (p) {
          if (p == null) return const Center(child: Text('Không có dữ liệu'));
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text('Thực nhận', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                      const SizedBox(height: 6),
                      Text('${_currency.format(p.totalAmount)}đ',
                          style: const TextStyle(color: AppColors.brand, fontWeight: FontWeight.w800, fontSize: 28)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _row('Ngày công theo lịch', '${p.scheduledDays} ngày'),
                      _row('Ngày công thực tế', '${p.workedDays} ngày'),
                      _row('Ngày nghỉ phép', '${p.paidLeaveDays} ngày'),
                      _row('Ngày vắng', '${p.absentDays} ngày'),
                      _row('Tổng giờ làm', '${p.totalHours}h'),
                      _row('Giờ tăng ca (OT)', '${p.otHours}h'),
                      _row('Tiền OT', '${_currency.format(p.otAmount)}đ'),
                      _row('Phạt đi trễ/về sớm', '${_currency.format(p.penaltyAmount)}đ', isNegative: p.penaltyAmount > 0),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('Không tải được chi tiết phiếu lương')),
      ),
    );
  }

  Widget _row(String label, String value, {bool isNegative = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
          Text(value,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: isNegative ? AppColors.redFg : AppColors.textDark,
              )),
        ],
      ),
    );
  }
}
