import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/models/user_model.dart';

class RankProgressScreen extends StatelessWidget {
  final UserModel user;
  const RankProgressScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    // Rank logic: 
    // Newbie: 0, Bronze: 1+, Silver: 5+, Gold: 15+, Platinum: 30+, Diamond: 50+
    int nextGoal = 1;
    String nextRank = 'Bronze';
    if (user.totalDonations >= 30) { nextGoal = 50; nextRank = 'Diamond'; }
    else if (user.totalDonations >= 15) { nextGoal = 30; nextRank = 'Platinum'; }
    else if (user.totalDonations >= 5) { nextGoal = 15; nextRank = 'Gold'; }
    else if (user.totalDonations >= 1) { nextGoal = 5; nextRank = 'Silver'; }
    else { nextGoal = 1; nextRank = 'Bronze'; }

    double progress = user.totalDonations / nextGoal;
    if (progress > 1.0) progress = 1.0;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFB),
      appBar: AppBar(
        title: Text('র‍্যাঙ্ক প্রগ্রেস', style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold, fontSize: 18)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildCurrentRankDisplay(),
            const SizedBox(height: 32),
            _buildProgressCard(progress, nextGoal, nextRank),
            const SizedBox(height: 32),
            _buildRankLadder(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentRankDisplay() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.amber.shade400, Colors.orange.shade800]),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: const Icon(Icons.stars_rounded, color: Colors.white, size: 80),
        ),
        const SizedBox(height: 20),
        Text('বর্তমান র‍্যাঙ্ক', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
        Text(user.rank.toUpperCase(), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.black87)),
      ],
    );
  }

  Widget _buildProgressCard(double progress, int goal, String next) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15)],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('পরবর্তী লক্ষ্য', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('$next ($goal ব্যাগ)', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: Colors.red.shade50,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'আপনি এখন পর্যন্ত ${user.totalDonations} ব্যাগ রক্ত দান করেছেন।',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildRankLadder() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('র‍্যাঙ্ক লিস্ট', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildRankRow('DIAMOND', '৫০+ ব্যাগ রক্ত দান', Colors.blue),
        _buildRankRow('PLATINUM', '৩০+ ব্যাগ রক্ত দান', Colors.purple),
        _buildRankRow('GOLD', '১৫+ ব্যাগ রক্ত দান', Colors.amber.shade700),
        _buildRankRow('SILVER', '৫+ ব্যাগ রক্ত দান', Colors.grey.shade600),
        _buildRankRow('BRONZE', '১+ ব্যাগ রক্ত দান', Colors.orange.shade800),
        _buildRankRow('NEWBIE', '০ রক্ত দান', Colors.grey.shade400),
      ],
    );
  }

  Widget _buildRankRow(String title, String desc, Color color) {
    bool isCurrent = user.rank.toUpperCase() == title;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrent ? color.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isCurrent ? Border.all(color: color, width: 1.5) : Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.military_tech_rounded, color: color),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                Text(desc, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              ],
            ),
          ),
          if (isCurrent) Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
            child: const Text('CURRENT', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
