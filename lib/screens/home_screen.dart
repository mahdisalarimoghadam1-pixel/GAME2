import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../game_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _nameCtrl = TextEditingController(text: 'بازیکن ۱');
  String _selectedAvatar = '🦁';
  final _avatars = ['🦁','🐯','🦊','🐺','🦅','🐉','🦄','🤖'];

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    return Scaffold(
      backgroundColor: const Color(0xFF0D0221),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            colors: [Color(0xFF3D0066), Color(0xFF0D0221)],
            center: Alignment(-0.6, -0.7),
            radius: 1.2,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Logo
                ShaderMask(
                  shaderCallback: (b) => const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFF6B6B), Color(0xFFC77DFF)],
                  ).createShader(b),
                  child: Text('Match Masters',
                    style: GoogleFonts.vazirmatn(
                      fontSize: 36, fontWeight: FontWeight.w900,
                      color: Colors.white,
                    )),
                ),
                Text('بازی Match-3 رقابتی',
                  style: GoogleFonts.vazirmatn(color: const Color(0xFFa89bc2), fontSize: 14)),
                const SizedBox(height: 24),
                // Trophy bar
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A0A3B),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF3D2080), width: 1),
                  ),
                  child: Row(
                    children: [
                      const Text('🏆', style: TextStyle(fontSize: 22)),
                      const SizedBox(width: 8),
                      Text('${gs.trophies}',
                        style: GoogleFonts.vazirmatn(
                          fontSize: 22, fontWeight: FontWeight.w900, color: const Color(0xFFFFD700))),
                      const SizedBox(width: 8),
                      Text('جام', style: GoogleFonts.vazirmatn(color: const Color(0xFFa89bc2))),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: gs.getLeagueColor(gs.trophies).withOpacity(.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: gs.getLeagueColor(gs.trophies).withOpacity(.5)),
                        ),
                        child: Text(gs.getLeagueName(gs.trophies),
                          style: GoogleFonts.vazirmatn(
                            color: gs.getLeagueColor(gs.trophies),
                            fontWeight: FontWeight.w700, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Player setup
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A0A3B),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFF3D2080), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('نام بازیکن',
                        style: GoogleFonts.vazirmatn(color: const Color(0xFFa89bc2), fontSize: 14)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _nameCtrl,
                        maxLength: 12,
                        style: GoogleFonts.vazirmatn(color: Colors.white),
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: const Color(0xFF2D1B69),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFF3D2080)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFF3D2080)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFC77DFF)),
                          ),
                        ),
                        textAlign: TextAlign.right,
                      ),
                      const SizedBox(height: 14),
                      Text('آواتار',
                        style: GoogleFonts.vazirmatn(color: const Color(0xFFa89bc2), fontSize: 14)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _avatars.map((av) => GestureDetector(
                          onTap: () => setState(() => _selectedAvatar = av),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 48, height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2D1B69),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _selectedAvatar == av
                                  ? const Color(0xFFFFD700) : const Color(0xFF3D2080),
                                width: _selectedAvatar == av ? 2.5 : 1.5,
                              ),
                            ),
                            child: Center(
                              child: Text(av, style: const TextStyle(fontSize: 24)),
                            ),
                          ),
                        )).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Play button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      context.read<GameState>().startGame(
                        _nameCtrl.text.isEmpty ? 'بازیکن ۱' : _nameCtrl.text,
                        _selectedAvatar,
                      );
                      Navigator.pushNamed(context, '/game');
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF7B2FBE),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 8,
                      shadowColor: const Color(0xFFC77DFF).withOpacity(.4),
                    ),
                    child: Text('⚔️  بازی با هوش مصنوعی',
                      style: GoogleFonts.vazirmatn(fontSize: 18, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pushNamed(context, '/leaderboard'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      foregroundColor: const Color(0xFFC77DFF),
                      side: const BorderSide(color: Color(0xFF3D2080)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('🏆  لیدربرد',
                      style: GoogleFonts.vazirmatn(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
