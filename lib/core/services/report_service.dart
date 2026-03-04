import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import '../../data/models/blood_request_model.dart';

class ReportService {
  Future<void> generateDonationReport({
    required String userName,
    required List<BloodRequestModel> myRequests,
    required List<BloodRequestModel> myDonations,
  }) async {
    try {
      // ১. পারমিশন চেক (অ্যান্ড্রয়েড ১০ এর নিচের জন্য প্রয়োজন হতে পারে)
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          // Alternative permission check for Android 13+
          await Permission.manageExternalStorage.request();
        }
      }

      final pdf = pw.Document();
      
      // Load Bengali Font (Using Google Fonts Noto Sans Bengali as fallback)
      final fontData = await PdfGoogleFonts.notoSansBengaliRegular();
      final boldFontData = await PdfGoogleFonts.notoSansBengaliBold();

      final completedRequests = myRequests.where((r) => r.status == 'completed').toList();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          theme: pw.ThemeData.withFont(
            base: fontData,
            bold: boldFontData,
          ),
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Text('রক্তদান রিপোর্ট (Blood Donation Report)', 
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 10),
              pw.Text('ব্যবহারকারীর নাম: $userName'),
              pw.Text('রিপোর্ট তৈরির তারিখ: ${DateFormat('dd MMM yyyy').format(DateTime.now())}'),
              pw.Divider(),
              
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 10),
                child: pw.Text('১. রক্ত গ্রহণ করেছেন (Received Blood)', 
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              ),
              _buildTable(completedRequests, isDonation: false, font: fontData),

              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 10),
                child: pw.Text('২. রক্ত প্রদান করেছেন (Blood Donated)', 
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              ),
              _buildTable(myDonations, isDonation: true, font: fontData),

              pw.SizedBox(height: 40),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text('সিস্টেম জেনারেটেড রিপোর্ট - রক্তদান অ্যাপ', 
                  style: const pw.TextStyle(color: PdfColors.grey)),
              ),
            ];
          },
        ),
      );

      // ২. সরাসরি ফাইল সেভ এবং ডাউনলোড ফোল্ডারে পাঠানো
      final bytes = await pdf.save();
      final fileName = 'Blood_Report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      
      // এই মেথডটি সরাসরি ফাইলে সেভ করবে এবং ইউজারকে ডাউনলোডের সুযোগ দেবে
      await Printing.sharePdf(
        bytes: bytes, 
        filename: fileName,
      );

    } catch (e) {
      debugPrint('PDF Generation Error: $e');
    }
  }

  pw.Widget _buildTable(List<BloodRequestModel> items, {required bool isDonation, required pw.Font font}) {
    if (items.isEmpty) return pw.Text('কোন তথ্য পাওয়া যায়নি (No records found).');

    return pw.Table.fromTextArray(
      headers: ['তারিখ (Date)', 'গ্রুপ (Group)', 'হাসপাতাল (Hospital)', 'ব্যাগ (Bags)'],
      data: items.map((item) => [
        DateFormat('dd/MM/yyyy').format(item.requiredDate ?? item.createdAt ?? DateTime.now()),
        item.bloodGroup,
        item.hospitalName,
        isDonation ? '1' : '${item.donatedBags}/${item.bloodBags}',
      ]).toList(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font),
      cellStyle: pw.TextStyle(font: font),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      cellHeight: 25,
      cellAlignment: pw.Alignment.centerLeft,
    );
  }
}
