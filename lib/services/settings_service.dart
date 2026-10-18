import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static SharedPreferences? _prefs;

  static Future<SharedPreferences> get prefs async {
    if (_prefs != null) return _prefs!;
    _prefs = await SharedPreferences.getInstance();
    return _prefs!;
  }

  // Theme mode: 'system', 'light', 'dark'
  static Future<String> getThemeMode() async {
    final p = await prefs;
    return p.getString('theme_mode') ?? 'system';
  }

  static Future<void> setThemeMode(String mode) async {
    final p = await prefs;
    await p.setString('theme_mode', mode);
  }

  // TTS speech rate
  static Future<double> getTtsRate() async {
    final p = await prefs;
    return p.getDouble('tts_rate') ?? 0.45;
  }

  static Future<void> setTtsRate(double rate) async {
    final p = await prefs;
    await p.setDouble('tts_rate', rate);
  }

  // Daily goal
  static Future<int> getDailyGoal() async {
    final p = await prefs;
    return p.getInt('daily_goal') ?? 20;
  }

  static Future<void> setDailyGoal(int goal) async {
    final p = await prefs;
    await p.setInt('daily_goal', goal);
  }

  static Future<bool> hasAcceptedPrivacy() async {
    final p = await prefs;
    return p.getBool('privacy_accepted') ?? false;
  }

  static Future<void> setPrivacyAccepted(bool accepted) async {
    final p = await prefs;
    await p.setBool('privacy_accepted', accepted);
  }
}
