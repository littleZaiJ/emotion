import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/metrics_calculator.dart';
import '../../data/local/entities/equivalent_entity.dart';
import '../interaction/timer_provider.dart';
import '../interaction/timer_widget.dart';
import '../settings/settings_provider.dart';
import 'dashboard_provider.dart';
import 'deficit_chart.dart';

class _StatusCircleDebugOverrides {
  final double? ci;
  final Duration? elapsed;
  const _StatusCircleDebugOverrides({this.ci, this.elapsed});

  _StatusCircleDebugOverrides copyWith({double? ci, Duration? elapsed}) {
    return _StatusCircleDebugOverrides(
      ci: ci ?? this.ci,
      elapsed: elapsed ?? this.elapsed,
    );
  }
}

final _statusCircleDebugOverridesProvider =
    StateProvider<_StatusCircleDebugOverrides>(
      (ref) => const _StatusCircleDebugOverrides(),
    );

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(dashboardNotifierProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _DashboardBody(data: data),
    );
  }
}

class _DashboardBody extends ConsumerStatefulWidget {
  final DashboardData data;
  const _DashboardBody({required this.data});

  @override
  ConsumerState<_DashboardBody> createState() => _DashboardBodyState();
}

class _DashboardBodyState extends ConsumerState<_DashboardBody> {
  Color get _levelColor {
    switch (widget.data.healthLevel) {
      case HealthLevel.healthy:
        return AppColors.expense;
      case HealthLevel.warning:
        return AppColors.warning;
      case HealthLevel.critical:
        return AppColors.income;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        _buildAppBar(context),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // 清醒指数卡片
              _ClarityIndexCard(
                data: widget.data,
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05),
              const SizedBox(height: 14),

              // v2.3：首页核心视觉 - 状态大圆盘（位于首屏核心，按钮内嵌于圆盘）
              const _StatusCircle()
                  .animate()
                  .fadeIn(delay: 120.ms, duration: 420.ms)
                  .slideY(begin: 0.05),
              const SizedBox(height: 18),

              // 等价物冲击区（净投入盈亏双态）
              _EquivalentsCard(
                data: widget.data,
              ).animate().fadeIn(delay: 160.ms, duration: 400.ms),
              const SizedBox(height: 12),

              // 数据明细三联卡片：花钱 / 出力折算 / 平均互动质量
              _StatsRow(
                data: widget.data,
              ).animate().fadeIn(delay: 220.ms, duration: 400.ms),
              const SizedBox(height: 16),

              // 7日趋势图（柱状图：日投入 + 回馈冲销）
              _ChartSection(
                data: widget.data,
              ).animate().fadeIn(delay: 260.ms, duration: 400.ms),

              const SizedBox(height: 12),

              // AI 点评
              _SnarkCard(
                data: widget.data,
                levelColor: _levelColor,
              ).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 12),

              // 动态干预卡片（毕业引导）
              _GraduationNudgeCard(
                data: widget.data,
                onReview: () => context.go('/history'),
              ).animate().fadeIn(delay: 340.ms),

              if (widget.data.healthLevel == HealthLevel.critical) ...[
                const SizedBox(height: 12),
                _CriticalWarning().animate().fadeIn(delay: 360.ms),
              ],

              const SizedBox(height: 40),
            ]),
          ),
        ),
      ],
    );
  }

  SliverAppBar _buildAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.background,
      expandedHeight: 0,
      title: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '恋爱账单',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.2,
              height: 1.0,
            ),
          ),
          Text(
            'CLARITY',
            style: GoogleFonts.robotoMono(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textTertiary,
              letterSpacing: 2,
              height: 1.0,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined, size: 20),
          onPressed: () => context.push('/settings'),
        ),
      ],
    );
  }

  // 记一笔入口迁移至底部 Docked FAB（AppShell），大盘页不再提供重复入口。
}

// ─── Clarity Index Card ───────────────────────────────────────

class _ClarityIndexCard extends StatelessWidget {
  final DashboardData data;
  const _ClarityIndexCard({required this.data});

