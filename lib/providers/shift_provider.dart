import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../models/shift_assignment.dart';
import 'auth_provider.dart';
import 'attendance_provider.dart' show MonthKey;

final shiftAssignmentsProvider = FutureProvider.family<List<ShiftAssignment>, MonthKey>((ref, key) async {
  final userId = ref.watch(authProvider).user?.id;
  if (userId == null) return [];
  final res = await ApiClient.instance.dio.get('/shifts/assignments', queryParameters: {
    'userId': userId,
    'year': key.year.toString(),
    'month': key.month.toString(),
    'limit': '100',
  });
  final items = (res.data['items'] as List).cast<Map<String, dynamic>>();
  final list = items.map(ShiftAssignment.fromJson).toList();
  list.sort((a, b) => a.workDate.compareTo(b.workDate));
  return list;
});
