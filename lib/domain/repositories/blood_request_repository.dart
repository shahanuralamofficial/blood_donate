import '../../data/models/blood_request_model.dart';

abstract class BloodRequestRepository {
  Future<void> createRequest(BloodRequestModel request);
  Future<void> updateRequestStatus(String requestId, String status);
  Future<void> acceptRequest(String requestId, String donorId);
  Stream<List<BloodRequestModel>> streamEmergencyRequests();
  Stream<List<BloodRequestModel>> streamMyRequests(String userId);
  Stream<List<BloodRequestModel>> streamMyDonations(String userId);
  Stream<List<BloodRequestModel>> streamAvailableRequestsForDonor(String bloodGroup);
  Stream<BloodRequestModel> streamRequestById(String requestId); // নতুন মেথড
}
