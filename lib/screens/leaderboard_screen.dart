import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../game_state.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final lb = gs.leaderboard.take(10).toList();
    const medals = ['🥇','🥈','🥉'];

    return Scaffold(
      backgroundColor: const Color(0xFF0D0221),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A0A3B),
        foregroundColor: Colors.white,
        title: Text('🏆  لیدربرد جهانی',
          style: GoogleFonts.vazirmatn(fontSize: 18, fontWeight: FontWeight.w700,
            color: const Color(0xFFFFD700))),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: lb.length,
        itemBuilder: (ctx, i) {
          final e = lb[i];
          final isTop3 = i < 3;
          return AnimatedContainer(
            duration: Duration(milliseconds: 200 + i * 50),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: i == 0
                ? const Color(0xFFFFD700).withOpacity(.1)
                : const Color(0xFF1A0A3B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: i == 0
                  ? const Color(0xFFFFD700).withOpacity(.4)
                  : const Color(0xFF3D2080),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    isTop3 ? medals[i] : '${i+1}',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.vazirmatn(
                      fontSize: isTop3 ? 20 : 14,
                      fontWeight: FontWeight.w900,
                      color: i == 0 ? const Color(0xFFFFD700)
                        : i == 1 ? const Color(0xFFC0C0C0)
                        : i == 2 ? const Color(0xFFCD7F32)
                        : const Color(0xFFa89bc2),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(e.avatar, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(e.name,
                    style: GoogleFonts.vazirmatn(fontSize: 14, fontWeight: FontWeight.w600)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D1B69),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('${e.wins} برد',
                    style: GoogleFonts.vazirmatn(fontSize: 11, color: const Color(0xFFa89bc2))),
                ),
                const SizedBox(width: 8),
                Text('${e.trophies} 🏆',
                  style: GoogleFonts.vazirmatn(
                    fontSize: 15, fontWeight: FontWeight.w900, color: const Color(0xFFFFD700))),
              ],
            ),
          );
        },
      ),
    );
  }
}
