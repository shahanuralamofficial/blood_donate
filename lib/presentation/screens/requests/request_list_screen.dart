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
      body: requestsAsync.when(
        data: (requests) {
          final filtered = requests.where((r) => 
            r.hospitalName.toLowerCase().contains(_searchQuery) || 
            r.district.toLowerCase().contains(_searchQuery) ||
            r.bloodGroup.toLowerCase().contains(_searchQuery)
          ).toList();

          if (filtered.isEmpty) return _buildEmptyState();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (context, index) => _buildRequestCard(filtered[index]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.red)),
        error: (e, s) => Center(child: Text('এরর: $e')),
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 8))],
        border: isUrgent ? Border.all(color: Colors.red.shade100, width: 1.5) : null,
      ),
      child: Column(
        children: [
          // Header: Requester Info
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _navigateToRequesterProfile(context, req.requesterId),
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.grey.shade200,
                    child: const Icon(Icons.person, size: 16, color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _navigateToRequesterProfile(context, req.requesterId),
                  child: Text(
                    'আবেদনকারী দেখুন',
                    style: TextStyle(color: Colors.blue.shade700, fontSize: 11, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat('dd MMM').format(req.createdAt ?? DateTime.now()),
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
                ),
              ],
            ),
          ),
          const Divider(height: 20, thickness: 0.5),
          // Body: Request Info
          InkWell(
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RequestDetailsScreen(request: req))),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      gradient: isUrgent 
                        ? LinearGradient(colors: [Colors.red, Colors.red.shade800], begin: Alignment.topLeft, end: Alignment.bottomRight)
                        : LinearGradient(colors: [Colors.red.shade50, Colors.red.shade100]),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Center(child: Text(req.bloodGroup, style: TextStyle(color: isUrgent ? Colors.white : Colors.red, fontWeight: FontWeight.bold, fontSize: 20))),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(child: Text(req.patientName.isEmpty ? 'নামহীন রোগী' : req.patientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                            if (isUrgent) ...[
                              const SizedBox(width: 8),
                              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)), child: const Text('জরুরি', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))),
                            ]
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(req.hospitalName, style: TextStyle(color: Colors.grey.shade600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Row(children: [const Icon(Icons.location_on_outlined, size: 12, color: Colors.grey), const SizedBox(width: 4), Text('${req.district}, ${req.thana}', style: TextStyle(color: Colors.grey.shade500, fontSize: 11))]),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.map_rounded, color: Colors.blue, size: 22), onPressed: () => _launchMapUrl(req.mapUrl ?? req.hospitalName)),
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
