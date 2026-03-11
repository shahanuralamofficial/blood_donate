import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/models/user_model.dart';
import '../../core/services/notification_service.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl();
});

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// রিয়েল-টাইম ইউজার ডাটা প্রোভাইডার
final currentUserDataProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  
  return authState.when(
    data: (user) {
      if (user == null) {
        // ইউজার লগআউট করলে সাবস্ক্রিপশন বন্ধ করা বা ক্লিনআপ করা
        return Stream.value(null);
      }
      
      // নতুন ইউজার লগইন করলে তার নোটিফিকেশন সার্ভিস রিফ্রেশ করা
      final notificationService = NotificationService();
      notificationService.startListening();
      
      // ইউজারের FCM Token আপডেট করা যাতে সঠিক ফোনে নোটিফিকেশন যায়
      FirebaseMessaging.instance.getToken().then((token) {
        if (token != null) {
          FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'fcmToken': token,
            'lastActive': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      });
      
      // অনলাইন স্ট্যাটাস আপডেট করা
      _updateUserOnlineStatus(user.uid, true);

      return FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .map((doc) => doc.exists ? UserModel.fromMap(doc.data()!) : null);
    },
    loading: () => const Stream.empty(),
    error: (_, __) => Stream.value(null),
  );
});

// প্রোফাইল ইনকমপ্লিট ডায়ালগ এই সেশনে দেখানো হয়েছে কি না
final profileIncompleteDialogShownProvider = StateProvider<bool>((ref) => false);

// ইউজার অনলাইন স্ট্যাটাস আপডেট করার ফাংশন
Future<void> _updateUserOnlineStatus(String uid, bool isOnline) async {
  try {
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'isOnline': isOnline,
      'lastActive': FieldValue.serverTimestamp(),
    });
  } catch (e) {
    print('Error updating online status: $e');
  }
}

final userStatusProvider = Provider((ref) => UserStatusNotifier());

class UserStatusNotifier {
  Future<void> updateStatus(bool isOnline) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'isOnline': isOnline,
        'lastActive': FieldValue.serverTimestamp(),
      });
    }
  }
}

// যে কোনো ইউজারের ডাটা আইডি দিয়ে স্ট্রিম করার প্রোভাইডার
final userStreamByIdProvider = StreamProvider.family<UserModel?, String>((ref, uid) {
  if (uid.isEmpty) return Stream.value(null);
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((doc) => doc.exists ? UserModel.fromMap(doc.data()!) : null);
});
