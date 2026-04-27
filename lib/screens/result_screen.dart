import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../game_state.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final isWin = gs.gameResult == 'win';
    final isDraw = gs.gameResult == 'draw';

    String emoji = isWin ? '🏆' : isDraw ? '🤝' : '😢';
    String title = isWin ? 'برنده شدید!' : isDraw ? 'مساوی!' : 'باختید!';
    Color titleColor = isWin ? const Color(0xFFFFD700)
      : isDraw ? const Color(0xFFC77DFF)
      : const Color(0xFFFF4D6D);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0221),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            colors: [Color(0xFF3D0066), Color(0xFF0D0221)],
            center: Alignment.topCenter,
            radius: 1.5,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A0A3B),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF3D2080), width: 2),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 72)),
                    const SizedBox(height: 12),
                    Text(title,
                      style: GoogleFonts.vazirmatn(
                        fontSize: 28, fontWeight: FontWeight.w900, color: titleColor)),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _ScoreCard(
                          avatar: gs.p1Avatar, name: gs.p1Name,
                          score: gs.scores[0], isWinner: gs.scores[0] > gs.scores[1]),
                        const SizedBox(width: 16),
                        _ScoreCard(
                          avatar: '🤖', name: 'هوش مصنوعی',
                          score: gs.scores[1], isWinner: gs.scores[1] > gs.scores[0]),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: gs.trophyChange >= 0
                          ? const Color(0xFF06D6A0).withOpacity(.15)
                          : const Color(0xFFFF4D6D).withOpacity(.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        gs.trophyChange >= 0
                          ? '+${gs.trophyChange} 🏆 جام کسب کردید'
                          : '${gs.trophyChange} 🏆 جام از دست دادید',
                        style: GoogleFonts.vazirmatn(
                          fontSize: 15, fontWeight: FontWeight.w700,
                          color: gs.trophyChange >= 0
                            ? const Color(0xFF06D6A0) : const Color(0xFFFF4D6D)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              gs.startGame(gs.p1Name, gs.p1Avatar);
                              Navigator.pushReplacementNamed(context, '/game');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7B2FBE),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text('🔄 دوباره',
                              style: GoogleFonts.vazirmatn(fontSize: 16, fontWeight: FontWeight.w700)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton(
                          onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                            foregroundColor: const Color(0xFFC77DFF),
                            side: const BorderSide(color: Color(0xFF3D2080)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('🏠', style: GoogleFonts.vazirmatn(fontSize: 18)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  final String avatar, name;
  final int score;
  final bool isWinner;
  const _ScoreCard({required this.avatar, required this.name,
    required this.score, required this.isWinner});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    decoration: BoxDecoration(
      color: const Color(0xFF2D1B69),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: isWinner ? const Color(0xFFFFD700) : const Color(0xFF3D2080),
        width: isWinner ? 2 : 1,
      ),
    ),
    child: Column(
      children: [
        Text(avatar, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 4),
        Text(name, style: GoogleFonts.vazirmatn(fontSize: 12, color: const Color(0xFFa89bc2))),
        Text('$score', style: GoogleFonts.vazirmatn(
          fontSize: 30, fontWeight: FontWeight.w900, color: const Color(0xFFFFD700))),
      ],
    ),
  );
}
