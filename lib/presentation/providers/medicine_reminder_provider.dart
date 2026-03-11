import 'dart:convert';
import 'package:blood_donate/core/services/notification_service.dart';
import 'package:blood_donate/data/models/medicine_reminder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

final medicineReminderProvider = StateNotifierProvider<MedicineReminderNotifier, List<MedicineReminder>>((ref) {
  return MedicineReminderNotifier();
});

class MedicineReminderNotifier extends StateNotifier<List<MedicineReminder>> {
  MedicineReminderNotifier() : super([]) {
    _loadReminders();
  }

  static const _storageKey = 'medicine_reminders';

  Future<void> _loadReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_storageKey);
    if (data != null) {
      final List<dynamic> decoded = jsonDecode(data);
      state = decoded.map((item) => MedicineReminder.fromJson(item)).toList();
    }
  }

  Future<void> _saveReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final String data = jsonEncode(state.map((item) => item.toJson()).toList());
    await prefs.setString(_storageKey, data);
  }

  Future<void> addReminder({
    required String name,
    required String dose,
    required List<String> times,
    required int duration,
  }) async {
    final newReminder = MedicineReminder(
      id: const Uuid().v4(),
      medicineName: name,
      dose: dose,
      reminderTimes: times,
      startDate: DateTime.now(),
      durationDays: duration,
    );

    state = [...state, newReminder];
    await _saveReminders();
    
    // Schedule notifications for each time
    for (int i = 0; i < times.length; i++) {
      await NotificationService().showLocalNotification(
        id: newReminder.id.hashCode + i,
        title: "ওষুধ খাওয়ার সময় হয়েছে",
        body: "${newReminder.medicineName} খাওয়ার সময় হয়েছে (${newReminder.dose})",
        payload: jsonEncode({'type': 'medicine_reminder', 'id': newReminder.id}),
      );
    }
  }

  Future<void> toggleReminder(String id) async {
    state = [
      for (final r in state)
        if (r.id == id) r.copyWith(isActive: !r.isActive) else r
    ];
    await _saveReminders();
  }

  Future<void> deleteReminder(String id) async {
    state = state.where((r) => r.id != id).toList();
    await _saveReminders();
  }
}
