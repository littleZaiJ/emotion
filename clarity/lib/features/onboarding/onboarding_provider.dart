import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/repositories/settings_repository.dart';

part 'onboarding_provider.g.dart';

/// Onboarding 表单状态
class OnboardingForm {
  final double hourlyRate;
  final List<String> selectedPreferences;
  final int currentStep;

  const OnboardingForm({
    this.hourlyRate = 50.0,
    this.selectedPreferences = const [],
    this.currentStep = 0,
  });

  OnboardingForm copyWith({
    double? hourlyRate,
    List<String>? selectedPreferences,
    int? currentStep,
  }) {
    return OnboardingForm(
      hourlyRate: hourlyRate ?? this.hourlyRate,
      selectedPreferences: selectedPreferences ?? this.selectedPreferences,
      currentStep: currentStep ?? this.currentStep,
    );
  }

  bool get canProceed {
    switch (currentStep) {
      case 0:
        return hourlyRate > 0;
      case 1:
        return selectedPreferences.isNotEmpty;
      default:
        return true;
    }
  }
}

@riverpod
class OnboardingController extends _$OnboardingController {
  @override
  OnboardingForm build() {
    return const OnboardingForm();
  }

  void setHourlyRate(double rate) {
    state = state.copyWith(hourlyRate: rate);
  }

  void togglePreference(String pref) {
    final current = List<String>.from(state.selectedPreferences);
    if (current.contains(pref)) {
      current.remove(pref);
    } else if (current.length < 3) {
      // 最多选3个
      current.add(pref);
    }
    state = state.copyWith(selectedPreferences: current);
  }

  void nextStep() {
    if (state.currentStep < 1) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void prevStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  void complete() {
    SettingsRepository().completeOnboarding(
      hourlyRate: state.hourlyRate,
      equivalentPreferences: state.selectedPreferences,
    );
  }
}
