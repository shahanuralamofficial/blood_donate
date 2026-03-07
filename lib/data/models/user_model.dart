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
  final bool isAvailable; // রক্তদানের জন্য এভেইলএবল কি না
  final DateTime? createdAt;
  final Map<String, dynamic>? address;
  final List<String> savedDonors;
  final List<String> blockedUsers; // নতুন: যাদের ব্লক করা হয়েছে
  final List<String> callBlockedUsers; // নতুন: যাদের কল ব্লক করা হয়েছে
  final List<String> mutedChats;   // নতুন: যাদের নোটিফিকেশন মিউট করা হয়েছে
  final String? fcmToken;
  final String? whatsappNumber;
  final double averageRating;
  final int totalReviews;
  
  // --- স্পেশাল ফিচার ফিল্ডস ---
  final DateTime? lastDonationDate;
  final int totalDonations;        
  final int totalRequests;         
  final int totalReceived;         
  final int totalReceivedBags;     
  final int totalCancelled;        
  final String rank;               
  final List<String> badges;
  final bool rankUpdatePending;

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
    this.isAvailable = true,
    this.createdAt,
    this.address,
    this.savedDonors = const [],
    this.blockedUsers = const [],
    this.callBlockedUsers = const [],
    this.mutedChats = const [],
    this.fcmToken,
    this.whatsappNumber,
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
    this.rankUpdatePending = false,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    int donations = map['totalDonations'] ?? 0;
    String calculatedRank = 'Newbie';
    if (donations >= 50) {
      calculatedRank = 'Diamond';
    } else if (donations >= 30) {
      calculatedRank = 'Platinum';
    } else if (donations >= 15) {
      calculatedRank = 'Gold';
    } else if (donations >= 5) {
      calculatedRank = 'Silver';
    } else if (donations >= 1) {
      calculatedRank = 'Bronze';
    }

    // Use stored rank if it exists and isn't 'Newbie', otherwise use calculated
    String finalRank = map['rank'] != null && map['rank'] != 'Newbie' 
        ? map['rank'] 
        : calculatedRank;

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
      isAvailable: map['isAvailable'] ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      address: map['address'] != null ? Map<String, dynamic>.from(map['address']) : null,
      savedDonors: List<String>.from(map['savedDonors'] ?? []),
      blockedUsers: List<String>.from(map['blockedUsers'] ?? []),
      callBlockedUsers: List<String>.from(map['callBlockedUsers'] ?? []),
      mutedChats: List<String>.from(map['mutedChats'] ?? []),
      fcmToken: map['fcmToken'],
      whatsappNumber: map['whatsappNumber'],
      averageRating: (map['averageRating'] ?? 5.0).toDouble(),
      totalReviews: map['totalReviews'] ?? 0,
      lastDonationDate: (map['lastDonationDate'] as Timestamp?)?.toDate(),
      totalDonations: donations,
      totalRequests: map['totalRequests'] ?? 0,
      totalReceived: map['totalReceived'] ?? 0,
      totalReceivedBags: map['totalReceivedBags'] ?? 0,
      totalCancelled: map['totalCancelled'] ?? 0,
      rank: finalRank,
      badges: List<String>.from(map['badges'] ?? []),
      rankUpdatePending: map['rankUpdatePending'] ?? false,
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
      'isAvailable': isAvailable,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'address': address,
      'savedDonors': savedDonors,
      'blockedUsers': blockedUsers,
      'callBlockedUsers': callBlockedUsers,
      'mutedChats': mutedChats,
      'fcmToken': fcmToken,
      'whatsappNumber': whatsappNumber,
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
      'rankUpdatePending': rankUpdatePending,
    };
  }
}
