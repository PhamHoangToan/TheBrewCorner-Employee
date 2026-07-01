import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../models/shift_assignment.dart';
import '../../providers/attendance_provider.dart' show MonthKey;
import '../../providers/shift_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_chip.dart';

final _weekdayFmt = DateFormat('EEEE, dd/MM', 'vi');

class ShiftScreen extends ConsumerStatefulWidget {
  const ShiftScreen({super.key});

  @override
  ConsumerState<ShiftScreen> createState() => _ShiftScreenState();
}

class _ShiftScreenState extends ConsumerState<ShiftScreen> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  MonthKey get _key => (year: _month.year, month: _month.month);

  void _shiftMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
  }

  @override
  Widget build(BuildContext context) {
    final assignmentsAsync = ref.watch(shiftAssignmentsProvider(_key));

    return Scaffold(
      appBar: AppBar(title: const Text('Ca làm việc')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(shiftAssignmentsProvider(_key)),
        child: assignmentsAsync.when(
          data: (assignments) {
            final scheduledCount = assignments.length;
            final workedCount = assignments.where((a) => a.status == 'COMPLETED' || a.status == 'IN_PROGRESS').length;

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _shiftMonth(-1)),
                        Text('Tháng ${_month.month}, ${_month.year}',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _shiftMonth(1)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('$scheduledCount ca theo lịch · $workedCount ca đã chấm công',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                const SizedBox(height: 14),
                if (assignments.isEmpty)
                  const EmptyState(message: 'Chưa có ca làm việc nào trong tháng này', icon: Icons.event_busy_outlined)
                else
                  for (final a in assignments) _ShiftRow(assignment: a),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const Center(child: Text('Không tải được lịch làm việc')),
        ),
      ),
    );
  }
}

class _ShiftRow extends StatelessWidget {
  const _ShiftRow({required this.assignment});
  final ShiftAssignment assignment;

  bool get _isFuture => assignment.workDate.isAfter(DateTime.utc(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      ));

  bool get _isLeaveNote {
    final n = (assignment.note ?? '').toLowerCase();
    return n.contains('phép') || n.contains('phep');
  }

  @override
  Widget build(BuildContext context) {
    Widget? trailing;
    if (_isFuture || assignment.status == 'SCHEDULED') {
      trailing = const Text('— Chưa tới ngày', style: TextStyle(fontSize: 11, color: AppColors.textMuted));
    } else if (assignment.status == 'ABSENT') {
      trailing = _isLeaveNote
          ? StatusChip(label: assignment.note ?? 'Nghỉ phép', background: AppColors.cream, foreground: AppColors.brand)
          : const StatusChip(label: 'Vắng mặt', background: AppColors.redBg, foreground: AppColors.redFg);
    } else {
      trailing = const StatusChip(label: 'Đang làm', background: AppColors.greenBg, foreground: AppColors.greenFg);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_weekdayFmt.format(assignment.workDate), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 3),
                  Text(
                    '${assignment.shiftName.isNotEmpty ? assignment.shiftName : 'Ca làm việc'} · ${assignment.startTime}–${assignment.endTime}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}
