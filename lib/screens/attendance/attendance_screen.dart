import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../models/attendance_log.dart';
import '../../providers/attendance_provider.dart';
import '../../widgets/status_chip.dart';
import 'correction_sheet.dart';

final _timeFmt = DateFormat('HH:mm');
final _weekdayFmt = DateFormat('EEEE, dd/MM', 'vi');

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
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
    final logsAsync = ref.watch(attendanceMonthProvider(_key));
    final correctionsAsync = ref.watch(attendanceCorrectionsProvider(_key));
    final now = DateTime.now();
    final isCurrentMonth = _month.year == now.year && _month.month == now.month;
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final lastDay = isCurrentMonth ? now.day : daysInMonth;

    return Scaffold(
      appBar: AppBar(title: const Text('Chấm công')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(attendanceMonthProvider(_key));
          ref.invalidate(attendanceCorrectionsProvider(_key));
        },
        child: logsAsync.when(
          data: (logs) => correctionsAsync.when(
            data: (corrections) {
              final byDay = <int, AttendanceLog>{};
              for (final l in logs) {
                byDay[l.workDate.day] = l;
              }
              final correctionByDay = <int, String>{};
              for (final c in corrections) {
                correctionByDay[c.workDate.day] = c.status;
              }

              final workedCount = logs.where((l) => l.checkIn != null).length;

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
                          IconButton(
                            icon: const Icon(Icons.chevron_right),
                            onPressed: isCurrentMonth ? null : () => _shiftMonth(1),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('$workedCount ngày có chấm công / $lastDay ngày',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  const SizedBox(height: 14),
                  for (int day = 1; day <= lastDay; day++)
                    _DayRow(
                      date: DateTime.utc(_month.year, _month.month, day),
                      log: byDay[day],
                      correctionStatus: correctionByDay[day],
                    ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const Center(child: Text('Không tải được dữ liệu bổ sung chấm công')),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const Center(child: Text('Không tải được dữ liệu chấm công')),
        ),
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({required this.date, required this.log, required this.correctionStatus});

  final DateTime date;
  final AttendanceLog? log;
  final String? correctionStatus;

  @override
  Widget build(BuildContext context) {
    final hasLog = log != null;
    final subtitle = hasLog
        ? 'Vào ${log!.checkIn != null ? _timeFmt.format(log!.checkIn!) : "—"}   •   Ra ${log!.checkOut != null ? _timeFmt.format(log!.checkOut!) : "—"}'
        : 'Không có dữ liệu chấm công';

    Widget trailing;
    if (hasLog) {
      final isPaidLeave = (log!.note ?? '').toLowerCase().contains('ngh') && (log!.note ?? '').toLowerCase().contains('ph');
      trailing = isPaidLeave
          ? StatusChip(label: 'Nghỉ phép', background: AppColors.cream, foreground: AppColors.brand)
          : log!.checkOut == null
              ? StatusChip(label: 'Thiếu giờ ra', background: AppColors.amberBg, foreground: AppColors.amberFg)
              : StatusChip(label: 'Đã chấm công', background: AppColors.greenBg, foreground: AppColors.greenFg);
    } else if (correctionStatus == 'PENDING') {
      trailing = StatusChip(label: 'Chờ duyệt bổ sung', background: AppColors.amberBg, foreground: AppColors.amberFg);
    } else if (correctionStatus == 'REJECTED') {
      trailing = IconButton(
        icon: const Icon(Icons.add_circle, color: AppColors.brand),
        onPressed: () => showCorrectionSheet(context, date),
      );
    } else if (correctionStatus == 'APPROVED') {
      trailing = StatusChip(label: 'Đã bổ sung', background: AppColors.greenBg, foreground: AppColors.greenFg);
    } else {
      trailing = IconButton(
        icon: const Icon(Icons.add_circle, color: AppColors.brand),
        onPressed: () => showCorrectionSheet(context, date),
      );
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
                  Text(_weekdayFmt.format(date), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 3),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
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
