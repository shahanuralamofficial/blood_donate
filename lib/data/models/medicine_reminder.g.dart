// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'medicine_reminder.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MedicineReminderImpl _$$MedicineReminderImplFromJson(
  Map<String, dynamic> json,
) => _$MedicineReminderImpl(
  id: json['id'] as String,
  medicineName: json['medicineName'] as String,
  dose: json['dose'] as String,
  reminderTimes: (json['reminderTimes'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  startDate: DateTime.parse(json['startDate'] as String),
  durationDays: (json['durationDays'] as num).toInt(),
  isActive: json['isActive'] as bool? ?? true,
);

Map<String, dynamic> _$$MedicineReminderImplToJson(
  _$MedicineReminderImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'medicineName': instance.medicineName,
  'dose': instance.dose,
  'reminderTimes': instance.reminderTimes,
  'startDate': instance.startDate.toIso8601String(),
  'durationDays': instance.durationDays,
  'isActive': instance.isActive,
};
