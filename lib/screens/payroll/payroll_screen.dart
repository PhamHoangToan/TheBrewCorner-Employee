import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../models/payroll.dart';
import '../../providers/payroll_provider.dart';
import '../../widgets/empty_state.dart';
import 'payroll_detail/payroll_detail_screen.dart';

final _currency = NumberFormat.decimalPattern('vi_VN');

const _statusLabel = {'DRAFT': 'Nháp', 'APPROVED': 'Đã duyệt', 'PAID': 'Đã trả'};
const _statusColor = {
  'DRAFT': (AppColors.amberBg, AppColors.amberFg),
  'APPROVED': (AppColors.amberBg, AppColors.amberFg),
  'PAID': (AppColors.greenBg, AppColors.greenFg),
};

class PayrollScreen extends ConsumerWidget {
  const PayrollScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payrollAsync = ref.watch(payrollListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Lương của tôi')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(payrollListProvider),
        child: payrollAsync.when(
          data: (list) {
            if (list.isEmpty) {
              return ListView(
                children: const [EmptyState(message: 'Chưa có phiếu lương', icon: Icons.receipt_long_outlined)],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: list.length,
              itemBuilder: (context, i) => _PayrollCard(payroll: list[i]),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const Center(child: Text('Không tải được dữ liệu lương')),
        ),
      ),
    );
  }
}

class _PayrollCard extends StatelessWidget {
  const _PayrollCard({required this.payroll});
  final Payroll payroll;

  @override
  Widget build(BuildContext context) {
    final colors = _statusColor[payroll.status] ?? (AppColors.amberBg, AppColors.amberFg);
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => PayrollDetailScreen(year: payroll.periodYear, month: payroll.periodMonth),
        )),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tháng ${payroll.periodMonth}/${payroll.periodYear}',
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 6),
                    Text('${_currency.format(payroll.totalAmount)}đ',
                        style: const TextStyle(color: AppColors.brand, fontWeight: FontWeight.w700, fontSize: 18)),
                    const SizedBox(height: 4),
                    Text('${payroll.workedDays + payroll.paidLeaveDays} ngày công · ${payroll.otHours}h OT',
                        style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: colors.$1, borderRadius: BorderRadius.circular(11)),
                    child: Text(_statusLabel[payroll.status] ?? payroll.status,
                        style: TextStyle(color: colors.$2, fontWeight: FontWeight.w700, fontSize: 10.5)),
                  ),
                  const SizedBox(height: 22),
                  const Icon(Icons.chevron_right, color: AppColors.textMuted),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
