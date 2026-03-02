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
  }

  @override
  Future<List<Map<String, dynamic>>> getNearbyDonors(double lat, double lng, double radiusInKm) async {
    // Basic implementation: In production, use GeoFirestore or Cloud Functions for proximity
    // For now, we fetch all active donors and filter locally (not scalable but works for MVP)
    final snapshot = await _firestore
        .collection('donors')
        .where('availability', isEqualTo: true)
        .get();

    List<Map<String, dynamic>> nearbyDonors = [];

    for (var doc in snapshot.docs) {
      final donorData = doc.data();
      final userDoc = await _firestore.collection('users').doc(doc.id).get();
      
      if (userDoc.exists) {
        nearbyDonors.add({
          'donor': DonorModel.fromMap(donorData),
          'user': UserModel.fromMap(userDoc.data()!),
        });
      }
    }
    return nearbyDonors;
  }

  @override
  Stream<List<Map<String, dynamic>>> streamAvailableDonors() {
    return _firestore
        .collection('donors')
        .where('availability', isEqualTo: true)
        .snapshots()
        .asyncMap((snapshot) async {
      List<Map<String, dynamic>> list = [];
      for (var doc in snapshot.docs) {
        final userDoc = await _firestore.collection('users').doc(doc.id).get();
        if (userDoc.exists) {
          list.add({
            'donor': DonorModel.fromMap(doc.data()),
            'user': UserModel.fromMap(userDoc.data()!),
          });
        }
      }
      return list;
    });
  }
}
