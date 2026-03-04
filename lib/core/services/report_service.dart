import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:bangla_pdf_fixer/bangla_pdf_fixer.dart';
import 'package:printing/printing.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../data/models/blood_request_model.dart';

class ReportService {
  Future<void> generateDonationReport({
    required BuildContext context,
    required String userName,
    required List<BloodRequestModel> myRequests,
    required List<BloodRequestModel> myDonations,
  }) async {
    try {
      // ১. পারমিশন চেক (অ্যান্ড্রয়েড ১৩ এর নিচের জন্য)
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (status.isPermanentlyDenied) {
          openAppSettings();
          return;
        }
      }

      final pdf = pw.Document();

      // Load Logo
      pw.MemoryImage? logoImage;
      try {
        final logoData = await rootBundle.load('assets/images/app_icon.png');
        logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
      } catch (e) {
        debugPrint('Logo loading failed: $e');
      }

      // Load Bengali Font (Google Fonts is more reliable)
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
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('রক্তদান রিপোর্ট'.fix(), 
                        style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                      pw.Text('(Blood Donation Report)', 
                        style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
                    ],
                  ),
                  if (logoImage != null) pw.Image(logoImage, width: 60, height: 60),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Text('${'ব্যবহারকারীর নাম'.fix()}: ${userName.fix()}'),
              pw.Text('${'রিপোর্ট তৈরির তারিখ'.fix()}: ${DateFormat('dd MMM yyyy').format(DateTime.now()).fix()}'),
              pw.Divider(),
              
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 10),
                child: pw.Text('১. রক্ত গ্রহণ করেছেন (Received Blood)'.fix(), 
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              ),
              _buildTable(completedRequests, isDonation: false, font: fontData),

              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 10),
                child: pw.Text('২. রক্ত প্রদান করেছেন (Blood Donated)'.fix(), 
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              ),
              _buildTable(myDonations, isDonation: true, font: fontData),

              pw.SizedBox(height: 40),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text('সিস্টেম জেনারেটেড রিপোর্ট - রক্তদান অ্যাপ'.fix(),
                  style: pw.TextStyle(color: PdfColors.grey)),
              ),
            ];
          },
        ),
      );

      final bytes = await pdf.save();
      final fileName = 'Blood_Report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      
      // ✅ ১০০% ফিক্সড মেথড: Printing.layoutPdf ব্যবহার করলে ইউজার সরাসরি সেভ/ডাউনলোড করতে পারে
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => bytes,
        name: fileName,
      );

    } catch (e) {
      debugPrint('PDF Generation Error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  pw.Widget _buildTable(List<BloodRequestModel> items, {required bool isDonation, required pw.Font font}) {
    if (items.isEmpty) return pw.Text('কোন তথ্য পাওয়া যায়নি (No records found).'.fix());

    return pw.TableHelper.fromTextArray(
      headers: [
        'তারিখ'.fix(),
        'গ্রুপ'.fix(),
        'হাসপাতাল'.fix(),
        'ব্যাগ'.fix()
      ],
      data: items.map((item) => [
        DateFormat('dd/MM/yyyy').format(item.requiredDate ?? item.createdAt ?? DateTime.now()).fix(),
        item.bloodGroup.fix(),
        item.hospitalName.fix(),
        (isDonation ? '1' : '${item.donatedBags}/${item.bloodBags}').fix(),
      ]).toList(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font),
      cellStyle: pw.TextStyle(font: font),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      cellHeight: 25,
      cellAlignment: pw.Alignment.centerLeft,
    );
  }
}
