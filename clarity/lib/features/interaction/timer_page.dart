import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/metrics_calculator.dart';
import '../../data/local/entities/transaction_entity.dart';
import '../settings/settings_provider.dart';
import 'timer_provider.dart';

class TimerPage extends ConsumerStatefulWidget {
  const TimerPage({super.key});

  @override
  ConsumerState<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends ConsumerState<TimerPage> {
  @override
  void initState() {
    super.initState();
    // 进页面时如果计时器是 idle，自动启动
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final timerState = ref.read(interactionTimerNotifierProvider);
      if (timerState.status == TimerStatus.idle) {
        final threshold = ref.read(settingsNotifierProvider).dignityThresholdMin;
        ref.read(interactionTimerNotifierProvider.notifier).start(threshold);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final timerState = ref.watch(interactionTimerNotifierProvider);

    // 计时完成后自动 pop 回 Dashboard
    ref.listen(interactionTimerNotifierProvider, (prev, next) {
      if (next.status == TimerStatus.idle &&
          prev != null &&
          prev.status != TimerStatus.idle) {
        if (mounted && context.canPop()) context.pop();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          color: AppColors.textSecondary,
          onPressed: () => _tryExit(context, timerState),
        ),
        title: Text(
          '等待计时',
          style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary),
        ),
      ),
      body: Column(
        children: [
          // Auto-prompt Banner
          if (timerState.showAutoPrompt)
            _AutoPromptBanner(
              elapsedMinutes: timerState.elapsed.inMinutes,
              onRecord: () => _showEvaluation(context, isAutoTriggered: true),
              onDismiss: () =>
                  ref.read(interactionTimerNotifierProvider.notifier).dismissAutoPrompt(),
            ).animate().slideY(begin: -0.3, duration: 300.ms),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: _buildBody(context, timerState),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, TimerState timerState) {
    switch (timerState.status) {
      case TimerStatus.idle:
        return const Center(
          child: CircularProgressIndicator(color: AppColors.expense),
        );

      case TimerStatus.finished:
        return _FinishedView();

      case TimerStatus.evaluating:
        return const Center(
          child: _EvaluatingPlaceholder(),
        );

      case TimerStatus.running:
      case TimerStatus.warning:
        return _RunningView(
          timerState: timerState,
          onFinish: () => _showEvaluation(context, isAutoTriggered: false),
          onCancel: () => _tryCancel(context, timerState),
        );
    }
  }

  Future<void> _tryExit(BuildContext context, TimerState timerState) async {
    if (timerState.isActive) {
      await _tryCancel(context, timerState);
    } else if (context.canPop()) {
      context.pop();
    }
  }

  Future<void> _tryCancel(BuildContext context, TimerState timerState) async {
    final mins = timerState.elapsed.inMinutes;
    final secs = timerState.elapsed.inSeconds % 60;
    final timeStr = mins > 0 ? '$mins 分 $secs 秒' : '$secs 秒';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('放弃计时？',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          '已等待 $timeStr。\n放弃后本次等待不计入账单。',
          style: const TextStyle(
              color: AppColors.textSecondary, fontSize: 13, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('继续等待',
                style: TextStyle(
                    color: AppColors.expense, fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('放弃',
                style: TextStyle(color: AppColors.textTertiary)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      ref.read(interactionTimerNotifierProvider.notifier).cancel();
      if (context.canPop()) context.pop();
    }
  }

  Future<void> _showEvaluation(BuildContext context,
      {required bool isAutoTriggered}) async {
    HapticFeedback.mediumImpact();
    ref.read(interactionTimerNotifierProvider.notifier).beginEvaluation();

    // 默认态度：auto-prompt → 冷暴力；手动 → 正常
    Attitude selectedAttitude = isAutoTriggered ? Attitude.cold : Attitude.normal;
    Medium selectedMedium = Medium.text;

    await showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 24),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.borderBright),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Ta 终于回了',
                      style: GoogleFonts.spaceGrotesk(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    const Text('评价这次回复的质量',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 16),

                    // 态度
                    const Text('Ta 的态度？',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _EvalChip(
                            label: '主动',
                            selected: selectedAttitude == Attitude.proactive,
                            onTap: () =>
                                setState(() => selectedAttitude = Attitude.proactive)),
                        _EvalChip(
                            label: '正常',
                            selected: selectedAttitude == Attitude.normal,
                            onTap: () =>
                                setState(() => selectedAttitude = Attitude.normal)),
                        _EvalChip(
                            label: '敷衍',
                            selected: selectedAttitude == Attitude.dismissive,
                            onTap: () =>
                                setState(() => selectedAttitude = Attitude.dismissive)),
                        _EvalChip(
                            label: '冷暴力',
                            selected: selectedAttitude == Attitude.cold,
                            onTap: () =>
                                setState(() => selectedAttitude = Attitude.cold)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 媒介
                    const Text('媒介？',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _EvalChip(
                            label: '文本',
                            selected: selectedMedium == Medium.text,
                            onTap: () => setState(() => selectedMedium = Medium.text)),
                        _EvalChip(
                            label: '语音',
                            selected: selectedMedium == Medium.voice,
                            onTap: () => setState(() => selectedMedium = Medium.voice)),
                        _EvalChip(
                            label: '图片',
                            selected: selectedMedium == Medium.media,
                            onTap: () => setState(() => selectedMedium = Medium.media)),
                      ],
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.expense,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          await ref
                              .read(interactionTimerNotifierProvider.notifier)
                              .completeEvaluation(
                                attitude: selectedAttitude,
                                medium: selectedMedium,
                                isAutoTriggered: isAutoTriggered,
                              );
                          if (ctx.mounted) Navigator.pop(ctx);
                          // state → idle 后 TimerPage 的 listen 自动 pop
                        },
                        child: Text(
                          '确认',
                          style: GoogleFonts.spaceGrotesk(
                              fontSize: 15, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ─── Running View ─────────────────────────────────────────────

class _RunningView extends StatelessWidget {
  final TimerState timerState;
  final VoidCallback onFinish;
  final VoidCallback onCancel;

  const _RunningView({
    required this.timerState,
    required this.onFinish,
    required this.onCancel,
  });

  TimerColorZone get _zone =>
      MetricsCalculator.timerColorZone(timerState.elapsed.inMinutes.toDouble());

  Color get _color => switch (_zone) {
        TimerColorZone.green => AppColors.expense,
        TimerColorZone.yellow => AppColors.warning,
        TimerColorZone.red => AppColors.income,
      };

  String get _statusText => switch (_zone) {
        TimerColorZone.green => 'Ta 可能在忙',
        TimerColorZone.yellow => '不太对劲',
        TimerColorZone.red => '尊严危险',
      };

  double get _progress =>
      (timerState.elapsed.inSeconds /
              (timerState.dignityThresholdMin * 60))
          .clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 状态标签 + 放弃按钮
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration:
                      BoxDecoration(color: _color, shape: BoxShape.circle),
                ).animate(onPlay: (c) => c.repeat()).fadeOut(duration: 800.ms),
                const SizedBox(width: 8),
                Text(
                  _statusText,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _color),
                ),
              ],
            ),
            GestureDetector(
              onTap: onCancel,
              child: const Text('放弃计时',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textTertiary)),
            ),
          ],
        ),
        const SizedBox(height: 40),

        // 计时大数字
        Text(
          formatDuration(timerState.elapsed),
          style: GoogleFonts.robotoMono(
            fontSize: 56,
            fontWeight: FontWeight.w700,
            color: _color,
            letterSpacing: -2,
            height: 1,
          ),
        ),
        const SizedBox(height: 16),

        // 进度条
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _progress,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation(_color),
            minHeight: 4,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '已等 ${timerState.elapsed.inMinutes} 分钟',
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textTertiary),
            ),
            Text(
              '阈值 ${timerState.dignityThresholdMin} 分钟',
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textTertiary),
            ),
          ],
        ),

