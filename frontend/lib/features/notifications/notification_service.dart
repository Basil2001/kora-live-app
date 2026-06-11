import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../core/network/api_client.dart';

class NotificationService {
  final ApiClient _apiClient;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isFirebaseInitialized = false;

  NotificationService(this._apiClient);

  Future<void> init() async {
    // 1. Initialize local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    try {
      await _localNotificationsPlugin.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse details) {
          debugPrint('Notification clicked: ${details.payload}');
        },
      );
    } catch (e) {
      debugPrint('Failed to initialize local notifications: $e');
    }

    // 2. Initialize Firebase Messaging (wrapped in try-catch so it won't crash if configuration is missing)
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      _isFirebaseInitialized = true;
      debugPrint('Firebase initialized successfully for notifications');
    } catch (e) {
      debugPrint('Firebase not configured or initialization failed: $e');
      debugPrint('Falling back to local-only/in-app notification center');
    }

    if (_isFirebaseInitialized) {
      _setupFirebaseListeners();
    }
  }

  void _setupFirebaseListeners() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Received foreground notification: ${message.notification?.title}');
      _showLocalNotification(message);
    });

    // Handle background click redirection
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Notification clicked opened app: ${message.data}');
    });
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'kora_channels',
      'Kora Live Notifications',
      channelDescription: 'Match alerts, goals, news and system updates',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _localNotificationsPlugin.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: platformChannelSpecifics,
      payload: jsonEncode(message.data),
    );
  }

  Future<void> requestPermissionAndRegisterToken() async {
    if (!_isFirebaseInitialized) {
      debugPrint('Firebase not initialized. Cannot register FCM token.');
      return;
    }

    try {
      final messaging = FirebaseMessaging.instance;
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted notification permission');
        
        // Get token
        String? token = await messaging.getToken();
        if (token != null) {
          await registerTokenWithBackend(token);
        }

        // Listen to token refreshes
        messaging.onTokenRefresh.listen((newToken) {
          registerTokenWithBackend(newToken);
        });
      } else {
        debugPrint('User declined notification permission');
      }
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
    }
  }

  Future<void> registerTokenWithBackend(String token) async {
    try {
      final response = await _apiClient.post('/notifications/tokens', data: {
        'token': token,
        'platform': defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
      });
      if (response.statusCode == 200) {
        debugPrint('FCM Token registered with backend successfully');
      }
    } catch (e) {
      debugPrint('Failed to register token with backend: $e');
    }
  }
}
