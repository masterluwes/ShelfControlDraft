import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:shelf_control/services/firestore_service.dart';
import 'package:shelf_control/models/app_notification_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shelf_control/models/pantry_item_model.dart';
import 'dart:convert';
import 'dart:io' show Platform;

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  late FirestoreService _firestoreService;
  late FirebaseAuth _auth;

  NotificationService() {
    _firestoreService = FirestoreService();
    _auth = FirebaseAuth.instance;
  }

  Future<void> initialize() async {

    // MUST BE DONE BEFORE SCHEDULING ANYTHING (especially for iOS)
    // Make sure you also added this in main.dart BEFORE calling NotificationService.initialize()
    // tz.initializeTimeZones();

    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      sound: true,
      badge: true,
    );

    print("🔔 Notification permission: ${settings.authorizationStatus}");

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        if (response.payload != null) {
          final payload = jsonDecode(response.payload!);
          if (payload['action'] == 'consume_prompt' &&
              payload['itemId'] != null) {
            await _handleConsumeAction(payload['itemId']);
          }
        }
      },
    );

    // iOS APNS token fetch
    if (Platform.isIOS &&
        settings.authorizationStatus == AuthorizationStatus.authorized) {
      print("📱 Waiting for APNS token...");
      String? apnsToken;
      for (int retries = 0; retries < 10 && apnsToken == null; retries++) {
        apnsToken = await _firebaseMessaging.getAPNSToken();
        await Future.delayed(const Duration(seconds: 1));
      }
      print("📱 APNS Token: $apnsToken");
    }

    final fcmToken = await _firebaseMessaging.getToken();
    print("🔥 FCM Token: $fcmToken");

    if (fcmToken != null) {
      await _saveTokenToFirestore(fcmToken);
    }

    _firebaseMessaging.onTokenRefresh.listen(_saveTokenToFirestore);
    FirebaseMessaging.onMessage.listen(_showLocalNotification);
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    print('[_showLocalNotification] Message received');

    const androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'Important alerts.',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );

    const iosDetails = DarwinNotificationDetails();

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    String? body = message.notification?.body;

    if (message.data['action'] == 'view_pantry_alerts') {
      body = 'You have items expiring soon. Check your pantry!';
    }

    await _flutterLocalNotificationsPlugin.show(
      0,
      message.notification?.title,
      body,
      platformDetails,
      payload: message.data['payload'],
    );
  }

  Future<void> scheduleWeeklyPantryReviewNotification({
    required TimeOfDay notificationTime,
    required int weekday,
    required String userId,
    required String householdId,
  }) async {
    await _flutterLocalNotificationsPlugin.cancel(1);

    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      notificationTime.hour,
      notificationTime.minute,
    );

    while (scheduledDate.weekday != weekday) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }

    const androidDetails = AndroidNotificationDetails(
      'weekly_pantry_channel',
      'Weekly Pantry Reminders',
      channelDescription: 'Weekly pantry check reminder.',
      importance: Importance.low,
      priority: Priority.low,
    );

    const iosDetails = DarwinNotificationDetails();

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      1,
      'Weekly Pantry Review',
      'Time to check your pantry for expiring items!',
      scheduledDate,
      platformDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: '{"type": "weekly_review", "householdId": "$householdId"}',
    );
  }

  Future<void> _saveTokenToFirestore(String token) async {
    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      await _firestoreService.updateUserFCMToken(userId, token);
    }
  }

  Future<void> _handleConsumeAction(String itemId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final itemDoc =
        await _firestoreService.db.collection('pantryItems').doc(itemId).get();

    if (!itemDoc.exists) return;

    final item = PantryItemModel.fromFirestore(itemDoc);

    await _firestoreService.recordConsumedItem(item, 1);
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }

  final firestoreService = FirestoreService();

  FlutterLocalNotificationsPlugin local = FlutterLocalNotificationsPlugin();

  const androidDetails = AndroidNotificationDetails(
    'high_importance_channel',
    'High Importance Notifications',
    channelDescription: 'Important alerts.',
    importance: Importance.max,
    priority: Priority.high,
  );

  const iosDetails = DarwinNotificationDetails();

  const NotificationDetails platformDetails = NotificationDetails(
    android: androidDetails,
    iOS: iosDetails,
  );

  await local.show(
    0,
    message.notification?.title,
    message.notification?.body,
    platformDetails,
  );
}
