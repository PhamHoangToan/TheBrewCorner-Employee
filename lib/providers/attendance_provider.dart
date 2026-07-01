import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../models/attendance_log.dart';
import 'auth_provider.dart';

typedef MonthKey = ({int year, int month});

final attendanceMonthProvider = FutureProvider.family<List<AttendanceLog>, MonthKey>((ref, key) async {
  final userId = ref.watch(authProvider).user?.id;
  if (userId == null) return [];
  final res = await ApiClient.instance.dio.get('/attendance', queryParameters: {
    'userId': userId,
    'year': key.year.toString(),
    'month': key.month.toString(),
    'limit': '100',
  });
  final items = (res.data['items'] as List).cast<Map<String, dynamic>>();
  return items.map(AttendanceLog.fromJson).toList();
});

final attendanceCorrectionsProvider = FutureProvider.family<List<AttendanceCorrectionRequest>, MonthKey>((ref, key) async {
  final userId = ref.watch(authProvider).user?.id;
  if (userId == null) return [];
  final res = await ApiClient.instance.dio.get('/attendance/corrections', queryParameters: {
    'userId': userId,
    'limit': '200',
  });
  final items = (res.data['items'] as List).cast<Map<String, dynamic>>();
  return items
      .map(AttendanceCorrectionRequest.fromJson)
      .where((c) => c.workDate.year == key.year && c.workDate.month == key.month)
      .toList();
});

class AttendanceRepository {
  AttendanceRepository(this.ref);
  final Ref ref;

  Future<void> submitCorrection({
    required DateTime workDate,
    DateTime? checkIn,
    DateTime? checkOut,
    required String reason,
  }) async {
    final userId = ref.read(authProvider).user!.id;
    // workDate maps to a `@db.Date` column on the backend (UTC-midnight
    // based) — always send it (and the check-in/out instants derived from
    // it) as UTC to avoid landing on the wrong calendar day.
    final utcWorkDate = DateTime.utc(workDate.year, workDate.month, workDate.day);
    await ApiClient.instance.dio.post('/attendance/corrections', data: {
      'userId': userId,
      'workDate': utcWorkDate.toIso8601String(),
      if (checkIn != null) 'checkIn': checkIn.toUtc().toIso8601String(),
      if (checkOut != null) 'checkOut': checkOut.toUtc().toIso8601String(),
      'reason': reason,
    });
  }
}

final attendanceRepositoryProvider = Provider((ref) => AttendanceRepository(ref));
