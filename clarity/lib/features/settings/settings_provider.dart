import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/local/entities/user_settings_entity.dart';
import '../../data/repositories/settings_repository.dart';
import '../dashboard/dashboard_provider.dart';

part 'settings_provider.g.dart';

@riverpod
SettingsRepository settingsRepository(SettingsRepositoryRef ref) {
  return SettingsRepository();
}

@riverpod
class SettingsNotifier extends _$SettingsNotifier {
  @override
  UserSettingsEntity build() {
    return ref.read(settingsRepositoryProvider).get();
  }

  void applyDebugPreset({
    double? hourlyRate,
    int? dignityThresholdMin,
    int? autoMarkAfterMin,
    List<String>? equivalentPreferences,
    double? ciValue,
    int? ciDeclineDays,
    int? ciRiseDays,
    bool? debugMode,
  }) {
    final current = state;

    if (hourlyRate != null) {
      current.hourlyRate = hourlyRate;
    }
    if (dignityThresholdMin != null) {
      current.dignityThresholdMin = dignityThresholdMin;
    }
    if (autoMarkAfterMin != null) {
      current.autoMarkAfterMin = autoMarkAfterMin;
    }
    if (equivalentPreferences != null) {
      current.equivalentPreferences = equivalentPreferences;
    }
    if (ciValue != null) {
      current.ciValue = ciValue.clamp(0.0, 1.0);
      current.lastRecordDate = DateTime.now();
    }
    if (ciDeclineDays != null) {
      current.ciDeclineDays = ciDeclineDays;
    }
    if (ciRiseDays != null) {
      current.ciRiseDays = ciRiseDays;
    }
    if (debugMode != null) {
      current.debugMode = debugMode;
    }

    ref.read(settingsRepositoryProvider).save(current);
    state = current;
    ref.invalidate(dashboardNotifierProvider);
  }

  void updateHourlyRate(double rate) {
    ref.read(settingsRepositoryProvider).updateHourlyRate(rate);
    state = ref.read(settingsRepositoryProvider).get();
    ref.invalidate(dashboardNotifierProvider);
  }

  void updateDignityThreshold(int minutes) {
    final current = state;
    current.dignityThresholdMin = minutes;
    ref.read(settingsRepositoryProvider).save(current);
    state = current;
    ref.invalidate(dashboardNotifierProvider);
  }

  void updateAutoMarkAfterMin(int minutes) {
    final current = state;
    current.autoMarkAfterMin = minutes;
    ref.read(settingsRepositoryProvider).save(current);
    state = current;
    ref.invalidate(dashboardNotifierProvider);
  }

  void updateApiKey(String key) {
    final current = state;
    current.claudeApiKey = key;
    ref.read(settingsRepositoryProvider).save(current);
    state = current;
  }

  void setDebugMode(bool enabled) {
    final current = state;
    current.debugMode = enabled;
    ref.read(settingsRepositoryProvider).save(current);
    state = current;
    ref.invalidate(dashboardNotifierProvider);
  }

  void updateEquivalentPreferences(List<String> preferences) {
    ref
        .read(settingsRepositoryProvider)
        .updateEquivalentPreferences(preferences);
    state = ref.read(settingsRepositoryProvider).get();
    ref.invalidate(dashboardNotifierProvider);
  }

  void resetCI() {
    final current = state;
    current.ciValue = 1.0;
    current.ciDeclineDays = 0;
    current.ciRiseDays = 0;
    ref.read(settingsRepositoryProvider).save(current);
    state = current;
    ref.invalidate(dashboardNotifierProvider);
  }

  void setCIValue(double value) {
    final current = state;
    current.ciValue = value.clamp(0.0, 1.0);
    current.ciDeclineDays = 0;
    current.ciRiseDays = 0;
    current.lastRecordDate = DateTime.now();
    ref.read(settingsRepositoryProvider).save(current);
    state = current;
    ref.invalidate(dashboardNotifierProvider);
  }
}
