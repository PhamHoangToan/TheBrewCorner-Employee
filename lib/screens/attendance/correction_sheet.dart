import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../providers/attendance_provider.dart';

final _dateFmt = DateFormat('dd/MM/yyyy');

Future<void> showCorrectionSheet(BuildContext context, DateTime workDate) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (_) => _CorrectionSheet(workDate: workDate),
  );
}

class _CorrectionSheet extends ConsumerStatefulWidget {
  const _CorrectionSheet({required this.workDate});
  final DateTime workDate;

  @override
  ConsumerState<_CorrectionSheet> createState() => _CorrectionSheetState();
}

class _CorrectionSheetState extends ConsumerState<_CorrectionSheet> {
  TimeOfDay? _checkIn;
  TimeOfDay? _checkOut;
  final _reasonCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime(bool isCheckIn) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: (isCheckIn ? _checkIn : _checkOut) ?? const TimeOfDay(hour: 8, minute: 0),
    );
    if (picked != null) {
      setState(() => isCheckIn ? _checkIn = picked : _checkOut = picked);
    }
  }

  // Always build UTC instants: `workDate` maps to a MySQL `@db.Date` column
  // on the backend, which is sensitive to timezone-ambiguous serialization —
  // a local (non-UTC) DateTime.toIso8601String() can land on the wrong
  // calendar day once parsed server-side.
  DateTime? _combine(TimeOfDay? t) {
    if (t == null) return null;
    return DateTime.utc(widget.workDate.year, widget.workDate.month, widget.workDate.day, t.hour, t.minute);
  }

  Future<void> _submit() async {
    if (_reasonCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập lý do')));
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref.read(attendanceRepositoryProvider).submitCorrection(
            workDate: widget.workDate,
            checkIn: _combine(_checkIn),
            checkOut: _combine(_checkOut),
            reason: _reasonCtrl.text.trim(),
          );
      final key = (year: widget.workDate.year, month: widget.workDate.month);
      ref.invalidate(attendanceCorrectionsProvider(key));
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã gửi yêu cầu bổ sung chấm công')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gửi yêu cầu thất bại')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36, height: 5,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(3)),
            ),
          ),
          const SizedBox(height: 18),
          Text('Bổ sung chấm công', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(_dateFmt.format(widget.workDate), style: const TextStyle(color: AppColors.textMuted)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _TimeField(label: 'Giờ vào', value: _checkIn, onTap: () => _pickTime(true)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _TimeField(label: 'Giờ ra', value: _checkOut, onTap: () => _pickTime(false)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text('Lý do', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 6),
          TextField(controller: _reasonCtrl, maxLines: 3),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Gửi yêu cầu'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({required this.label, required this.value, required this.onTap});
  final String label;
  final TimeOfDay? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.textMuted)),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.pageBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              value != null ? value!.format(context) : '--:--',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}
