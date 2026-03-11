import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../providers/medicine_reminder_provider.dart';
import '../../providers/language_provider.dart';

class MedicineReminderScreen extends ConsumerWidget {
  const MedicineReminderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminders = ref.watch(medicineReminderProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(ref.tr('medicine_reminders'), style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFE53935),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _showAddManualReminderDialog(context, ref),
          ),
        ],
      ),
      body: reminders.isEmpty
          ? _buildEmptyState(context, ref)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: reminders.length,
              itemBuilder: (context, index) {
                final reminder = reminders[index];
                return _buildReminderCard(context, ref, reminder);
              },
            ),
    );
  }

  void _showAddManualReminderDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final doseController = TextEditingController();
    final times = ValueNotifier<List<TimeOfDay>>([const TimeOfDay(hour: 8, minute: 0)]);
    int duration = 7;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(ref.tr('add_reminder'), style: GoogleFonts.notoSansBengali(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: ref.tr('medicine_name'),
                  hintText: ref.tr('enter_medicine_name'),
                  prefixIcon: const Icon(Icons.medication),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: doseController,
                      decoration: InputDecoration(
                        labelText: ref.tr('dose'),
                        hintText: ref.tr('enter_dose'),
                        prefixIcon: const Icon(Icons.numbers),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: duration,
                      decoration: InputDecoration(
                        labelText: ref.tr('duration_days'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: [3, 5, 7, 10, 14, 30].map((d) => DropdownMenuItem(value: d, child: Text("$d ${ref.tr('days_remaining').split(' ').last}"))).toList(),
                      onChanged: (val) => setState(() => duration = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(ref.tr('select_times'), style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ValueListenableBuilder<List<TimeOfDay>>(
                valueListenable: times,
                builder: (context, currentTimes, _) => Wrap(
                  spacing: 8,
                  children: [
                    ...currentTimes.asMap().entries.map((entry) => Chip(
                          label: Text(entry.value.format(context)),
                          onDeleted: currentTimes.length > 1 ? () => times.value = List.from(times.value)..removeAt(entry.key) : null,
                        )),
                    ActionChip(
                      avatar: const Icon(Icons.add, size: 16),
                      label: Text(ref.tr('add_time')),
                      onPressed: () async {
                        final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                        if (picked != null) times.value = List.from(times.value)..add(picked);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    if (nameController.text.isNotEmpty && doseController.text.isNotEmpty) {
                      ref.read(medicineReminderProvider.notifier).addReminder(
                            name: nameController.text,
                            dose: doseController.text,
                            times: times.value.map((t) => t.format(context)).toList(),
                            duration: duration,
                          );
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ref.tr('medicine_added'))));
                    }
                  },
                  child: Text(ref.tr('save_reminder'), style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 20),
          Text(
            ref.tr('no_reminders'),
            style: GoogleFonts.notoSansBengali(fontSize: 18, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            ref.tr('scan_to_add_reminder'),
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSansBengali(fontSize: 14, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderCard(BuildContext context, WidgetRef ref, dynamic reminder) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: reminder.isActive ? Colors.red.shade50 : Colors.grey.shade100,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: reminder.isActive ? Colors.red.shade100 : Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.medication_rounded,
                      color: reminder.isActive ? Colors.red : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reminder.medicineName,
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "${ref.tr('dose')}: ${reminder.dose}",
                          style: GoogleFonts.notoSansBengali(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: reminder.isActive,
                    activeColor: Colors.red,
                    onChanged: (val) {
                      ref.read(medicineReminderProvider.notifier).toggleReminder(reminder.id);
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.access_time_rounded, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: reminder.reminderTimes.map<Widget>((time) {
                          return Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              time,
                              style: const TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                    onPressed: () {
                      ref.read(medicineReminderProvider.notifier).deleteReminder(reminder.id);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
