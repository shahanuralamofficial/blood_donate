import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/donor_repository.dart';
import '../models/donor_model.dart';
import '../models/user_model.dart';

class DonorRepositoryImpl implements DonorRepository {
  final FirebaseFirestore _firestore;

  DonorRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> updateDonorProfile(DonorModel donor) async {
    await _firestore.collection('donors').doc(donor.uid).set(donor.toMap(), SetOptions(merge: true));
    // ইউজার কালেকশনেও এভেইলিবিলিটি আপডেট করছি
    await _firestore.collection('users').doc(donor.uid).update({
      'isAvailable': donor.availability,
    });
  }

  @override
  Future<List<Map<String, dynamic>>> getNearbyDonors(double lat, double lng, double radiusInKm) async {
    final snapshot = await _firestore
        .collection('users')
        .where('isAvailable', isEqualTo: true)
        .get();

    return snapshot.docs.map((doc) {
      final user = UserModel.fromMap(doc.data());
      return {
        'donor': DonorModel(uid: doc.id, availability: true),
        'user': user,
      };
    }).toList();
  }

  @override
  Stream<List<Map<String, dynamic>>> streamAvailableDonors() {
    // যারা রক্ত দিতে ইচ্ছুক (isAvailable: true) এবং যাদের ব্লাড গ্রুপ দেওয়া আছে তাদের দেখাচ্ছি
    return _firestore
        .collection('users')
        .where('isAvailable', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final userData = doc.data();
        return {
          'donor': DonorModel(uid: doc.id, availability: true),
          'user': UserModel.fromMap(userData),
        };
      }).where((element) {
        // যাদের ব্লাড গ্রুপ তথ্য নেই তাদের লিস্টে দেখাচ্ছি না
        final user = element['user'] as UserModel;
        return user.bloodGroup != null && user.bloodGroup!.isNotEmpty;
      }).toList();
    });
  }
}
