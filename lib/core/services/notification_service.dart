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

      // গুরুত্বপূর্ণ: অ্যাপ ওপেন হওয়ার পর লিসেনার শুরু করা
      _startNotificationListener();
    }
  }

  // রিয়েল-টাইম লিসেনার: ডাটাবেসে নতুন নোটিফিকেশন আসলেই পুশ দেখাবে
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
          
          // সময় চেক করা (যাতে পুরনো নোটিফিকেশন বারবার না আসে)
          final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
          if (createdAt != null && DateTime.now().difference(createdAt).inSeconds < 10) {
            _showLocalNotification(
              title: data['title'] ?? 'নতুন বার্তা',
              body: data['body'] ?? '',
            );
          }
        }
      }
    });
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
      print('Notification Error: $e');
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

    // একই বিভাগ, জেলা ও থানার দাতাদের খোঁজা হচ্ছে
    final donorsQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('address.division', isEqualTo: division)
        .where('address.district', isEqualTo: district)
        .where('address.thana', isEqualTo: thana)
        .where('bloodGroup', isEqualTo: bloodGroup)
        .get();

    for (var doc in donorsQuery.docs) {
      if (doc.id != currentUserId) {
        await sendNotificationToUser(
          receiverId: doc.id,
          title: 'জরুরি $bloodGroup রক্তের প্রয়োজন!',
          body: '$thana, $district-এ আপনার গ্রুপের রক্ত প্রয়োজন। দ্রুত অ্যাপে দেখুন।',
          data: {
            'requestId': requestId,
            'type': 'blood_request',
            'bloodGroup': bloodGroup,
            'location': '$thana, $district'
          },
        );
      }
    }

    // যদি থানা পর্যায়ে পর্যাপ্ত দাতা না পাওয়া যায়, তবে পুরো জেলার দাতাদেরও জানানো যেতে পারে (ঐচ্ছিক)
    if (donorsQuery.docs.length < 5) {
      final districtDonorsQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('address.division', isEqualTo: division)
          .where('address.district', isEqualTo: district)
          .where('bloodGroup', isEqualTo: bloodGroup)
          .limit(20) // অতিরিক্ত লোড এড়াতে লিমিট
          .get();

      for (var doc in districtDonorsQuery.docs) {
        // যারা অলরেডি থানা লেভেলে নোটিফিকেশন পায়নি তাদের পাঠানো
        bool alreadyNotified = donorsQuery.docs.any((d) => d.id == doc.id);
        if (doc.id != currentUserId && !alreadyNotified) {
          await sendNotificationToUser(
            receiverId: doc.id,
            title: 'আপনার জেলায় $bloodGroup রক্তের প্রয়োজন!',
            body: '$district-এ রক্তের জরুরি আবেদন করা হয়েছে। দয়া করে দেখুন।',
            data: {'requestId': requestId, 'type': 'blood_request'},
          );
        }
      }
    }
  }
}
