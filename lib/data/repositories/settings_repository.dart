import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository {
  SettingsRepository(this._preferences);

  final SharedPreferences _preferences;

  Future<void> initialize() async {}

  bool get darkMode => _preferences.getBool('darkMode') ?? false;
  bool get hasCompletedOnboarding =>
      _preferences.getBool('hasCompletedOnboarding') ?? false;

  Future<void> setDarkMode(bool value) => _preferences.setBool('darkMode', value);
  Future<void> setOnboardingComplete() =>
      _preferences.setBool('hasCompletedOnboarding', true);
}
