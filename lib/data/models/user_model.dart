import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String phone;
  final String? email;
  final String role; // 'user' or 'admin'
  final String? profileImageUrl;
  final String? bloodGroup;
  final String? gender;
  final bool isVerified;
  final bool isActive;
  final DateTime? createdAt;
  final Map<String, dynamic>? address;
  final List<String> savedDonors;
  final String? fcmToken;
  final double averageRating;
  final int totalReviews;
  
  // --- স্পেশাল ফিচার ফিল্ডস ---
  final DateTime? lastDonationDate;
  final int totalDonations;        // মোট কত ব্যাগ রক্ত দিয়েছেন
  final int totalRequests;         // মোট কতবার আবেদন করেছেন
  final int totalReceived;         // মোট কতবার রক্ত পেয়েছেন
  final int totalReceivedBags;     // মোট কত ব্যাগ রক্ত পেয়েছেন
  final int totalCancelled;        // নতুন: মোট কতটি আবেদন বাতিল করেছেন
  final String rank;               
  final List<String> badges;

  UserModel({
    required this.uid,
    required this.name,
    required this.phone,
    this.email,
    this.role = 'user',
    this.profileImageUrl,
    this.bloodGroup,
    this.gender,
    this.isVerified = false,
    this.isActive = true,
    this.createdAt,
    this.address,
    this.savedDonors = const [],
    this.fcmToken,
    this.averageRating = 5.0,
    this.totalReviews = 0,
    this.lastDonationDate,
    this.totalDonations = 0,
    this.totalRequests = 0,
    this.totalReceived = 0,
    this.totalReceivedBags = 0,
    this.totalCancelled = 0,
    this.rank = 'Newbie',
    this.badges = const [],
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'],
      role: map['role'] ?? 'user',
      profileImageUrl: map['profileImageUrl'],
      bloodGroup: map['bloodGroup'],
      gender: map['gender'],
      isVerified: map['isVerified'] ?? false,
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      address: map['address'] != null ? Map<String, dynamic>.from(map['address']) : null,
      savedDonors: List<String>.from(map['savedDonors'] ?? []),
      fcmToken: map['fcmToken'],
      averageRating: (map['averageRating'] ?? 5.0).toDouble(),
      totalReviews: map['totalReviews'] ?? 0,
      lastDonationDate: (map['lastDonationDate'] as Timestamp?)?.toDate(),
      totalDonations: map['totalDonations'] ?? 0,
      totalRequests: map['totalRequests'] ?? 0,
      totalReceived: map['totalReceived'] ?? 0,
      totalReceivedBags: map['totalReceivedBags'] ?? 0,
      totalCancelled: map['totalCancelled'] ?? 0,
      rank: map['rank'] ?? 'Newbie',
      badges: List<String>.from(map['badges'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'phone': phone,
      'email': email,
      'role': role,
      'profileImageUrl': profileImageUrl,
      'bloodGroup': bloodGroup,
      'gender': gender,
      'isVerified': isVerified,
      'isActive': isActive,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'address': address,
      'savedDonors': savedDonors,
      'fcmToken': fcmToken,
      'averageRating': averageRating,
      'totalReviews': totalReviews,
      'lastDonationDate': lastDonationDate != null ? Timestamp.fromDate(lastDonationDate!) : null,
      'totalDonations': totalDonations,
      'totalRequests': totalRequests,
      'totalReceived': totalReceived,
      'totalReceivedBags': totalReceivedBags,
      'totalCancelled': totalCancelled,
      'rank': rank,
      'badges': badges,
    };
  }
}
