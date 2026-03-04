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
      length: 4,
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFB),
        appBar: AppBar(
          title: Text('ইতিহাস', style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: const Color(0xFFE53935),
          elevation: 0,
          actions: [
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
                onPressed: () async {
                  final myRequests = myRequestsAsync.value ?? [];
                  final myDonations = myDonationsAsync.value ?? [];
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('রিপোর্ট তৈরি হচ্ছে...')),
                  );

                  await ReportService().generateDonationReport(
                    userName: user.name,
                    myRequests: myRequests,
                    myDonations: myDonations,
                  );
                },
                tooltip: 'রিপোর্ট ডাউনলোড',
              ),
            )
          ],
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelPadding: const EdgeInsets.symmetric(horizontal: 20),
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
            labelStyle: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold, fontSize: 15),
            unselectedLabelStyle: GoogleFonts.notoSansBengali(fontWeight: FontWeight.normal, fontSize: 14),
            tabs: const [
              Tab(text: 'রক্তের আবেদন'),
              Tab(text: 'রক্ত পেয়েছি'),
              Tab(text: 'আমার রক্তদান'),
              Tab(text: 'বাতিল'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // ১. আমার আবেদন (Pending/Accepted)
            _buildFilteredRequestList(myRequestsAsync, (req) => req.status == 'pending' || req.status == 'accepted' || req.status == 'donated'),
            
            // ২. রক্ত পেয়েছি (Completed)
            _buildFilteredRequestList(myRequestsAsync, (req) => req.status == 'completed'),
            
            // ৩. আমার রক্তদান (Where you will find the Thank You Note)
            _buildRequestList(myDonationsAsync),

            // ৪. বাতিল করা আবেদন
            _buildFilteredRequestList(myRequestsAsync, (req) => req.status == 'cancelled'),
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
          return _buildEmptyState(Icons.history_rounded, 'কোন তথ্য পাওয়া যায়নি');
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
          return _buildEmptyState(Icons.volunteer_activism_outlined, 'আপনি এখনো কোন রক্তদান করেননি');
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

  Widget _buildEmptyState(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey.shade200),
          const SizedBox(height: 16),
          Text(message, style: GoogleFonts.notoSansBengali(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildRequestCard(BuildContext context, dynamic req) {
    bool isCompleted = req.status == 'completed';
    bool isCancelled = req.status == 'cancelled';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
        border: isCompleted ? Border.all(color: Colors.green.withValues(alpha: 0.3), width: 1) : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: isCancelled ? Colors.grey.shade100 : (isCompleted ? Colors.green.shade50 : const Color(0xFFFDECEA)), 
            borderRadius: BorderRadius.circular(15)
          ),
          child: Center(
            child: Text(
              req.bloodGroup, 
              style: TextStyle(
                color: isCancelled ? Colors.grey : (isCompleted ? Colors.green : const Color(0xFFE53935)), 
                fontWeight: FontWeight.bold, 
                fontSize: 18
              )
            )
          ),
        ),
        title: Text(
          req.patientName.isEmpty ? req.hospitalName : req.patientName, 
          style: GoogleFonts.notoSansBengali(
            fontWeight: FontWeight.bold, 
            fontSize: 16, 
            color: isCancelled ? Colors.grey : Colors.black87
          )
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(req.hospitalName, style: TextStyle(fontSize: 12, color: Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text('তারিখ: ${DateFormat('dd MMM yyyy').format(req.requiredDate ?? DateTime.now())}', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
          ],
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
    IconData icon = Icons.timer_rounded;

    switch (status) {
      case 'completed': 
        color = Colors.green; text = 'সম্পন্ন'; icon = Icons.check_circle_rounded; break;
      case 'accepted': 
        color = Colors.blue; text = 'গৃহীত'; icon = Icons.handshake_rounded; break;
      case 'donated': 
        color = Colors.purple; text = 'দান করেছেন'; icon = Icons.volunteer_activism_rounded; break;
      case 'pending': 
        color = Colors.orange; text = 'অপেক্ষমান'; icon = Icons.hourglass_empty_rounded; break;
      case 'cancelled': 
        color = Colors.red; text = 'বাতিল'; icon = Icons.cancel_rounded; break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.notoSansBengali(color: color, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
