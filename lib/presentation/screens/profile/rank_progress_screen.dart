import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/models/user_model.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/language_provider.dart';
import '../../../data/models/user_model.dart';

class RankProgressScreen extends ConsumerWidget {
  final UserModel user;
  const RankProgressScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Rank logic: 
    // Newbie: 0, Bronze: 1+, Silver: 5+, Gold: 15+, Platinum: 30+, Diamond: 50+
    int nextGoal = 1;
    String nextRankKey = 'rank_bronze';
    if (user.totalDonations >= 30) { nextGoal = 50; nextRankKey = 'rank_diamond'; }
    else if (user.totalDonations >= 15) { nextGoal = 30; nextRankKey = 'rank_platinum'; }
    else if (user.totalDonations >= 5) { nextGoal = 15; nextRankKey = 'rank_gold'; }
    else if (user.totalDonations >= 1) { nextGoal = 5; nextRankKey = 'rank_silver'; }
    else { nextGoal = 1; nextRankKey = 'rank_bronze'; }

    double progress = user.totalDonations / nextGoal;
    if (progress > 1.0) progress = 1.0;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFB),
      appBar: AppBar(
        title: Text(ref.tr('rank_progress'), style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold, fontSize: 18)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildCurrentRankDisplay(ref),
            const SizedBox(height: 32),
            _buildProgressCard(ref, progress, nextGoal, ref.tr(nextRankKey)),
            const SizedBox(height: 32),
            _buildRankLadder(ref),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentRankDisplay(WidgetRef ref) {
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
        Text(ref.tr('current_rank'), style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
        Text(ref.tr('rank_${user.rank.toLowerCase()}').toUpperCase(), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.black87)),
      ],
    );
  }

  Widget _buildProgressCard(WidgetRef ref, double progress, int goal, String next) {
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
              Text(ref.tr('next_goal'), style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('$next ($goal ${goal > 1 ? ref.tr('bags_count') : ref.tr('bag_count')})', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
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
            '${ref.tr('donated_total_prefix')}${user.totalDonations} ${user.totalDonations > 1 ? ref.tr('bags_count') : ref.tr('bag_count')}${ref.tr('donated_total_suffix')}',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildRankLadder(WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(ref.tr('rank_list'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildRankRow(ref, 'DIAMOND', 'rank_diamond', ref.tr('rank_diamond_desc'), Colors.blue),
        _buildRankRow(ref, 'PLATINUM', 'rank_platinum', ref.tr('rank_platinum_desc'), Colors.purple),
        _buildRankRow(ref, 'GOLD', 'rank_gold', ref.tr('rank_gold_desc'), Colors.amber.shade700),
        _buildRankRow(ref, 'SILVER', 'rank_silver', ref.tr('rank_silver_desc'), Colors.grey.shade600),
        _buildRankRow(ref, 'BRONZE', 'rank_bronze', ref.tr('rank_bronze_desc'), Colors.orange.shade800),
        _buildRankRow(ref, 'NEWBIE', 'rank_newbie', ref.tr('rank_newbie_desc'), Colors.grey.shade400),
      ],
    );
  }

  Widget _buildRankRow(WidgetRef ref, String rawTitle, String key, String desc, Color color) {
    bool isCurrent = user.rank.toUpperCase() == rawTitle;
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
                Text(ref.tr(key).toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                Text(desc, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              ],
            ),
          ),
          if (isCurrent) Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
            child: Text(ref.tr('current'), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
