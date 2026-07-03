import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../models/notification_item.dart';
import 'auth_provider.dart';

// Thông báo cá nhân của nhân viên (duyệt nghỉ phép, phân ca, lương...) — polling, không dùng socket
final myNotificationsProvider = FutureProvider<List<NotificationItem>>((ref) async {
  final userId = ref.watch(authProvider).user?.id;
  if (userId == null) return [];
  final res = await ApiClient.instance.dio.get('/notifications', queryParameters: {
    'userId': userId,
    'limit': '50',
  });
  final items = (res.data['items'] as List).cast<Map<String, dynamic>>();
  return items.map(NotificationItem.fromJson).toList();
});

final unreadCountProvider = FutureProvider<int>((ref) async {
  final userId = ref.watch(authProvider).user?.id;
  if (userId == null) return 0;
  final res = await ApiClient.instance.dio.get('/notifications/unread-count', queryParameters: {
    'userId': userId,
  });
  return (res.data['count'] as num?)?.toInt() ?? 0;
});

class NotificationsRepository {
  NotificationsRepository(this._ref);
  final Ref _ref;

  Future<void> markAllRead() async {
    final userId = _ref.read(authProvider).user?.id;
    if (userId == null) return;
    await ApiClient.instance.dio.patch('/notifications/read-all', queryParameters: {'userId': userId});
  }

  Future<void> markRead(String id) async {
    await ApiClient.instance.dio.patch('/notifications/$id/read');
  }
}

final notificationsRepositoryProvider = Provider((ref) => NotificationsRepository(ref));
