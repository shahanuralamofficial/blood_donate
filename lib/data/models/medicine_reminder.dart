import 'package:freezed_annotation/freezed_annotation.dart';

part 'medicine_reminder.freezed.dart';
part 'medicine_reminder.g.dart';

@freezed
class MedicineReminder with _$MedicineReminder {
  const factory MedicineReminder({
    required String id,
    required String medicineName,
    required String dose, // e.g., 1+0+1
    required List<String> reminderTimes, // e.g., ["08:00", "14:00", "20:00"]
    required DateTime startDate,
    required int durationDays,
    @Default(true) bool isActive,
  }) = _MedicineReminder;

  factory MedicineReminder.fromJson(Map<String, dynamic> json) => _$MedicineReminderFromJson(json);
}
