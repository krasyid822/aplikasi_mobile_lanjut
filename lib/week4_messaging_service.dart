import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background handler must initialize Firebase if used
  await Firebase.initializeApp();
  // In many cases Android/iOS will show the notification automatically
}

class MessagingService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static final AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'paml_channel',
    'PAML Notifications',
    description: 'Notifikasi penting aplikasi PAML',
    importance: Importance.high,
  );

  /// Initialize messaging: permissions, local notifications, listeners
  static Future<void> init() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Init local notifications
    final initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/launcher_icon'),
      iOS: DarwinInitializationSettings(),
      macOS: DarwinInitializationSettings(),
    );
    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        // handle notification tap if needed: response.payload or response.notificationResponse
      },
    );

    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_channel);
    }

    // Request permission (iOS / Android 13+)
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    // Foreground messages -> show local notification
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification == null) return;
      final android = notification.android;

      _localNotifications.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: android?.smallIcon,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    });

    // Handle when a user taps a notification (app in background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // You can use message.data to navigate to specific screen
    });

    // Optionally handle initial message when app launched from terminated state
    await _messaging.getInitialMessage();

    // Keep tokens up to date: when token refreshes, store it for the signed-in user
    _messaging.onTokenRefresh.listen((newToken) async {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null && newToken.isNotEmpty) {
        final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);
        await userDoc.set({
          'fcmTokens': FieldValue.arrayUnion([newToken]),
        }, SetOptions(merge: true));
      }
    });
  }

  static Future<void> saveTokenToFirestore(String uid) async {
    final token = await _messaging.getToken();
    if (token == null) return;
    final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);
    await userDoc.set({
      'fcmTokens': FieldValue.arrayUnion([token]),
    }, SetOptions(merge: true));
  }

  static Future<void> removeToken(String uid) async {
    final token = await _messaging.getToken();
    if (token == null) return;
    final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);
    try {
      await userDoc.update({
        'fcmTokens': FieldValue.arrayRemove([token]),
      });
    } catch (e) {
      // If the document doesn't exist or update fails, try a merge set instead
      try {
        await userDoc.set({
          'fcmTokens': FieldValue.arrayRemove([token]),
        }, SetOptions(merge: true));
      } catch (_) {
        // Ignore failures here to avoid blocking logout
      }
    }
  }

  static Future<void> subscribeToCampaignsTopic() async {
    await _messaging.subscribeToTopic('campaigns');
  }

  static Future<void> unsubscribeFromCampaignsTopic() async {
    await _messaging.unsubscribeFromTopic('campaigns');
  }

  /// Show a local notification from other services (e.g. Supabase realtime)
  static Future<void> showLocalNotification({
    required String title,
    required String body,
  }) async {
    _localNotifications.show(
      id: title.hashCode,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}
