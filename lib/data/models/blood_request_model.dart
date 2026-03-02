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
  final String division;
  final String district;
  final String thana;
  final String union;
  final int bloodBags;
  final int donatedBags;
  final String? donatedBy; 
  final String? mapUrl;
  final String? thankYouNote; // নতুন: রক্তদাতার জন্য ধন্যবাদ বার্তা
  final DateTime? requiredDate;
  final DateTime? createdAt;

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
    required this.division,
    required this.district,
    required this.thana,
    required this.union,
    required this.bloodBags,
    this.donatedBags = 0,
    this.donatedBy,
    this.mapUrl,
    this.thankYouNote,
    this.requiredDate,
    this.createdAt,
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
      division: map['division'] ?? '',
      district: map['district'] ?? '',
      thana: map['thana'] ?? '',
      union: map['union'] ?? '',
      bloodBags: map['bloodBags'] ?? 1,
      donatedBags: map['donatedBags'] ?? 0,
      donatedBy: map['donatedBy'],
      mapUrl: map['mapUrl'],
      thankYouNote: map['thankYouNote'],
      requiredDate: (map['requiredDate'] as Timestamp?)?.toDate(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
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
      'division': division,
      'district': district,
      'thana': thana,
      'union': union,
      'bloodBags': bloodBags,
      'donatedBags': donatedBags,
      'donatedBy': donatedBy,
      'mapUrl': mapUrl,
      'thankYouNote': thankYouNote,
      'requiredDate': requiredDate != null ? Timestamp.fromDate(requiredDate!) : null,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}
