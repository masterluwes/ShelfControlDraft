import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz; // Import timezone
import 'package:shelf_control/services/firestore_service.dart'; // Import FirestoreService
import 'package:shelf_control/models/app_notification_model.dart'; // Import AppNotificationModel
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth
import 'package:firebase_core/firebase_core.dart'; // Import FirebaseCore for background handler
import 'package:intl/intl.dart'; // Import DateFormat
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Timestamp
import 'package:shelf_control/models/pantry_item_model.dart'; // Import PantryItemModel
import 'dart:convert'; // Import for jsonDecode

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  late FirestoreService _firestoreService;
  late FirebaseAuth _auth;

  NotificationService() {
    _firestoreService = FirestoreService(); // Initialize FirestoreService
    _auth = FirebaseAuth.instance; // Initialize FirebaseAuth
  }

  Future<void> initialize() async {
    // Request permission for iOS and web
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('User granted permission: ${settings.authorizationStatus}');

    // Initialize flutter_local_notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // Handle notification tap
        print('Notification tapped: ${response.payload}');
        if (response.payload != null) {
          final Map<String, dynamic> payload = jsonDecode(response.payload!);
          if (payload['action'] == 'consume_prompt' && payload['itemId'] != null) {
            await _handleConsumeAction(payload['itemId']);
          }
        }
      },
    );

    // Get the device token and save it to Firestore
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      print('FCM Token: $token');
      await _saveTokenToFirestore(token);
    }

    // Listen for token refreshes
    _firebaseMessaging.onTokenRefresh.listen(_saveTokenToFirestore).onError((err) {
      print('Error refreshing FCM token: $err');
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
        _showLocalNotification(message);
      }
    });

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    print('[_showLocalNotification] Received foreground message:');
    print('[_showLocalNotification] Message data: ${message.data}');
    print('[_showLocalNotification] Message notification body: ${message.notification?.body}');

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      channelDescription: 'This channel is used for important notifications.', // description
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    String? notificationBody = message.notification?.body;
    if (message.data['action'] == 'view_pantry_alerts') {
      // Override with a generalized message for push notifications
      notificationBody = 'You have items expiring soon. Check your pantry!';
      print('[_showLocalNotification] Overriding notification body for pantry_summary: $notificationBody');
    }

    await _flutterLocalNotificationsPlugin.show(
      0,
      message.notification?.title,
      notificationBody, // Use the generalized body
      platformChannelSpecifics,
      payload: message.data['payload'],
    );
    print('[_showLocalNotification] Local notification shown with title: ${message.notification?.title}, body: $notificationBody, payload: ${message.data['payload']}');
  }

  // Schedule a weekly recurring pantry review notification
  Future<void> scheduleWeeklyPantryReviewNotification({
    required TimeOfDay notificationTime,
    required int weekday, // 1 for Monday, 7 for Sunday
    required String userId,
    required String householdId,
  }) async {
    await _flutterLocalNotificationsPlugin.cancel(1); // Cancel any existing weekly notification

    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      notificationTime.hour,
      notificationTime.minute,
    );

    // Adjust to the correct weekday
    while (scheduledDate.weekday != weekday) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // If the scheduled time has already passed for this week, schedule for next week
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      1, // Notification ID
      'Weekly Pantry Review',
      'Time to check your pantry for expiring items and plan your meals!',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'weekly_pantry_channel',
          'Weekly Pantry Reminders',
          channelDescription: 'Reminders to review your pantry weekly.',
          importance: Importance.low,
          priority: Priority.low,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: '{"type": "weekly_review", "householdId": "$householdId"}',
    );

    // Add to in-app notification history
    await _firestoreService.addAppNotification(
      AppNotificationModel(
        userId: userId,
        householdId: householdId,
        title: 'Weekly Pantry Review Scheduled',
        body: 'Your weekly reminder is set for ${notificationTime.hour.toString().padLeft(2, '0')}:${notificationTime.minute.toString().padLeft(2, '0')} every ${DateFormat('EEEE').format(scheduledDate)}.',
        type: 'weekly_review_scheduled',
        createdAt: Timestamp.now(),
        isRead: false,
        payload: '{"type": "weekly_review_scheduled", "householdId": "$householdId"}',
      ),
    );

    print('Weekly pantry review scheduled for: $scheduledDate');
  }

  Future<void> _saveTokenToFirestore(String token) async {
    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      await _firestoreService.updateUserFCMToken(userId, token);
      print('FCM token saved/updated for user $userId');
    } else {
      print('No user logged in to save FCM token.');
    }
  }

  // New method to handle consumption action from notification
  Future<void> _handleConsumeAction(String itemId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      print('User not logged in, cannot handle consume action.');
      return;
    }

    // Fetch the pantry item to get its details
    final itemDoc = await _firestoreService.db.collection('pantryItems').doc(itemId).get();
    if (!itemDoc.exists) {
      print('Pantry item $itemId not found for consumption.');
      return;
    }

    final item = PantryItemModel.fromFirestore(itemDoc);

    // For simplicity, assume consuming 1 unit for now.
    // You might want to extend this with more complex logic or a default quantity.
    await _firestoreService.recordConsumedItem(item, 1);
    print('Consumed 1 unit of ${item.name} from notification.');

    // Optionally, add an in-app notification for confirmation
    await _firestoreService.addAppNotification(
      AppNotificationModel(
        userId: userId,
        householdId: item.householdId, // Assuming item has householdId
        title: 'Item Consumed',
        body: 'You consumed 1 unit of ${item.name} via notification.',
        type: 'item_consumed',
        createdAt: Timestamp.now(),
        isRead: false,
        payload: '{"type": "item_consumed", "itemId": "$itemId"}',
      ),
    );
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure to call `initializeApp` before using them.
  // Ensure Firebase is initialized only once in the background handler.
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }

  print("[_firebaseMessagingBackgroundHandler] Handling a background message: ${message.messageId}");
  print("[_firebaseMessagingBackgroundHandler] Message data: ${message.data}");
  print("[_firebaseMessagingBackgroundHandler] Message notification body: ${message.notification?.body}");

  // Initialize FirestoreService and FirebaseAuth for background processing
  final FirestoreService firestoreService = FirestoreService();
  final FirebaseAuth auth = FirebaseAuth.instance;

  // Handle interactive actions from background messages
  if (message.data['action'] == 'consume_prompt' && message.data['itemId'] != null) {
    final userId = auth.currentUser?.uid;
    if (userId != null) {
      // Fetch the pantry item to get its details
      final itemDoc = await firestoreService.db.collection('pantryItems').doc(message.data['itemId']).get();
      if (itemDoc.exists) {
        final item = PantryItemModel.fromFirestore(itemDoc);
        await firestoreService.recordConsumedItem(item, 1);
        print('[_firebaseMessagingBackgroundHandler] Consumed 1 unit of ${item.name} from background notification.');

        // Optionally, add an in-app notification for confirmation
        await firestoreService.addAppNotification(
          AppNotificationModel(
            userId: userId,
            householdId: item.householdId,
            title: 'Item Consumed',
            body: 'You consumed 1 unit of ${item.name} via background notification.',
            type: 'item_consumed',
            createdAt: Timestamp.now(),
            isRead: false,
            payload: '{"type": "item_consumed", "itemId": "${message.data['itemId']}"}',
          ),
        );
      } else {
        print('[_firebaseMessagingBackgroundHandler] Pantry item ${message.data['itemId']} not found for background consumption.');
      }
    } else {
      print('[_firebaseMessagingBackgroundHandler] No user logged in for background consume action.');
    }
  }

  // Show a local notification for the received message (if it has a notification payload)
  if (message.notification != null) {
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      channelDescription: 'This channel is used for important notifications.', // description
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    String? notificationBody = message.notification?.body;
    if (message.data['action'] == 'view_pantry_alerts') {
      // Override with a generalized message for push notifications
      notificationBody = 'You have items expiring soon. Check your pantry!';
      print('[_firebaseMessagingBackgroundHandler] Overriding notification body for pantry_summary: $notificationBody');
    }

    await flutterLocalNotificationsPlugin.show(
      0,
      message.notification?.title,
      notificationBody, // Use the generalized body
      platformChannelSpecifics,
      payload: jsonEncode(message.data), // Use the full data payload for interactive handling
    );
    print('[_firebaseMessagingBackgroundHandler] Local notification shown with title: ${message.notification?.title}, body: $notificationBody, payload: ${jsonEncode(message.data)}');
  }
}
