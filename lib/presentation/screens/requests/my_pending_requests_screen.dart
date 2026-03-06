import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/blood_request_provider.dart';
import '../../providers/language_provider.dart';
import 'request_details_screen.dart';

class MyPendingRequestsScreen extends ConsumerWidget {
  const MyPendingRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myRequestsAsync = ref.watch(myRequestsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFB),
      appBar: AppBar(
        title: Text(ref.tr('my_pending_requests'), style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold, fontSize: 18)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: myRequestsAsync.when(
        data: (requests) {
          final pending = requests.where((r) => r.status == 'pending').toList();

          if (pending.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.hourglass_empty_rounded, size: 80, color: Colors.grey.shade200),
                  const SizedBox(height: 16),
                  Text(ref.tr('no_pending_requests_msg'), style: GoogleFonts.notoSansBengali(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pending.length,
            itemBuilder: (context, index) {
              final req = pending[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
                  border: Border.all(color: Colors.orange.shade50),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.orange.shade50, shape: BoxShape.circle),
                    child: const Icon(Icons.timer_outlined, color: Colors.orange),
                  ),
                  title: Text(req.hospitalName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(ref.tr('blood_req_group').replaceFirst('{}', req.bloodGroup), style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RequestDetailsScreen(request: req))),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.red)),
        error: (e, s) => Center(child: Text('${ref.tr('error')}: $e')),
      ),
    );
  }
}
