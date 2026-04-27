import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

const int COLS = 7;
const int ROWS = 7;
const int GEM_TYPES = 6;
const int ROUNDS = 5;
const int TURN_TIME = 15;

class LeaderboardEntry {
  String name, avatar;
  int score, trophies, wins;
  LeaderboardEntry({required this.name, required this.avatar,
    required this.score, required this.trophies, required this.wins});

  Map<String, dynamic> toJson() => {
    'name': name, 'avatar': avatar,
    'score': score, 'trophies': trophies, 'wins': wins
  };

  factory LeaderboardEntry.fromJson(Map<String, dynamic> j) =>
    LeaderboardEntry(name: j['name'], avatar: j['avatar'],
      score: j['score'], trophies: j['trophies'], wins: j['wins']);
}

class GameState extends ChangeNotifier {
  List<List<int>> board = [];
  List<int> scores = [0, 0];
  List<double> boostCharge = [0, 0];
  int currentPlayer = 0;
  int round = 1;
  bool animating = false;
  bool gameActive = false;
  int timerVal = TURN_TIME;
  Timer? timerHandle;
  String p1Name = 'بازیکن ۱';
  String p1Avatar = '🦁';
  int trophies = 0;
  int wins = 0;
  List<LeaderboardEntry> leaderboard = [];
  int? selectedRow, selectedCol;
  bool hintUsed = false;
  int hintRow1 = -1, hintCol1 = -1, hintRow2 = -1, hintCol2 = -1;
  int _turnCount = 0;
  String gameResult = ''; // 'win','lose','draw'
  int trophyChange = 0;

  final Random _rnd = Random();

  // AI entries
  final List<LeaderboardEntry> _aiPlayers = [
    LeaderboardEntry(name:'AlphaBot', avatar:'🤖', score:3200, trophies:420, wins:87),
    LeaderboardEntry(name:'GemQueen', avatar:'👑', score:2850, trophies:310, wins:64),
    LeaderboardEntry(name:'StarLord', avatar:'⭐', score:2600, trophies:280, wins:55),
    LeaderboardEntry(name:'DragonX', avatar:'🐉', score:2400, trophies:230, wins:48),
    LeaderboardEntry(name:'NinjaMatch', avatar:'🥷', score:2100, trophies:190, wins:39),
  ];

