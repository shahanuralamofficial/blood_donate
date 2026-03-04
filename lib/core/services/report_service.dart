import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:bangla_pdf_fixer/bangla_pdf_fixer.dart';
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
      
      // Load Logo with error handling
      pw.MemoryImage? logoImage;
      try {
        final logoData = await rootBundle.load('assets/images/app_icon.png');
        logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
      } catch (e) {
        debugPrint('Logo loading failed: $e');
      }
      
      // Load Bengali Font
      pw.Font? fontData;
      pw.Font? boldFontData;
      try {
        fontData = await PdfGoogleFonts.notoSansBengaliRegular();
        boldFontData = await PdfGoogleFonts.notoSansBengaliBold();
      } catch (e) {
        debugPrint('Font loading failed: $e');
        // Fallback to standard font if Google Fonts fails
        fontData = pw.Font.helvetica();
        boldFontData = pw.Font.helveticaBold();
      }

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
                        style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, font: boldFontData)),
                      pw.Text('(Blood Donation Report)', 
                        style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
                    ],
                  ),
                  if (logoImage != null) pw.Image(logoImage, width: 60, height: 60),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Text('${'ব্যবহারকারীর নাম'.fix()}: ${userName.fix()}', style: pw.TextStyle(font: fontData)),
              pw.Text('${'রিপোর্ট তৈরির তারিখ'.fix()}: ${DateFormat('dd MMM yyyy').format(DateTime.now()).fix()}', style: pw.TextStyle(font: fontData)),
              pw.Divider(),
              
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 10),
                child: pw.Text('১. রক্ত গ্রহণ করেছেন (Received Blood)'.fix(), 
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, font: boldFontData)),
              ),
              _buildTable(completedRequests, isDonation: false, font: fontData ?? pw.Font.helvetica()),

              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 10),
                child: pw.Text('২. রক্ত প্রদান করেছেন (Blood Donated)'.fix(), 
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, font: boldFontData)),
              ),
              _buildTable(myDonations, isDonation: true, font: fontData ?? pw.Font.helvetica()),

              pw.SizedBox(height: 40),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text('সিস্টেম জেনারেটেড রিপোর্ট - রক্তদান অ্যাপ'.fix(),
                  style: pw.TextStyle(color: PdfColors.grey, font: fontData)),
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
    if (items.isEmpty) return pw.Text('কোন তথ্য পাওয়া যায়নি (No records found).'.fix());

    return pw.TableHelper.fromTextArray(
      headers: [
        'তারিখ (Date)'.fix(),
        'গ্রুপ (Group)'.fix(),
        'হাসপাতাল (Hospital)'.fix(),
        'ব্যাগ (Bags)'.fix()
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
