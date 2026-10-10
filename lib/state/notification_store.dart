import 'package:flutter/foundation.dart';

class AppNotification {
  final String title;
  final String message;
  final DateTime timestamp;
  bool read;

  AppNotification(this.title, this.message, {DateTime? timestamp})
    : timestamp = timestamp ?? DateTime.now(),
      read = false;
}

class NotificationStore extends ChangeNotifier {
  final List<AppNotification> _notifications = [];

  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => !n.read).length;

  void push(String title, String message) {
    _notifications.insert(0, AppNotification(title, message));
    notifyListeners();
  }

  void markAllRead() {
    for (final n in _notifications) {
      n.read = true;
    }
    notifyListeners();
  }

  void clear() {
    _notifications.clear();
    notifyListeners();
  }
}
