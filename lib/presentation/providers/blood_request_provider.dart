import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/blood_request_repository_impl.dart';
import '../../domain/repositories/blood_request_repository.dart';
import '../../data/models/blood_request_model.dart';
import 'auth_provider.dart';

final bloodRequestRepositoryProvider = Provider<BloodRequestRepository>((ref) {
  return BloodRequestRepositoryImpl();
});

final emergencyRequestsProvider = StreamProvider<List<BloodRequestModel>>((ref) {
  return ref.watch(bloodRequestRepositoryProvider).streamEmergencyRequests();
});

final myRequestsProvider = StreamProvider<List<BloodRequestModel>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);
  return ref.watch(bloodRequestRepositoryProvider).streamMyRequests(user.uid);
});

final myDonationsProvider = StreamProvider<List<BloodRequestModel>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);
  return ref.watch(bloodRequestRepositoryProvider).streamMyDonations(user.uid);
});

// রিকোয়েস্ট আইডি অনুযায়ী রিয়েল-টাইম স্ট্রিম প্রোভাইডার
final requestStreamByIdProvider = StreamProvider.family<BloodRequestModel, String>((ref, requestId) {
  return ref.watch(bloodRequestRepositoryProvider).streamRequestById(requestId);
});
