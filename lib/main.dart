import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/auth/auth_wrapper.dart';
import 'core/services/notification_service.dart';
import 'presentation/screens/chat/chat_screen.dart';
import 'presentation/screens/requests/request_details_screen.dart';
import 'presentation/screens/home/notification_screen.dart';
import 'presentation/providers/auth_provider.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase Initialize
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Background Handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(
    const ProviderScope(
      child: BloodDonateApp(),
    ),
  );
}

class BloodDonateApp extends ConsumerStatefulWidget {
  const BloodDonateApp({super.key});

  @override
  ConsumerState<BloodDonateApp> createState() => _BloodDonateAppState();
}

class _BloodDonateAppState extends ConsumerState<BloodDonateApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // অ্যাপ চালু হওয়ার পর ব্যাকগ্রাউন্ডে নোটিফিকেশন সার্ভিস চালু করা
    Future.microtask(() async {
      try {
        await NotificationService().init();
      } catch (e) {
        debugPrint("Notification Init Error: $e");
      }
    });

    _updateStatus(true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _updateStatus(false);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateStatus(true);
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _updateStatus(false);
    }
  }

  void _updateStatus(bool isOnline) {
    try {
      ref.read(userStatusProvider).updateStatus(isOnline);
    } catch (e) {
      debugPrint("Status Update Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'রক্তদান - Blood Donate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      navigatorKey: NotificationService.navigatorKey, // নেভিগেটর কি সেট করা হলো
      onGenerateRoute: (settings) {
        if (settings.name == '/chat') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => ChatScreen(
              requestId: args['chatId'],
              otherUserName: args['otherUserName'],
              otherUserId: args['otherUserId'],
            ),
          );
        }
        if (settings.name == '/request_details') {
          final requestId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (context) => RequestDetailsScreen(requestId: requestId),
          );
        }
        if (settings.name == '/notifications') {
          return MaterialPageRoute(
            builder: (context) => const NotificationScreen(),
          );
        }
        return null;
      },
      home: const AuthWrapper(),
    );
  }
}
