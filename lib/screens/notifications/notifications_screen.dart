import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../models/notification_item.dart';
import '../../providers/notifications_provider.dart';
import '../../widgets/empty_state.dart';

final _timeFmt = DateFormat('HH:mm dd/MM/yyyy');

IconData _iconFor(String type) {
  if (type.startsWith('LEAVE')) return Icons.event_note_outlined;
  if (type.startsWith('SHIFT')) return Icons.calendar_month_outlined;
  if (type.startsWith('PAYROLL')) return Icons.payments_outlined;
  if (type.startsWith('CORRECTION')) return Icons.access_time_outlined;
  return Icons.notifications_outlined;
}

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(myNotificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(notificationsRepositoryProvider).markAllRead();
              ref.invalidate(myNotificationsProvider);
              ref.invalidate(unreadCountProvider);
            },
            child: const Text('Đọc tất cả'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(myNotificationsProvider);
          ref.invalidate(unreadCountProvider);
        },
        child: notificationsAsync.when(
          data: (items) => items.isEmpty
              ? ListView(
                  padding: const EdgeInsets.all(20),
                  children: const [EmptyState(message: 'Chưa có thông báo nào', icon: Icons.notifications_none)],
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, i) => _NotificationRow(
                    item: items[i],
                    onTap: () async {
                      if (!items[i].read) {
                        await ref.read(notificationsRepositoryProvider).markRead(items[i].id);
                        ref.invalidate(myNotificationsProvider);
                        ref.invalidate(unreadCountProvider);
                      }
                    },
                  ),
                ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const Center(child: Text('Không tải được thông báo')),
        ),
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({required this.item, required this.onTap});
  final NotificationItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: item.read ? null : AppColors.cream,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(_iconFor(item.type), size: 22, color: AppColors.brand),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title,
                        style: TextStyle(
                          fontWeight: item.read ? FontWeight.w600 : FontWeight.w800,
                          fontSize: 13,
                        )),
                    const SizedBox(height: 3),
                    Text(item.body, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    const SizedBox(height: 4),
                    Text(_timeFmt.format(item.createdAt.toLocal()),
                        style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
                  ],
                ),
              ),
              if (!item.read)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 5),
                  decoration: const BoxDecoration(color: AppColors.brand, shape: BoxShape.circle),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
