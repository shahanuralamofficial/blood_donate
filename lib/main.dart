import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/auth/auth_wrapper.dart';
import 'core/services/notification_service.dart';
import 'presentation/screens/chat/chat_screen.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  final notificationService = NotificationService();
  await notificationService.init();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(
    const ProviderScope(
      child: BloodDonateApp(),
    ),
  );
}

class BloodDonateApp extends StatelessWidget {
  const BloodDonateApp({super.key});

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
        return null;
      },
      home: const AuthWrapper(),
    );
  }
}
