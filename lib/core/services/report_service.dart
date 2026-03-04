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

      // HTML স্পেশাল ক্যারেক্টার এস্কেপ করা
      String escape(String text) => text.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');

      // ১. রক্ত গ্রহণ টেবিলের ডাটা তৈরি
      final receivedRows = completedRequests.isEmpty 
        ? '<tr><td colspan="4" class="empty-msg">কোন রেকর্ড পাওয়া যায়নি</td></tr>'
        : completedRequests.map((item) => """
            <tr>
                <td>${DateFormat('dd/MM/yyyy').format(item.requiredDate ?? item.createdAt ?? DateTime.now())}</td>
                <td style="text-align: center; font-weight: bold;">${item.bloodGroup}</td>
                <td>${escape(item.hospitalName)}</td>
                <td style="text-align: center">${item.donatedBags}/${item.bloodBags}</td>
            </tr>
          """).join();

      // ২. রক্ত দান টেবিলের ডাটা তৈরি
      final donationRows = myDonations.isEmpty 
        ? '<tr><td colspan="4" class="empty-msg">কোন রেকর্ড পাওয়া যায়নি</td></tr>'
        : myDonations.map((item) => """
            <tr>
                <td>${DateFormat('dd/MM/yyyy').format(item.requiredDate ?? item.createdAt ?? DateTime.now())}</td>
                <td style="text-align: center; font-weight: bold;">${item.bloodGroup}</td>
                <td>${escape(item.hospitalName)}</td>
                <td style="text-align: center">১</td>
            </tr>
          """).join();

      // প্রফেশনাল HTML টেম্পলেট (যা বাংলা যুক্তাক্ষর ১০০% সঠিক দেখাবে)
      final htmlContent = """
<!DOCTYPE html>
<html lang="bn">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link href="https://fonts.googleapis.com/css2?family=Noto+Sans+Bengali:wght@400;700&display=swap" rel="stylesheet">
    <style>
        * { box-sizing: border-box; }
        body {
            font-family: 'Noto Sans Bengali', 'Arial', sans-serif;
            margin: 0;
            padding: 40px;
            color: #333;
            background: white;
            line-height: 1.5;
        }
        .header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            border-bottom: 4px solid #D32F2F;
            padding-bottom: 15px;
            margin-bottom: 30px;
        }
        .header-info h1 {
            color: #D32F2F;
            margin: 0;
            font-size: 32px;
            font-weight: 700;
        }
        .header-info p {
            margin: 5px 0 0 0;
            color: #757575;
            font-size: 14px;
            letter-spacing: 1px;
        }
        .logo { width: 70px; height: 70px; object-fit: contain; }
        .user-card {
            background-color: #F5F5F5;
            padding: 20px;
            border-radius: 12px;
            display: flex;
            justify-content: space-between;
            margin-bottom: 40px;
            border: 1px solid #E0E0E0;
        }
        .user-card div { font-size: 16px; }
        .user-card strong { color: #D32F2F; }
        .section-title {
            display: flex;
            align-items: center;
            margin: 30px 0 15px 0;
            font-size: 20px;
            font-weight: 700;
            color: #1A237E;
        }
        .section-title::before {
            content: "";
            display: inline-block;
            width: 6px;
            height: 24px;
            background: #D32F2F;
            margin-right: 12px;
            border-radius: 3px;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 30px;
            border-radius: 8px;
            overflow: hidden;
            box-shadow: 0 2px 5px rgba(0,0,0,0.05);
        }
        th {
            background-color: #D32F2F;
            color: white;
            text-align: left;
            padding: 14px;
            font-size: 15px;
        }
        td {
            border-bottom: 1px solid #EEEEEE;
            padding: 12px 14px;
            font-size: 14px;
            color: #424242;
        }
        tr:last-child td { border-bottom: none; }
        tr:nth-child(even) { background-color: #FAFAFA; }
        .footer {
            margin-top: 60px;
            border-top: 2px solid #EEEEEE;
            padding-top: 20px;
            display: flex;
            justify-content: space-between;
            font-size: 12px;
            color: #9E9E9E;
        }
        .empty-msg {
            text-align: center;
            color: #9E9E9E;
            padding: 30px;
            font-style: italic;
        }
    </style>
</head>
<body>
    <div class="header">
        <div class="header-info">
            <h1>রক্তদান রিপোর্ট</h1>
            <p>BLOOD DONATION SUMMARY REPORT</p>
        </div>
        ${logoBase64.isNotEmpty ? '<img src="data:image/png;base64,$logoBase64" class="logo">' : ''}
    </div>

    <div class="user-card">
        <div><strong>দাতা:</strong> ${escape(userName)}</div>
        <div><strong>তারিখ:</strong> $dateToday</div>
    </div>

    <div class="section-title">১. রক্ত গ্রহণ (Received Blood)</div>
    <table>
        <thead>
            <tr>
                <th style="width: 20%">তারিখ</th>
                <th style="width: 15%; text-align: center">গ্রুপ</th>
                <th style="width: 45%">হাসপাতাল</th>
                <th style="width: 20%; text-align: center">ব্যাগ</th>
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
                <th style="width: 20%">তারিখ</th>
                <th style="width: 15%; text-align: center">গ্রুপ</th>
                <th style="width: 45%">হাসপাতাল</th>
                <th style="width: 20%; text-align: center">ব্যাগ</th>
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

      // HTML কে সরাসরি পিডিএফে রূপান্তর (সবচেয়ে নির্ভরযোগ্য পদ্ধতি)
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
