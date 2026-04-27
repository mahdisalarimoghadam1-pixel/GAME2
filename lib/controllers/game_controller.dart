import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_model.dart';

class GameController extends ChangeNotifier {
  GameState? _state;
  GameState? get state => _state;

  String playerName = 'بازیکن ۱';
  String playerAvatar = '🦁';
  int trophies = 0;
  int wins = 0;
  List<LeaderboardEntry> leaderboard = [];

  int? selectedR, selectedC;
  int? hintR1, hintC1, hintR2, hintC2;
  int turnCount = 0;
  int? lastScoreGain;
  int? lastScorePlayer;
  bool showCombo = false;
  String comboText = '';

  Timer? _timer;

  static const List<LeaderboardEntry> _aiPlayers = [];

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    trophies = prefs.getInt('trophies') ?? 0;
    wins = prefs.getInt('wins') ?? 0;
    playerName = prefs.getString('playerName') ?? 'بازیکن ۱';
    playerAvatar = prefs.getString('playerAvatar') ?? '🦁';
    final lbJson = prefs.getString('leaderboard');
    if (lbJson != null) {
      final list = jsonDecode(lbJson) as List;
      leaderboard = list.map((e) => LeaderboardEntry.fromJson(e)).toList();
    }
    _ensureAIPlayers();
    notifyListeners();
  }

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('trophies', trophies);
    await prefs.setInt('wins', wins);
    await prefs.setString('playerName', playerName);
    await prefs.setString('playerAvatar', playerAvatar);
    await prefs.setString('leaderboard', jsonEncode(leaderboard.map((e) => e.toJson()).toList()));
  }

  void _ensureAIPlayers() {
    final aiDefaults = [
      {'name': 'AlphaBot', 'avatar': '🤖', 'score': 3200, 'trophies': 420, 'wins': 87},
      {'name': 'GemQueen', 'avatar': '👑', 'score': 2850, 'trophies': 310, 'wins': 64},
      {'name': 'StarLord', 'avatar': '⭐', 'score': 2600, 'trophies': 280, 'wins': 55},
      {'name': 'DragonX', 'avatar': '🐉', 'score': 2400, 'trophies': 230, 'wins': 48},
      {'name': 'NinjaMatch', 'avatar': '🥷', 'score': 2100, 'trophies': 190, 'wins': 39},
      {'name': 'PuzzlePro', 'avatar': '🧩', 'score': 1800, 'trophies': 150, 'wins': 30},
    ];
    for (final ai in aiDefaults) {
      if (!leaderboard.any((e) => e.name == ai['name'])) {
        leaderboard.add(LeaderboardEntry(
          name: ai['name'] as String,
          avatar: ai['avatar'] as String,
          score: ai['score'] as int,
          trophies: ai['trophies'] as int,
          wins: ai['wins'] as int,
        ));
      }
    }
    _sortLeaderboard();
  }

  void _sortLeaderboard() {
    leaderboard.sort((a, b) => b.trophies.compareTo(a.trophies));
  }

  void startGame() {
    _timer?.cancel();
    selectedR = null; selectedC = null;
    hintR1 = null; hintC1 = null; hintR2 = null; hintC2 = null;
    turnCount = 0;
    showCombo = false;
    _state = GameState.initial();
    _state!.gameActive = true;
    notifyListeners();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _state!.timerVal = turnSeconds;
    notifyListeners();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_state == null || !_state!.gameActive) { t.cancel(); return; }
      _state!.timerVal--;
      notifyListeners();
      if (_state!.timerVal <= 0) { t.cancel(); _skipTurn(); }
    });
  }

  void _stopTimer() { _timer?.cancel(); }

  void onGemTap(int r, int c) {
    if (_state == null || _state!.animating || _state!.currentPlayer != 0 || !_state!.gameActive) return;
    if (selectedR == null) {
      selectedR = r; selectedC = c;
      notifyListeners();
    } else {
      final sr = selectedR!, sc = selectedC!;
      if (sr == r && sc == c) { selectedR = null; selectedC = null; notifyListeners(); return; }
      if (_isAdjacent(sr, sc, r, c)) {
        selectedR = null; selectedC = null;
        _doSwap(sr, sc, r, c, 0);
      } else {
        selectedR = r; selectedC = c;
        notifyListeners();
      }
    }
  }

  bool _isAdjacent(int r1, int c1, int r2, int c2) =>
      (r1 - r2).abs() + (c1 - c2).abs() == 1;

  Future<void> _doSwap(int r1, int c1, int r2, int c2, int player) async {
    final s = _state!;
    s.animating = true;
    _stopTimer();
    notifyListeners();

    final tmp = s.board[r1][c1];
    s.board[r1][c1] = s.board[r2][c2];
    s.board[r2][c2] = tmp;
    notifyListeners();

    final matches = s.findMatches();
    if (matches.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 200));
      s.board[r2][c2] = s.board[r1][c1];
      s.board[r1][c1] = tmp;
      s.animating = false;
      notifyListeners();
      if (player == 0) _startTimer();
      return;
    }

    await _processMatches(matches, player);
    s.animating = false;
    notifyListeners();
    _nextTurn();
  }

  Future<void> _processMatches(List<List<int>> matches, int player) async {
    final s = _state!;
    int pts = matches.length * 10;
    final bonus = matches.length >= 5 ? 30 : matches.length >= 4 ? 15 : 0;
    pts += bonus;
    s.scores[player] += pts;
    s.boostCharge[player] = (s.boostCharge[player] + matches.length * 5).clamp(0, 100);

    lastScoreGain = pts;
    lastScorePlayer = player;
    if (bonus > 0) {
      showCombo = true;
      comboText = matches.length >= 5 ? '🔥 COMBO!' : '⚡ BONUS!';
    }
    notifyListeners();

    // mark matched
    for (final m in matches) s.board[m[0]][m[1]] = -1;
    await Future.delayed(const Duration(milliseconds: 380));

    s.dropGems();
    showCombo = false;
    lastScoreGain = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 150));

    // cascade
    final cascade = s.findMatches();
    if (cascade.isNotEmpty) {
      await _processMatches(cascade, player);
    }
  }

  void _nextTurn() {
    final s = _state!;
    turnCount++;
    if (turnCount % 2 == 0) {
      s.round++;
      if (s.round > roundsPerGame) { _endGame(); return; }
    }
    s.currentPlayer = 1 - s.currentPlayer;
    notifyListeners();
    if (s.currentPlayer == 1) {
      Future.delayed(const Duration(milliseconds: 800), _doAITurn);
    } else {
      _startTimer();
    }
  }

  Future<void> _doAITurn() async {
    final s = _state;
    if (s == null || !s.gameActive) return;
    s.animating = true;
    notifyListeners();

    // AI booster
    if (s.boostCharge[1] >= 100) {
      s.boostCharge[1] = 0;
      s.scores[1] += 50;
      showCombo = true;
      comboText = '🤖 بوستر!';
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 600));
      showCombo = false;
    }

    final move = s.findBestMove();
    if (move != null) {
      hintR1 = move[0]; hintC1 = move[1];
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 400));
      hintR2 = move[2]; hintC2 = move[3];
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 300));
      hintR1 = null; hintC1 = null; hintR2 = null; hintC2 = null;

      final tmp = s.board[move[0]][move[1]];
      s.board[move[0]][move[1]] = s.board[move[2]][move[3]];
      s.board[move[2]][move[3]] = tmp;
      final matches = s.findMatches();
      if (matches.isNotEmpty) {
        notifyListeners();
        await _processMatches(matches, 1);
      } else {
        s.board[move[2]][move[3]] = s.board[move[0]][move[1]];
        s.board[move[0]][move[1]] = tmp;
      }
    }

    s.animating = false;
    notifyListeners();

    turnCount++;
    if (turnCount % 2 == 0) {
      s.round++;
      if (s.round > roundsPerGame) { _endGame(); return; }
    }
    s.currentPlayer = 0;
    notifyListeners();
    _startTimer();
  }

  void useBooster() {
    final s = _state;
    if (s == null || s.boostCharge[0] < 100 || s.currentPlayer != 0 || s.animating) return;
    s.boostCharge[0] = 0;
    s.scores[0] += 60;
    showCombo = true;
    comboText = '💥 بوستر!';
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 700), () {
      showCombo = false;
      notifyListeners();
    });
  }

  void showHint() {
    final s = _state;
    if (s == null || s.animating || s.currentPlayer != 0 || s.hintUsed) return;
    s.hintUsed = true;
    final move = s.findBestMove();
    if (move != null) {
      hintR1 = move[0]; hintC1 = move[1];
      hintR2 = move[2]; hintC2 = move[3];
      notifyListeners();
      Future.delayed(const Duration(seconds: 2), () {
        hintR1 = null; hintC1 = null; hintR2 = null; hintC2 = null;
        notifyListeners();
      });
    }
  }

  void skipTurn() {
    if (_state == null || _state!.animating || _state!.currentPlayer != 0 || !_state!.gameActive) return;
    _skipTurn();
  }

  void _skipTurn() {
    _stopTimer();
    _nextTurn();
  }

  void _endGame() {
    final s = _state!;
    s.gameActive = false;
    _stopTimer();

    final p1Won = s.scores[0] > s.scores[1];
    final draw = s.scores[0] == s.scores[1];

    int trophyChange;
    if (draw) { trophyChange = 5; }
    else if (p1Won) { trophyChange = 30; wins++; }
    else { trophyChange = -10; }

    trophies = (trophies + trophyChange).clamp(0, 9999);
    _updateLeaderboard(s.scores[0]);
    saveData();
    notifyListeners();
  }

  void _updateLeaderboard(int score) {
    final idx = leaderboard.indexWhere((e) => e.name == playerName);
    if (idx >= 0) {
      leaderboard[idx].trophies = trophies;
      leaderboard[idx].wins = wins;
    } else {
      leaderboard.add(LeaderboardEntry(
        name: playerName, avatar: playerAvatar,
        score: score, trophies: trophies, wins: wins,
      ));
    }
    _sortLeaderboard();
  }

  String getLeagueName() {
    if (trophies >= 300) return 'افسانه‌ای';
    if (trophies >= 150) return 'طلایی';
    if (trophies >= 60) return 'نقره‌ای';
    return 'برنزی';
  }

  int get trophyChange {
    if (_state == null) return 0;
    final p1Won = _state!.scores[0] > _state!.scores[1];
    final draw = _state!.scores[0] == _state!.scores[1];
    if (draw) return 5;
    if (p1Won) return 30;
    return -10;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
