import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/user_model.dart';

abstract class AuthRepository {
  Stream<User?> get authStateChanges;
  Future<UserModel?> getCurrentUserData();
  Future<void> signInWithEmail(String email, String password);
  Future<void> signUpWithEmail(UserModel user, String password);
  Future<void> signOut();
  Future<void> sendPasswordResetEmail(String email);
  Future<void> sendVerificationEmail();
}
