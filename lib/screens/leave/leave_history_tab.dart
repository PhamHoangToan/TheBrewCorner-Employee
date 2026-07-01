import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../providers/leave_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_chip.dart';

final _dateFmt = DateFormat('dd/MM/yyyy');

const _leaveTypeLabel = {'ANNUAL': 'Phép năm', 'SICK': 'Ốm', 'UNPAID': 'Không lương'};

class LeaveHistoryTab extends ConsumerWidget {
  const LeaveHistoryTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaveAsync = ref.watch(leaveRequestsProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(leaveRequestsProvider),
      child: leaveAsync.when(
        data: (list) {
          if (list.isEmpty) {
            return ListView(
              children: const [EmptyState(message: 'Chưa gửi đơn nghỉ nào', icon: Icons.event_busy_outlined)],
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final r = list[i];
              final sameDay = r.startDate.year == r.endDate.year &&
                  r.startDate.month == r.endDate.month &&
                  r.startDate.day == r.endDate.day;
              final dateLabel = sameDay
                  ? _dateFmt.format(r.startDate)
                  : '${_dateFmt.format(r.startDate)} – ${_dateFmt.format(r.endDate)}';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(dateLabel, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                          ),
                          StatusChip.forRequestStatus(r.status),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(_leaveTypeLabel[r.type] ?? r.type, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(r.reason, style: const TextStyle(fontSize: 12.5)),
                      if (r.status == 'REJECTED' && (r.rejectReason ?? '').isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text('Lý do từ chối: ${r.rejectReason}',
                            style: const TextStyle(fontSize: 11.5, color: AppColors.redFg)),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('Không tải được lịch sử đơn nghỉ')),
      ),
    );
  }
}
