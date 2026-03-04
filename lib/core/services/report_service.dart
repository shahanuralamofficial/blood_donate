import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../data/models/blood_request_model.dart';

class ReportService {
  /// নিরাপদ ইউনিকোড শেপার যা পিডিএফে বাংলা কার-চিহ্নের অবস্থান ঠিক করবে।
  /// এটি RangeError মুক্ত এবং যুক্তাক্ষর সাপোর্ট করে।
  String _shapeBengali(String? text) {
    if (text == null || text.isEmpty) return '';
    
    final hasBengali = RegExp(r'[\u0980-\u09FF]').hasMatch(text);
    if (!hasBengali) return text;

    try {
      List<int> codeUnits = text.codeUnits;
      List<int> result = [];

      for (int i = 0; i < codeUnits.length; i++) {
        int char = codeUnits[i];
        
        // 'ি' (09BF), 'ে' (09C7), 'ৈ' (09C8) চেক করা
        if (char == 0x09BF || char == 0x09C7 || char == 0x09C8) {
          if (result.isNotEmpty) {
            int last = result.removeLast();
            
            // হসন্ত (09CD) থাকলে এটি যুক্তাক্ষর, আরও এক ধাপ পেছনে যেতে হবে
            if (last == 0x09CD && result.isNotEmpty) {
              int prevChar = result.removeLast();
              result.add(char); // কার আগে আসবে
              result.add(prevChar);
              result.add(last);
            } else {
              result.add(char); // কার আগে আসবে
              result.add(last);
            }
            continue;
          }
        }
        result.add(char);
      }
      return String.fromCharCodes(result);
    } catch (e) {
      debugPrint('Shaping error: $e');
      return text; // ভুল হলে মূল টেক্সট ফেরত দেবে
    }
  }

  Future<void> generateDonationReport({
    required BuildContext context,
    required String userName,
    required List<BloodRequestModel> myRequests,
    required List<BloodRequestModel> myDonations,
  }) async {
    try {
      // অ্যান্ড্রয়েড ১৩+ এর জন্য পারমিশন চেক প্রয়োজন নেই, তবে নিচে এর জন্য হ্যান্ডেল করা আছে
      if (Platform.isAndroid && (await Permission.storage.isDenied)) {
        await Permission.storage.request();
      }

      final pdf = pw.Document();

      // লোগো লোড
      pw.MemoryImage? logoImage;
      try {
        final logoData = await rootBundle.load('assets/images/app_icon.png');
        logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
      } catch (e) {
        debugPrint('Logo loading failed: $e');
      }

      // ফন্ট লোড (ইন্টারনেট কানেকশন প্রয়োজন)
      final fontData = await PdfGoogleFonts.notoSansBengaliRegular();
      final boldFontData = await PdfGoogleFonts.notoSansBengaliBold();

      final completedRequests = myRequests.where((r) => r.status == 'completed').toList();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
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
                      pw.Text(_shapeBengali('রক্তদান রিপোর্ট'), 
                        style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold, color: PdfColors.red900)),
                      pw.Text('Blood Donation Summary Report', 
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                    ],
                  ),
                  if (logoImage != null) pw.Image(logoImage, width: 50, height: 50),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Divider(thickness: 2, color: PdfColors.red800),
              pw.SizedBox(height: 20),
              
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      child: pw.Text('${_shapeBengali('দাতা')}: ${_shapeBengali(userName)}', 
                        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Text('${_shapeBengali('তারিখ')}: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}', 
                      style: const pw.TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 30),
              
              _buildSectionTitle('১. রক্ত গ্রহণ (Received Blood)'),
              pw.SizedBox(height: 10),
              _buildTable(completedRequests, isDonation: false, font: fontData),

              pw.SizedBox(height: 30),

              _buildSectionTitle('২. রক্ত প্রদান (Blood Donated)'),
              pw.SizedBox(height: 10),
              _buildTable(myDonations, isDonation: true, font: fontData),

              pw.Spacer(),
              pw.Divider(thickness: 0.5, color: PdfColors.grey400),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(_shapeBengali('জীবন বাঁচুক রক্তদানে'),
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.red700)),
                  pw.Text(_shapeBengali('সিস্টেম জেনারেটেড রিপোর্ট'),
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                ],
              ),
            ];
          },
        ),
      );

      final bytes = await pdf.save();
      
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => bytes,
        name: 'Blood_Report_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );

    } catch (e) {
      debugPrint('PDF Generation Error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'), 
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  pw.Widget _buildSectionTitle(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(left: 5, bottom: 2),
      decoration: const pw.BoxDecoration(
        border: pw.Border(left: pw.BorderSide(color: PdfColors.red800, width: 4))
      ),
      child: pw.Text(_shapeBengali(title), 
        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900)),
    );
  }

  pw.Widget _buildTable(List<BloodRequestModel> items, {required bool isDonation, required pw.Font font}) {
    if (items.isEmpty) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 10),
        child: pw.Text(_shapeBengali('কোন রেকর্ড পাওয়া যায়নি'), 
          style: const pw.TextStyle(color: PdfColors.grey500, fontSize: 12)),
      );
    }

    return pw.TableHelper.fromTextArray(
      headers: [
        _shapeBengali('তারিখ'),
        _shapeBengali('গ্রুপ'),
        _shapeBengali('হাসপাতাল'),
        _shapeBengali('ব্যাগ')
      ],
      data: items.map((item) => [
        DateFormat('dd/MM/yyyy').format(item.requiredDate ?? item.createdAt ?? DateTime.now()),
        item.bloodGroup, 
        _shapeBengali(item.hospitalName),
        isDonation ? '1' : '${item.donatedBags}/${item.bloodBags}',
      ]).toList(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font, color: PdfColors.white, fontSize: 12),
      cellStyle: pw.TextStyle(font: font, fontSize: 11),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.red800),
      cellHeight: 35,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.center,
        2: pw.Alignment.centerLeft,
        3: pw.Alignment.center,
      },
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
    );
  }
}
