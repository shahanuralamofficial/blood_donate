import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/blood_request_provider.dart';
import '../requests/request_details_screen.dart';
import '../../../core/services/report_service.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserDataProvider).value;
    if (user == null) return const Scaffold(body: Center(child: Text('লগইন প্রয়োজন')));

    final myRequestsAsync = ref.watch(myRequestsProvider);
    final myDonationsAsync = ref.watch(myDonationsProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F7),
        appBar: AppBar(
          title: Text('ইতিহাস', style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: const Color(0xFFE53935),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
              onPressed: () {
                final myRequests = myRequestsAsync.value ?? [];
                final myDonations = myDonationsAsync.value ?? [];
                ReportService().generateDonationReport(
                  userName: user.name,
                  myRequests: myRequests,
                  myDonations: myDonations,
                );
              },
              tooltip: 'রিপোর্ট ডাউনলোড',
            )
          ],
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelPadding: const EdgeInsets.symmetric(horizontal: 20),
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withOpacity(0.7),
            labelStyle: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold, fontSize: 15),
            unselectedLabelStyle: GoogleFonts.notoSansBengali(fontWeight: FontWeight.normal, fontSize: 14),
            tabs: const [
              Tab(text: 'আমার আবেদন'),
              Tab(text: 'রক্ত পেয়েছি'),
              Tab(text: 'আমার রক্তদান'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // ১. আমার আবেদন (পেন্ডিং, একসেপ্টেড এবং বাতিল - সব এখানে থাকবে)
            _buildFilteredRequestList(myRequestsAsync, (req) => req.status != 'completed'),
            
            // ২. রক্ত পেয়েছি (শুধুমাত্র সম্পন্ন হওয়াগুলো)
            _buildFilteredRequestList(myRequestsAsync, (req) => req.status == 'completed'),
            
            // ৩. আমার রক্তদান
            _buildRequestList(myDonationsAsync),
          ],
        ),
      ),
    );
  }

  Widget _buildFilteredRequestList(AsyncValue myRequests, bool Function(dynamic) filter) {
    return myRequests.when(
      data: (requests) {
        final filteredList = requests.where(filter).toList();
        if (filteredList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history_rounded, size: 60, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text('কোন তথ্য পাওয়া যায়নি', style: GoogleFonts.notoSansBengali(color: Colors.blueGrey)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredList.length,
          itemBuilder: (context, index) => _buildRequestCard(context, filteredList[index]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: Colors.red)),
      error: (e, s) => Center(child: Text('এরর: $e')),
    );
  }

  Widget _buildRequestList(AsyncValue myRequests) {
    return myRequests.when(
      data: (requests) {
        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.volunteer_activism_outlined, size: 60, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text('কোন তথ্য পাওয়া যায়নি', style: GoogleFonts.notoSansBengali(color: Colors.blueGrey)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) => _buildRequestCard(context, requests[index]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: Colors.red)),
      error: (e, s) => Center(child: Text('এরর: $e')),
    );
  }

  Widget _buildRequestCard(BuildContext context, dynamic req) {
    bool isCancelled = req.status == 'cancelled';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isCancelled ? Colors.grey.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isCancelled ? Border.all(color: Colors.grey.shade200) : null,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: isCancelled ? Colors.grey.shade200 : const Color(0xFFFDECEA), 
            borderRadius: BorderRadius.circular(12)
          ),
          child: Center(
            child: Text(
              req.bloodGroup, 
              style: TextStyle(color: isCancelled ? Colors.grey : Color(0xFFE53935), fontWeight: FontWeight.bold, fontSize: 16)
            )
          ),
        ),
        title: Text(
          req.hospitalName, 
          style: GoogleFonts.notoSansBengali(
            fontWeight: FontWeight.bold, 
            fontSize: 15, 
            color: isCancelled ? Colors.grey : Colors.black87
          )
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text('তারিখ: ${DateFormat('dd MMM yyyy').format(req.requiredDate ?? DateTime.now())}', style: GoogleFonts.notoSansBengali(color: Colors.grey.shade700, fontSize: 12)),
        ),
        trailing: _buildStatusChip(req.status),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => RequestDetailsScreen(request: req)),
          );
        },
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color = Colors.orange;
    String text = status;
    switch (status) {
      case 'completed': color = Colors.green; text = 'সম্পন্ন'; break;
      case 'accepted': color = Colors.blue; text = 'গৃহীত'; break;
      case 'donated': color = Colors.purple; text = 'রক্ত দেওয়া হয়েছে'; break;
      case 'pending': color = Colors.orange; text = 'অপেক্ষমান'; break;
      case 'cancelled': color = Colors.red; text = 'বাতিল'; break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Text(
        text,
        style: GoogleFonts.notoSansBengali(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
