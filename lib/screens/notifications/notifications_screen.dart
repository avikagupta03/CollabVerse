import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/notification_service.dart';
import '../../widgets/empty_state.dart';

class NotificationsScreen extends StatefulWidget {
  final String userId;

  const NotificationsScreen({super.key, required this.userId});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late NotificationService _notificationService;
  bool _showUnreadOnly = false;

  @override
  void initState() {
    super.initState();
    _notificationService = NotificationService();
  }

  Future<void> _markAsRead(String notificationId) async {
    await _notificationService.markAsRead(widget.userId, notificationId);
  }

  Future<void> _deleteNotification(String notificationId) async {
    await _notificationService.deleteNotification(
      widget.userId,
      notificationId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        elevation: 0,
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Text('Mark all as read'),
                onTap: () => _notificationService.markAllAsRead(widget.userId),
              ),
              PopupMenuItem(
                child: Row(
                  children: [
                    Checkbox(
                      value: _showUnreadOnly,
                      onChanged: (value) {
                        setState(() => _showUnreadOnly = value ?? false);
                      },
                    ),
                    const SizedBox(width: 8),
                    const Text('Unread only'),
                  ],
                ),
                onTap: () => setState(() => _showUnreadOnly = !_showUnreadOnly),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _showUnreadOnly
            ? _notificationService.getUnreadNotifications(widget.userId)
            : _notificationService.getAllNotifications(widget.userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return EmptyState(
              icon: Icons.notifications_none,
              title: 'No notifications',
              description: _showUnreadOnly
                  ? 'All caught up!'
                  : 'You don\'t have any notifications yet',
            );
          }

          final notifications = snapshot.data!.docs;

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notifData =
                  notifications[index].data() as Map<String, dynamic>;
              final isRead = notifData['is_read'] ?? false;
              final notificationId = notifications[index].id;

              return Dismissible(
                key: Key(notificationId),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: Colors.red,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) => _deleteNotification(notificationId),
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isRead ? Colors.white : Colors.blue[50],
                    border: Border(
                      left: BorderSide(
                        color: isRead ? Colors.transparent : Colors.blue,
                        width: 4,
                      ),
                    ),
                  ),
                  child: ListTile(
                    title: Text(
                      notifData['title'] ?? 'Notification',
                      style: TextStyle(
                        fontWeight: isRead
                            ? FontWeight.normal
                            : FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(notifData['message'] ?? ''),
                    trailing: !isRead
                        ? Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                          )
                        : null,
                    onTap: () {
                      if (!isRead) {
                        _markAsRead(notificationId);
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
