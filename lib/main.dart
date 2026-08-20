import 'package:flutter/material.dart';
import 'models/game_state.dart';
import 'services/storage_service.dart';
import 'screens/game_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();
  runApp(const DoudizhuApp());
}

class DoudizhuApp extends StatefulWidget {
  const DoudizhuApp({super.key});

  @override
  State<DoudizhuApp> createState() => _DoudizhuAppState();
}

class _DoudizhuAppState extends State<DoudizhuApp> {
  late final GameState gameState;

  @override
  void initState() {
    super.initState();
    gameState = GameState();
    gameState.initGame();
  }

  @override
  Widget build(BuildContext context) {
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
