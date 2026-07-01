import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../providers/leave_provider.dart';

final _dateFmt = DateFormat('dd/MM/yyyy');

const _leaveTypes = {
  'ANNUAL': 'Phép năm',
  'SICK': 'Ốm',
  'UNPAID': 'Không lương',
};

class LeaveFormTab extends ConsumerStatefulWidget {
  const LeaveFormTab({super.key});

  @override
  ConsumerState<LeaveFormTab> createState() => _LeaveFormTabState();
}

class _LeaveFormTabState extends ConsumerState<LeaveFormTab> {
  DateTime? _startDate;
  DateTime? _endDate;
  String _type = 'ANNUAL';
  final _reasonCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _startDate : _endDate) ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(picked)) _endDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn khoảng ngày nghỉ')));
      return;
    }
    if (_reasonCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập lý do')));
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref.read(leaveRepositoryProvider).submit(
            startDate: _startDate!,
            endDate: _endDate!,
            type: _type,
            reason: _reasonCtrl.text.trim(),
          );
      ref.invalidate(leaveRequestsProvider);
      if (mounted) {
        setState(() {
          _startDate = null;
          _endDate = null;
          _type = 'ANNUAL';
          _reasonCtrl.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã gửi đơn nghỉ phép')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gửi đơn thất bại')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Khoảng ngày nghỉ', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.textMuted)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _dateField('Từ ngày', _startDate, () => _pickDate(true))),
                    const SizedBox(width: 14),
                    Expanded(child: _dateField('Đến ngày', _endDate, () => _pickDate(false))),
                  ],
                ),
                const SizedBox(height: 18),
                const Text('Loại nghỉ', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.textMuted)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _type,
                  items: _leaveTypes.entries
                      .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                      .toList(),
                  onChanged: (v) => setState(() => _type = v ?? 'ANNUAL'),
                ),
                const SizedBox(height: 18),
                const Text('Lý do', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.textMuted)),
                const SizedBox(height: 8),
                TextField(controller: _reasonCtrl, maxLines: 3),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Gửi đơn'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _dateField(String label, DateTime? value, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
        const SizedBox(height: 4),
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
              value != null ? _dateFmt.format(value) : '--/--/----',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
            ),
          ),
        ),
      ],
    );
  }
}
