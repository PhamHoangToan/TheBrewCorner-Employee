import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../models/shift_change_request.dart';
import 'auth_provider.dart';

// Danh sách ca đang hoạt động để nhân viên chọn khi đăng ký
final shiftOptionsProvider = FutureProvider<List<ShiftOption>>((ref) async {
  final res = await ApiClient.instance.dio.get('/shifts', queryParameters: {'limit': '50'});
  final items = (res.data['items'] as List).cast<Map<String, dynamic>>();
  return items.map(ShiftOption.fromJson).toList();
});

final myShiftRequestsProvider = FutureProvider<List<ShiftChangeRequest>>((ref) async {
  final userId = ref.watch(authProvider).user?.id;
  if (userId == null) return [];
  final res = await ApiClient.instance.dio.get('/shifts/requests', queryParameters: {
    'userId': userId,
    'limit': '50',
  });
  final items = (res.data['items'] as List).cast<Map<String, dynamic>>();
  return items.map(ShiftChangeRequest.fromJson).toList();
});

class ShiftRequestRepository {
  ShiftRequestRepository(this._ref);
  final Ref _ref;

  String? get _userId => _ref.read(authProvider).user?.id;

  Future<void> submitRegister({required String shiftId, required DateTime workDate, required String reason}) async {
    await ApiClient.instance.dio.post('/shifts/requests', data: {
      'userId': _userId,
      'type': 'REGISTER',
      'shiftId': shiftId,
      'workDate': workDate.toIso8601String(),
      'reason': reason,
    });
  }

  Future<void> submitSwap({required String assignmentId, required DateTime workDate, required String reason}) async {
    await ApiClient.instance.dio.post('/shifts/requests', data: {
      'userId': _userId,
      'type': 'SWAP',
      'targetAssignmentId': assignmentId,
      'workDate': workDate.toIso8601String(),
      'reason': reason,
    });
  }
}

final shiftRequestRepositoryProvider = Provider((ref) => ShiftRequestRepository(ref));
