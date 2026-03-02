import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: Text('নোটিফিকেশন', style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFFE53935),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none_rounded, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'এখনো কোনো নতুন নোটিফিকেশন নেই',
              style: GoogleFonts.notoSansBengali(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
