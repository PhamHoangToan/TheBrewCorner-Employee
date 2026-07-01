import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../models/payroll.dart';
import 'auth_provider.dart';

final payrollListProvider = FutureProvider<List<Payroll>>((ref) async {
  final userId = ref.watch(authProvider).user?.id;
  if (userId == null) return [];
  final res = await ApiClient.instance.dio.get('/payroll/user/$userId');
  final data = res.data;
  final items = (data is Map ? data['items'] as List? : data as List?) ?? [];
  final list = items.cast<Map<String, dynamic>>().map(Payroll.fromJson).toList();
  list.sort((a, b) {
    final ay = a.periodYear * 12 + a.periodMonth;
    final by = b.periodYear * 12 + b.periodMonth;
    return by.compareTo(ay);
  });
  return list;
});

typedef PayrollPeriod = ({int year, int month});

final payrollDetailProvider = FutureProvider.family<Payroll?, PayrollPeriod>((ref, period) async {
  final userId = ref.watch(authProvider).user?.id;
  if (userId == null) return null;
  final res = await ApiClient.instance.dio.get('/payroll/user/$userId/${period.year}/${period.month}');
  if (res.data == null) return null;
  return Payroll.fromJson(res.data as Map<String, dynamic>);
});
