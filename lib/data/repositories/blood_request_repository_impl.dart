import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/blood_request_repository.dart';
import '../models/blood_request_model.dart';

class BloodRequestRepositoryImpl implements BloodRequestRepository {
  final FirebaseFirestore _firestore;

  BloodRequestRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<String> createRequest(BloodRequestModel request) async {
    final docRef = await _firestore.collection('blood_requests').add(request.toMap());
    return docRef.id;
  }

  @override
  Future<void> updateRequestStatus(String requestId, String status) async {
    await _firestore.collection('blood_requests').doc(requestId).update({
      'status': status,
    });
  }

  @override
  Future<void> acceptRequest(String requestId, String donorId) async {
    await _firestore.collection('blood_requests').doc(requestId).update({
      'donorId': donorId,
      'status': 'accepted',
    });
  }

  @override
  Stream<List<BloodRequestModel>> streamEmergencyRequests() {
    return _firestore
        .collection('blood_requests')
        .where('status', isEqualTo: 'pending') // শুধুমাত্র পেন্ডিংগুলো দেখাবে
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BloodRequestModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  @override
  Stream<List<BloodRequestModel>> streamMyRequests(String userId) {
    return _firestore
        .collection('blood_requests')
        .where('requesterId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BloodRequestModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  @override
  Stream<List<BloodRequestModel>> streamMyDonations(String userId) {
    return _firestore
        .collection('blood_requests')
        .where('donorId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BloodRequestModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  @override
  Stream<List<BloodRequestModel>> streamAvailableRequestsForDonor(String bloodGroup) {
    return _firestore
        .collection('blood_requests')
        .where('bloodGroup', isEqualTo: bloodGroup)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BloodRequestModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  @override
  Stream<BloodRequestModel> streamRequestById(String requestId) {
    return _firestore
        .collection('blood_requests')
        .doc(requestId)
        .snapshots()
        .map((doc) => BloodRequestModel.fromMap(doc.data()!, doc.id));
  }
}
