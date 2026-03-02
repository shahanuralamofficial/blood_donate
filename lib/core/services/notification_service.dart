import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  Future<void> init() async {
    // ১. পারমিশন রিকোয়েস্ট (অ্যান্ড্রয়েড ১৩+)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // ২. টোকেন সংগ্রহ ও সেভ
      String? token = await _fcm.getToken();
      if (token != null) {
        await _saveTokenToFirestore(token);
      }

      // টোকেন রিফ্রেশ লিসেনার
      _fcm.onTokenRefresh.listen(_saveTokenToFirestore);

      // ৩. লোকাল নোটিফিকেশন কনফিগারেশন (Foreground এর জন্য)
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);
      
      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (details) {
          // নোটিফিকেশনে ক্লিক করলে নির্দিষ্ট পেজে যাওয়ার লজিক এখানে হবে
        },
      );

      // অ্যান্ড্রয়েড চ্যানেল তৈরি (High Priority)
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'blood_donate_channel', 
        'Blood Donate Notifications',
        description: 'Important notifications for blood requests and messages.',
        importance: Importance.max,
        playSound: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      // ৪. মেসেজ লিসেনার
      FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    }
  }

  Future<void> _saveTokenToFirestore(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'fcmToken': token,
        'lastActive': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? _ = message.notification?.android;

    if (notification != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'blood_donate_channel',
            'Blood Donate Notifications',
            channelDescription: 'Blood requests and messages.',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            color: Color(0xFFE53935),
          ),
        ),
      );
    }
  }

  // রিয়েল-টাইম রিকোয়েস্ট নোটিফিকেশন লজিক (ক্লায়েন্ট সাইড থেকে ট্রিগার করার জন্য)
  // তবে এটি প্রফেশনালভাবে Firebase Functions দিয়ে করা উচিত।
}
