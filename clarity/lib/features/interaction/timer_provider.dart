import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/utils/metrics_calculator.dart';
import '../../data/local/entities/interaction_entity.dart';
import '../../data/local/entities/transaction_entity.dart';
import '../../data/repositories/interactions_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../dashboard/dashboard_provider.dart';
import '../input/input_provider.dart';

part 'timer_provider.g.dart';

enum TimerStatus { idle, running, warning, evaluating, finished }

class TimerState {
  final TimerStatus status;
  final DateTime? startTime;
  final String? interactionId;
  final Duration elapsed;
  final int dignityThresholdMin;
  final bool hasPrompted;
  final bool showAutoPrompt;
  final bool isAutoPromptTriggered;

  const TimerState({
    this.status = TimerStatus.idle,
    this.startTime,
    this.interactionId,
    this.elapsed = Duration.zero,
    this.dignityThresholdMin = 240,
    this.hasPrompted = false,
    this.showAutoPrompt = false,
    this.isAutoPromptTriggered = false,
  });

  TimerState copyWith({
    TimerStatus? status,
    DateTime? startTime,
    String? interactionId,
    Duration? elapsed,
    int? dignityThresholdMin,
    bool? hasPrompted,
    bool? showAutoPrompt,
    bool? isAutoPromptTriggered,
  }) {
    return TimerState(
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      interactionId: interactionId ?? this.interactionId,
      elapsed: elapsed ?? this.elapsed,
      dignityThresholdMin: dignityThresholdMin ?? this.dignityThresholdMin,
      hasPrompted: hasPrompted ?? this.hasPrompted,
      showAutoPrompt: showAutoPrompt ?? this.showAutoPrompt,
      isAutoPromptTriggered: isAutoPromptTriggered ?? this.isAutoPromptTriggered,
    );
  }

  bool get isActive =>
      status == TimerStatus.running || status == TimerStatus.warning;
}

@riverpod
InteractionsRepository interactionsRepository(InteractionsRepositoryRef ref) {
  return InteractionsRepository();
}

@riverpod
class InteractionTimerNotifier extends _$InteractionTimerNotifier {
  Timer? _ticker;
  bool _didRehydrate = false;

  @override
  TimerState build() {
    ref.onDispose(() => _ticker?.cancel());
    if (!_didRehydrate) {
      _didRehydrate = true;
      Future.microtask(_rehydrateIfNeeded);
    }
    return const TimerState();
  }

  void _rehydrateIfNeeded() {
    if (state.status != TimerStatus.idle) return;
    final active = ref.read(interactionsRepositoryProvider).getActive();
    if (active == null) return;

    final threshold = SettingsRepository().get().dignityThresholdMin;
    final now = DateTime.now();
    final elapsed = now.difference(active.startTime);
    final minutes = elapsed.inMinutes.toDouble();

    final zone = MetricsCalculator.timerColorZone(minutes);
    final isWarning = zone == TimerColorZone.red;

    final autoPromptThreshold = threshold + 30;
    final shouldPrompt = minutes >= autoPromptThreshold;

    state = TimerState(
      status: isWarning ? TimerStatus.warning : TimerStatus.running,
      startTime: active.startTime,
      interactionId: active.id,
      elapsed: elapsed,
      dignityThresholdMin: threshold,
      hasPrompted: false,
      showAutoPrompt: false,
      isAutoPromptTriggered: shouldPrompt,
    );
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void start(int dignityThresholdMin) {
    _ticker?.cancel();
    final now = DateTime.now();
    final settings = SettingsRepository().get();

    final entity = InteractionEntity()
      ..id = ''
      ..startTime = now
      ..endTime = null
      ..status = WaitStatus.running
      ..hourlyRateSnapshot = settings.hourlyRate;
    ref.read(interactionsRepositoryProvider).save(entity);

    state = TimerState(
      status: TimerStatus.running,
      startTime: now,
      interactionId: entity.id,
      elapsed: Duration.zero,
      dignityThresholdMin: dignityThresholdMin,
    );
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (state.startTime == null) return;
    final elapsed = DateTime.now().difference(state.startTime!);
    final minutes = elapsed.inMinutes.toDouble();

    // 颜色区间：固定阈值 60/240min
    final zone = MetricsCalculator.timerColorZone(minutes);
    final isWarning = zone == TimerColorZone.red;

    // 自动结算触发条件：t >= dignityThresholdMin + 30min，且仅触发一次
    final autoPromptThreshold = state.dignityThresholdMin + 30;
    final shouldPrompt =
        minutes >= autoPromptThreshold && !state.isAutoPromptTriggered;

    if (shouldPrompt) {
      _ticker?.cancel();
      final active = ref.read(interactionsRepositoryProvider).getActive();
      if (active != null) {
        ref.read(interactionsRepositoryProvider).autoSettle(active);
        ref.invalidate(transactionsRepositoryProvider);
        ref.invalidate(dashboardNotifierProvider);
      }
      state = state.copyWith(
        elapsed: elapsed,
        status: TimerStatus.finished,
        hasPrompted: true,
        showAutoPrompt: false,
        isAutoPromptTriggered: true,
      );
      Future.delayed(const Duration(seconds: 2), () {
        try {
          state = const TimerState();
        } catch (_) {}
      });
      return;
    }

    state = state.copyWith(
      elapsed: elapsed,
      status: isWarning ? TimerStatus.warning : TimerStatus.running,
    );
  }

  void dismissAutoPrompt() {
    state = state.copyWith(showAutoPrompt: false);
  }

  void beginEvaluation() {
    _ticker?.cancel();
    if (state.startTime == null) return;
    state = state.copyWith(status: TimerStatus.evaluating, showAutoPrompt: false);
  }

  void resume() {
    if (state.startTime == null) {
      state = const TimerState();
      return;
    }
    final elapsed = DateTime.now().difference(state.startTime!);
    final minutes = elapsed.inMinutes.toDouble();
    final zone = MetricsCalculator.timerColorZone(minutes);
    final isWarning = zone == TimerColorZone.red;

    state = state.copyWith(
      status: isWarning ? TimerStatus.warning : TimerStatus.running,
      elapsed: elapsed,
      showAutoPrompt: false,
    );
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  Future<void> completeEvaluation({
    required Attitude attitude,
    required Medium medium,
    bool isAutoTriggered = false,
  }) async {
    if (state.startTime == null) return;

    final active = ref.read(interactionsRepositoryProvider).getActive();
    if (active == null) return;

    // 结算 Interaction 并更新 CI
    ref.read(interactionsRepositoryProvider).settleAndWaitUpdateCI(
      interaction: active,
      attitude: attitude,
      medium: medium,
    );

    ref.invalidate(transactionsRepositoryProvider);
    ref.invalidate(dashboardNotifierProvider);

    state = state.copyWith(status: TimerStatus.finished);
    await Future.delayed(const Duration(seconds: 2));
    try {
      state = const TimerState();
    } catch (_) {
      // notifier disposed
    }
  }

  void cancel() {
    _ticker?.cancel();
    final active = ref.read(interactionsRepositoryProvider).getActive();
    if (active != null) {
      ref.read(interactionsRepositoryProvider).delete(active.id);
    }
    state = const TimerState();
  }
}
