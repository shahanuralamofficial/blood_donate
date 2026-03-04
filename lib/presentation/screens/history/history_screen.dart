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
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: Text('ইতিহাস',
              style: GoogleFonts.notoSansBengali(
                  fontWeight: FontWeight.bold, color: Colors.white)),
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
                    context: context,
                    userName: user.name,
                    myRequests: myRequests,
                    myDonations: myDonations,
                  );
                },
                tooltip: 'রিপোর্ট ডাউনলোড',
              ),
            ),
            const SizedBox(width: 8),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelPadding: const EdgeInsets.symmetric(horizontal: 20),
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
            labelStyle: GoogleFonts.notoSansBengali(
                fontWeight: FontWeight.bold, fontSize: 15),
            unselectedLabelStyle: GoogleFonts.notoSansBengali(
                fontWeight: FontWeight.normal, fontSize: 14),
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
            _buildFilteredRequestList(
                myRequestsAsync,
                (req) =>
                    req.status == 'pending' ||
                    req.status == 'accepted' ||
                    req.status == 'donated'),
            _buildFilteredRequestList(
                myRequestsAsync, (req) => req.status == 'completed'),
            _buildRequestList(myDonationsAsync),
            _buildFilteredRequestList(
                myRequestsAsync, (req) => req.status == 'cancelled'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilteredRequestList(
      AsyncValue myRequests, bool Function(dynamic) filter) {
    return myRequests.when(
      data: (requests) {
        final filteredList = requests.where(filter).toList();
        if (filteredList.isEmpty) {
          return _buildEmptyState(Icons.history_rounded, 'কোন তথ্য পাওয়া যায়নি');
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          itemCount: filteredList.length,
          itemBuilder: (context, index) =>
              _buildRequestCard(context, filteredList[index]),
        );
      },
      loading: () =>
          const Center(child: CircularProgressIndicator(color: Colors.red)),
      error: (e, s) => Center(child: Text('এরর: $e')),
    );
  }

  Widget _buildRequestList(AsyncValue myRequests) {
    return myRequests.when(
      data: (requests) {
        if (requests.isEmpty) {
          return _buildEmptyState(
              Icons.volunteer_activism_outlined, 'আপনি এখনো কোন রক্তদান করেননি');
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          itemCount: requests.length,
          itemBuilder: (context, index) =>
              _buildRequestCard(context, requests[index]),
        );
      },
      loading: () =>
          const Center(child: CircularProgressIndicator(color: Colors.red)),
      error: (e, s) => Center(child: Text('এরর: $e')),
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 64, color: Colors.grey.shade300),
          ),
          const SizedBox(height: 16),
          Text(message,
              style: GoogleFonts.notoSansBengali(
                  color: Colors.grey.shade500,
                  fontSize: 16,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildRequestCard(BuildContext context, dynamic req) {
    bool isCompleted = req.status == 'completed';
    bool isCancelled = req.status == 'cancelled';
    bool isUrgent = req.isEmergency ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => RequestDetailsScreen(request: req)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: isUrgent
                            ? Colors.red
                            : (isCancelled
                                ? Colors.grey.shade100
                                : (isCompleted
                                    ? Colors.green.shade50
                                    : const Color(0xFFFDECEA))),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          req.bloodGroup,
                          style: TextStyle(
                            color: isUrgent
                                ? Colors.white
                                : (isCancelled
                                    ? Colors.grey
                                    : (isCompleted
                                        ? Colors.green
                                        : const Color(0xFFE53935))),
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  req.patientName.isEmpty
                                      ? req.hospitalName
                                      : req.patientName,
                                  style: GoogleFonts.notoSansBengali(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: isCancelled
                                        ? Colors.grey
                                        : Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isUrgent) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade600,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'জরুরি',
                                    style: GoogleFonts.notoSansBengali(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            req.hospitalName,
                            style: GoogleFonts.notoSansBengali(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    _buildStatusBadge(req.status),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, thickness: 0.5),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_today_rounded,
                            size: 14, color: Colors.grey.shade400),
                        const SizedBox(width: 6),
                        Text(
                          DateFormat('dd MMM yyyy')
                              .format(req.requiredDate ?? DateTime.now()),
                          style: GoogleFonts.notoSansBengali(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded,
                            size: 14, color: Colors.grey.shade400),
                        const SizedBox(width: 4),
                        Text(
                          req.district ?? '',
                          style: GoogleFonts.notoSansBengali(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.orange;
    String text = status;

    switch (status) {
      case 'completed':
        color = Colors.green;
        text = 'সম্পন্ন';
        break;
      case 'accepted':
        color = Colors.blue;
        text = 'গৃহীত';
        break;
      case 'donated':
        color = Colors.purple;
        text = 'দান করেছেন';
        break;
      case 'pending':
        color = Colors.orange;
        text = 'অপেক্ষমান';
        break;
      case 'cancelled':
        color = Colors.red;
        text = 'বাতিল';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: GoogleFonts.notoSansBengali(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
