import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../../data/models/blood_request_model.dart';

class ReportService {
  Future<void> generateDonationReport({
    required String userName,
    required List<BloodRequestModel> myRequests,
    required List<BloodRequestModel> myDonations,
  }) async {
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

    // পয়েন্ট ৬: সরাসরি ফাইলে সেভ এবং প্রিন্ট প্রিভিউ
    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Blood_Report_${DateFormat('dd_MMM_yyyy').format(DateTime.now())}.pdf'
      );
    } catch (e) {
      print('PDF Error: $e');
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
