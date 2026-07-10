import 'package:flutter/foundation.dart';

import '../../data/repositories/settings_repository.dart';

class SettingsProvider extends ChangeNotifier {
  SettingsProvider(this._repository);

  final SettingsRepository _repository;
  bool darkMode = false;
  bool hasCompletedOnboarding = false;

  void load() {
    darkMode = _repository.darkMode;
    hasCompletedOnboarding = _repository.hasCompletedOnboarding;
    notifyListeners();
  }

  Future<void> toggleDarkMode(bool value) async {
    darkMode = value;
    await _repository.setDarkMode(value);
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    hasCompletedOnboarding = true;
    await _repository.setOnboardingComplete();
    notifyListeners();
  }
}
