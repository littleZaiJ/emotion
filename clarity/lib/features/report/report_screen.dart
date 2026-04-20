import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:screenshot/screenshot.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/share_image.dart';
import '../../core/services/graduation_service.dart';
import '../dashboard/dashboard_provider.dart';
import '../dashboard/deficit_chart.dart';

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  final _screenshotController = ScreenshotController();
  bool _isSharing = false;

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(dashboardNotifierProvider);
    final waitHours = data.totalWaitMinutes / 60.0;
    final stamp = GraduationService.stampText;
    final nickname = GraduationService.nickname;
    final generatedTitle = GraduationService.generatedTitle;

    final levelColor = switch (data.healthLevel) {
      HealthLevel.healthy => AppColors.expense,
      HealthLevel.warning => AppColors.warning,
      HealthLevel.critical => AppColors.income,
    };

    final title = switch (data.healthLevel) {
      HealthLevel.healthy => '清醒体检单',
      HealthLevel.warning => '清醒体检单（预警）',
      HealthLevel.critical => '破产通知书',
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title),
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        actions: [
          IconButton(
            icon: _isSharing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.share),
            onPressed: _isSharing ? null : () => _shareReport(),
          ),
        ],
      ),
      body: Screenshot(
        controller: _screenshotController,
        child: Container(
          color: AppColors.background,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            child: _ReportContent(
              data: data,
              levelColor: levelColor,
              waitHours: waitHours,
              stampText: stamp,
              nickname: nickname,
              generatedTitle: generatedTitle,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _shareReport() async {
    if (_isSharing) return;

    setState(() => _isSharing = true);

    try {
      // `captureFromLongWidget` requires bounded constraints when the widget
      // tree contains `Expanded/Flexible/Spacer` (ReportContent does).
      final width = MediaQuery.of(context).size.width;
      final data = ref.read(dashboardNotifierProvider);
      final levelColor = switch (data.healthLevel) {
        HealthLevel.healthy => AppColors.expense,
        HealthLevel.warning => AppColors.warning,
        HealthLevel.critical => AppColors.income,
      };
      final Uint8List image = await _screenshotController.captureFromLongWidget(
        InheritedTheme.captureAll(
          context,
          MediaQuery(
            data: MediaQuery.of(context),
            child: MaterialApp(
              theme: ThemeData.dark(),
              home: Scaffold(
                backgroundColor: AppColors.background,
                body: _ReportContent(
                  data: data,
                  levelColor: levelColor,
                  waitHours: data.totalWaitMinutes / 60.0,
                  generatedAt: DateTime.now(),
                  stampText: GraduationService.stampText,
                  nickname: GraduationService.nickname,
                  generatedTitle: GraduationService.generatedTitle,
                ),
              ),
            ),
          ),
        ),
        context: context,
        pixelRatio: 3.0,
        constraints: BoxConstraints.tightFor(width: width),
      );
      await sharePngBytes(image, text: '我的恋爱账单体检单 · CLARITY');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('分享失败: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }
}

class _ReportContent extends StatelessWidget {
  final DashboardData data;
  final Color levelColor;
  final double waitHours;
  final DateTime? generatedAt;
  final String? stampText;
  final String? nickname;
  final String? generatedTitle;

  const _ReportContent({
    required this.data,
    required this.levelColor,
    required this.waitHours,
    this.generatedAt,
    this.stampText,
    this.nickname,
    this.generatedTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0A),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: levelColor.withAlpha(120), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '恋爱账单体检单',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textSecondary,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'CLARITY CHECKUP',
                        style: GoogleFonts.robotoMono(
                          fontSize: 10,
                          color: AppColors.textTertiary,
                          letterSpacing: 2,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: levelColor.withAlpha(16),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: levelColor.withAlpha(80)),
                    ),
                    child: Text(
                      '清醒指数 ${data.ciValue.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: levelColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '累计倒贴总额',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                formatCurrency(data.sunkCost),
                style: GoogleFonts.robotoMono(
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                  color: levelColor,
                  letterSpacing: -1.5,
                  height: 1,
                ),
              ),
              const SizedBox(height: 12),
              Container(height: 1, color: AppColors.border),
              const SizedBox(height: 12),

              // Stats
              _RowStat(
                label: '打水漂的钱',
                value: formatCurrency(data.totalCashInvestment),
              ),
              const SizedBox(height: 8),
              _RowStat(
                label: '当牛做马费',
                value: formatCurrency(data.totalLaborValueInvestment),
              ),
              const SizedBox(height: 8),
              _RowStat(
                label: '卑微等待时长',
                value: waitHours >= 1
                    ? '${waitHours.toStringAsFixed(1)} 小时'
                    : '${data.totalWaitMinutes.toStringAsFixed(0)} 分钟',
              ),
              const SizedBox(height: 8),
              _RowStat(label: '7日投入', value: formatCurrency(data.ti7d)),
              const SizedBox(height: 8),
              _RowStat(label: '平均互动质量', value: data.avgIQS.toStringAsFixed(1)),
              const SizedBox(height: 14),

              // 7日趋势图
              Container(
                height: 120,
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TrendBarChart(stats: data.last7Days),
              ),
              const SizedBox(height: 14),

              // 毒舌短评
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: levelColor.withAlpha(10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: levelColor.withAlpha(60)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '毒舌短评：',
                      style: TextStyle(
                        fontSize: 12,
                        color: levelColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        data.snarkLine.isEmpty
                            ? '先记几笔，让我有数据怼醒你。'
                            : data.snarkLine,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // 分享提示
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        '二维码',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        '截图发给朋友，让 Ta 也别当冤种。',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (generatedAt != null) ...[
                const SizedBox(height: 10),
                Text(
                  '生成时间 ${generatedAt!.toIso8601String()}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textQuaternary,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (stampText != null && stampText!.isNotEmpty)
          Positioned(
            top: 10,
            right: 8,
            child: Transform.rotate(
              angle: -0.2,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.income.withAlpha(18),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.income.withAlpha(120),
                    width: 1,
                  ),
                ),
                child: Text(
                  stampText!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.income,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
          ),
        if ((nickname ?? '').trim().isNotEmpty &&
            (generatedTitle ?? '').trim().isNotEmpty)
          Positioned(
            bottom: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
              ),
              child: Text(
                '${generatedTitle!.trim()} · ${nickname!.trim()}',
                style: GoogleFonts.robotoMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _RowStat extends StatelessWidget {
  final String label;
  final String value;
  const _RowStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
        ),
        Text(
          value,
          style: GoogleFonts.robotoMono(
            fontSize: 13,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