  void _showCIHelp(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    '什么是清醒指数 (CI)?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '满分为 1.0。它衡量你的“上头”与“倒贴”程度。\n'
                    '数值越低，说明你在这段关系里单方面投入的沉没成本（金钱、精力、等待时间）越高。\n'
                    '低于 0.2 时，系统将拉响危险警报。',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ci = data.ciValue;
    final color = AppTheme.colorForClarityIndex(ci);
    final progress = MetricsCalculator.ciProgressValue(ci);

    final statusLabel = getCiLabel(ci);
    final String statusDesc;
    if (ci >= 0.8) {
      statusDesc = '你是清醒的';
    } else if (ci >= 0.5) {
      statusDesc = '开始上头了';
    } else if (ci >= 0.2) {
      statusDesc = '你在重度内耗';
    } else {
      statusDesc = '你在倒贴人生';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(60), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    '清醒指数',
                    style: GoogleFonts.robotoMono(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => _showCIHelp(context),
                    borderRadius: BorderRadius.circular(99),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: AppColors.textTertiary.withAlpha(210),
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withAlpha(20),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            ci.toStringAsFixed(2),
            style: GoogleFonts.robotoMono(
              fontSize: 48,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: -1,
              height: 1,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            statusDesc,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Equivalents Card ─────────────────────────────────────────

class _EquivalentsCard extends StatelessWidget {
  final DashboardData data;
  const _EquivalentsCard({required this.data});

  @override
  Widget build(BuildContext context) {
    // 没有任何投入（还没开始记账）时不展示该模块，避免空暴击/空盈余。
    if (data.totalInvestment <= 0) return const SizedBox.shrink();

    final netInvestment = data.totalInvestment - data.totalReturn; // >0: 亏损期
    final isLossPhase = netInvestment > 0;
    final amount = isLossPhase
        ? netInvestment
        : (data.totalReturn - data.totalInvestment);
    final accent = isLossPhase ? AppColors.expense : AppColors.income;
    final title = isLossPhase ? '等价物暴击' : (amount > 0 ? '情绪盈余' : '价值满足');

    // 根据偏好标签获取等价物
    final items = EquivalentPresets.getByPreferences(
      data.equivalentPreferences,
    );

    double valueForCompare;
    if (isLossPhase) {
      valueForCompare = netInvestment;
    } else if (amount > 0) {
      valueForCompare = amount;
    } else {
      // 平衡期：用近期回馈值做一个“正向叙事”的参照，避免出现 0 的空卡片。
      valueForCompare = data.last7Days.fold(
        0.0,
        (sum, s) => sum + s.totalReturn,
      );
    }

    String body;
    if (valueForCompare < 25) {
      body = isLossPhase ? '这些钱还不够买一杯奶茶' : '回馈不多，但至少没让你白忙。';
    } else {
      final lines = <String>[];
      for (final item in items) {
        final count = item.calculateCount(valueForCompare);
        if (count > 0) lines.add('≈ $count${item.unit}${item.name}');
      }
      body = lines.isNotEmpty
          ? lines.join('\n')
          : (isLossPhase ? '这些钱，先别花在 Ta 身上。' : '旗鼓相当的投入，才是最健康的。');
    }

    // 负反馈文案
    final negativeFeedback = data.lastNegativeFeedback.isNotEmpty
        ? data.lastNegativeFeedback
        : '¥${data.totalReturn.toStringAsFixed(0)} 的回馈';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isLossPhase
                ? '¥ ${amount.toStringAsFixed(0)}'
                : '+ ¥ ${amount.toStringAsFixed(0)}',
            style: GoogleFonts.robotoMono(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 4),
          if (isLossPhase)
            Text(
              '而你只收到了 $negativeFeedback',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textTertiary,
              ),
            )
          else
            const Text(
              '旗鼓相当的投入，才是最健康的。',
              style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
            ),
        ],
      ),
    );
  }
}

// ─── Stats Row ────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final DashboardData data;
  const _StatsRow({required this.data});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MiniCard(
            label: '花钱',
            value: formatCurrency(data.totalCashInvestment),
            color: AppColors.expense,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MiniCard(
            label: '出力折算',
            value: formatCurrency(data.totalLaborValueInvestment),
            color: AppColors.warning,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MiniCard(
            label: '互动质量',
            value: data.totalReturn > 0 ? data.avgIQS.toStringAsFixed(1) : '--',
            color: AppTheme.colorForClarityIndex(data.ciValue),
          ),
        ),
      ],
    );
  }
}

class _MiniCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textTertiary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: GoogleFonts.robotoMono(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Chart Section ────────────────────────────────────────────

class _ChartSection extends StatelessWidget {
  final DashboardData data;
  const _ChartSection({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '近7日投入趋势',
          style: GoogleFonts.robotoMono(
            fontSize: 11,
            color: AppColors.textTertiary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          height: 160,
          padding: const EdgeInsets.fromLTRB(0, 8, 8, 0),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: TrendBarChart(stats: data.last7Days),
        ),
        const SizedBox(height: 8),
        const Row(
          children: [
            _Legend(color: AppColors.expense, label: '日投入（TI）'),
            SizedBox(width: 12),
            _Legend(color: AppColors.income, label: '日回馈（冲销）'),
          ],
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
        ),
      ],
    );
  }
}

