import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  StreamSubscription<QuerySnapshot>? _notificationSubscription;

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

      _startNotificationListener();
    }
  }

  void _startNotificationListener() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _notificationSubscription?.cancel();
    _notificationSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data() as Map<String, dynamic>;
          final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
          if (createdAt != null && DateTime.now().difference(createdAt).inSeconds < 30) {
            _showLocalNotification(
              title: data['title'] ?? 'নতুন বার্তা',
              body: data['body'] ?? '',
            );
          }
        }
      }
    }, onError: (e) => print('Notification Listener Error: $e'));
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
    if (notification != null) {
      _showLocalNotification(title: notification.title, body: notification.body);
    }
  }

  Future<void> _showLocalNotification({String? title, String? body}) async {
    await _localNotifications.show(
      DateTime.now().millisecond, title, body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'blood_donate_channel', 'Blood Donate Notifications',
          importance: Importance.max, priority: Priority.high, icon: '@mipmap/ic_launcher',
          playSound: true, enableVibration: true,
        ),
      ),
    );
  }

  Future<void> sendNotificationToUser({
    required String receiverId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(receiverId).collection('notifications').add({
        'title': title,
        'body': body,
        'data': data,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Send Notification Error for $receiverId: $e');
    }
  }

  Future<void> notifyNearbyDonors({
    required String division,
    required String district,
    required String thana,
    required String bloodGroup,
    required String requestId,
  }) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    Set<String> notifiedUserIds = {};

    try {
      // ১. থানা লেভেলে দাতাদের খোঁজা (সবচেয়ে সঠিক ফিল্টারিং)
      final thanaDonors = await FirebaseFirestore.instance
          .collection('users')
          .where('address.division', isEqualTo: division)
          .where('address.district', isEqualTo: district)
          .where('address.thana', isEqualTo: thana)
          .where('bloodGroup', isEqualTo: bloodGroup)
          .where('isAvailable', isEqualTo: true)
          .get();

      for (var doc in thanaDonors.docs) {
        if (doc.id != currentUserId) {
          await sendNotificationToUser(
            receiverId: doc.id,
            title: 'জরুরি $bloodGroup রক্ত প্রয়োজন!',
            body: '$thana, $district-এ আপনার গ্রুপের রক্তের আবেদন করা হয়েছে।',
            data: {'requestId': requestId, 'type': 'blood_request'},
          );
          notifiedUserIds.add(doc.id);
        }
      }

      // ২. যদি থানা লেভেলে দাতা কম থাকে, তবে জেলা লেভেলে বাড়ানো
      if (notifiedUserIds.length < 3) {
        final districtDonors = await FirebaseFirestore.instance
            .collection('users')
            .where('address.division', isEqualTo: division)
            .where('address.district', isEqualTo: district)
            .where('bloodGroup', isEqualTo: bloodGroup)
            .where('isAvailable', isEqualTo: true)
            .limit(15)
            .get();

        for (var doc in districtDonors.docs) {
          if (doc.id != currentUserId && !notifiedUserIds.contains(doc.id)) {
            await sendNotificationToUser(
              receiverId: doc.id,
              title: 'আপনার জেলায় $bloodGroup রক্ত প্রয়োজন!',
              body: '$district-এ রক্তের জরুরি আবেদন করা হয়েছে। দয়া করে দেখুন।',
              data: {'requestId': requestId, 'type': 'blood_request'},
            );
            notifiedUserIds.add(doc.id);
          }
        }
      }
      
      print('Total donors notified: ${notifiedUserIds.length}');
    } catch (e) {
      print('Notify Nearby Donors Error: $e');
      // যদি ইনডেক্স এরর হয়, তবে ব্যাকআপ হিসেবে শুধুমাত্র ব্লাড গ্রুপ দিয়ে খুঁজি
      _notifyFallback(bloodGroup, requestId, currentUserId);
    }
  }

  // ব্যাকআপ নোটিফিকেশন লজিক (যদি এরিয়া কুয়েরি ফেইল করে)
  Future<void> _notifyFallback(String bloodGroup, String requestId, String? currentUserId) async {
    try {
      final fallbackDonors = await FirebaseFirestore.instance
          .collection('users')
          .where('bloodGroup', isEqualTo: bloodGroup)
          .where('isAvailable', isEqualTo: true)
          .limit(10)
          .get();

      for (var doc in fallbackDonors.docs) {
        if (doc.id != currentUserId) {
          await sendNotificationToUser(
            receiverId: doc.id,
            title: 'জরুরি রক্তের প্রয়োজন!',
            body: 'আপনার গ্রুপের রক্তের একটি নতুন আবেদন করা হয়েছে। দ্রুত চেক করুন।',
            data: {'requestId': requestId, 'type': 'blood_request'},
          );
        }
      }
    } catch (e) {
      print('Fallback Notification Error: $e');
    }
  }
}
