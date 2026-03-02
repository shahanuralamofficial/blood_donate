import 'package:cloud_firestore/cloud_firestore.dart';

class DonorModel {
  final String uid;
  final DateTime? lastDonationDate;
  final bool availability;
  final GeoPoint? location;
  final int totalDonations;
  final double rating;

  DonorModel({
    required this.uid,
    this.lastDonationDate,
    this.availability = true,
    this.location,
    this.totalDonations = 0,
    this.rating = 5.0,
  });

  factory DonorModel.fromMap(Map<String, dynamic> map) {
    return DonorModel(
      uid: map['uid'] ?? '',
      lastDonationDate: (map['lastDonationDate'] as Timestamp?)?.toDate(),
      availability: map['availability'] ?? true,
      location: map['location'] as GeoPoint?,
      totalDonations: map['totalDonations'] ?? 0,
      rating: (map['rating'] ?? 5.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'lastDonationDate': lastDonationDate != null ? Timestamp.fromDate(lastDonationDate!) : null,
      'availability': availability,
      'location': location,
      'totalDonations': totalDonations,
      'rating': rating,
    };
  }
}