class _StatusCircle extends ConsumerWidget {
  const _StatusCircle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(interactionTimerNotifierProvider);
    final settings = ref.watch(settingsNotifierProvider);
    final threshold = settings.dignityThresholdMin;
    final ci = settings.ciValue;
    final debugMode = settings.debugMode;
    final debugOverrides = ref.watch(_statusCircleDebugOverridesProvider);

    final isActive = timerState.isActive;
    final effectiveCi = debugMode ? (debugOverrides.ci ?? ci) : ci;
    final effectiveElapsed = debugMode
        ? (debugOverrides.elapsed ?? timerState.elapsed)
        : timerState.elapsed;
    final previewActive =
        debugMode &&
        !isActive &&
        (debugOverrides.ci != null || debugOverrides.elapsed != null);
    final effectiveIsActive = isActive || previewActive;

    final visual = _StatusCircleVisual.forState(
      ci: effectiveCi,
      elapsed: effectiveElapsed,
      isActive: effectiveIsActive,
    );

    final baseSize = (MediaQuery.sizeOf(context).width * 0.62).clamp(
      200.0,
      236.0,
    );

    Widget circle;
    if (!effectiveIsActive) {
      circle = _BreathingCircleShell(
        visual: visual,
        breathe: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.nightlight_round,
              color: AppColors.textTertiary,
              size: 22,
            ),
            const SizedBox(height: 10),
            Text(
              '开启漫长等待',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    } else {
      circle = _BreathingCircleShell(
        visual: visual,
        breathe: true,
        innerMonologue: _InnerMonologueLayer(
          ci: effectiveCi,
          elapsed: effectiveElapsed,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _OutlinedText(
              text: formatHms(effectiveElapsed),
              strokeColor: visual.timeStrokeColor,
              strokeWidth: 2,
              style: GoogleFonts.robotoMono(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.6,
                height: 1.0,
                color: visual.timeTextColor,
                fontFeatures: const [ui.FontFeature.tabularFigures()],
                shadows: [
                  Shadow(
                    color: Colors.black87,
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              visual.statusLine,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.6),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    final idleCta = SizedBox(
      width: 180,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
            side: const BorderSide(color: AppColors.border),
          ),
        ),
        onPressed: () {
          ref.read(interactionTimerNotifierProvider.notifier).start(threshold);
        },
        child: Text(
          '开始熬',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );

    final runningCta = GestureDetector(
      onTap: () async {
        HapticFeedback.mediumImpact();
        await showTimerEvaluationSheet(context, ref, allowCancel: true);
      },
      child:
          Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedOpacity(
                      opacity: (timerState.elapsed.inSeconds % 2 == 0)
                          ? 1.0
                          : 0.45,
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeInOut,
                      child: AnimatedScale(
                        scale: (timerState.elapsed.inSeconds % 2 == 0)
                            ? 1.0
                            : 1.35,
                        duration: const Duration(milliseconds: 900),
                        curve: Curves.easeInOut,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.8),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '回了么？',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .moveY(begin: 0, end: -2, duration: 900.ms),
    );

    return SizedBox(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: baseSize + 28,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Align(alignment: Alignment.topCenter, child: circle),
                Positioned(
                  top: baseSize - 22,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: previewActive
                        ? _DebugPreviewChip(
                            ci: effectiveCi,
                            elapsed: effectiveElapsed,
                          )
                        : (isActive ? runningCta : idleCta),
                  ),
                ),
              ],
            ),
          ),
          if (debugMode) ...[
            const SizedBox(height: 10),
            _StatusCircleDebugPanel(
              ci: effectiveCi,
              elapsed: effectiveElapsed,
              onSetCi: (v) {
                ref.read(_statusCircleDebugOverridesProvider.notifier).state =
                    debugOverrides.copyWith(ci: v);
              },
              onSetElapsed: (d) {
                ref.read(_statusCircleDebugOverridesProvider.notifier).state =
                    debugOverrides.copyWith(elapsed: d);
              },
              onReset: () {
                ref.read(_statusCircleDebugOverridesProvider.notifier).state =
                    const _StatusCircleDebugOverrides();
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _DebugPreviewChip extends StatelessWidget {
  final double ci;
  final Duration elapsed;
  const _DebugPreviewChip({required this.ci, required this.elapsed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        'DEBUG 预览  CI ${ci.toStringAsFixed(2)}  ·  ${formatHms(elapsed)}',
        style: GoogleFonts.spaceGrotesk(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _StatusCircleDebugPanel extends StatelessWidget {
  final double ci;
  final Duration elapsed;
  final ValueChanged<double> onSetCi;
  final ValueChanged<Duration> onSetElapsed;
  final VoidCallback onReset;

  const _StatusCircleDebugPanel({
    required this.ci,
    required this.elapsed,
    required this.onSetCi,
    required this.onSetElapsed,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final elapsedMinutes = elapsed.inMinutes.clamp(0, 12 * 60);
    final stage = _StatusCircleVisual._stageFor(
      Duration(minutes: elapsedMinutes),
    );
    final stageLabel = switch (stage) {
      _WaitStage.fermentation => '阶段 1 (0~1h)',
      _WaitStage.stress => '阶段 2 (1~4h)',
      _WaitStage.exhaustion => '阶段 3 (>4h)',
    };

    void bumpCi(double delta) => onSetCi((ci + delta).clamp(0.0, 1.0));
    void setCi(double value) => onSetCi(value.clamp(0.0, 1.0));

    void bumpMinutes(int delta) {
      final next = (elapsedMinutes + delta).clamp(0, 12 * 60);
      onSetElapsed(Duration(minutes: next));
    }

    void setMinutes(int minutes) {
      onSetElapsed(Duration(minutes: minutes.clamp(0, 12 * 60)));
    }

    final ciValue = ci.clamp(0.0, 1.0);
    final timeValue = (elapsedMinutes / (12 * 60)).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'DEBUG 控制台',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      stageLabel,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: onReset,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textTertiary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                    ),
                    child: const Text('重置'),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // CI bar (always visible in debug mode)
              _DebugBar(
                title: 'CI 指数',
                valueLabel: ciValue.toStringAsFixed(2),
                value: ciValue,
                activeColor: AppColors.expense,
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _DebugPill(label: '-0.10', onTap: () => bumpCi(-0.10)),
                  _DebugPill(label: '-0.05', onTap: () => bumpCi(-0.05)),
                  _DebugPill(label: '+0.05', onTap: () => bumpCi(0.05)),
                  _DebugPill(label: '+0.10', onTap: () => bumpCi(0.10)),
                  _DebugPill(label: 'CI=1.00', onTap: () => setCi(1.0)),
                  _DebugPill(label: 'CI=0.60', onTap: () => setCi(0.6)),
                  _DebugPill(label: 'CI=0.20', onTap: () => setCi(0.2)),
                ],
              ),
              const SizedBox(height: 12),

              // Time bar (always visible in debug mode)
              _DebugBar(
                title: '等待时长',
                valueLabel: formatHms(Duration(minutes: elapsedMinutes)),
                value: timeValue,
                activeColor: stage == _WaitStage.stress
                    ? AppColors.income
                    : (stage == _WaitStage.exhaustion
                          ? AppColors.textTertiary
                          : AppColors.warning),
                markers: const [1 / 12, 4 / 12],
                markerLabels: const ['1h', '4h'],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _DebugPill(label: '-5m', onTap: () => bumpMinutes(-5)),
                  _DebugPill(label: '+5m', onTap: () => bumpMinutes(5)),
                  _DebugPill(label: '-30m', onTap: () => bumpMinutes(-30)),
                  _DebugPill(label: '+30m', onTap: () => bumpMinutes(30)),
                  _DebugPill(label: '0m', onTap: () => setMinutes(0)),
                  _DebugPill(label: '30m', onTap: () => setMinutes(30)),
                  _DebugPill(label: '1h', onTap: () => setMinutes(60)),
                  _DebugPill(label: '2h', onTap: () => setMinutes(120)),
                  _DebugPill(label: '4h', onTap: () => setMinutes(240)),
                  _DebugPill(label: '6h', onTap: () => setMinutes(360)),
                  _DebugPill(label: '8h', onTap: () => setMinutes(480)),
                ],
              ),
            ],
          );

          if (!constraints.hasBoundedHeight) return content;
          return SingleChildScrollView(child: content);
        },
      ),
    );
  }
}

class _DebugPill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _DebugPill({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          label,
          style: GoogleFonts.robotoMono(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _DebugBar extends StatelessWidget {
  final String title;
  final String valueLabel;
  final double value;
  final Color activeColor;
  final List<double> markers;
  final List<String> markerLabels;

  const _DebugBar({
    required this.title,
    required this.valueLabel,
    required this.value,
    required this.activeColor,
    this.markers = const [],
    this.markerLabels = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textTertiary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            Text(
              valueLabel,
              style: GoogleFonts.robotoMono(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 14,
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: value.clamp(0.0, 1.0),
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation(activeColor),
                  minHeight: 10,
                ),
              ),
              for (var i = 0; i < markers.length; i++)
                Positioned.fill(
                  child: Align(
                    alignment: Alignment(
                      (markers[i].clamp(0.0, 1.0) * 2) - 1,
                      0,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 2,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(180),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                        if (i < markerLabels.length)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              markerLabels[i],
                              style: const TextStyle(
                                fontSize: 9,
                                color: AppColors.textTertiary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BreathingCircleShell extends StatefulWidget {
  const _BreathingCircleShell({
    required this.visual,
    required this.child,
    required this.breathe,
    this.innerMonologue,
  });

  final _StatusCircleVisual visual;
  final Widget child;
  final bool breathe;
  final Widget? innerMonologue;

  @override
  State<_BreathingCircleShell> createState() => _BreathingCircleShellState();
}

class _BreathingCircleShellState extends State<_BreathingCircleShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.visual.breathDuration,
    );
    if (widget.breathe) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _BreathingCircleShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visual.breathDuration != widget.visual.breathDuration) {
      _controller.duration = widget.visual.breathDuration;
      if (widget.breathe && !_controller.isAnimating) {
        _controller.repeat();
      }
    }

    if (oldWidget.breathe != widget.breathe) {
      if (widget.breathe) {
        _controller.repeat();
      } else {
        _controller.stop();
        _controller.value = 0;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseSize = (MediaQuery.sizeOf(context).width * 0.62).clamp(
      200.0,
      236.0,
    );

    final visual = widget.visual;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final pulse = widget.breathe
            ? _breathingPulse(visual.stage, _controller.value)
            : 0.0;
        final scale = widget.breathe
            ? ui.lerpDouble(1.0, visual.maxScale, pulse)!
            : 1.0;

        final spread = ui.lerpDouble(0.0, visual.glowSpreadMax, pulse)!;
        final blur = ui.lerpDouble(
          visual.glowBlurMin,
          visual.glowBlurMax,
          pulse,
        )!;
        final alpha = ui
            .lerpDouble(
              visual.glowAlphaMin.toDouble(),
              visual.glowAlphaMax.toDouble(),
              pulse,
            )!
            .round()
            .clamp(0, 255);

        final baseBackground = DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: const Alignment(-0.22, -0.28),
              radius: 1.08,
              colors: [
                visual.backgroundCenterColor,
                visual.backgroundEdgeColor,
              ],
            ),
            border: Border.all(
              color: visual.ringColor.withAlpha(200),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: visual.glowColor.withAlpha(alpha),
                blurRadius: blur,
                spreadRadius: spread,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: const Alignment(-0.28, -0.35),
                      radius: 0.92,
                      colors: [
                        Colors.white.withAlpha(22),
                        Colors.transparent,
                        Colors.black.withAlpha(88),
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );

        // Apply filters to the base circle only; keep OS text on top for readability.
        Widget background = baseBackground;
        if (visual.blurSigma > 0) {
          background = ImageFiltered(
            imageFilter: ui.ImageFilter.blur(
              sigmaX: visual.blurSigma,
              sigmaY: visual.blurSigma,
            ),
            child: background,
          );
        }

        final jitter = widget.breathe && visual.jitter
            ? Offset(
                math.sin(_controller.value * math.pi * 10) * visual.jitterPx,
                math.cos(_controller.value * math.pi * 12) *
                    (visual.jitterPx * 0.7),
              )
            : Offset.zero;

        return Transform.translate(
          offset: jitter,
          child: Transform.scale(
            scale: scale,
            child: SizedBox(
              width: baseSize,
              height: baseSize,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipOval(
                      child: Stack(
                        children: [
                          Positioned.fill(child: background),
                          if (widget.breathe &&
                              visual.stage == _WaitStage.stress)
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _PulseRingPainter(
                                  t: _controller.value,
                                  color: visual.ringColor,
                                ),
                              ),
                            ),
                          if (widget.innerMonologue != null)
                            Positioned.fill(child: widget.innerMonologue!),
                        ],
                      ),
                    ),
                  ),
                  Center(child: widget.child),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

enum _WaitStage { fermentation, stress, exhaustion }

class _PulseRingPainter extends CustomPainter {
  final double t;
  final Color color;
  const _PulseRingPainter({required this.t, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final base = size.shortestSide / 2;

    // One expanding ring per cycle: center -> near edge.
    final p = t.clamp(0.0, 1.0);
    final radius = ui.lerpDouble(base * 0.18, base * 0.96, p)!;
    final alpha = (p < 0.5 ? p * 2 : (1 - p) * 2) * 0.33;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = ui.lerpDouble(1.5, 6.0, p)!
      ..color = color.withAlpha((alpha * 255).round().clamp(0, 255))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _PulseRingPainter oldDelegate) {
    return oldDelegate.t != t || oldDelegate.color != color;
  }
}

double _breathingPulse(_WaitStage stage, double t) {
  // One forward cycle produces one inhale+exhale pulse.
  // Stage-specific curves match ` animation.md`.
  switch (stage) {
    case _WaitStage.fermentation:
      // Smooth sine breathing: 0..1..0
      return (0.5 - 0.5 * math.cos(2 * math.pi * t)).clamp(0.0, 1.0);
    case _WaitStage.stress:
      // Faster with a slight "stutter" feel.
      final tri = t < 0.5 ? (t * 2) : ((1 - t) * 2);
      var v = Curves.easeInOutBack.transform(tri.clamp(0.0, 1.0));
      // Add a subtle burr; clamp to avoid obvious wobble.
      v += 0.05 * math.sin(2 * math.pi * 12 * t) * (0.6 - 0.2 * tri);
      return v.clamp(0.0, 1.0);
    case _WaitStage.exhaustion:
      // Asymmetric: very slow expand, slightly faster shrink.
      const expandPhase = 0.72;
      if (t <= expandPhase) {
        return Curves.easeOutExpo.transform((t / expandPhase).clamp(0.0, 1.0));
      }
      final x = ((t - expandPhase) / (1 - expandPhase)).clamp(0.0, 1.0);
      return (1.0 - Curves.easeInCubic.transform(x)).clamp(0.0, 1.0);
  }
}

class _StatusCircleVisual {
  final _WaitStage stage;
  final Color ringColor;
  final Color timeTextColor;
  final Color timeStrokeColor;
  final Color glowColor;
  final int glowAlphaMin;
  final int glowAlphaMax;
  final double glowBlurMin;
  final double glowBlurMax;
  final double glowSpreadMax;
  final double maxScale;
  final Color backgroundCenterColor;
  final Color backgroundEdgeColor;
  final Duration breathDuration;
  final double blurSigma;
  final bool jitter;
  final double jitterPx;
  final String statusLine;

  const _StatusCircleVisual({
    required this.stage,
    required this.ringColor,
    required this.timeTextColor,
    required this.timeStrokeColor,
    required this.glowColor,
    required this.glowAlphaMin,
    required this.glowAlphaMax,
    required this.glowBlurMin,
    required this.glowBlurMax,
    required this.glowSpreadMax,
    required this.maxScale,
    required this.backgroundCenterColor,
    required this.backgroundEdgeColor,
    required this.breathDuration,
    required this.blurSigma,
    required this.jitter,
    required this.jitterPx,
    required this.statusLine,
  });

  // v1.6 dark emotional palette (center -> edge/halo).
  static const _stage1Center = Color(0xFF1E3F33); // 深墨绿
  static const _stage1Edge = Color(0xFF0B1B15); // 极暗绿
  static const _stage2Center = Color(0xFF8C4A19); // 暗铁锈红/焦糖色
  static const _stage2Edge = Color(0xFF3A1E08); // 深褐
  static const _stage3Center = Color(0xFF4A1515); // 血痂暗红
  static const _stage3Edge = Color(0xFF1A0505); // 近乎纯黑

  static ({Color center, Color edge}) _paletteFor(Duration elapsed) {
    // Cross-fade around boundaries to avoid abrupt stage flips.
    const transition = Duration(minutes: 6);
    const h1 = Duration(hours: 1);
    const h4 = Duration(hours: 4);
    final half = Duration(milliseconds: transition.inMilliseconds ~/ 2);

    if (elapsed <= h1 - half) return (center: _stage1Center, edge: _stage1Edge);
    if (elapsed < h1 + half) {
      final t =
          (elapsed - (h1 - half)).inMilliseconds / transition.inMilliseconds;
      return (
        center: Color.lerp(_stage1Center, _stage2Center, t) ?? _stage2Center,
        edge: Color.lerp(_stage1Edge, _stage2Edge, t) ?? _stage2Edge,
      );
    }
    if (elapsed <= h4 - half) return (center: _stage2Center, edge: _stage2Edge);
    if (elapsed < h4 + half) {
      final t =
          (elapsed - (h4 - half)).inMilliseconds / transition.inMilliseconds;
      return (
        center: Color.lerp(_stage2Center, _stage3Center, t) ?? _stage3Center,
        edge: Color.lerp(_stage2Edge, _stage3Edge, t) ?? _stage3Edge,
      );
    }
    return (center: _stage3Center, edge: _stage3Edge);
  }

  static _WaitStage _stageFor(Duration elapsed) {
    final minutes = elapsed.inMinutes;
    if (minutes < 60) return _WaitStage.fermentation;
    if (minutes < 240) return _WaitStage.stress;
    return _WaitStage.exhaustion;
  }

  static _StatusCircleVisual forState({
    required double ci,
    required Duration elapsed,
    required bool isActive,
  }) {
    final stage = _stageFor(elapsed);
    final blurSigma = ((1.0 - ci).clamp(0.0, 1.0) * 8.0);
    final palette = _paletteFor(elapsed);

    final ringColor = isActive
        ? (Color.lerp(palette.center, Colors.white, 0.18) ?? Colors.white)
        : AppColors.borderBright;
    final glowColor = isActive ? ringColor : AppColors.borderBright;

    const timeTextColor = Colors.white;
    const timeStrokeColor = Colors.black87;

    final breathDuration = switch (stage) {
      _WaitStage.fermentation => const Duration(milliseconds: 2500),
      _WaitStage.stress => const Duration(milliseconds: 1000),
      _WaitStage.exhaustion => const Duration(milliseconds: 4000),
    };

    final jitter = isActive && stage == _WaitStage.stress;

    final shadowBase = switch (stage) {
      _WaitStage.fermentation => (70, 130, 18.0, 34.0, 6.0),
      _WaitStage.stress => (110, 220, 22.0, 48.0, 16.0),
      _WaitStage.exhaustion => (35, 85, 12.0, 20.0, 2.0),
    };
    final ciScale = (0.45 + 0.55 * ci.clamp(0.0, 1.0));
    final glowAlphaMin = (shadowBase.$1 * ciScale).round();
    final glowAlphaMax = (shadowBase.$2 * ciScale).round();

    final statusLine = isActive
        ? switch (stage) {
            _WaitStage.fermentation => '期待与焦躁',
            _WaitStage.stress => '愤怒与急躁',
            _WaitStage.exhaustion => '无力与深渊',
          }
        : '开启漫长等待';

    return _StatusCircleVisual(
      stage: stage,
      ringColor: ringColor,
      timeTextColor: timeTextColor,
      timeStrokeColor: timeStrokeColor,
      glowColor: glowColor,
      glowAlphaMin: isActive ? glowAlphaMin : 50,
      glowAlphaMax: isActive ? glowAlphaMax : 80,
      glowBlurMin: isActive ? shadowBase.$3 : 14.0,
      glowBlurMax: isActive ? shadowBase.$4 : 18.0,
      glowSpreadMax: isActive ? shadowBase.$5 : 2.0,
      maxScale: switch (stage) {
        _WaitStage.fermentation => 1.04,
        // After 1h: bigger “from center to edge” anxious pulse.
        _WaitStage.stress => 1.07,
        _WaitStage.exhaustion => 1.02,
      },
      backgroundCenterColor: palette.center,
      backgroundEdgeColor: palette.edge,
      breathDuration: breathDuration,
      blurSigma: isActive ? blurSigma : 0.0,
      jitter: isActive ? jitter : false,
      jitterPx: 0.8,
      statusLine: statusLine,
    );
  }
}

class _OutlinedText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final Color strokeColor;
  final double strokeWidth;

  const _OutlinedText({
    required this.text,
    required this.style,
    required this.strokeColor,
    this.strokeWidth = 2,
  });

  @override
  Widget build(BuildContext context) {
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = strokeColor
      ..strokeJoin = StrokeJoin.round;

    return Stack(
      alignment: Alignment.center,
      children: [
        Text(text, style: style.copyWith(foreground: strokePaint, color: null)),
        Text(text, style: style),
      ],
    );
  }
}

class _InnerMonologueLayer extends StatefulWidget {
  final double ci;
  final Duration elapsed;
  const _InnerMonologueLayer({required this.ci, required this.elapsed});

  @override
  State<_InnerMonologueLayer> createState() => _InnerMonologueLayerState();
}

class _InnerMonologueLayerState extends State<_InnerMonologueLayer>
    with SingleTickerProviderStateMixin {
  // `animation.md` OS system: 3~8s trigger, Fade + Slide + Hold + Fade(+Scale)
  // Add a few stage-flavored phrases to keep the narrative consistent.
  static const _highPool = ['应该在忙吧', '到底在忙什么', '浪费时间', '又装死'];
  static const _lowPool = ['看见了为什么不回', 'Ta 根本不在乎吧', '算了，不指望了', '没意思'];

  late final math.Random _rng;
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _slideY;
  late final Animation<double> _scale;

  Timer? _timer;
  String _text = '';
  Alignment _pos = Alignment.center;

  @override
  void initState() {
    super.initState();
    _rng = math.Random(DateTime.now().millisecondsSinceEpoch);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    );

    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.36), weight: 1000),
      TweenSequenceItem(tween: ConstantTween(0.36), weight: 2000),
      TweenSequenceItem(tween: Tween(begin: 0.36, end: 0.0), weight: 1500),
    ]).animate(_controller);

    _slideY = TweenSequence<double>(
      [
        TweenSequenceItem(tween: Tween(begin: 0.2, end: 0.0), weight: 1000),
        TweenSequenceItem(tween: ConstantTween(0.0), weight: 3500),
      ],
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 3000),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.06), weight: 1500),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _scheduleNext();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _scheduleNext() {
    _timer?.cancel();
    final delayMs = 3000 + _rng.nextInt(5001); // 3~8s
    _timer = Timer(Duration(milliseconds: delayMs), () {
      if (!mounted) return;
      if (!_controller.isAnimating) _trigger();
      _scheduleNext();
    });
  }

  void _trigger() {
    final pool = widget.ci > 0.6 ? _highPool : _lowPool;
    final text = pool[_rng.nextInt(pool.length)];

    // Keep around center but avoid covering the timer digits.
    Alignment pos = Alignment.center;
    for (var i = 0; i < 8; i++) {
      final x = (_rng.nextDouble() * 0.7 - 0.35).clamp(-0.35, 0.35);
      final y = (_rng.nextDouble() * 0.75 - 0.12).clamp(-0.12, 0.55);
      pos = Alignment(x, y);
      if (x.abs() > 0.14 || y.abs() > 0.14) break;
    }

    setState(() {
      _text = text;
      _pos = pos;
    });
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        if (_text.isEmpty) return const SizedBox.shrink();
        final opacity = _opacity.value;
        if (opacity <= 0.01) return const SizedBox.shrink();

        return Align(
          alignment: _pos,
          child: Opacity(
            opacity: opacity,
            child: FractionalTranslation(
              translation: Offset(0, _slideY.value),
              child: Transform.scale(
                scale: _scale.value,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(150),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white.withAlpha(26)),
                  ),
                  child: Text(
                    _text,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.white.withValues(alpha: 0.6),
                      shadows: const [
                        Shadow(
                          color: Colors.black87,
                          blurRadius: 12,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Snark Card ───────────────────────────────────────────────

class _SnarkCard extends StatelessWidget {
  final DashboardData data;
  final Color levelColor;
  const _SnarkCard({required this.data, required this.levelColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: levelColor.withAlpha(10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: levelColor.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI 毒舌助理',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: levelColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            data.snarkLine.isEmpty ? '先记几笔，让我有数据怼醒你。' : data.snarkLine,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _GraduationNudgeCard extends StatelessWidget {
  final DashboardData data;
  final VoidCallback onReview;
  const _GraduationNudgeCard({required this.data, required this.onReview});

  @override
  Widget build(BuildContext context) {
    // PRD v1.2: the “毕业”入口不常驻设置页，改为数据驱动的动态卡片引导。
    final shouldShow =
        data.healthLevel == HealthLevel.critical ||
        (data.sunkCost >= 2000 && data.ciValue < 0.6);
    if (!shouldShow) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.income.withAlpha(12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.income.withAlpha(90)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '毕业引导',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.income,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '当 CI 持续走低且净投入扩大时，建议到「复盘」封存账单并生成最终体检单。',
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.income,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              onPressed: onReview,
              child: Text(
                '去复盘',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
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

// ─── Critical Warning ─────────────────────────────────────────

class _CriticalWarning extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.incomeLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.income.withAlpha(100)),
      ),
      child: Column(
        children: [
          Text(
            '⚠️  当前关系已破产',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.income,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '建议立即执行断联',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
