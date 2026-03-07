import 'dart:async';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../localization/app_translations.dart';
import '../../presentation/screens/chat/voice_call_screen.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  StreamSubscription<QuerySnapshot>? _notificationSubscription;
  final Set<String> _notifiedChatIds = {}; // ট্র্যাক করবে কোন চ্যাটের নোটিফিকেশন অলরেডি দেখানো হয়েছে

  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // বর্তমানে ইউজার কোন চ্যাট স্ক্রিনে আছে তা ট্র্যাক করার জন্য
  static String? currentChatId;

  // গ্লোবাল নেভিগেটর কি (যাতে যেকোনো জায়গা থেকে নেভিগেট করা যায়)
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  Future<void> init() async {
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true, badge: true, sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      String? token = await _fcm.getToken();
      if (token != null) await _saveTokenToFirestore(token);
      _fcm.onTokenRefresh.listen(_saveTokenToFirestore);

      const AndroidInitializationSettings initializationSettingsAndroid = 
          AndroidInitializationSettings('@mipmap/launcher_icon');
      
      const InitializationSettings initializationSettings = 
          InitializationSettings(android: initializationSettingsAndroid);
      
      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
      );

      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'blood_donate_channel', 
        'Blood Donate Notifications',
        importance: Importance.max, 
        playSound: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
      
      FirebaseMessaging.onMessage.listen(_showForegroundNotification);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpened);

      _startNotificationListener();
    }
  }

  // নোটিফিকেশনে ক্লিক করলে এখানে আসবে (Foreground/Background)
  void _onDidReceiveNotificationResponse(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final Map<String, dynamic> data = jsonDecode(response.payload!);
        _navigateBasedOnData(data);
      } catch (e) {
        debugPrint('Notification Payload Error: $e');
      }
    }
  }

  // অ্যাপ বন্ধ থাকলে বা ব্যাকগ্রাউন্ডে থাকলে নোটিফিকেশনে ক্লিক করলে
  void _handleMessageOpened(RemoteMessage message) {
    _navigateBasedOnData(message.data);
  }

  void _navigateBasedOnData(Map<String, dynamic> data) {
    final type = data['type'];
    final requestId = data['requestId'];

    if (type == 'chat') {
      final chatId = data['chatId'];
      final senderName = data['senderName'] ?? 'বার্তা';
      final senderId = data['senderId'];
      
      navigatorKey.currentState?.pushNamed('/chat', arguments: {
        'chatId': chatId,
        'otherUserName': senderName,
        'otherUserId': senderId,
      });
    } else if (type == 'call') {
      final channelId = data['channelId'];
      final senderName = data['senderName'] ?? 'User';
      final isVideo = data['isVideo'] == 'true';
      
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => CallScreen(
            channelId: channelId,
            otherUserName: senderName,
            isVideoCall: isVideo,
          ),
        ),
      );
    } else if (type == 'blood_request' || type == 'emergency' || type == 'request' || type == 'donation_confirm') {
      // যদি রক্ত দিয়েছে এমন নোটিফিকেশন হয় বা সাধারণ রিকোয়েস্ট হয়, তবে ডিটেইলস পেজে যাবে
      if (requestId != null) {
        navigatorKey.currentState?.pushNamed('/request_details', arguments: requestId);
      } else {
        navigatorKey.currentState?.pushNamed('/notifications');
      }
    } else {
      // অন্য সব সাধারণ নোটিফিকেশনের ক্ষেত্রে নোটিফিকেশন স্ক্রিনে যাবে
      navigatorKey.currentState?.pushNamed('/notifications');
    }
  }

  // ইউজার লগইন করার পর এই মেথডটি কল করতে হবে
  void startListening() {
    _startNotificationListener();
  }

  void _startNotificationListener() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('No user found to start notification listener');
      return;
    }

    debugPrint('Starting notification listener for: ${user.uid}');
    _notificationSubscription?.cancel();
    
    // শুধুমাত্র লিসেনার শুরু হওয়ার পর থেকে আসা নোটিফিকেশনগুলো দেখানোর জন্য টাইমস্ট্যাম্প নিচ্ছি
    final DateTime startTime = DateTime.now();

    _notificationSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen((snapshot) async {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data() as Map<String, dynamic>;
          
          // পুরাতন নোটিফিকেশন ইগনোর করা (লিসেনার শুরু হওয়ার আগের গুলো)
          final Timestamp? createdAt = data['createdAt'] as Timestamp?;
          if (createdAt != null && createdAt.toDate().isBefore(startTime)) {
            continue;
          }

          if (data['isRead'] == true) continue;

          final notificationData = data['data'] as Map<String, dynamic>?;

          // ২. চ্যাট নোটিফিকেশন স্পেশাল ফিল্টারিং
          if (notificationData != null && notificationData['type'] == 'chat') {
            final chatId = notificationData['chatId'];
            final senderId = notificationData['senderId'];

            // ইউজার যদি নিজের মেসেজের নোটিফিকেশন পায় (কদাচিৎ ঘটে), তবে ইগনোর করবে
            if (senderId == user.uid) {
              change.doc.reference.update({'isRead': true});
              continue;
            }

            // যদি এই চ্যাটটি মিউট করা থাকে, তবে নোটিফিকেশন দেখাবে না
            final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
            final userData = userDoc.data();
            if (userData != null) {
              final List<dynamic> mutedChats = userData['mutedChats'] ?? [];
              if (mutedChats.contains(chatId)) {
                change.doc.reference.update({'isRead': true});
                continue;
              }
            }

            // ইউজার যদি অলরেডি এই চ্যাটরুমে থাকে, তবে নোটিফিকেশন দেখাবে না এবং এটাকে Read মার্ক করবে
            if (chatId == currentChatId) {
              change.doc.reference.update({'isRead': true});
              continue;
            }

            // এই চ্যাটের জন্য যদি অলরেডি একবার নোটিফিকেশন দেখানো হয়ে থাকে (ইউজার এখনও পড়েনি), তবে আর দেখাবে না
            if (_notifiedChatIds.contains(chatId)) {
              continue;
            }

            _notifiedChatIds.add(chatId);
          }

          _showLocalNotification(
            title: _localizeStatic(data['title'], notificationData),
            body: _localizeStatic(data['body'], notificationData),
            payload: jsonEncode(data['data'] ?? {}),
          );
        }
      }
    }, onError: (e) => debugPrint('Notification Listener Error: $e'));
  }

  // স্ট্যাটিক লোকালইজেশন (নোটিফিকেশন সার্ভিসের জন্য)
  String _localizeStatic(String? key, Map<String, dynamic>? data) {
    if (key == null) return '';
    
    // বর্তমান ল্যাঙ্গুয়েজ কোড ডিফল্ট হিসেবে 'bn' নিচ্ছি (যেহেতু এটিই প্রাইমারি)
    // বাস্তব ক্ষেত্রে এটি SharedPreferences থেকে নেওয়া যেতে পারে
    const String lang = 'bn'; 
    final translations = AppTranslations.translations[lang];
    
    if (translations != null && translations.containsKey(key)) {
      String text = translations[key]!;
      if (data != null) {
        if (key == 'emergency_blood_req' || key == 'blood_req_district' || key == 'blood_req_division') {
          text = text.replaceFirst('{}', data['bloodGroup'] ?? '');
        } else if (key == 'blood_req_nearby') {
          text = text.replaceFirst('{}', data['thana'] ?? '').replaceFirst('{}', data['district'] ?? '');
        }
      }
      return text;
    }
    return key;
  }

  // যখন ইউজার কোনো চ্যাট ওপেন করবে, তখন ওই চ্যাটের জন্য নতুন নোটিফিকেশন এলাউ করতে হবে
  static void clearNotifiedChat(String chatId) {
    NotificationService()._notifiedChatIds.remove(chatId);
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
    final data = message.data;
    if (data['type'] == 'call') {
      _navigateBasedOnData(data);
    } else {
      _showLocalNotification(
        title: message.notification?.title, 
        body: message.notification?.body,
        payload: jsonEncode(message.data),
      );
    }
  }

  Future<void> _showLocalNotification({String? title, String? body, String? payload}) async {
    await _localNotifications.show(
      DateTime.now().millisecond, title, body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'blood_donate_channel', 'Blood Donate Notifications',
          importance: Importance.max, 
          priority: Priority.high, 
          icon: '@mipmap/launcher_icon',
          playSound: true, 
          enableVibration: true,
          showWhen: true,
          styleInformation: const BigTextStyleInformation(''),
        ),
      ),
      payload: payload,
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
      debugPrint('Send Notification Error: $e');
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
            title: 'emergency_blood_req', // Key
            body: 'blood_req_nearby', // Key
            data: {
              'requestId': requestId, 
              'type': 'blood_request',
              'thana': thana,
              'district': district,
              'bloodGroup': bloodGroup, // For dynamic replacement in translation
            },
          );
          notifiedUserIds.add(doc.id);
        }
      }

      // যদি থানায় ৫০ জনের কম হয়, তবে জেলায় পাঠানো হবে
      if (notifiedUserIds.length < 50) {
        final districtDonors = await FirebaseFirestore.instance
            .collection('users')
            .where('address.division', isEqualTo: division)
            .where('address.district', isEqualTo: district)
            .where('bloodGroup', isEqualTo: bloodGroup)
            .where('isAvailable', isEqualTo: true)
            .limit(300) // জেলা পর্যায়ে ৩০০ জন পর্যন্ত চেক করবে
            .get();

        for (var doc in districtDonors.docs) {
          if (doc.id != currentUserId && !notifiedUserIds.contains(doc.id)) {
            await sendNotificationToUser(
              receiverId: doc.id,
              title: 'blood_req_district', // Key
              body: 'blood_req_district', // Key
              data: {
                'requestId': requestId, 
                'type': 'blood_request',
                'thana': thana,
                'district': district,
                'division': division,
                'bloodGroup': bloodGroup,
              },
            );
            notifiedUserIds.add(doc.id);
          }
        }
      }

      // যদি এখনো ৫০ জনের কম হয়, তবে পুরো বিভাগ জুড়ে নোটিফিকেশন যাবে
      if (notifiedUserIds.length < 50) {
        final divisionDonors = await FirebaseFirestore.instance
            .collection('users')
            .where('address.division', isEqualTo: division)
            .where('bloodGroup', isEqualTo: bloodGroup)
            .where('isAvailable', isEqualTo: true)
            .limit(500) // বিভাগ পর্যায়ে ৫০০ জন পর্যন্ত চেক করবে
            .get();

        for (var doc in divisionDonors.docs) {
          if (doc.id != currentUserId && !notifiedUserIds.contains(doc.id)) {
            await sendNotificationToUser(
              receiverId: doc.id,
              title: 'blood_req_division', // Key
              body: 'blood_req_division', // Key
              data: {
                'requestId': requestId, 
                'type': 'blood_request',
                'thana': thana,
                'district': district,
                'division': division,
                'bloodGroup': bloodGroup,
              },
            );
            notifiedUserIds.add(doc.id);
          }
        }
      }
    } catch (e) {
      debugPrint('Notify Nearby Donors Error: $e');
      _notifyFallback(bloodGroup, requestId, currentUserId, thana, district);
    }
  }

  Future<void> _notifyFallback(String bloodGroup, String requestId, String? currentUserId, String thana, String district) async {
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
            title: 'emergency_blood_needed', // Key
            body: 'new_blood_req_msg', // Key
            data: {
              'requestId': requestId, 
              'type': 'blood_request',
              'thana': thana,
              'district': district,
            },
          );
        }
      }
    } catch (e) {
      debugPrint('Fallback Notification Error: $e');
    }
  }
}
