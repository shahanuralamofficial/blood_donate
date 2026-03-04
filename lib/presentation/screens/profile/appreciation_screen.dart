import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/blood_request_provider.dart';
import '../requests/request_details_screen.dart';

class AppreciationScreen extends ConsumerWidget {
  const AppreciationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myDonationsAsync = ref.watch(myDonationsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFB),
      appBar: AppBar(
        title: Text('প্রাপ্ত ধন্যবাদ বার্তা', style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold, fontSize: 18)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: myDonationsAsync.when(
        data: (donations) {
          final notes = donations.where((d) => d.status == 'completed' && d.thankYouNote != null && d.thankYouNote!.isNotEmpty).toList();

          if (notes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border_rounded, size: 80, color: Colors.grey.shade200),
                  const SizedBox(height: 16),
                  Text('এখনো কোনো ধন্যবাদ বার্তা পাননি', style: GoogleFonts.notoSansBengali(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final req = notes[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                  border: Border.all(color: Colors.pink.shade50),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(backgroundColor: Colors.pink.shade50, child: const Icon(Icons.favorite, color: Colors.pink, size: 20)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(req.patientName.isEmpty ? 'নামহীন রোগী' : req.patientName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text(req.hospitalName, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '"${req.thankYouNote}"',
                      style: GoogleFonts.notoSansBengali(fontStyle: FontStyle.italic, color: Colors.blueGrey.shade800, height: 1.5),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RequestDetailsScreen(request: req))),
                      child: Text('আবেদনের বিস্তারিত দেখুন', style: TextStyle(color: Colors.pink.shade700, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.red)),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
