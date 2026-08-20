import 'package:flutter/material.dart';
import 'models/game_state.dart';
import 'services/storage_service.dart';
import 'screens/game_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();
  runApp(const DoudizhuApp());
}

class DoudizhuApp extends StatelessWidget {
  const DoudizhuApp({super.key});

  @override
  Widget build(BuildContext context) {
    final gameState = GameState();
    gameState.initGame();

    return MaterialApp(
      title: '欢乐斗地主',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      home: GameScreen(
        gameState: gameState,
        showDownloadButton: const bool.fromEnvironment('SHOW_DOWNLOAD', defaultValue: false),
      ),
    );
  }
}
