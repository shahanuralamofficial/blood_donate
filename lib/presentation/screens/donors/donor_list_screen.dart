import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/donor_provider.dart';
import '../../providers/auth_provider.dart';
import '../../../core/services/location_service.dart';
import '../chat/chat_screen.dart';

class DonorListScreen extends ConsumerStatefulWidget {
  const DonorListScreen({super.key});

  @override
  ConsumerState<DonorListScreen> createState() => _DonorListScreenState();
}

class _DonorListScreenState extends ConsumerState<DonorListScreen> {
  Position? _currentPosition;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    try {
      final pos = await LocationService().getCurrentPosition();
      setState(() => _currentPosition = pos);
    } catch (e) {
      debugPrint("Location Error: $e");
    }
  }

  double _calculateDistance(double endLat, double endLng) {
    if (_currentPosition == null) return 0.0;
    return Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      endLat,
      endLng,
    ) / 1000;
  }

  Future<void> _makeCall(String phone) async {
    final Uri url = Uri(scheme: 'tel', path: phone);
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint("Call Error: $e");
    }
  }

  Future<void> _toggleSaveDonor(String donorId, List<String> currentlySaved) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    List<String> newList = List.from(currentlySaved);
    if (newList.contains(donorId)) {
      newList.remove(donorId);
    } else {
      newList.add(donorId);
    }

    await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).update({
      'savedDonors': newList,
    });
    ref.invalidate(currentUserDataProvider);
  }

  @override
  Widget build(BuildContext context) {
    final donorsAsync = ref.watch(availableDonorsProvider);
    final userData = ref.watch(currentUserDataProvider).value;
    final savedDonors = userData?.savedDonors ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: Text('রক্তদাতা খুঁজুন', style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFFE53935),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: donorsAsync.when(
              data: (donors) {
                final filteredDonors = donors.where((item) {
                  final name = (item['user'].name ?? '').toString().toLowerCase();
                  final bg = (item['user'].bloodGroup ?? '').toString().toLowerCase();
                  return name.contains(_searchQuery) || bg.contains(_searchQuery);
                }).toList();

                if (filteredDonors.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded, size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('কোন দাতা পাওয়া যায়নি', style: GoogleFonts.notoSansBengali(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                if (_currentPosition != null) {
                  filteredDonors.sort((a, b) {
                    final distA = _calculateDistance(a['donor'].location?.latitude ?? 0, a['donor'].location?.longitude ?? 0);
                    final distB = _calculateDistance(b['donor'].location?.latitude ?? 0, b['donor'].location?.longitude ?? 0);
                    return distA.compareTo(distB);
                  });
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: filteredDonors.length,
                  itemBuilder: (context, index) {
                    final item = filteredDonors[index];
                    final user = item['user'];
                    final donor = item['donor'];
                    final distance = donor.location != null ? _calculateDistance(donor.location!.latitude, donor.location!.longitude) : null;
                    final isSaved = savedDonors.contains(user.uid);
                    final rating = user.averageRating;

                    return _buildDonorCard(user, donor, distance, isSaved, rating);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: Colors.red)),
              error: (e, s) => Center(child: Text('ত্রুটি: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFFE53935),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.black87),
        decoration: InputDecoration(
          hintText: 'নাম বা ব্লাড গ্রুপ দিয়ে খুঁজুন...',
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        ),
        onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
      ),
    );
  }

  Widget _buildDonorCard(user, donor, distance, isSaved, rating) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // বাম পাশের ব্লাড গ্রুপ সেকশন
              Container(
                width: 70,
                color: const Color(0xFFE53935).withOpacity(0.05),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(user.bloodGroup ?? '?', style: const TextStyle(color: Color(0xFFE53935), fontWeight: FontWeight.bold, fontSize: 24)),
                    const Text('গ্রুপ', style: TextStyle(color: Color(0xFFE53935), fontSize: 10)),
                  ],
                ),
              ),
              
              // মাঝখানের তথ্য সেকশন
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${user.name} (রক্তদাতা)',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _toggleSaveDonor(user.uid, (ref.read(currentUserDataProvider).value?.savedDonors ?? [])),
                            child: Icon(isSaved ? Icons.favorite : Icons.favorite_border, color: Colors.orange, size: 22),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, size: 14, color: Colors.blueGrey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${user.address?['thana'] ?? 'অজানা'}, ${user.address?['district'] ?? ''}',
                              style: TextStyle(color: Colors.blueGrey.shade600, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded, color: Colors.orange, size: 16),
                                const SizedBox(width: 2),
                                Text(rating.toStringAsFixed(1), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange)),
                              ],
                            ),
                          ),
                          if (distance != null && distance > 0) ...[
                            const SizedBox(width: 8),
                            Text('• ${distance.toStringAsFixed(1)} কিমি দূরে', style: const TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.w600)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              // ডানপাশের কল ও চ্যাট বাটন
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.call_rounded, color: Colors.green),
                      onPressed: () => _makeCall(user.phone),
                      style: IconButton.styleFrom(backgroundColor: Colors.green.withOpacity(0.1)),
                    ),
                    const SizedBox(height: 8),
                    IconButton(
                      icon: const Icon(Icons.chat_bubble_rounded, color: Colors.blue),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(requestId: 'direct_${user.uid}', otherUserName: user.name)));
                      },
                      style: IconButton.styleFrom(backgroundColor: Colors.blue.withOpacity(0.1)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