        const Spacer(),

        // 终于回了按钮
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            onPressed: onFinish,
            child: Text(
              '【 终于回了 】',
              style: GoogleFonts.spaceGrotesk(
                  fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Auto-prompt Banner ───────────────────────────────────────

class _AutoPromptBanner extends StatelessWidget {
  final int elapsedMinutes;
  final VoidCallback onRecord;
  final VoidCallback onDismiss;

  const _AutoPromptBanner({
    required this.elapsedMinutes,
    required this.onRecord,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.income.withAlpha(18),
      padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppColors.income, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '你已等待超过 $elapsedMinutes 分钟，要记录吗？',
              style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.4),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: onRecord,
            child: const Text('立即记录',
                style: TextStyle(
                    color: AppColors.income,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: const Icon(Icons.close,
                size: 16, color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}

// ─── Finished View ────────────────────────────────────────────

class _FinishedView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline,
              color: AppColors.expense, size: 48),
          const SizedBox(height: 12),
          Text(
            '已记账',
            style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.expense),
          ),
          const SizedBox(height: 6),
          const Text('等待成本已写入账单',
              style: TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

// ─── Evaluating Placeholder ───────────────────────────────────

class _EvaluatingPlaceholder extends StatelessWidget {
  const _EvaluatingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: AppColors.expense),
        ),
        const SizedBox(height: 12),
        Text(
          '正在评估互动质量…',
          style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

// ─── Eval Chip ────────────────────────────────────────────────

class _EvalChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _EvalChip(
      {required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.expense.withAlpha(18)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
              color: selected ? AppColors.expense : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: selected ? AppColors.expense : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
