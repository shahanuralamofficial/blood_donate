import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const primaryRed = Color(0xFFE53935);
  static const secondaryRed = Color(0xFFFDECEA);
  static const darkGrey = Color(0xFF263238);
  static const softGrey = Color(0xFFF5F5F7);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryRed,
        primary: primaryRed,
        secondary: const Color(0xFFFFA000),
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: softGrey,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: darkGrey,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.notoSansBengali(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: darkGrey,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        labelStyle: const TextStyle(color: primaryRed, fontWeight: FontWeight.bold, fontSize: 14),
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        // ডিফল্ট বর্ডার
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        // যখন সিলেক্ট করা থাকবে না (Idle state)
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        // যখন সিলেক্ট করা হবে (Focused state)
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryRed, width: 1.5),
        ),
        // যখন কোনো এরর থাকবে
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryRed,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      ),
    );
  }
}
