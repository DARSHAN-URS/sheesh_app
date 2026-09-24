import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 1. Initialize Firebase Core safely
      await Firebase.initializeApp();

      // 2. Initialize local notifications for foreground popups
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings();
      const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);

      await _localNotifications.initialize(initSettings);

      // 3. Request permissions on Android 13+ and iOS
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // 4. Retrieve FCM token
        final token = await messaging.getToken();
        if (token != null) {
          _registerTokenWithBackend(token);
        }

        // Listen for token refresh
        messaging.onTokenRefresh.listen((newToken) {
          _registerTokenWithBackend(newToken);
        });

        // 5. Foreground notification handler
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          _showLocalNotification(message);
        });
      }

      _isInitialized = true;
      if (kDebugMode) {
        debugPrint('🔔 [NotificationService] Initialized successfully');
      }
    } catch (e) {
      // Graceful fallback if Firebase google-services.json has not been placed yet
      if (kDebugMode) {
        debugPrint('ℹ️ [NotificationService] Running without active Firebase credentials: $e');
      }
    }
  }

  Future<void> _registerTokenWithBackend(String token) async {
    try {
      await apiService.post('/auth/device-token', data: {
        'token': token,
        'platform': Platform.isAndroid ? 'android' : (Platform.isIOS ? 'ios' : 'web'),
      });
      if (kDebugMode) {
        debugPrint('🔔 [NotificationService] Registered FCM device token with backend');
      }
    } catch (_) {
      // User might not be logged in yet — token can be registered later after auth
    }
  }

  void _showLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'sheesh_orders_channel',
      'Sheesh Order Updates',
      channelDescription: 'Notifications for hyper-local artisan order updates and status changes',
      importance: Importance.max,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
    );
  }
}

final notificationService = NotificationService();
