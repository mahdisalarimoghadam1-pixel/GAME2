import 'dart:math';

const int boardCols = 7;
const int boardRows = 7;
const int gemTypes = 6;
const int roundsPerGame = 5;
const int turnSeconds = 15;

const List<String> gemEmojis = ['❤️', '💙', '🧡', '💚', '💜', '💛'];

const List<Color> gemColors = [
  Color(0xFFFF4D6D),
  Color(0xFF4CC9F0),
  Color(0xFFF4A261),
  Color(0xFF06D6A0),
  Color(0xFFC77DFF),
  Color(0xFFFFD166),
];

const List<Color> gemDarkColors = [
  Color(0xFFC9184A),
  Color(0xFF4361EE),
  Color(0xFFE76F51),
  Color(0xFF019863),
  Color(0xFF7B2FBE),
  Color(0xFFEF9E00),
];

class GameState {
  List<List<int>> board;
  List<int> scores;
  List<double> boostCharge;
  int currentPlayer; // 0=human, 1=AI
  int round;
  bool animating;
  bool gameActive;
  int timerVal;
  bool hintUsed;

  GameState({
    required this.board,
    required this.scores,
    required this.boostCharge,
    this.currentPlayer = 0,
    this.round = 1,
    this.animating = false,
    this.gameActive = false,
    this.timerVal = turnSeconds,
    this.hintUsed = false,
  });

  static List<List<int>> createBoard() {
    final rng = Random();
    final board = List.generate(boardRows, (r) => List.filled(boardCols, 0));
    for (int r = 0; r < boardRows; r++) {
      for (int c = 0; c < boardCols; c++) {
        int t;
        do {
          t = rng.nextInt(gemTypes);
        } while (
          (c >= 2 && board[r][c - 1] == t && board[r][c - 2] == t) ||
          (r >= 2 && board[r - 1][c] == t && board[r - 2][c] == t)
        );
        board[r][c] = t;
      }
    }
    return board;
  }

  static GameState initial() => GameState(
    board: createBoard(),
    scores: [0, 0],
    boostCharge: [0.0, 0.0],
    gameActive: true,
  );

  List<List<int>> findMatches() {
    final matched = <String>{};
    for (int r = 0; r < boardRows; r++) {
      for (int c = 0; c < boardCols - 2; c++) {
        if (board[r][c] == board[r][c + 1] && board[r][c] == board[r][c + 2]) {
          int k = c;
          while (k < boardCols && board[r][k] == board[r][c]) matched.add('$r,$k'); k++;
          while (k < boardCols && board[r][k] == board[r][c-1]) {matched.add('$r,$k'); k++;}
        }
      }
    }
    for (int c = 0; c < boardCols; c++) {
      for (int r = 0; r < boardRows - 2; r++) {
        if (board[r][c] == board[r + 1][c] && board[r][c] == board[r + 2][c]) {
          int k = r;
          while (k < boardRows && board[k][c] == board[r][c]) {matched.add('$k,$c'); k++;}
        }
      }
    }
    return matched.map((s) {
      final p = s.split(',');
      return [int.parse(p[0]), int.parse(p[1])];
    }).toList();
  }

  List<int>? findBestMove() {
    for (int r = 0; r < boardRows; r++) {
      for (int c = 0; c < boardCols; c++) {
        final neighbors = [
          [r - 1, c], [r + 1, c], [r, c - 1], [r, c + 1]
        ];
        for (final n in neighbors) {
          final nr = n[0], nc = n[1];
          if (nr < 0 || nr >= boardRows || nc < 0 || nc >= boardCols) continue;
          final tmp = board[r][c];
          board[r][c] = board[nr][nc];
          board[nr][nc] = tmp;
          final m = findMatches();
          board[nr][nc] = board[r][c];
          board[r][c] = tmp;
          if (m.isNotEmpty) return [r, c, nr, nc];
        }
      }
    }
    return null;
  }

  void dropGems() {
    final rng = Random();
    for (int c = 0; c < boardCols; c++) {
      int empty = boardRows - 1;
      for (int r = boardRows - 1; r >= 0; r--) {
        if (board[r][c] != -1) { board[empty--][c] = board[r][c]; }
      }
      for (int r = empty; r >= 0; r--) {
        board[r][c] = rng.nextInt(gemTypes);
      }
    }
  }
}

class LeaderboardEntry {
  final String name;
  final String avatar;
  final int score;
  int trophies;
  int wins;

  LeaderboardEntry({
    required this.name,
    required this.avatar,
    required this.score,
    required this.trophies,
    required this.wins,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> j) => LeaderboardEntry(
    name: j['name'], avatar: j['avatar'], score: j['score'],
    trophies: j['trophies'], wins: j['wins'],
  );

  Map<String, dynamic> toJson() => {
    'name': name, 'avatar': avatar, 'score': score,
    'trophies': trophies, 'wins': wins,
  };
}
