import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/blood_request_provider.dart';
import '../../../data/models/blood_request_model.dart';
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
        error: (e, s) => Center(child: Text('ত্রুটি: $e')),
      ),
    );
  }

  Widget _buildRequestCard(BloodRequestModel req) {
    final bool isUrgent = req.isEmergency;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RequestDetailsScreen(request: req))),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  color: isUrgent ? Colors.red : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(child: Text(req.bloodGroup, style: TextStyle(color: isUrgent ? Colors.white : Colors.red, fontWeight: FontWeight.bold, fontSize: 18))),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(req.patientName.isEmpty ? 'নামহীন রোগী' : req.patientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(req.hospitalName, style: TextStyle(color: Colors.grey.shade600, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text('${req.district}, ${req.thana}', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                  ],
                ),
              ),
              if (isUrgent) Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(8)),
                child: const Text('জরুরি', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              IconButton(icon: const Icon(Icons.map_rounded, color: Colors.blue, size: 20), onPressed: () => _launchMapUrl(req.mapUrl ?? req.hospitalName)),
            ],
          ),
        ),
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