  GameState() { _loadPrefs(); }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    trophies = p.getInt('trophies') ?? 0;
    wins = p.getInt('wins') ?? 0;
    final raw = p.getString('leaderboard');
    if (raw != null) {
      leaderboard = (jsonDecode(raw) as List)
        .map((e) => LeaderboardEntry.fromJson(e)).toList();
    }
    _ensureAIPlayers();
    notifyListeners();
  }

  Future<void> _savePrefs() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('trophies', trophies);
    await p.setInt('wins', wins);
    await p.setString('leaderboard',
      jsonEncode(leaderboard.map((e) => e.toJson()).toList()));
  }

  void _ensureAIPlayers() {
    for (final ai in _aiPlayers) {
      if (!leaderboard.any((e) => e.name == ai.name)) {
        leaderboard.add(ai);
      }
    }
    _sortLeaderboard();
  }

  void _sortLeaderboard() {
    leaderboard.sort((a, b) => b.trophies.compareTo(a.trophies));
  }

  // ── BOARD ──────────────────────────────────────────
  void initBoard() {
    board = List.generate(ROWS, (r) =>
      List.generate(COLS, (c) => _safeGem(r, c, [])));
    // ensure no initial matches
    board = List.generate(ROWS, (r) =>
      List.generate(COLS, (c) {
        int t;
        do { t = _rnd.nextInt(GEM_TYPES); }
        while (_wouldMatch(r, c, t));
        return t;
      }));
  }

  bool _wouldMatch(int r, int c, int t) {
    if (c >= 2 && board[r][c-1] == t && board[r][c-2] == t) return true;
    if (r >= 2 && board[r-1][c] == t && board[r-2][c] == t) return true;
    return false;
  }

  int _safeGem(int r, int c, List ignore) => _rnd.nextInt(GEM_TYPES);

  // ── START GAME ─────────────────────────────────────
  void startGame(String name, String avatar) {
    p1Name = name;
    p1Avatar = avatar;
    initBoard();
    scores = [0, 0];
    boostCharge = [0, 0];
    currentPlayer = 0;
    round = 1;
    animating = false;
    gameActive = true;
    hintUsed = false;
    selectedRow = null;
    selectedCol = null;
    _turnCount = 0;
    hintRow1 = hintRow2 = hintCol1 = hintCol2 = -1;
    gameResult = '';
    trophyChange = 0;
    _startTimer();
    notifyListeners();
  }

  // ── TIMER ──────────────────────────────────────────
  void _startTimer() {
    timerHandle?.cancel();
    timerVal = TURN_TIME;
    timerHandle = Timer.periodic(const Duration(seconds: 1), (_) {
      timerVal--;
      if (timerVal <= 0) { timerHandle?.cancel(); _skipTurn(); }
      notifyListeners();
    });
  }

  void _stopTimer() { timerHandle?.cancel(); timerVal = TURN_TIME; }

  void _skipTurn() {
    if (!gameActive || animating) return;
    _nextTurn();
  }

  void skipTurn() => _skipTurn();

  // ── GEM SELECT / SWAP ──────────────────────────────
  Future<void> selectGem(int r, int c) async {
    if (animating || currentPlayer != 0 || !gameActive) return;
    if (selectedRow == null) {
      selectedRow = r; selectedCol = c;
      notifyListeners();
    } else {
      final sr = selectedRow!, sc = selectedCol!;
      selectedRow = null; selectedCol = null;
      if (sr == r && sc == c) { notifyListeners(); return; }
      if (_isAdjacent(sr, sc, r, c)) {
        await _doSwap(sr, sc, r, c, 0);
      } else {
        selectedRow = r; selectedCol = c;
        notifyListeners();
      }
    }
  }

  bool _isAdjacent(int r1, int c1, int r2, int c2) =>
    (r1 - r2).abs() + (c1 - c2).abs() == 1;

  Future<void> _doSwap(int r1, int c1, int r2, int c2, int player) async {
    animating = true;
    _stopTimer();
    notifyListeners();

    final tmp = board[r1][c1];
    board[r1][c1] = board[r2][c2];
    board[r2][c2] = tmp;
    notifyListeners();

    final matches = _findMatches();
    if (matches.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 200));
      board[r1][c1] = board[r2][c2];
      board[r2][c2] = tmp;
      animating = false;
      notifyListeners();
      if (player == 0) _startTimer();
      return;
    }

    await _processMatches(matches, player);
    animating = false;
    _nextTurn();
  }

  // ── MATCH LOGIC ────────────────────────────────────
  List<List<int>> _findMatches() {
    final Set<String> matched = {};
    for (int r = 0; r < ROWS; r++) {
      for (int c = 0; c < COLS - 2; c++) {
        if (board[r][c] == board[r][c+1] && board[r][c] == board[r][c+2]) {
          int k = c;
          while (k < COLS && board[r][k] == board[r][c]) matched.add('$r,$k'), k++;
        }
      }
    }
    for (int c = 0; c < COLS; c++) {
      for (int r = 0; r < ROWS - 2; r++) {
        if (board[r][c] == board[r+1][c] && board[r][c] == board[r+2][c]) {
          int k = r;
          while (k < ROWS && board[k][c] == board[r][c]) matched.add('$k,$c'), k++;
        }
      }
    }
    return matched.map((s) {
      final p = s.split(',');
      return [int.parse(p[0]), int.parse(p[1])];
    }).toList();
  }

  Future<void> _processMatches(List<List<int>> matches, int player) async {
    int pts = matches.length * 10;
    if (matches.length >= 5) pts += 30;
    else if (matches.length >= 4) pts += 15;

    scores[player] += pts;
    boostCharge[player] = (boostCharge[player] + matches.length * 5).clamp(0, 100);

    for (final m in matches) board[m[0]][m[1]] = -1;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 350));

    _dropGems();
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 200));

    final cascade = _findMatches();
    if (cascade.isNotEmpty) {
      await Future.delayed(const Duration(milliseconds: 150));
      await _processMatches(cascade, player);
    }
  }

  void _dropGems() {
    for (int c = 0; c < COLS; c++) {
      int empty = ROWS - 1;
      for (int r = ROWS - 1; r >= 0; r--) {
        if (board[r][c] != -1) { board[empty--][c] = board[r][c]; }
      }
      for (int r = empty; r >= 0; r--) board[r][c] = _rnd.nextInt(GEM_TYPES);
    }
  }

  // ── BOOSTER ────────────────────────────────────────
  void activateBooster(int player) {
    if (boostCharge[player] < 100) return;
    if (player == 0 && currentPlayer != 0) return;
    boostCharge[player] = 0;
    scores[player] += 60;
    notifyListeners();
  }

  // ── HINT ───────────────────────────────────────────
  void showHint() {
    if (hintUsed || currentPlayer != 0) return;
    hintUsed = true;
    final move = _findBestMove();
    if (move != null) {
      hintRow1 = move[0]; hintCol1 = move[1];
      hintRow2 = move[2]; hintCol2 = move[3];
      notifyListeners();
      Future.delayed(const Duration(seconds: 2), () {
        hintRow1 = hintRow2 = hintCol1 = hintCol2 = -1;
        notifyListeners();
      });
    }
  }

  // ── AI ─────────────────────────────────────────────
  Future<void> doAITurn() async {
    if (!gameActive) return;
    animating = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 600));

    if (boostCharge[1] >= 100) {
      boostCharge[1] = 0;
      scores[1] += 60;
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 400));
    }

    final move = _findBestMove();
    if (move != null) {
      await _doSwap(move[0], move[1], move[2], move[3], 1);
    } else {
      animating = false;
    }

    final done = _trackRound();
    if (!done) {
      currentPlayer = 0;
      notifyListeners();
      _startTimer();
    }
  }

  List<int>? _findBestMove() {
    for (int r = 0; r < ROWS; r++) {
      for (int c = 0; c < COLS; c++) {
        for (final d in [[-1,0],[1,0],[0,-1],[0,1]]) {
          final nr = r + d[0], nc = c + d[1];
          if (nr < 0 || nr >= ROWS || nc < 0 || nc >= COLS) continue;
          final tmp = board[r][c];
          board[r][c] = board[nr][nc];
          board[nr][nc] = tmp;
          final m = _findMatches();
          board[r][c] = board[nr][nc];
          board[nr][nc] = tmp;
          if (m.isNotEmpty) return [r, c, nr, nc];
        }
      }
    }
    return null;
  }

  // ── TURN / ROUND ───────────────────────────────────
  void _nextTurn() {
    currentPlayer = 1 - currentPlayer;
    hintUsed = false;
    hintRow1 = hintRow2 = hintCol1 = hintCol2 = -1;

    final done = _trackRound();
    if (!done) {
      notifyListeners();
      if (currentPlayer == 1) {
        doAITurn();
      } else {
        _startTimer();
      }
    }
  }

  bool _trackRound() {
    _turnCount++;
    if (_turnCount % 2 == 0) {
      round++;
      if (round > ROUNDS) {
        _endGame();
        return true;
      }
    }
    notifyListeners();
    return false;
  }

  // ── END GAME ───────────────────────────────────────
  void _endGame() {
    gameActive = false;
    _stopTimer();
    final s1 = scores[0], s2 = scores[1];

    if (s1 > s2) {
      gameResult = 'win'; trophyChange = 30; wins++;
    } else if (s2 > s1) {
      gameResult = 'lose'; trophyChange = -10;
    } else {
      gameResult = 'draw'; trophyChange = 5;
    }

    trophies = (trophies + trophyChange).clamp(0, 99999);
    _updateLeaderboard();
    _savePrefs();
    notifyListeners();
  }

  void _updateLeaderboard() {
    final idx = leaderboard.indexWhere((e) => e.name == p1Name);
    if (idx >= 0) {
      leaderboard[idx].score = max(leaderboard[idx].score, scores[0]);
      leaderboard[idx].trophies = trophies;
      leaderboard[idx].wins = wins;
    } else {
      leaderboard.add(LeaderboardEntry(
        name: p1Name, avatar: p1Avatar,
        score: scores[0], trophies: trophies, wins: wins,
      ));
    }
    _sortLeaderboard();
  }

  String getLeagueName(int t) {
    if (t >= 300) return 'افسانه‌ای';
    if (t >= 150) return 'طلایی';
    if (t >= 60) return 'نقره‌ای';
    return 'برنزی';
  }

  Color getLeagueColor(int t) {
    if (t >= 300) return const Color(0xFFC77DFF);
    if (t >= 150) return const Color(0xFFFFD700);
    if (t >= 60) return const Color(0xFFC0C0C0);
    return const Color(0xFFCD7F32);
  }
}
