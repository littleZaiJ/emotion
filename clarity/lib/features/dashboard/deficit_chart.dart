import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import 'dashboard_provider.dart';

/// 7日投入柱状图（PRD VFinal §2.3）
/// 每日双柱：TI（日投入）向上；回馈（冲销）向下
/// 长按 Tooltip 显示：日期 / 花钱 / 出力 / 回馈
class TrendBarChart extends StatelessWidget {
  final List<DailyStats> stats;

  const TrendBarChart({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final hasData = stats.any((s) => s.totalExpense > 0 || s.totalReturn > 0);
    if (!hasData) {
      return Center(
        child: Text(
          '暂无数据\n记录第一笔开始追踪',
          textAlign: TextAlign.center,
          style: GoogleFonts.robotoMono(
            fontSize: 12,
            color: AppColors.textTertiary,
          ),
        ),
      );
    }

    final maxExpense = stats.map((s) => s.totalExpense).fold(0.0, max);
    final maxReturn = stats.map((s) => s.totalReturn).fold(0.0, max);

    final chartMax = (maxExpense < 10 ? 100.0 : maxExpense * 1.35);
    final chartMin = maxReturn > 0
        ? -(maxReturn < 10 ? 100.0 : maxReturn * 1.35)
        : 0.0;
    final span = (chartMax - chartMin).abs();

    return BarChart(
      BarChartData(
        maxY: chartMax,
        minY: chartMin,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: span / 3,
          getDrawingHorizontalLine: (_) => const FlLine(
            color: AppColors.border,
            strokeWidth: 0.5,
            dashArray: [4, 4],
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 20,
              getTitlesWidget: (value, _) {
                final idx = value.toInt();
                if (idx < 0 || idx >= stats.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text(
                    formatWeekday(stats[idx].date),
                    style: GoogleFonts.robotoMono(
                      fontSize: 9,
                      color: AppColors.textTertiary,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AppColors.surfaceElevated,
            tooltipRoundedRadius: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              if (groupIndex < 0 || groupIndex >= stats.length) return null;
              final s = stats[groupIndex];
              final tooltipLines = [
                formatDate(s.date),
                '花钱  ¥${s.cashExpense.toStringAsFixed(0)}',
                '出力  ¥${s.laborExpense.toStringAsFixed(0)}',
                '回馈  ¥${s.totalReturn.toStringAsFixed(0)}',
              ].join('\n');
              return BarTooltipItem(
                tooltipLines,
                GoogleFonts.robotoMono(
                  fontSize: 10,
                  color: AppColors.textPrimary,
                  height: 1.6,
                ),
              );
            },
          ),
        ),
        barGroups: List.generate(stats.length, (i) {
          return BarChartGroupData(
            x: i,
            barsSpace: 6,
            barRods: [
              BarChartRodData(
                toY: stats[i].totalExpense,
                color: AppColors.expense,
                width: 10,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
              if (stats[i].totalReturn > 0)
                BarChartRodData(
                  toY: -stats[i].totalReturn,
                  color: AppColors.income,
                  width: 10,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(4),
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }
}

// DeficitChart 已重命名为 TrendBarChart（PRD VFinal 图表类型变更为柱状图）
