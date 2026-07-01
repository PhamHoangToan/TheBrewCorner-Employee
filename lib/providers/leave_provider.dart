import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../models/leave_request.dart';
import 'auth_provider.dart';

final leaveRequestsProvider = FutureProvider<List<LeaveRequest>>((ref) async {
  final userId = ref.watch(authProvider).user?.id;
  if (userId == null) return [];
  final res = await ApiClient.instance.dio.get('/leave-requests', queryParameters: {'userId': userId});
  final items = (res.data['items'] as List).cast<Map<String, dynamic>>();
  final list = items.map(LeaveRequest.fromJson).toList();
  list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return list;
});

class LeaveRepository {
  LeaveRepository(this.ref);
  final Ref ref;

  Future<void> submit({
    required DateTime startDate,
    required DateTime endDate,
    required String type,
    required String reason,
  }) async {
    final userId = ref.read(authProvider).user!.id;
    // Normalize to UTC date-only: startDate/endDate come from showDatePicker,
    // which returns a *local* DateTime. Serializing that as-is is timezone
    // ambiguous and can land on the wrong calendar day once the backend
    // parses it (the `@db.Date` columns are UTC-midnight based).
    DateTime utcDateOnly(DateTime d) => DateTime.utc(d.year, d.month, d.day);
    await ApiClient.instance.dio.post('/leave-requests', data: {
      'userId': userId,
      'startDate': utcDateOnly(startDate).toIso8601String(),
      'endDate': utcDateOnly(endDate).toIso8601String(),
      'type': type,
      'reason': reason,
    });
  }
}

final leaveRepositoryProvider = Provider((ref) => LeaveRepository(ref));
