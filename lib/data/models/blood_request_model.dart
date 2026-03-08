import 'package:cloud_firestore/cloud_firestore.dart';

class BloodRequestModel {
  final String requestId;
  final String requesterId;
  final String? donorId;
  final String bloodGroup;
  final String status; // 'pending', 'accepted', 'donated', 'completed', 'cancelled'
  final bool isEmergency;
  final String patientName;
  final String relationWithPatient;
  final String hospitalName;
  final String patientProblem;
  final String description; 
  final String phoneNumber;
  final String? patientImageUrl;
  final String? whatsappNumber;
  final String division;
  final String district;
  final String thana;
  final String union;
  final int bloodBags;
  final int donatedBags;
  final int? acceptedBags; // দাতা যত ব্যাগ দিতে চেয়েছে
  final String? donationType; // 'self' or 'arranged'
  final String? donatedBy; 
  final String? mapUrl;
  final String? thankYouNote; // রিকোয়েস্টার থেকে দাতার জন্য নোট
  final String? donorExperience; // দাতা থেকে রিকোয়েস্টারের জন্য রিভিউ
  final DateTime? requiredDate;
  final DateTime? createdAt;
  final DateTime? completedAt; // রক্তদান সম্পন্ন হওয়ার তারিখ
  final DateTime? reviewedAt; // রিভিউ দেওয়ার তারিখ

  BloodRequestModel({
    required this.requestId,
    required this.requesterId,
    this.donorId,
    required this.bloodGroup,
    required this.status,
    required this.isEmergency,
    required this.patientName,
    required this.relationWithPatient,
    required this.hospitalName,
    required this.patientProblem,
    required this.description,
    required this.phoneNumber,
    this.patientImageUrl,
    this.whatsappNumber,
    required this.division,
    required this.district,
    required this.thana,
    required this.union,
    required this.bloodBags,
    this.donatedBags = 0,
    this.acceptedBags,
    this.donatedBy,
    this.mapUrl,
    this.thankYouNote,
    this.donorExperience,
    this.requiredDate,
    this.createdAt,
    this.donationType, 
    this.completedAt,
    this.reviewedAt,
  });

  factory BloodRequestModel.fromMap(Map<String, dynamic> map, String id) {
    return BloodRequestModel(
      requestId: id,
      requesterId: map['requesterId'] ?? '',
      donorId: map['donorId'],
      bloodGroup: map['bloodGroup'] ?? '',
      status: map['status'] ?? 'pending',
      isEmergency: map['isEmergency'] ?? false,
      patientName: map['patientName'] ?? '',
      relationWithPatient: map['relationWithPatient'] ?? '',
      hospitalName: map['hospitalName'] ?? '',
      patientProblem: map['patientProblem'] ?? '',
      description: map['description'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      patientImageUrl: map['patientImageUrl'],
      whatsappNumber: map['whatsappNumber'],
      division: map['division'] ?? '',
      district: map['district'] ?? '',
      thana: map['thana'] ?? '',
      union: map['union'] ?? '',
      bloodBags: map['bloodBags'] ?? 1,
      donatedBags: map['donatedBags'] ?? 0,
      acceptedBags: map['acceptedBags'],
      donationType: map['donationType'],
      donatedBy: map['donatedBy'],
      mapUrl: map['mapUrl'],
      thankYouNote: map['thankYouNote'],
      donorExperience: map['donorExperience'],
      requiredDate: (map['requiredDate'] as Timestamp?)?.toDate(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      completedAt: (map['completedAt'] as Timestamp?)?.toDate(),
      reviewedAt: (map['reviewedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'requesterId': requesterId,
      'donorId': donorId,
      'bloodGroup': bloodGroup,
      'status': status,
      'isEmergency': isEmergency,
      'patientName': patientName,
      'relationWithPatient': relationWithPatient,
      'hospitalName': hospitalName,
      'patientProblem': patientProblem,
      'description': description,
      'phoneNumber': phoneNumber,
      'patientImageUrl': patientImageUrl,
      'whatsappNumber': whatsappNumber,
      'division': division,
      'district': district,
      'thana': thana,
      'union': union,
      'bloodBags': bloodBags,
      'donatedBags': donatedBags,
      'acceptedBags': acceptedBags,
      'donationType': donationType,
      'donatedBy': donatedBy,
      'mapUrl': mapUrl,
      'thankYouNote': thankYouNote,
      'donorExperience': donorExperience,
      'requiredDate': requiredDate != null ? Timestamp.fromDate(requiredDate!) : null,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
    };
  }
}
