import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../utils/constants.dart';

class AppNotification {
  final String id;
  final String userId;   // recipient
  final String title;
  final String body;
  final String type;     
  final String emoji;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic> payload; 

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.emoji,
    required this.isRead,
    required this.createdAt,
    this.payload = const {},
  });

  factory AppNotification.fromMap(Map<String, dynamic> map, String id) {
    return AppNotification(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      type: map['type'] ?? 'system',
      emoji: map['emoji'] ?? '🔔',
      isRead: map['isRead'] ?? false,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      payload: Map<String, dynamic>.from(map['payload'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'title': title,
        'body': body,
        'type': type,
        'emoji': emoji,
        'isRead': isRead,
        'createdAt': FieldValue.serverTimestamp(),
        'payload': payload,
      };
}


class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _local.initialize(
      const InitializationSettings(
          android: androidSettings, iOS: iosSettings),
    );

    // Request Android 13+ permission
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }


  Stream<List<AppNotification>> listenToNotifications(String userId,
      {bool showBanners = false}) {
    return _db
        .collection(AppConstants.notificationsCol)
        .doc(userId)
        .collection('items')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) {
      final notifications = snap.docs
          .map((d) => AppNotification.fromMap(d.data(), d.id))
          .toList();

      if (showBanners) {
        for (final change in snap.docChanges) {
          if (change.type == DocumentChangeType.added) {
            final notif =
                AppNotification.fromMap(change.doc.data()!, change.doc.id);
            if (!notif.isRead) {
              _showLocalNotification(notif);
            }
          }
        }
      }

      return notifications;
    });
  }


  Future<void> sendNotification({
    required String toUserId,
    required String title,
    required String body,
    required String type,
    required String emoji,
    Map<String, dynamic> payload = const {},
  }) async {
    final notif = AppNotification(
      id: '',
      userId: toUserId,
      title: title,
      body: body,
      type: type,
      emoji: emoji,
      isRead: false,
      createdAt: DateTime.now(),
      payload: payload,
    );

    await _db
        .collection(AppConstants.notificationsCol)
        .doc(toUserId)
        .collection('items')
        .add(notif.toMap());
  }

  Future<void> notifyNewOrder({
    required String farmerId,
    required String buyerName,
    required String productName,
    required int quantity,
    required String unit,
    required String orderId,
  }) =>
      sendNotification(
        toUserId: farmerId,
        title: 'New Order Received! 📦',
        body:
            '$buyerName placed an order for $productName ($quantity $unit). Tap to review.',
        type: 'order',
        emoji: '📦',
        payload: {'orderId': orderId},
      );

  Future<void> notifyOrderStatusChange({
    required String buyerId,
    required String status,
    required String productName,
    required String orderId,
  }) {
    final (emoji, title, body) = switch (status) {
      'Accepted' => (
          '✅',
          'Order Accepted!',
          'Your order for $productName has been accepted by the farmer.'
        ),
      'Rejected' => (
          '❌',
          'Order Rejected',
          'Your order for $productName was rejected. Try another seller.'
        ),
      'Delivered' => (
          '🚚',
          'Order Delivered!',
          'Your order for $productName has been marked as delivered.'
        ),
      _ => ('🔔', 'Order Update', 'Your order for $productName was updated to $status.'),
    };

    return sendNotification(
      toUserId: buyerId,
      title: title,
      body: body,
      type: 'order',
      emoji: emoji,
      payload: {'orderId': orderId},
    );
  }

  Future<void> markAsRead(String userId, String notificationId) async {
    await _db
        .collection(AppConstants.notificationsCol)
        .doc(userId)
        .collection('items')
        .doc(notificationId)
        .update({'isRead': true});
  }

  Future<void> markAllAsRead(String userId) async {
    final batch = _db.batch();
    final snap = await _db
        .collection(AppConstants.notificationsCol)
        .doc(userId)
        .collection('items')
        .where('isRead', isEqualTo: false)
        .get();

    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Stream<int> unreadCount(String userId) {
    return _db
        .collection(AppConstants.notificationsCol)
        .doc(userId)
        .collection('items')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  Future<void> _showLocalNotification(AppNotification notif) async {
    if (!_initialized) return;

    const androidDetails = AndroidNotificationDetails(
      'kisan_dost_channel',
      'Kisan Dost Notifications',
      channelDescription: 'Order and activity notifications',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _local.show(
      notif.id.hashCode,
      '${notif.emoji} ${notif.title}',
      notif.body,
      const NotificationDetails(
          android: androidDetails, iOS: iosDetails),
    );
  }
}
