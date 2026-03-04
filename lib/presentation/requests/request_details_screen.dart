import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/blood_request_model.dart';
import '../providers/auth_provider.dart';
import '../providers/blood_request_provider.dart';
import '../screens/chat/chat_screen.dart';

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // রিয়েল-টাইম ডাটা লিসেন করার জন্য স্ট্রিম প্রোভাইডার
    final liveRequestAsync = ref.watch(requestStreamByIdProvider(request.requestId));
    final user = ref.watch(currentUserDataProvider).value;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text('আবেদনের বিবরণ'),
        elevation: 0,
      ),
      body: liveRequestAsync.when(
        data: (liveRequest) {
          final isRequester = user?.uid == liveRequest.requesterId;
          final isDonor = user?.uid == liveRequest.donorId;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusSection(liveRequest.status),
                const SizedBox(height: 20),
                _buildInfoCard(liveRequest),
                const SizedBox(height: 24),
                
                _buildContactCard(context, isRequester, liveRequest),
                
                const SizedBox(height: 32),
                
                if (!isRequester && liveRequest.status == 'pending')
                  ElevatedButton(
                    onPressed: () => _acceptRequest(context, ref, liveRequest.requestId, user!.uid),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, minimumSize: const Size(double.infinity, 56)),
                    child: const Text('রক্তদানে রাজি হোন', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                
                if (isDonor && liveRequest.status == 'accepted')
                  ElevatedButton(
                    onPressed: () => _updateStatus(context, ref, liveRequest.requestId, 'donated', 'রক্ত দিয়েছেন নিশ্চিত করার জন্য ধন্যবাদ!'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, minimumSize: const Size(double.infinity, 56)),
                    child: const Text('আমি রক্ত দিয়েছি', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),

                if (isRequester && (liveRequest.status == 'accepted' || liveRequest.status == 'donated'))
                  Column(
                    children: [
                      if (liveRequest.status == 'donated')
                        Container(
                          padding: const EdgeInsets.all(16),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50, 
                            borderRadius: BorderRadius.circular(12), 
                            border: Border.all(color: Colors.orange.shade200)
                          ),
                          child: const Text(
                            'রক্তদাতা জানিয়েছেন তিনি রক্ত দিয়েছেন। আপনি কি রক্ত পেয়েছেন?',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                          ),
                        ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _updateStatus(context, ref, liveRequest.requestId, 'completed', 'ধন্যবাদ! আবেদনটি সম্পন্ন করা হয়েছে।'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, minimumSize: const Size(double.infinity, 56)),
                        child: const Text('হ্যাঁ, রক্ত পেয়েছি (নিশ্চিত করুন)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),

                if (liveRequest.status == 'completed')
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text('অভিনন্দন! এই রক্তদান সফলভাবে সম্পন্ন হয়েছে। ❤️', 
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green), textAlign: TextAlign.center),
                    ),
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('ত্রুটি: $e')),
      ),
    );
  }

  Widget _buildStatusSection(String status) {
    Color color = Colors.grey;
    String text = 'অজানা';
    switch (status) {
      case 'pending': color = Colors.orange; text = 'অপেক্ষমান'; break;
      case 'accepted': color = Colors.blue; text = 'দাতা পাওয়া গেছে'; break;
      case 'donated': color = Colors.purple; text = 'রক্ত দেওয়া হয়েছে'; break;
      case 'completed': color = Colors.green; text = 'সম্পন্ন হয়েছে'; break;
      case 'cancelled': color = Colors.red; text = 'বাতিল'; break;
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
      child: Center(
        child: Text(text, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildInfoCard(BloodRequestModel req) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildRow('রক্তের গ্রুপ', req.bloodGroup, isBold: true),
            const Divider(),
            _buildRow('হাসপাতাল', req.hospitalName),
            _buildRow('রোগীর সমস্যা', req.patientProblem),
            _buildRow('জেলা', req.district),
            _buildRow('তারিখ', DateFormat('dd MMM yyyy').format(req.requiredDate ?? DateTime.now())),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(BuildContext context, bool isRequester, BloodRequestModel req) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const CircleAvatar(backgroundColor: Colors.red, radius: 25, child: Icon(Icons.person, color: Colors.white)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('যোগাযোগ করুন', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(req.phoneNumber, style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            ),
            IconButton(icon: const Icon(Icons.call, color: Colors.green, size: 30), onPressed: () => _makePhoneCall(req.phoneNumber)),
            IconButton(
              icon: const Icon(Icons.chat_bubble_rounded, color: Colors.blue, size: 30),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(requestId: req.requestId, otherUserName: isRequester ? 'রক্তদাতা' : 'গ্রহীতা')));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.blueGrey)),
          Expanded(child: Text(value, textAlign: TextAlign.right, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: 15))),
        ],
      ),
    );
  }

  void _acceptRequest(BuildContext context, WidgetRef ref, String requestId, String donorId) async {
    try {
      await ref.read(bloodRequestRepositoryProvider).acceptRequest(requestId, donorId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('রক্তদানে রাজি হওয়ার জন্য ধন্যবাদ!')));
      }
    } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ত্রুটি: $e')));
    }
  }

  void _updateStatus(BuildContext context, WidgetRef ref, String requestId, String status, String message) async {
     try {
      await ref.read(bloodRequestRepositoryProvider).updateRequestStatus(requestId, status);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ত্রুটি: $e')));
    }
  }
}
