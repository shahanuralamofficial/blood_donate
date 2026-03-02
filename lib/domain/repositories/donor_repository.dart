import '../../data/models/donor_model.dart';

abstract class DonorRepository {
  Future<void> updateDonorProfile(DonorModel donor);
  Future<List<Map<String, dynamic>>> getNearbyDonors(double lat, double lng, double radiusInKm);
  Stream<List<Map<String, dynamic>>> streamAvailableDonors();
}
