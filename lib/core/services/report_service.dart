import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../data/models/blood_request_model.dart';

class ReportService {
  Future<void> generateDonationReport({
    required String userName,
    required List<BloodRequestModel> myRequests,
    required List<BloodRequestModel> myDonations,
  }) async {
    // ১. পারমিশন চেক (অ্যান্ড্রয়েড ১০ এর নিচের জন্য প্রয়োজন হতে পারে)
    if (Platform.isAndroid) {
      await Permission.storage.request();
    }

    final pdf = pw.Document();
    final completedRequests = myRequests.where((r) => r.status == 'completed').toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text('Blood Donation Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 10),
            pw.Text('User: $userName'),
            pw.Text('Report Date: ${DateFormat('dd MMM yyyy').format(DateTime.now())}'),
            pw.Divider(),
            
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 10),
              child: pw.Text('1. Received Blood (Success)', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            ),
            _buildTable(completedRequests, isDonation: false),

            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 10),
              child: pw.Text('2. Blood Donated to Others', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            ),
            _buildTable(myDonations, isDonation: true),

            pw.SizedBox(height: 40),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text('System Generated Report - Blood Donate App', style: const pw.TextStyle(color: PdfColors.grey)),
            ),
          ];
        },
      ),
    );

    try {
      // ২. ফাইল লোকেশন খুঁজে বের করা (সরাসরি ডাউনলোড ফোল্ডার)
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      final String fileName = 'Blood_Report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final String filePath = '${directory!.path}/$fileName';
      final file = File(filePath);

      // ৩. পিডিএফ সেভ করা
      await file.writeAsBytes(await pdf.save());
      
      print('PDF saved to: $filePath');
      // আপনি চাইলে এখানে একটি লোকাল নোটিফিকেশন বা স্ন্যাকবার দেখাতে পারেন
    } catch (e) {
      print('PDF Save Error: $e');
    }
  }

  pw.Widget _buildTable(List<BloodRequestModel> items, {required bool isDonation}) {
    if (items.isEmpty) return pw.Text('No records found.');

    return pw.Table.fromTextArray(
      headers: ['Date', 'Blood Group', 'Hospital', 'Bags'],
      data: items.map((item) => [
        DateFormat('dd/MM/yyyy').format(item.requiredDate ?? item.createdAt ?? DateTime.now()),
        item.bloodGroup,
        item.hospitalName,
        isDonation ? '1' : '${item.donatedBags}/${item.bloodBags}',
      ]).toList(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      cellHeight: 25,
    );
  }
}
