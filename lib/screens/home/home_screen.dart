import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/leave_provider.dart';
import '../../providers/payroll_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/status_chip.dart';

final _currency = NumberFormat.decimalPattern('vi_VN');
final _dateFmt = DateFormat('dd/MM/yyyy');

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final payrollAsync = ref.watch(payrollListProvider);
    final leaveAsync = ref.watch(leaveRequestsProvider);

    final greetingHour = DateTime.now().hour;
    final greeting = greetingHour < 12
        ? 'Chào buổi sáng'
        : greetingHour < 18
            ? 'Chào buổi chiều'
            : 'Chào buổi tối';

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 96,
        title: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$greeting, ${user?.name.split(' ').last ?? ''}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
              const SizedBox(height: 2),
              Text(_dateFmt.format(DateTime.now()), style: const TextStyle(color: AppColors.cream, fontSize: 12)),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'logout') ref.read(authProvider.notifier).logout();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'logout', child: Text('Đăng xuất')),
              ],
              child: CircleAvatar(
                backgroundColor: AppColors.cream,
                child: Text(
                  (user?.name ?? '?').substring(0, 1).toUpperCase(),
                  style: const TextStyle(color: AppColors.brand, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(payrollListProvider);
          ref.invalidate(leaveRequestsProvider);
          await ref.read(authProvider.notifier).refreshProfile();
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    icon: Icons.beach_access_outlined,
                    value: '${user?.paidLeaveDaysLeft ?? 0} ngày',
                    label: 'Ngày phép còn lại',
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: payrollAsync.when(
                    data: (list) => StatCard(
                      icon: Icons.attach_money_rounded,
                      value: list.isEmpty ? '—' : '${_currency.format(list.first.totalAmount)}đ',
                      label: list.isEmpty ? 'Chưa có phiếu lương' : 'Lương tháng ${list.first.periodMonth}',
                    ),
                    loading: () => const StatCard(icon: Icons.attach_money_rounded, value: '...', label: 'Đang tải'),
                    error: (_, _) => const StatCard(icon: Icons.attach_money_rounded, value: '—', label: 'Lỗi tải dữ liệu'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            leaveAsync.when(
              data: (list) {
                final pending = list.where((r) => r.status == 'PENDING').length;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.description_outlined, color: AppColors.brand, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('$pending đơn chờ duyệt', style: Theme.of(context).textTheme.titleSmall),
                              const Text('Yêu cầu nghỉ phép', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const SizedBox(height: 72),
              error: (_, _) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),
            Text('Đơn nghỉ gần đây', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            leaveAsync.when(
              data: (list) {
                if (list.isEmpty) return const EmptyState(message: 'Chưa gửi đơn nghỉ nào', icon: Icons.event_busy_outlined);
                final recent = list.take(3).toList();
                return Column(
                  children: recent.map((r) {
                    final sameDay = r.startDate == r.endDate ||
                        (r.startDate.year == r.endDate.year && r.startDate.month == r.endDate.month && r.startDate.day == r.endDate.day);
                    final dateLabel = sameDay
                        ? _dateFmt.format(r.startDate)
                        : '${_dateFmt.format(r.startDate)} – ${_dateFmt.format(r.endDate)}';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(width: 4, height: 40, color: AppColors.brand),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(dateLabel, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                  Text(_leaveTypeLabel(r.type), style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                                ],
                              ),
                            ),
                            StatusChip.forRequestStatus(r.status),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
              error: (_, _) => const EmptyState(message: 'Không tải được dữ liệu', icon: Icons.error_outline),
            ),
          ],
        ),
      ),
    );
  }
}

String _leaveTypeLabel(String type) {
  switch (type) {
    case 'SICK':
      return 'Ốm';
    case 'UNPAID':
      return 'Không lương';
    default:
      return 'Phép năm';
  }
}
