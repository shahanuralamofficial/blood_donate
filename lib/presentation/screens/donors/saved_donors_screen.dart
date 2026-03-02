import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../chat/chat_screen.dart';

class SavedDonorsScreen extends ConsumerWidget {
  const SavedDonorsScreen({super.key});

  Future<void> _makeCall(String phone) async {
    final Uri url = Uri(scheme: 'tel', path: phone);
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint("Call Error: $e");
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userData = ref.watch(currentUserDataProvider).value;
    final savedIds = userData?.savedDonors ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: Text('সেভ করা দাতা', style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFFE53935),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: savedIds.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('এখনো কাউকে সেভ করেননি', style: GoogleFonts.notoSansBengali(color: Colors.grey)),
                ],
              ),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where(FieldPath.documentId, whereIn: savedIds)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.red.shade50,
                          child: Text(data['bloodGroup'] ?? '?', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        ),
                        title: Text(data['name'] ?? 'নাম নেই', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${data['address']?['thana'] ?? ''}, ${data['address']?['district'] ?? ''}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.call, color: Colors.green), onPressed: () => _makeCall(data['phone'])),
                            IconButton(
                              icon: const Icon(Icons.chat_bubble_outline, color: Colors.blue),
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(requestId: 'direct_${docs[index].id}', otherUserName: data['name'])));
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
