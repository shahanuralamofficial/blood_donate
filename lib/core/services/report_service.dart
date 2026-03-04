import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
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
      // অ্যান্ড্রয়েড স্টোরেজ পারমিশন চেক
      if (Platform.isAndroid && (await Permission.storage.isDenied)) {
        await Permission.storage.request();
      }

      // অ্যাপ লোগোকে Base64 এ রূপান্তর (পিডিএফে দেখানোর জন্য)
      String logoBase64 = "";
      try {
        final logoData = await rootBundle.load('assets/images/app_icon.png');
        logoBase64 = base64Encode(logoData.buffer.asUint8List());
      } catch (e) {
        debugPrint('Logo loading error: $e');
      }

      final completedRequests = myRequests.where((r) => r.status == 'completed').toList();
      final dateToday = DateFormat('dd/MM/yyyy').format(DateTime.now());

      // ১. রক্ত গ্রহণ টেবিলের ডাটা তৈরি
      final receivedRows = completedRequests.isEmpty 
        ? '<tr><td colspan="4" class="empty-msg">কোন রেকর্ড পাওয়া যায়নি</td></tr>'
        : completedRequests.map((item) => """
            <tr>
                <td>${DateFormat('dd/MM/yyyy').format(item.requiredDate ?? item.createdAt ?? DateTime.now())}</td>
                <td style="text-align: center">${item.bloodGroup}</td>
                <td>${item.hospitalName}</td>
                <td style="text-align: center">${item.donatedBags}/${item.bloodBags}</td>
            </tr>
          """).join();

      // ২. রক্ত দান টেবিলের ডাটা তৈরি
      final donationRows = myDonations.isEmpty 
        ? '<tr><td colspan="4" class="empty-msg">কোন রেকর্ড পাওয়া যায়নি</td></tr>'
        : myDonations.map((item) => """
            <tr>
                <td>${DateFormat('dd/MM/yyyy').format(item.requiredDate ?? item.createdAt ?? DateTime.now())}</td>
                <td style="text-align: center">${item.bloodGroup}</td>
                <td>${item.hospitalName}</td>
                <td style="text-align: center">১</td>
            </tr>
          """).join();

      // প্রফেশনাল HTML টেম্পলেট (যা বাংলা যুক্তাক্ষর ১০০% সঠিক দেখাবে)
      final htmlContent = """
<!DOCTYPE html>
<html lang="bn">
<head>
    <meta charset="UTF-8">
    <style>
        body {
            font-family: 'Arial', sans-serif;
            margin: 0;
            padding: 30px;
            color: #333;
        }
        .header-container {
            display: flex;
            justify-content: space-between;
            align-items: center;
            border-bottom: 3px solid #b71c1c;
            padding-bottom: 10px;
            margin-bottom: 25px;
        }
        .header-text h1 {
            color: #b71c1c;
            margin: 0;
            font-size: 28px;
        }
        .header-text p {
            margin: 0;
            color: #666;
            font-size: 12px;
        }
        .logo {
            width: 60px;
            height: 60px;
        }
        .info-box {
            background-color: #f8f9fa;
            padding: 15px;
            border-radius: 8px;
            display: flex;
            justify-content: space-between;
            margin-bottom: 30px;
            border: 1px solid #eee;
        }
        .section-title {
            border-left: 5px solid #b71c1c;
            padding-left: 10px;
            margin: 25px 0 15px 0;
            font-size: 18px;
            font-weight: bold;
            color: #2c3e50;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 20px;
        }
        th {
            background-color: #b71c1c;
            color: white;
            text-align: left;
            padding: 10px;
            font-size: 14px;
        }
        td {
            border: 1px solid #eee;
            padding: 10px;
            font-size: 13px;
        }
        tr:nth-child(even) {
            background-color: #fcfcfc;
        }
        .footer {
            margin-top: 50px;
            border-top: 1px solid #eee;
            padding-top: 15px;
            display: flex;
            justify-content: space-between;
            font-size: 11px;
            color: #888;
        }
        .empty-msg {
            text-align: center;
            color: #999;
            padding: 20px;
        }
    </style>
</head>
<body>
    <div class="header-container">
        <div class="header-text">
            <h1>রক্তদান রিপোর্ট</h1>
            <p>Blood Donation Summary Report</p>
        </div>
        ${logoBase64.isNotEmpty ? '<img src="data:image/png;base64,$logoBase64" class="logo">' : ''}
    </div>

    <div class="info-box">
        <div><strong>দাতা:</strong> $userName</div>
        <div><strong>তারিখ:</strong> $dateToday</div>
    </div>

    <div class="section-title">১. রক্ত গ্রহণ (Received Blood)</div>
    <table>
        <thead>
            <tr>
                <th>তারিখ</th>
                <th style="text-align: center">গ্রুপ</th>
                <th>হাসপাতাল</th>
                <th style="text-align: center">ব্যাগ</th>
            </tr>
        </thead>
        <tbody>
            $receivedRows
        </tbody>
    </table>

    <div class="section-title">২. রক্ত প্রদান (Blood Donated)</div>
    <table>
        <thead>
            <tr>
                <th>তারিখ</th>
                <th style="text-align: center">গ্রুপ</th>
                <th>হাসপাতাল</th>
                <th style="text-align: center">ব্যাগ</th>
            </tr>
        </thead>
        <tbody>
            $donationRows
        </tbody>
    </table>

    <div class="footer">
        <div><em>"জীবন বাঁচুক রক্তদানে"</em></div>
        <div>সিস্টেম জেনারেটেড রিপোর্ট - রক্তদান অ্যাপ</div>
    </div>
</body>
</html>
""";

      // Printing প্যাকেজ ব্যবহার করে HTML-কে সরাসরি পিডিএফে রূপান্তর। 
      // এটি ফোনের সিস্টেম ইঞ্জিন ব্যবহার করে, তাই বাংলা যুক্তাক্ষর ১০০% নিখুঁত হবে।
      await Printing.layoutPdf(
        onLayout: (format) async => await Printing.convertHtml(
          html: htmlContent,
          format: format,
        ),
        name: 'Blood_Report_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );

    } catch (e) {
      debugPrint('PDF Generation Error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
