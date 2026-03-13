import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/language_provider.dart';
import 'medicine_reminder_screen.dart';

class PrescriptionReaderScreen extends ConsumerWidget {
  const PrescriptionReaderScreen({super.key});

  void _showComingSoonSnackBar(BuildContext context, WidgetRef ref) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.auto_awesome_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Text(ref.tr('coming_soon')),
          ],
        ),
        backgroundColor: Colors.blueGrey.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(ref.tr('prescription_reader'), style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFE53935),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [const Color(0xFFE53935).withOpacity(0.05), Colors.white],
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
                      ),
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(color: Colors.red.withOpacity(0.15), shape: BoxShape.circle),
                      ),
                      Icon(Icons.edit_note_rounded, size: 70, color: Colors.red.shade600),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Text(
                    ref.tr('prescription_reader'),
                    style: GoogleFonts.notoSansBengali(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    ref.tr('feature_under_development'),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.notoSansBengali(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
                  ),
                  const SizedBox(height: 50),
                  
                  // Manual Add Button (Active)
                  _buildActionButton(
                    icon: Icons.add_circle_outline_rounded,
                    label: ref.tr('add_reminder_manually'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MedicineReminderScreen()),
                      );
                    },
                    isPrimary: true,
                  ),
                  
                  const SizedBox(height: 30),
                  const Divider(),
                  const SizedBox(height: 20),
                  
                  Text(
                    ref.tr('ai_health_features'),
                    style: GoogleFonts.notoSansBengali(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 15),
                  
                  // Camera & Gallery (Marked as Coming Soon)
                  Row(
                    children: [
                      Expanded(
                        child: _buildComingSoonButton(
                          context, 
                          ref,
                          icon: Icons.camera_alt_outlined, 
                          label: ref.tr('camera'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildComingSoonButton(
                          context, 
                          ref,
                          icon: Icons.photo_library_outlined, 
                          label: ref.tr('gallery'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Helpful Reminder
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: Colors.blue.shade700, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "আপনি এখন ম্যানুয়ালি ওষুধের নাম ও সময় লিখে রিমাইন্ডার সেট করতে পারেন।",
                      style: GoogleFonts.notoSansBengali(
                        fontSize: 12,
                        color: Colors.blue.shade900,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required VoidCallback onTap, bool isPrimary = false}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: (isPrimary ? Colors.red : Colors.grey).withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 24),
        label: Text(label, style: GoogleFonts.notoSansBengali(fontSize: 16, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? const Color(0xFFE53935) : Colors.white,
          foregroundColor: isPrimary ? Colors.white : Colors.black87,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildComingSoonButton(BuildContext context, WidgetRef ref, {required IconData icon, required String label}) {
    return InkWell(
      onTap: () => _showComingSoonSnackBar(context, ref),
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.grey.shade500),
            const SizedBox(height: 8),
            Text(label, style: GoogleFonts.notoSansBengali(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              ref.tr('coming_soon'),
              style: const TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}
