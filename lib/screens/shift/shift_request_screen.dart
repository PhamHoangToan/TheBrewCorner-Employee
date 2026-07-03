import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../models/shift_change_request.dart';
import '../../providers/shift_request_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_chip.dart';

final _dateFmt = DateFormat('dd/MM/yyyy');

class ShiftRequestScreen extends ConsumerStatefulWidget {
  const ShiftRequestScreen({super.key});

  @override
  ConsumerState<ShiftRequestScreen> createState() => _ShiftRequestScreenState();
}

class _ShiftRequestScreenState extends ConsumerState<ShiftRequestScreen> {
  String? _shiftId;
  DateTime? _workDate;
  final _reasonCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _workDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (picked != null) setState(() => _workDate = picked);
  }

  Future<void> _submit() async {
    if (_shiftId == null || _workDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn ca và ngày làm')));
      return;
    }
    if (_reasonCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập lý do / ghi chú')));
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref.read(shiftRequestRepositoryProvider).submitRegister(
            shiftId: _shiftId!,
            workDate: _workDate!,
            reason: _reasonCtrl.text.trim(),
          );
      ref.invalidate(myShiftRequestsProvider);
      if (mounted) {
        setState(() {
          _shiftId = null;
          _workDate = null;
          _reasonCtrl.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã gửi yêu cầu đăng ký ca')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gửi thất bại — có thể bạn đã có ca này hoặc đã gửi yêu cầu rồi')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shiftsAsync = ref.watch(shiftOptionsProvider);
    final requestsAsync = ref.watch(myShiftRequestsProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Đăng ký ca'),
          bottom: const TabBar(tabs: [Tab(text: 'Đăng ký ca mới'), Tab(text: 'Yêu cầu của tôi')]),
        ),
        body: TabBarView(
          children: [
            // ── Tab 1: form đăng ký ca ──
            ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Ca muốn đăng ký',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.textMuted)),
                        const SizedBox(height: 8),
                        shiftsAsync.when(
                          data: (shifts) => DropdownButtonFormField<String>(
                            initialValue: _shiftId,
                            hint: const Text('Chọn ca làm việc'),
                            items: shifts
                                .map((s) => DropdownMenuItem(value: s.id, child: Text(s.label)))
                                .toList(),
                            onChanged: (v) => setState(() => _shiftId = v),
                          ),
                          loading: () => const LinearProgressIndicator(),
                          error: (_, _) => const Text('Không tải được danh sách ca'),
                        ),
                        const SizedBox(height: 18),
                        const Text('Ngày làm',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.textMuted)),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _pickDate,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              color: AppColors.pageBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text(
                              _workDate != null ? _dateFmt.format(_workDate!) : '--/--/----',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text('Lý do / ghi chú',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.textMuted)),
                        const SizedBox(height: 8),
                        TextField(controller: _reasonCtrl, maxLines: 3),
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _submitting ? null : _submit,
                            child: _submitting
                                ? const SizedBox(
                                    width: 20, height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('Gửi yêu cầu'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // ── Tab 2: lịch sử yêu cầu ──
            RefreshIndicator(
              onRefresh: () async => ref.invalidate(myShiftRequestsProvider),
              child: requestsAsync.when(
                data: (requests) => requests.isEmpty
                    ? ListView(
                        padding: const EdgeInsets.all(20),
                        children: const [EmptyState(message: 'Chưa có yêu cầu nào', icon: Icons.swap_horiz_outlined)],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: requests.length,
                        itemBuilder: (context, i) => _RequestRow(request: requests[i]),
                      ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => const Center(child: Text('Không tải được danh sách yêu cầu')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestRow extends StatelessWidget {
  const _RequestRow({required this.request});
  final ShiftChangeRequest request;

  StatusChip get _statusChip {
    switch (request.status) {
      case 'APPROVED':
        return const StatusChip(label: 'Đã duyệt', background: AppColors.greenBg, foreground: AppColors.greenFg);
      case 'REJECTED':
        return const StatusChip(label: 'Từ chối', background: AppColors.redBg, foreground: AppColors.redFg);
      default:
        return const StatusChip(label: 'Chờ duyệt', background: AppColors.cream, foreground: AppColors.brand);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${request.type == 'SWAP' ? 'Nhượng ca' : 'Đăng ký ca'} · ${_dateFmt.format(request.workDate)}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
                _statusChip,
              ],
            ),
            const SizedBox(height: 3),
            Text(
              '${request.shiftName.isNotEmpty ? request.shiftName : 'Ca làm việc'} · ${request.startTime}–${request.endTime}',
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
            if (request.reason.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text('Lý do: ${request.reason}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ],
            if (request.status == 'REJECTED' && (request.rejectReason ?? '').isNotEmpty) ...[
              const SizedBox(height: 3),
              Text('Từ chối: ${request.rejectReason}', style: const TextStyle(fontSize: 11, color: AppColors.redFg)),
            ],
          ],
        ),
      ),
    );
  }
}
