import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _happyBeansKey = 'happy_beans';
  static const int _defaultBeans = 1000;
  static const String _soundKey = 'sound_enabled';
  static const String _totalGamesKey = 'total_games';
  static const String _winCountKey = 'win_count';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static int getHappyBeans() {
    return _prefs?.getInt(_happyBeansKey) ?? _defaultBeans;
  }

  static Future<void> setHappyBeans(int beans) async {
    await _prefs?.setInt(_happyBeansKey, beans);
  }

  static Future<void> addHappyBeans(int amount) async {
    final current = getHappyBeans();
    await setHappyBeans(current + amount);
  }

  static bool getSoundEnabled() {
    return _prefs?.getBool(_soundKey) ?? true;
  }

  static Future<void> setSoundEnabled(bool enabled) async {
    await _prefs?.setBool(_soundKey, enabled);
  }

  static int getTotalGames() {
    return _prefs?.getInt(_totalGamesKey) ?? 0;
  }

  static Future<void> incrementTotalGames() async {
    await _prefs?.setInt(_totalGamesKey, getTotalGames() + 1);
  }

  static int getWinCount() {
    return _prefs?.getInt(_winCountKey) ?? 0;
  }

  static Future<void> incrementWinCount() async {
    await _prefs?.setInt(_winCountKey, getWinCount() + 1);
  }
}
