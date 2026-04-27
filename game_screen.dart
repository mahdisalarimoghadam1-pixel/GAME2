import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../game_state.dart';

const List<String> GEM_EMOJIS = ['❤️','💙','🧡','💚','💜','💛'];
const List<List<Color>> GEM_COLORS = [
  [Color(0xFFFF4D6D), Color(0xFFC9184A)],
  [Color(0xFF4CC9F0), Color(0xFF4361EE)],
  [Color(0xFFF4A261), Color(0xFFE76F51)],
  [Color(0xFF06D6A0), Color(0xFF019863)],
  [Color(0xFFC77DFF), Color(0xFF7B2FBE)],
  [Color(0xFFFFD166), Color(0xFFEF9E00)],
];

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();

    // Navigate to result when game ends
    if (!gs.gameActive && gs.gameResult.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Navigator.of(context).canPop()) {
          Navigator.pushReplacementNamed(context, '/result');
        }
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D0221),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            colors: [Color(0xFF00336B), Color(0xFF0D0221)],
            center: Alignment(0.8, 0.8),
            radius: 1.2,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              children: [
                const SizedBox(height: 8),
                _HUD(),
                const SizedBox(height: 8),
                _BoosterBar(),
                const SizedBox(height: 6),
                _RoundInfo(),
                const SizedBox(height: 8),
                Expanded(child: _Board()),
                const SizedBox(height: 10),
                _ActionRow(),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HUD extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    return Row(
      children: [
        _PlayerHUD(name: gs.p1Name, avatar: gs.p1Avatar,
          score: gs.scores[0], isActive: gs.currentPlayer == 0, reversed: false),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF1A0A3B),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF3D2080)),
          ),
          child: Text('VS', style: GoogleFonts.vazirmatn(
            fontSize: 13, fontWeight: FontWeight.w900, color: const Color(0xFFa89bc2))),
        ),
        _PlayerHUD(name: 'هوش مصنوعی', avatar: '🤖',
          score: gs.scores[1], isActive: gs.currentPlayer == 1, reversed: true),
      ],
    );
  }
}

class _PlayerHUD extends StatelessWidget {
  final String name, avatar;
  final int score;
  final bool isActive, reversed;
  const _PlayerHUD({required this.name, required this.avatar,
    required this.score, required this.isActive, required this.reversed});

  @override
  Widget build(BuildContext context) {
    final content = [
      Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFF2D1B69), shape: BoxShape.circle,
          border: Border.all(
            color: isActive ? const Color(0xFF06D6A0) : const Color(0xFF3D2080),
            width: isActive ? 2.5 : 1.5,
          ),
        ),
        child: Center(child: Text(avatar, style: const TextStyle(fontSize: 22))),
      ),
      const SizedBox(width: 8),
      Column(
        crossAxisAlignment: reversed ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(name, style: GoogleFonts.vazirmatn(fontSize: 12, fontWeight: FontWeight.w700)),
          Text('$score', style: GoogleFonts.vazirmatn(
            fontSize: 22, fontWeight: FontWeight.w900, color: const Color(0xFFFFD700))),
        ],
      ),
    ];
    return Expanded(
      child: Row(
        mainAxisAlignment: reversed ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: reversed ? content.reversed.toList() : content,
      ),
    );
  }
}

class _BoosterBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    return Row(
      children: [
        ElevatedButton(
          onPressed: gs.boostCharge[0] >= 100 && gs.currentPlayer == 0
            ? () => gs.activateBooster(0) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4CC9F0),
            foregroundColor: const Color(0xFF0D0221),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            minimumSize: Size.zero,
            textStyle: GoogleFonts.vazirmatn(fontSize: 11, fontWeight: FontWeight.w700),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('💥 بوستر'),
        ),
        const SizedBox(width: 6),
        Expanded(child: _BoostBarFill(
          value: gs.boostCharge[0] / 100,
          color1: const Color(0xFF4CC9F0), color2: const Color(0xFF4361EE))),
        const SizedBox(width: 6),
        Expanded(child: _BoostBarFill(
          value: gs.boostCharge[1] / 100,
          color1: const Color(0xFFFF4D6D), color2: const Color(0xFFC77DFF))),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: gs.boostCharge[1] >= 100 ? const Color(0xFFFF4D6D) : const Color(0xFF1A0A3B),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('بوستر 🤖',
            style: GoogleFonts.vazirmatn(fontSize: 11, fontWeight: FontWeight.w700,
              color: gs.boostCharge[1] >= 100 ? Colors.white : const Color(0xFF666))),
        ),
      ],
    );
  }
}

