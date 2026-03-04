import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../providers/blood_request_provider.dart';
import '../../../data/models/blood_request_model.dart';
import '../../../data/models/user_model.dart';
import '../donors/donor_public_profile_screen.dart';
import 'request_details_screen.dart';
import 'create_request_screen.dart'; // Added
import 'package:url_launcher/url_launcher.dart';

class RequestListScreen extends ConsumerStatefulWidget {
  const RequestListScreen({super.key});

  @override
  ConsumerState<RequestListScreen> createState() => _RequestListScreenState();
}

class _RequestListScreenState extends ConsumerState<RequestListScreen> {
  String _searchQuery = '';

  Future<void> _launchMapUrl(String address) async {
    final Uri url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}');
    try { await launchUrl(url, mode: LaunchMode.externalApplication); } catch (e) { debugPrint("Map Error: $e"); }
  }

  void _navigateToRequesterProfile(BuildContext context, String requesterId) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(requesterId).get();
    if (doc.exists && context.mounted) {
      final requesterUser = UserModel.fromMap(doc.data()!);
      Navigator.push(context, MaterialPageRoute(builder: (_) => DonorPublicProfileScreen(donor: requesterUser)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(emergencyRequestsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFB),
      appBar: AppBar(
        title: Text('সকল রক্তের আবেদন', style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold, fontSize: 18)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'হাসপাতাল বা জেলা দিয়ে খুঁজুন...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFE53935),
        elevation: 4,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('রক্তের আবেদন', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateRequestScreen())),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(emergencyRequestsProvider);
          await Future.delayed(const Duration(seconds: 1));
        },
        child: requestsAsync.when(
          data: (requests) {
            final filtered = requests.where((r) => 
              r.hospitalName.toLowerCase().contains(_searchQuery) || 
              r.district.toLowerCase().contains(_searchQuery) ||
              r.bloodGroup.toLowerCase().contains(_searchQuery)
            ).toList();

            if (filtered.isEmpty) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.6,
                  alignment: Alignment.center,
                  child: _buildEmptyState(),
                ),
              );
            }

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80), // Extra padding for FAB
              itemCount: filtered.length,
              itemBuilder: (context, index) => _buildRequestCard(filtered[index]),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: Colors.red)),
          error: (e, s) => Center(child: Text('এরর: $e')),
        ),
      ),
    );
  }

  Widget _buildRequestCard(BloodRequestModel req) {
    final bool isUrgent = req.isEmergency;
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
        border: isUrgent ? Border.all(color: Colors.red.shade100, width: 1.5) : null,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _navigateToRequesterProfile(context, req.requesterId),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, size: 14, color: Colors.blue.shade700),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _navigateToRequesterProfile(context, req.requesterId),
                  child: Text(
                    'আবেদনকারী প্রোফাইল',
                    style: GoogleFonts.notoSansBengali(
                      color: Colors.blue.shade700,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat('dd MMM, hh:mm a').format(req.createdAt ?? DateTime.now()),
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade400,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 20, thickness: 0.5),
          ),
          InkWell(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => RequestDetailsScreen(request: req)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: isUrgent
                          ? LinearGradient(colors: [Colors.red.shade400, Colors.red.shade700])
                          : LinearGradient(colors: [Colors.red.shade50, Colors.red.shade100]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: isUrgent
                          ? [
                              BoxShadow(
                                color: Colors.red.withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              )
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        req.bloodGroup,
                        style: TextStyle(
                          color: isUrgent ? Colors.white : Colors.red,
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
                                req.patientName.isEmpty ? 'নামহীন রোগী' : req.patientName,
                                style: GoogleFonts.notoSansBengali(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isUrgent) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.location_on_rounded, size: 14, color: Colors.grey.shade400),
                                const SizedBox(width: 4),
                                Text(
                                  '${req.thana}, ${req.district}',
                                  style: GoogleFonts.notoSansBengali(
                                    color: Colors.grey.shade500,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: () => _launchMapUrl(req.mapUrl ?? req.hospitalName),
                              child: Text(
                                'ম্যাপ দেখুন',
                                style: GoogleFonts.notoSansBengali(
                                  color: Colors.blue.shade700,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.blue.shade700,
                      size: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 80, color: Colors.grey.shade200),
          const SizedBox(height: 16),
          Text('কোন আবেদন পাওয়া যায়নি', style: GoogleFonts.notoSansBengali(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }
}
