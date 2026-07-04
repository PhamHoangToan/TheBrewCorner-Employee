import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../models/shift_assignment.dart';
import '../../providers/attendance_provider.dart' show MonthKey;
import '../../providers/shift_provider.dart';
import '../../providers/shift_request_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_chip.dart';
import 'shift_request_screen.dart';

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

  // Gửi yêu cầu nhượng lại 1 ca đã được phân (admin duyệt mới có hiệu lực)
  Future<void> _confirmSwap(ShiftAssignment assignment) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nhượng lại ca này?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${assignment.shiftName} · ${_weekdayFmt.format(assignment.workDate)}',
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              maxLines: 2,
              decoration: const InputDecoration(hintText: 'Lý do nhượng ca...'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Hủy')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Gửi yêu cầu')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(shiftRequestRepositoryProvider).submitSwap(
            assignmentId: assignment.id,
            workDate: assignment.workDate,
            reason: reasonCtrl.text.trim(),
          );
      ref.invalidate(myShiftRequestsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã gửi yêu cầu nhượng ca — chờ quản lý duyệt')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gửi yêu cầu thất bại')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final assignmentsAsync = ref.watch(shiftAssignmentsProvider(_key));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ca làm việc'),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ShiftRequestScreen()),
            ),
            icon: const Icon(Icons.add_circle_outline, size: 18),
            label: const Text('Đăng ký ca'),
          ),
        ],
      ),
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
                  for (final a in assignments)
                    _ShiftRow(assignment: a, onSwap: () => _confirmSwap(a)),
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
  const _ShiftRow({required this.assignment, required this.onSwap});
  final ShiftAssignment assignment;
  final VoidCallback onSwap;

  bool get _isFuture => assignment.workDate.isAfter(DateTime.utc(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      ));

  bool get _isLeaveNote {
    final n = (assignment.note ?? '').toLowerCase();
    return n.contains('phép') || n.contains('phep');
  }

  bool get _isSwapNote {
    final n = (assignment.note ?? '').toLowerCase();
    return n.contains('nhượng ca') || n.contains('nhuong ca');
  }

  @override
  Widget build(BuildContext context) {
    Widget? trailing;
    if (assignment.status == 'ABSENT') {
      // Vắng mặt / nghỉ phép / đã nhượng ca luôn ưu tiên hiện đúng, kể cả khi ca ở ngày tương lai.
      trailing = _isSwapNote
          ? StatusChip(label: assignment.note ?? 'Cần người thay', background: AppColors.amberBg, foreground: AppColors.amberFg)
          : _isLeaveNote
              ? StatusChip(label: assignment.note ?? 'Nghỉ phép', background: AppColors.cream, foreground: AppColors.brand)
              : const StatusChip(label: 'Vắng mặt', background: AppColors.redBg, foreground: AppColors.redFg);
    } else if (_isFuture) {
      trailing = TextButton(
        onPressed: onSwap,
        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8), minimumSize: Size.zero),
        child: const Text('Nhượng ca', style: TextStyle(fontSize: 11)),
      );
    } else if (assignment.status == 'SCHEDULED') {
      // Đã tới ngày làm nhưng chưa ai cập nhật / không có chấm công → coi là vắng mặt.
      trailing = const StatusChip(label: 'Vắng mặt', background: AppColors.redBg, foreground: AppColors.redFg);
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
