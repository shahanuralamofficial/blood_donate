import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepositoryImpl({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  @override
  Future<UserModel?> getCurrentUserData() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (doc.exists && doc.data() != null) {
      return UserModel.fromMap(doc.data()!);
    }
    return null;
  }

  @override
  Future<void> signInWithEmail(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  @override
  Future<void> signUpWithEmail(UserModel user, String password) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: user.email!,
      password: password,
    );

    // ইমেইল ভেরিফিকেশন লিঙ্ক পাঠানো (বন্ধ করা হয়েছে ইউজার এক্সপেরিয়েন্সের জন্য)
    // await userCredential.user?.sendEmailVerification();

    final newUser = UserModel(
      uid: userCredential.user!.uid,
      name: user.name,
      phone: user.phone,
      email: user.email,
      role: user.role,
      profileImageUrl: user.profileImageUrl,
      bloodGroup: user.bloodGroup,
      gender: user.gender,
      isVerified: user.isVerified,
      isActive: user.isActive,
      createdAt: DateTime.now(),
      address: user.address,
    );

    await _firestore.collection('users').doc(newUser.uid).set(newUser.toMap());
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  @override
  Future<void> sendVerificationEmail() async {
    await _auth.currentUser?.sendEmailVerification();
  }
}
