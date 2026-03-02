import 'dart:async';
import 'dart:convert';
import 'package:http/dio.dart' as dio_lib; // Use dio for API calls if needed
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
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true, badge: true, sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      String? token = await _fcm.getToken();
      if (token != null) await _saveTokenToFirestore(token);
      _fcm.onTokenRefresh.listen(_saveTokenToFirestore);

      const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
      
      await _localNotifications.initialize(initializationSettings);

      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'blood_donate_channel', 'Blood Donate Notifications',
        importance: Importance.max, playSound: true,
      );

      await _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);
      FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    }
  }

  Future<void> _saveTokenToFirestore(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'fcmToken': token,
      }, SetOptions(merge: true));
    }
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    if (notification != null) {
      await _localNotifications.show(
        notification.hashCode, notification.title, notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'blood_donate_channel', 'Blood Donate Notifications',
            importance: Importance.max, priority: Priority.high, icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    }
  }

  // --- Push Notification Trigger Logic ---
  // In a real app, this should be done via Firebase Cloud Functions (Node.js)
  // For client-side demo, we use Firestore-based notification triggers
  
  Future<void> sendNotificationToUser({
    required String receiverId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // ১. ইউজারের টোকেন খুঁজে বের করা
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(receiverId).get();
      final String? token = userDoc.data()?['fcmToken'];

      if (token != null) {
        // ২. ইউজারের ইন-অ্যাপ নোটিফিকেশন কালেকশনে সেভ করা
        await FirebaseFirestore.instance.collection('users').doc(receiverId).collection('notifications').add({
          'title': title,
          'body': body,
          'data': data,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        print('Notification logged for $receiverId: $title');
      }
    } catch (e) {
      print('Notification Error: $e');
    }
  }

  // ৩. আশেপাশে থাকা রক্তদাতাদের জানানো
  Future<void> notifyNearbyDonors({
    required String district,
    required String bloodGroup,
    required String requestId,
  }) async {
    final donorsQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('address.district', isEqualTo: district)
        .where('bloodGroup', isEqualTo: bloodGroup)
        .get();

    for (var doc in donorsQuery.docs) {
      if (doc.id != FirebaseAuth.instance.currentUser?.uid) {
        await sendNotificationToUser(
          receiverId: doc.id,
          title: 'জরুরি রক্তের প্রয়োজন!',
          body: '$district-এ $bloodGroup রক্ত প্রয়োজন। এখনই আবেদনটি দেখুন।',
          data: {'requestId': requestId, 'type': 'emergency'},
        );
      }
    }
  }
}
