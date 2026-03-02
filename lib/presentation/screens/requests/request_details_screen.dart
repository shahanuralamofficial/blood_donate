import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/models/blood_request_model.dart';
import '../../../data/models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/blood_request_provider.dart';
import '../chat/chat_screen.dart';
import '../donors/donor_public_profile_screen.dart';

class RequestDetailsScreen extends ConsumerWidget {
  final BloodRequestModel request;

  const RequestDetailsScreen({super.key, required this.request});

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      await launchUrl(launchUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint("Call Error: $e");
    }
  }

  Future<void> _openMap(String? address) async {
    if (address == null || address.isEmpty) return;
    final Uri url = Uri.parse(
      address.startsWith('http')
          ? address
          : 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}',
    );
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint("Map Error: $e");
    }
  }

  void _navigateToDonorProfile(BuildContext context, String donorId) async {
    final donorDoc = await FirebaseFirestore.instance.collection('users').doc(donorId).get();
    if (donorDoc.exists && context.mounted) {
      final donorUser = UserModel.fromMap(donorDoc.data()!);
      Navigator.push(context, MaterialPageRoute(builder: (_) => DonorPublicProfileScreen(donor: donorUser)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveRequestAsync = ref.watch(requestStreamByIdProvider(request.requestId));
    final user = ref.watch(currentUserDataProvider).value;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFB),
      appBar: AppBar(
        title: Text('আবেদনের বিবরণ', style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold, fontSize: 18)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: liveRequestAsync.when(
        data: (liveRequest) {
          final isRequester = user?.uid == liveRequest.requesterId;
          final isDonor = user?.uid == liveRequest.donorId;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusSection(liveRequest.status),
                const SizedBox(height: 24),
                _buildProgressCard(liveRequest),
                const SizedBox(height: 20),
                _buildInfoCard(liveRequest),
                const SizedBox(height: 24),
                _buildContactCard(context, isRequester, liveRequest),
                const SizedBox(height: 32),

                if (!isRequester && liveRequest.status == 'pending')
                  ElevatedButton(
                    onPressed: () => _showAcceptDonationDialog(context, ref, liveRequest, user!.uid),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, minimumSize: const Size(double.infinity, 56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                    child: const Text('রক্তদানে রাজি হোন', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),

                if (isDonor && liveRequest.status == 'accepted')
                  ElevatedButton(
                    onPressed: () => _updateStatus(context, ref, liveRequest.requestId, 'donated', 'রক্ত দিয়েছেন নিশ্চিত করার জন্য ধন্যবাদ!'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, minimumSize: const Size(double.infinity, 56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                    child: const Text('আমি রক্ত দিয়েছি', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),

                if (isRequester && (liveRequest.status == 'accepted' || liveRequest.status == 'donated'))
                  Column(
                    children: [
                      if (liveRequest.status == 'donated') _buildStatusAlert('রক্তদাতা জানিয়েছেন তিনি রক্ত দিয়েছেন।'),
                      ElevatedButton(
                        onPressed: () => _showConfirmBloodDialog(context, ref, liveRequest),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, minimumSize: const Size(double.infinity, 56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                        child: const Text('রক্ত পেয়েছি', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => _showNotReceivedDialog(context, ref, liveRequest),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red), minimumSize: const Size(double.infinity, 56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                        child: const Text('রক্ত পাইনি', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),

                if (isRequester && (liveRequest.status == 'pending' || liveRequest.status == 'accepted'))
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Center(
                      child: TextButton(onPressed: () => _showCancelDialog(context, ref, liveRequest.requestId, liveRequest.requesterId), child: const Text('আবেদনটি বাতিল করুন', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
                    ),
                  ),

                if (liveRequest.status == 'completed') _buildSuccessMessage(liveRequest),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.red)),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _updateStatus(BuildContext context, WidgetRef ref, String requestId, String status, String message) async {
    try {
      await ref.read(bloodRequestRepositoryProvider).updateRequestStatus(requestId, status);
      if (context.mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message))); Navigator.pop(context); }
    } catch (e) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); }
  }

  void _showAcceptDonationDialog(BuildContext context, WidgetRef ref, BloodRequestModel req, String donorId) {
    int bagsToDonate = 1;
    int remainingBags = req.bloodBags - req.donatedBags;
    if (remainingBags <= 0) remainingBags = 1;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('রক্তদানে রাজি হোন'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('আপনি ${req.patientName}-কে কয় ব্যাগ রক্ত দিতে পারবেন?'),
            const SizedBox(height: 16),
            StatefulBuilder(builder: (context, setState) => DropdownButton<int>(value: bagsToDonate, isExpanded: true, items: List.generate(remainingBags, (index) => index + 1).map((e) => DropdownMenuItem(value: e, child: Text('$e ব্যাগ'))).toList(), onChanged: (v) => setState(() => bagsToDonate = v!))),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('বাতিল')), ElevatedButton(onPressed: () async { await ref.read(bloodRequestRepositoryProvider).acceptRequest(req.requestId, donorId); if (context.mounted) { Navigator.pop(context); Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('রক্তদানে রাজি হওয়ার জন্য ধন্যবাদ!'))); } }, child: const Text('আমি রাজি'))],
      ),
    );
  }

  void _showConfirmBloodDialog(BuildContext context, WidgetRef ref, BloodRequestModel req) {
    int receivedBags = 1; String donationMethod = 'self'; String? currentDonorId = req.donorId; final thankYouController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('রক্তদান নিশ্চিত করুন', style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold)),
        content: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('দাতা কিভাবে রক্ত দিয়েছেন?', style: TextStyle(fontWeight: FontWeight.w600)),
                RadioListTile<String>(title: const Text('নিজে দিয়েছেন'), value: 'self', groupValue: donationMethod, onChanged: (v) => setState(() => donationMethod = v!)),
                RadioListTile<String>(title: const Text('অন্য কারো মাধ্যমে'), value: 'managed', groupValue: donationMethod, onChanged: (v) => setState(() => donationMethod = v!)),
                const Divider(),
                const Text('কয় ব্যাগ পেয়েছেন?', style: TextStyle(fontWeight: FontWeight.w600)),
                DropdownButton<int>(value: receivedBags, isExpanded: true, items: List.generate(req.bloodBags - req.donatedBags + 1, (index) => index + 1).map((e) => DropdownMenuItem(value: e, child: Text('$e ব্যাগ'))).toList(), onChanged: (v) => setState(() => receivedBags = v!)),
                const SizedBox(height: 16),
                TextField(controller: thankYouController, decoration: InputDecoration(labelText: 'রক্তদাতার জন্য ধন্যবাদ বার্তা', hintText: 'একটি সুন্দর বার্তা লিখুন...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: Colors.grey.shade50), maxLines: 3),
              ],
            ),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('পরে করব')), ElevatedButton(onPressed: () async { int totalDonated = req.donatedBags + receivedBags; bool isFullyCompleted = totalDonated >= req.bloodBags; String newStatus = isFullyCompleted ? 'completed' : 'pending'; WriteBatch batch = FirebaseFirestore.instance.batch(); DocumentReference reqRef = FirebaseFirestore.instance.collection('blood_requests').doc(req.requestId); batch.update(reqRef, {'donatedBags': totalDonated, 'status': newStatus, 'donatedBy': donationMethod, 'donorId': currentDonorId, 'thankYouNote': thankYouController.text.trim()}); if (currentDonorId != null) { DocumentReference donorRef = FirebaseFirestore.instance.collection('users').doc(currentDonorId); batch.update(donorRef, {'totalDonations': FieldValue.increment(receivedBags), 'lastDonationDate': FieldValue.serverTimestamp(), 'rankUpdatePending': true}); } DocumentReference requesterRef = FirebaseFirestore.instance.collection('users').doc(req.requesterId); batch.update(requesterRef, {'totalReceivedBags': FieldValue.increment(receivedBags), if (isFullyCompleted) 'totalReceived': FieldValue.increment(1)}); await batch.commit(); if (context.mounted) { Navigator.pop(context); Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('রক্তদান সফলভাবে সম্পন্ন হয়েছে!'))); } if (currentDonorId != null) { _showReviewDialog(context, currentDonorId); } }, child: const Text('নিশ্চিত করুন'))],
      ),
    );
  }

  void _showNotReceivedDialog(BuildContext context, WidgetRef ref, BloodRequestModel req) {
    String? selectedReason; final reasons = ['দাতা আসেননি', 'দাতা টাকা চেয়েছেন', 'দাতা অযোগ্য ছিলেন', 'অন্যান্য'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('রক্ত না পাওয়ার কারণ'),
        content: StatefulBuilder(builder: (context, setState) => Column(mainAxisSize: MainAxisSize.min, children: reasons.map((r) => RadioListTile<String>(title: Text(r), value: r, groupValue: selectedReason, onChanged: (v) => setState(() => selectedReason = v))).toList())),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('বাতিল')), ElevatedButton(onPressed: selectedReason == null ? null : () async { await FirebaseFirestore.instance.collection('blood_requests').doc(req.requestId).update({'status': 'pending', 'donorId': null}); if (context.mounted) { Navigator.pop(context); if (req.donorId != null) { _showReviewDialog(context, req.donorId!); } } }, child: const Text('নিশ্চিত করুন'))],
      ),
    );
  }

  void _showReviewDialog(BuildContext context, String donorId) {
    double rating = 5.0; final commentController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('রক্তদাতাকে রেটিং দিন'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StatefulBuilder(builder: (context, setState) => DropdownButton<double>(value: rating, isExpanded: true, items: [5.0, 4.0, 3.0, 2.0, 1.0].map((e) => DropdownMenuItem(value: e, child: Text('$e স্টার ⭐'))).toList(), onChanged: (v) => setState(() => rating = v!))),
            const SizedBox(height: 12),
            TextField(controller: commentController, decoration: const InputDecoration(hintText: 'মন্তব্য লিখুন')),
          ],
        ),
        actions: [ElevatedButton(onPressed: () async { if (donorId.isNotEmpty) { final donorRef = FirebaseFirestore.instance.collection('users').doc(donorId); await FirebaseFirestore.instance.runTransaction((transaction) async { final snapshot = await transaction.get(donorRef); if (snapshot.exists) { double currentRating = (snapshot.data()?['averageRating'] ?? 5.0).toDouble(); int totalReviews = (snapshot.data()?['totalReviews'] ?? 0) + 1; double newRating = (currentRating * (totalReviews - 1) + rating) / totalReviews; transaction.update(donorRef, {'averageRating': newRating, 'totalReviews': totalReviews}); } }); } if (context.mounted) Navigator.pop(context); }, child: const Text('সাবমিট'))],
      ),
    );
  }

  void _showCancelDialog(BuildContext context, WidgetRef ref, String requestId, String requesterId) {
    String? selectedReason; final reasons = ['রক্ত অফলাইনে পেয়েছি', 'রোগী মারা গেছেন', 'অন্যান্য'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('আবেদন বাতিলের কারণ'),
        content: Column(mainAxisSize: MainAxisSize.min, children: reasons.map((r) => RadioListTile<String>(title: Text(r), value: r, groupValue: selectedReason, onChanged: (v) async { await ref.read(bloodRequestRepositoryProvider).updateRequestStatus(requestId, 'cancelled'); final userRef = FirebaseFirestore.instance.collection('users').doc(requesterId); await userRef.update({'totalCancelled': FieldValue.increment(1)}); if (context.mounted) { Navigator.pop(context); Navigator.pop(context); } })).toList()),
      ),
    );
  }

  Widget _buildStatusSection(String status) {
    Color color = Colors.orange; if (status == 'accepted') color = Colors.blue; if (status == 'donated') color = Colors.purple; if (status == 'completed') color = Colors.green; if (status == 'cancelled') color = Colors.red;
    return Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 20), decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.2))), child: Center(child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2))));
  }

  Widget _buildProgressCard(BloodRequestModel req) {
    double progress = req.bloodBags > 0 ? (req.donatedBags / req.bloodBags) : 0;
    return Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]), child: Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('রক্তের প্রগ্রেস', style: TextStyle(fontWeight: FontWeight.bold)), Text('${req.donatedBags}/${req.bloodBags} ব্যাগ', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold))]), const SizedBox(height: 12), ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: progress, minHeight: 8, color: Colors.red, backgroundColor: Colors.red.shade50))]));
  }

  Widget _buildInfoCard(BloodRequestModel req) {
    return Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]), child: Column(children: [_buildRow('রোগীর নাম', req.patientName, isBold: true), const Divider(height: 24), _buildRow('রক্তের গ্রুপ', req.bloodGroup, isBold: true, color: Colors.red), const Divider(height: 24), _buildRow('হাসপাতাল', req.hospitalName), const SizedBox(height: 12), _buildRow('জেলা', req.district), const SizedBox(height: 12), _buildRow('তারিখ', DateFormat('dd MMM yyyy').format(req.requiredDate ?? DateTime.now()))]));
  }

  Widget _buildContactCard(BuildContext context, bool isRequester, BloodRequestModel req) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15)]),
      child: Row(
        children: [
          const CircleAvatar(radius: 25, backgroundColor: Color(0xFFE53935), child: Icon(Icons.person, color: Colors.white)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('যোগাযোগ করুন', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                GestureDetector(
                  onTap: req.donorId != null ? () => _navigateToDonorProfile(context, req.donorId!) : null,
                  child: Text(
                    isRequester && req.donorId != null ? 'রক্তদাতা: বিস্তারিত দেখুন' : req.phoneNumber,
                    style: TextStyle(color: isRequester && req.donorId != null ? Colors.blue : Colors.grey.shade600, fontSize: 13, decoration: isRequester && req.donorId != null ? TextDecoration.underline : null),
                  ),
                ),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.call, color: Colors.green), onPressed: () => _makePhoneCall(req.phoneNumber)),
          IconButton(icon: const Icon(Icons.chat_bubble_rounded, color: Colors.blue), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(requestId: req.requestId, otherUserName: isRequester ? 'রক্তদাতা' : 'গ্রহীতা')))),
          if (req.mapUrl != null) IconButton(icon: const Icon(Icons.map_rounded, color: Colors.orange), onPressed: () => _openMap(req.mapUrl)),
        ],
      ),
    );
  }

  Widget _buildStatusAlert(String msg) {
    return Container(padding: const EdgeInsets.all(16), margin: const EdgeInsets.only(bottom: 16), width: double.infinity, decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.orange.shade100)), child: Row(children: [const Icon(Icons.info_outline, color: Colors.orange, size: 20), const SizedBox(width: 12), Expanded(child: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 13)))]));
  }

  Widget _buildSuccessMessage(BloodRequestModel req) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.green.shade100)),
      child: Column(
        children: [
          const Icon(Icons.check_circle_rounded, color: Colors.green, size: 60), const SizedBox(height: 16),
          Text('রক্তদান সফল হয়েছে! ❤️', style: GoogleFonts.notoSansBengali(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green.shade800)),
          if (req.thankYouNote != null && req.thankYouNote!.isNotEmpty) ...[
            const SizedBox(height: 24),
            Container(padding: const EdgeInsets.all(20), width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.green.shade100)), child: Column(children: [const Icon(Icons.format_quote_rounded, color: Colors.green, size: 30), const SizedBox(height: 8), Text(req.thankYouNote!, textAlign: TextAlign.center, style: GoogleFonts.notoSansBengali(fontSize: 15, fontStyle: FontStyle.italic, color: Colors.blueGrey.shade800, height: 1.5)), const SizedBox(height: 12), const Text('— গ্রহীতার পক্ষ থেকে', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey))])),
          ],
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false, Color? color}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)), Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: 14, color: color ?? Colors.black87))]);
  }
}
