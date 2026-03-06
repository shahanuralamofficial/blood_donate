import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/blood_request_provider.dart';
import '../requests/request_details_screen.dart';
import '../../../core/services/report_service.dart';

import '../../../presentation/providers/language_provider.dart';

class HistoryScreen extends ConsumerWidget {
  final int initialIndex;
  const HistoryScreen({super.key, this.initialIndex = 0});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserDataProvider).value;
    if (user == null) return Scaffold(body: Center(child: Text(ref.tr('login_required'))));

    final myRequestsAsync = ref.watch(myRequestsProvider);
    final myDonationsAsync = ref.watch(myDonationsProvider);

    return DefaultTabController(
      key: ValueKey(initialIndex), // Add a key to force rebuild when index changes
      length: 4,
      initialIndex: initialIndex,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: Text(ref.tr('history'),
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
                    SnackBar(content: Text(ref.tr('report_generating'))),
                  );

                  await ReportService().generateDonationReport(
                    context: context,
                    userName: user.name,
                    myRequests: myRequests,
                    myDonations: myDonations,
                  );
                },
                tooltip: ref.tr('download_report'),
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
            unselectedLabelColor: Colors.white.withOpacity(0.7),
            labelStyle: GoogleFonts.notoSansBengali(
                fontWeight: FontWeight.bold, fontSize: 15),
            unselectedLabelStyle: GoogleFonts.notoSansBengali(
                fontWeight: FontWeight.normal, fontSize: 14),
            tabs: [
              Tab(text: ref.tr('blood_request')),
              Tab(text: ref.tr('received_blood')),
              Tab(text: ref.tr('my_donations')),
              Tab(text: ref.tr('cancelled')),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildFilteredRequestList(
                ref,
                myRequestsAsync,
                (req) =>
                    req.status == 'pending' ||
                    req.status == 'accepted' ||
                    req.status == 'donated'),
            _buildFilteredRequestList(
                ref, myRequestsAsync, (req) => req.status == 'completed'),
            _buildRequestList(ref, myDonationsAsync),
            _buildFilteredRequestList(
                ref, myRequestsAsync, (req) => req.status == 'cancelled'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilteredRequestList(
      WidgetRef ref, AsyncValue myRequests, bool Function(dynamic) filter) {
    return myRequests.when(
      data: (requests) {
        final filteredList = requests.where(filter).toList();
        if (filteredList.isEmpty) {
          return _buildEmptyState(ref, Icons.history_rounded, ref.tr('no_data_found'));
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          itemCount: filteredList.length,
          itemBuilder: (context, index) =>
              _buildRequestCard(context, ref, filteredList[index]),
        );
      },
      loading: () =>
          const Center(child: CircularProgressIndicator(color: Colors.red)),
      error: (e, s) => Center(child: Text('${ref.tr('error')}: $e')),
    );
  }

  Widget _buildRequestList(WidgetRef ref, AsyncValue myRequests) {
    return myRequests.when(
      data: (requests) {
        if (requests.isEmpty) {
          return _buildEmptyState(ref,
              Icons.volunteer_activism_outlined, ref.tr('no_donations_yet'));
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          itemCount: requests.length,
          itemBuilder: (context, index) =>
              _buildRequestCard(context, ref, requests[index]),
        );
      },
      loading: () =>
          const Center(child: CircularProgressIndicator(color: Colors.red)),
      error: (e, s) => Center(child: Text('${ref.tr('error')}: $e')),
    );
  }

  Widget _buildEmptyState(WidgetRef ref, IconData icon, String message) {
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

  Widget _buildRequestCard(BuildContext context, WidgetRef ref, dynamic req) {
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
            color: Colors.black.withOpacity(0.04),
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
                                    ref.tr('emergency'),
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
                    _buildStatusBadge(ref, req.status),
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
                          DateFormat('dd MMM yyyy', ref.watch(languageProvider).languageCode)
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

  Widget _buildStatusBadge(WidgetRef ref, String status) {
    Color color = Colors.orange;
    String text = ref.tr(status);

    switch (status) {
      case 'completed':
        color = Colors.green;
        break;
      case 'accepted':
        color = Colors.blue;
        break;
      case 'donated':
        color = Colors.purple;
        break;
      case 'pending':
        color = Colors.orange;
        break;
      case 'cancelled':
        color = Colors.red;
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
