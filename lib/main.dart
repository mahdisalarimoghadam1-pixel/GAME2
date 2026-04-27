import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'game_state.dart';
import 'screens/home_screen.dart';
import 'screens/game_screen.dart';
import 'screens/result_screen.dart';
import 'screens/leaderboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(
    ChangeNotifierProvider(
      create: (_) => GameState(),
      child: const MatchMastersApp(),
    ),
  );
}

class MatchMastersApp extends StatelessWidget {
  const MatchMastersApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Match Masters',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFC77DFF),
          secondary: Color(0xFF4CC9F0),
          surface: Color(0xFF1A0A3B),
          background: Color(0xFF0D0221),
        ),
        textTheme: GoogleFonts.vazirmatnTextTheme(
          ThemeData.dark().textTheme,
        ),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (_) => const HomeScreen(),
        '/game': (_) => const GameScreen(),
        '/result': (_) => const ResultScreen(),
        '/leaderboard': (_) => const LeaderboardScreen(),
      },
    );
  }
}