class _BoostBarFill extends StatelessWidget {
  final double value;
  final Color color1, color2;
  const _BoostBarFill({required this.value, required this.color1, required this.color2});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 12,
      decoration: BoxDecoration(
        color: const Color(0xFF2D1B69),
        borderRadius: BorderRadius.circular(6),
      ),
      child: FractionallySizedBox(
        widthFactor: value.clamp(0, 1),
        alignment: Alignment.centerLeft,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color1, color2]),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
    );
  }
}

class _RoundInfo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    return Row(
      children: [
        _InfoPill('دور ${gs.round} / $ROUNDS'),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            gs.currentPlayer == 0 ? 'نوبت شما ✨' : 'نوبت هوش مصنوعی 🤖',
            textAlign: TextAlign.center,
            style: GoogleFonts.vazirmatn(
              fontSize: 13, fontWeight: FontWeight.w700,
              color: const Color(0xFF06D6A0)),
          ),
        ),
        const SizedBox(width: 8),
        _TimerPill(gs.timerVal),
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String text;
  const _InfoPill(this.text);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xFF1A0A3B),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFF3D2080)),
    ),
    child: Text(text, style: GoogleFonts.vazirmatn(fontSize: 12, color: const Color(0xFFa89bc2))),
  );
}

class _TimerPill extends StatelessWidget {
  final int val;
  const _TimerPill(this.val);
  @override
  Widget build(BuildContext context) {
    final urgent = val <= 5;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: urgent ? const Color(0xFFFF4D6D).withOpacity(.2) : const Color(0xFF1A0A3B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: urgent ? const Color(0xFFFF4D6D) : const Color(0xFF3D2080)),
      ),
      child: Text('⏱ $val',
        style: GoogleFonts.vazirmatn(
          fontSize: 14, fontWeight: FontWeight.w700,
          color: urgent ? const Color(0xFFFF4D6D) : const Color(0xFFFFD700))),
    );
  }
}

class _Board extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    if (gs.board.isEmpty) return const SizedBox();
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A0A3B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF3D2080), width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.4), blurRadius: 20)],
      ),
      padding: const EdgeInsets.all(10),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: COLS, crossAxisSpacing: 5, mainAxisSpacing: 5,
        ),
        itemCount: ROWS * COLS,
        itemBuilder: (ctx, idx) {
          final r = idx ~/ COLS, c = idx % COLS;
          return _GemCell(row: r, col: c);
        },
      ),
    );
  }
}

class _GemCell extends StatelessWidget {
  final int row, col;
  const _GemCell({required this.row, required this.col});

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    if (gs.board.isEmpty || row >= gs.board.length || col >= gs.board[row].length) {
      return const SizedBox();
    }
    final type = gs.board[row][col];
    if (type < 0 || type >= GEM_COLORS.length) return const SizedBox();

    final isSelected = gs.selectedRow == row && gs.selectedCol == col;
    final isHint = (row == gs.hintRow1 && col == gs.hintCol1) ||
                   (row == gs.hintRow2 && col == gs.hintCol2);
    final disabled = gs.animating || gs.currentPlayer == 1;

    return GestureDetector(
      onTap: disabled ? null : () => gs.selectGem(row, col),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: GEM_COLORS[type],
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
              ? const Color(0xFFFFD700)
              : isHint
                ? const Color(0xFF06D6A0)
                : Colors.white.withOpacity(.1),
            width: isSelected || isHint ? 2.5 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(color: const Color(0xFFFFD700).withOpacity(.5), blurRadius: 12, spreadRadius: 2),
          ] : isHint ? [
            BoxShadow(color: const Color(0xFF06D6A0).withOpacity(.5), blurRadius: 10, spreadRadius: 1),
          ] : [],
        ),
        transform: isSelected
          ? (Matrix4.identity()..scale(1.1))
          : Matrix4.identity(),
        child: Center(
          child: Text(
            GEM_EMOJIS[type],
            style: TextStyle(fontSize: MediaQuery.of(context).size.width / COLS / 2.5),
          ),
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: gs.animating || gs.currentPlayer != 0 ? null : () => gs.showHint(),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFC77DFF),
              side: const BorderSide(color: Color(0xFF3D2080)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('💡 راهنمایی', style: GoogleFonts.vazirmatn(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton(
            onPressed: gs.animating || gs.currentPlayer != 0 ? null : () => gs.skipTurn(),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFa89bc2),
              side: const BorderSide(color: Color(0xFF3D2080)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('⏭ رد کردن', style: GoogleFonts.vazirmatn(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(width: 10),
        IconButton(
          onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
          icon: const Icon(Icons.home_rounded, color: Color(0xFFa89bc2)),
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFF1A0A3B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: Color(0xFF3D2080))),
          ),
        ),
      ],
    );
  }
}
