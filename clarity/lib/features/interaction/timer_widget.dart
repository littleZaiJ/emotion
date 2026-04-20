import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/metrics_calculator.dart';
import '../../data/local/entities/transaction_entity.dart';
import '../settings/settings_provider.dart';
import 'timer_provider.dart';

/// 嵌入式计时器按钮
class BigTimerButton extends ConsumerWidget {
  const BigTimerButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(interactionTimerNotifierProvider);
    final settingsAsync = ref.watch(settingsNotifierProvider);
    final threshold = settingsAsync.dignityThresholdMin;

    if (timerState.status == TimerStatus.idle) {
      return _IdleButton(
        onTap: () {
          ref.read(interactionTimerNotifierProvider.notifier).start(threshold);
        },
      );
    }

    if (timerState.status == TimerStatus.finished) {
      return const _FinishedState();
    }

    if (timerState.status == TimerStatus.evaluating) {
      return const _EvaluatingState();
    }

    return _ActiveTimer(
      elapsed: timerState.elapsed,
      dignityThresholdMin: threshold,
      onFinish: () => _showEvaluation(context, ref),
      onCancel: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text('放弃计时？', style: TextStyle(color: AppColors.textPrimary)),
            content: Text(
              '已等待 ${formatDuration(timerState.elapsed)}。\n放弃后本次等待不计入账单。',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.6),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('继续等待', style: TextStyle(color: AppColors.expense, fontWeight: FontWeight.w600)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('放弃', style: TextStyle(color: AppColors.textTertiary)),
              ),
            ],
          ),
        );
        if (confirm == true && context.mounted) {
          ref.read(interactionTimerNotifierProvider.notifier).cancel();
        }
      },
    );
  }
}

void _showEvaluation(BuildContext context, WidgetRef ref) {
  HapticFeedback.mediumImpact();
  showTimerEvaluationSheet(context, ref, allowCancel: false);
}

Future<void> showTimerEvaluationSheet(
  BuildContext context,
  WidgetRef ref, {
  required bool allowCancel,
}) async {
  ref.read(interactionTimerNotifierProvider.notifier).beginEvaluation();

  Future<void> resumeIfNeeded() async {
    ref.read(interactionTimerNotifierProvider.notifier).resume();
  }

  await showModalBottomSheet(
    context: context,
    isDismissible: allowCancel,
    enableDrag: allowCancel,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) {
      return PopScope(
        canPop: allowCancel,
        onPopInvokedWithResult: (didPop, result) {
          if (allowCancel && didPop) resumeIfNeeded();
        },
        child: _EvaluationSheet(
          allowCancel: allowCancel,
          onCancel: allowCancel
              ? () async {
                  await resumeIfNeeded();
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              : null,
        ),
      );
    },
  );
}

class _IdleButton extends StatelessWidget {
  final VoidCallback onTap;
  const _IdleButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.expense.withAlpha(20),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.expense.withAlpha(60)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.timer_outlined, color: AppColors.expense, size: 20),
            const SizedBox(width: 8),
            Text(
              '开始等',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.expense,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FinishedState extends StatelessWidget {
  const _FinishedState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.expense.withAlpha(10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.expense.withAlpha(40)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline, color: AppColors.expense, size: 20),
          const SizedBox(width: 8),
          Text(
            '已记账',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.expense,
            ),
          ),
        ],
      ),
    );
  }
}

class _EvaluatingState extends StatelessWidget {
  const _EvaluatingState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '正在评估...',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveTimer extends StatelessWidget {
  final Duration elapsed;
  final int dignityThresholdMin;
  final VoidCallback onFinish;
  final VoidCallback onCancel;

  const _ActiveTimer({
    required this.elapsed,
    required this.dignityThresholdMin,
    required this.onFinish,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final minutes = elapsed.inMinutes.toDouble();
    final zone = MetricsCalculator.timerColorZone(minutes);

    Color timerColor;
    String statusLine;
    switch (zone) {
      case TimerColorZone.green:
        timerColor = AppColors.expense;
        statusLine = 'Ta 可能在忙';
      case TimerColorZone.yellow:
        timerColor = AppColors.warning;
        statusLine = '不太对劲';
      case TimerColorZone.red:
        timerColor = AppColors.income;
        statusLine = '尊严危险';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: timerColor.withAlpha(10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: timerColor.withAlpha(60)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: timerColor, shape: BoxShape.circle),
                  ).animate(onPlay: (c) => c.repeat()).fadeOut(duration: 800.ms),
                  const SizedBox(width: 8),
                  Text(
                    statusLine,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: timerColor,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: onCancel,
                child: Text(
                  '放弃',
                  style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            formatDuration(elapsed),
            style: GoogleFonts.robotoMono(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: timerColor,
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (elapsed.inSeconds / (dignityThresholdMin * 60)).clamp(0.0, 1.0),
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation(timerColor),
            minHeight: 4,
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onFinish,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: timerColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '终于回了',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EvaluationSheet extends ConsumerStatefulWidget {
  final bool allowCancel;
  final Future<void> Function()? onCancel;

  const _EvaluationSheet({required this.allowCancel, required this.onCancel});

  @override
  ConsumerState<_EvaluationSheet> createState() => _EvaluationSheetState();
}

class _EvaluationSheetState extends ConsumerState<_EvaluationSheet> {
  Attitude _selectedAttitude = Attitude.normal;
  Medium _selectedMedium = Medium.text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderBright),
      ),
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
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ta 终于回了',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              if (widget.allowCancel)
                IconButton(
                  onPressed: () async => widget.onCancel?.call(),
                  icon: const Icon(Icons.close_rounded),
                  color: AppColors.textTertiary,
                  iconSize: 18,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  tooltip: '还没回',
                ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            '评价这次回复的质量',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          const Text(
            'Ta 的态度？',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _EvalChip(
                label: '主动',
                selected: _selectedAttitude == Attitude.proactive,
                onTap: () => setState(() => _selectedAttitude = Attitude.proactive),
              ),
              _EvalChip(
                label: '正常',
                selected: _selectedAttitude == Attitude.normal,
                onTap: () => setState(() => _selectedAttitude = Attitude.normal),
              ),
              _EvalChip(
                label: '敷衍',
                selected: _selectedAttitude == Attitude.dismissive,
                onTap: () => setState(() => _selectedAttitude = Attitude.dismissive),
              ),
              _EvalChip(
                label: '冷暴力',
                selected: _selectedAttitude == Attitude.cold,
                onTap: () => setState(() => _selectedAttitude = Attitude.cold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            '媒介？',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _EvalChip(
                label: '文本',
                selected: _selectedMedium == Medium.text,
                onTap: () => setState(() => _selectedMedium = Medium.text),
              ),
              _EvalChip(
                label: '语音',
                selected: _selectedMedium == Medium.voice,
                onTap: () => setState(() => _selectedMedium = Medium.voice),
              ),
              _EvalChip(
                label: '图片',
                selected: _selectedMedium == Medium.media,
                onTap: () => setState(() => _selectedMedium = Medium.media),
              ),
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
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              onPressed: () async {
                await ref
                    .read(interactionTimerNotifierProvider.notifier)
                    .completeEvaluation(
                      attitude: _selectedAttitude,
                      medium: _selectedMedium,
                    );
                if (context.mounted) Navigator.pop(context);
              },
              child: Text(
                '确认',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EvalChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _EvalChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

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
            color: selected ? AppColors.expense : AppColors.border,
          ),
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
