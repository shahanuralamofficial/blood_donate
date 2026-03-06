import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../providers/auth_provider.dart';
import '../chat/chat_screen.dart';

import '../../providers/language_provider.dart';

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

  Future<void> _openWhatsApp(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    String cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (!cleanPhone.startsWith('88')) {
      cleanPhone = '88$cleanPhone';
    }
    final Uri url = Uri.parse("https://wa.me/$cleanPhone");
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint("WhatsApp Error: $e");
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userData = ref.watch(currentUserDataProvider).value;
    final savedIds = userData?.savedDonors ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: Text(ref.tr('saved_donors_title'), style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold, color: Colors.white)),
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
                  Text(ref.tr('no_saved_donors'), style: GoogleFonts.notoSansBengali(color: Colors.grey)),
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

                final docs = snapshot.data!.docs.where((doc) => doc.id != userData?.uid).toList();

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.favorite_border, size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(ref.tr('no_saved_donors'), style: GoogleFonts.notoSansBengali(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final donorId = docs[index].id;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          onTap: () {
                            // Optionally navigate to public profile
                          },
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                data['bloodGroup'] ?? '?',
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            data['name'] ?? ref.tr('unknown'),
                            style: GoogleFonts.notoSansBengali(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            '${data['address']?['thana'] ?? ''}, ${data['address']?['district'] ?? ''}',
                            style: GoogleFonts.notoSansBengali(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildActionCircle(
                                icon: Icons.call,
                                color: Colors.green,
                                onTap: () => _makeCall(data['phone']),
                              ),
                              const SizedBox(width: 8),
                              _buildActionCircle(
                                icon: FontAwesomeIcons.whatsapp,
                                color: const Color(0xFF25D366),
                                isFontAwesome: true,
                                onTap: () => _openWhatsApp(data['whatsappNumber'] ?? data['phone']),
                              ),
                              const SizedBox(width: 8),
                              _buildActionCircle(
                                icon: Icons.chat_bubble_outline,
                                color: Colors.blue,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ChatScreen(
                                        requestId: 'direct_$donorId',
                                        otherUserName: data['name'],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildActionCircle({
    required dynamic icon,
    required Color color,
    required VoidCallback onTap,
    bool isFontAwesome = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: isFontAwesome
            ? FaIcon(icon as IconData, color: color, size: 18)
            : Icon(icon as IconData, color: color, size: 18),
      ),
    );
  }
}
