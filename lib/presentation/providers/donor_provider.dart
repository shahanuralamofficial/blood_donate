import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/donor_repository_impl.dart';
import '../../domain/repositories/donor_repository.dart';

final donorRepositoryProvider = Provider<DonorRepository>((ref) {
  return DonorRepositoryImpl();
});

final availableDonorsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(donorRepositoryProvider).streamAvailableDonors();
});

final nearbyDonorsProvider = FutureProvider.family<List<Map<String, dynamic>>, ({double lat, double lng, double radius})>((ref, arg) {
  return ref.watch(donorRepositoryProvider).getNearbyDonors(arg.lat, arg.lng, arg.radius);
});
