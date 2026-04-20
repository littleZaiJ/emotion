import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/local/entities/transaction_entity.dart';
import '../../data/local/entities/interaction_entity.dart';
import '../../data/local/hive_service.dart';
import '../../data/repositories/transactions_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../input/input_provider.dart';

part 'dashboard_provider.g.dart';

enum HealthLevel { healthy, warning, critical }

/// 7日每天的统计数据（用于趋势柱状图）
class DailyStats {
  final DateTime date;
  final double cashExpense; // 花钱
  final double laborExpense; // 出力折算
  final double totalReturn; // 回馈

  const DailyStats({
    required this.date,
    this.cashExpense = 0,
    this.laborExpense = 0,
    this.totalReturn = 0,
  });

  /// TI（日投入）= 花钱 + 出力折算
  double get totalExpense => cashExpense + laborExpense;

  double get net => totalReturn - totalExpense;
}

class DashboardData {
  final double ciValue; // 当前 CI 值
  final double totalInvestment; // 总投入（花钱 + 出力）
  final double totalReturn; // 总回馈
  final double totalCashInvestment;
  final double totalLaborValueInvestment;
  final double avgIQS; // 平均 IQS
  final double totalWaitMinutes;
  final int totalInteractionCount;
  final List<DailyStats> last7Days;
  final HealthLevel healthLevel;
  final String snarkLine;
  final List<String> equivalentPreferences;
  final String lastNegativeFeedback; // 最近一次负反馈描述

  const DashboardData({
    this.ciValue = 1.0,
    this.totalInvestment = 0,
    this.totalReturn = 0,
    this.totalCashInvestment = 0,
    this.totalLaborValueInvestment = 0,
    this.avgIQS = 0,
    this.totalWaitMinutes = 0,
    this.totalInteractionCount = 0,
    this.last7Days = const [],
    this.healthLevel = HealthLevel.healthy,
    this.snarkLine = '',
    this.equivalentPreferences = const [],
    this.lastNegativeFeedback = '',
  });

  double get deficit => totalReturn - totalInvestment;
  double get sunkCost =>
      (totalInvestment - totalReturn).clamp(0.0, double.infinity);
  double get ti7d => last7Days.fold(0.0, (sum, s) => sum + s.totalExpense);
}

String _snarkLineFor({
  required double ci,
  required double avgIQS,
  required int ciDeclineDays,
}) {
  if (ci >= 0.8) return '清醒指数在线：稳住，别作妖。';
  if (ciDeclineDays >= 3) return '清醒指数连续下滑：别再自我感动了，立刻止损！';
  if (ci >= 0.5) return '清醒指数下滑：别再自我感动，先观察。';
  if (ci >= 0.2) return '清醒指数告急：你在重度内耗，建议立刻止损。';
  if (avgIQS < 0) return '互动质量负分：醒醒，你在和空气谈恋爱。';
  return '清醒指数爆炸：建议立刻断联止损。';
}

@riverpod
class DashboardNotifier extends _$DashboardNotifier {
  @override
  DashboardData build() {
    final txRepo = ref.watch(transactionsRepositoryProvider);
    return _compute(txRepo);
  }

  DashboardData _compute(TransactionsRepository txRepo) {
    final all = txRepo.getAll();
    final last7 = txRepo.getLast7Days();
    final settings = SettingsRepository().get();
    final now = DateTime.now();
    final frictionTimes = all
        .where((t) => t.type == TransactionType.timeFriction)
        .map((t) => t.timestamp)
        .toList();

    bool isHighLeverageReturn(TransactionEntity tx) {
      return tx.type == TransactionType.return_ &&
          (tx.returnCategoryV2 == ReturnCategoryV2.intimacy ||
              tx.returnCategoryV2 == ReturnCategoryV2.emotionalValue);
    }

    bool isDecayed(TransactionEntity tx) {
      if (!isHighLeverageReturn(tx)) return false;
      final activeUntil = tx.timestamp.add(const Duration(hours: 24));
      if (now.isAfter(activeUntil)) return true;
      return frictionTimes.any(
        (t) => t.isAfter(tx.timestamp) && t.isBefore(activeUntil),
      );
    }

    double effectiveReturnValue(TransactionEntity tx) {
      if (tx.type != TransactionType.return_) return 0.0;
      if (isDecayed(tx)) return 0.0;
      return tx.totalValue;
    }

    double totalCashExpense = 0;
    double totalLaborValueExpense = 0;
    double totalReturn = 0;
    double totalIQS = 0;
    int returnCount = 0;
    String lastNegativeFeedback = '';

    // 找最近一次负反馈（按时间倒序）
    final sortedAll = all.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    for (final tx in sortedAll) {
      if (tx.type == TransactionType.return_ &&
          tx.attitude != null &&
          (tx.attitude == Attitude.cold ||
              tx.attitude == Attitude.dismissive)) {
        final attitudeDesc = tx.attitude == Attitude.cold ? '冷暴力' : '敷衍';
        final mediumDesc = tx.medium == Medium.voice
            ? '语音'
            : tx.medium == Medium.media
            ? '图片'
            : '文本';
        lastNegativeFeedback = 'Ta 的 $attitudeDesc$mediumDesc';
        break;
      }
    }

    for (final tx in all) {
      switch (tx.type) {
        case TransactionType.expense:
          totalCashExpense += tx.monetaryAmount;
          break;
        case TransactionType.labor:
        case TransactionType.timeFriction:
          totalLaborValueExpense += tx.totalValue;
          break;
        case TransactionType.return_:
          totalReturn += effectiveReturnValue(tx);
          if (tx.iqs != null) {
            totalIQS += tx.iqs!;
            returnCount++;
          }
          break;
        case TransactionType.aiVerdict:
          break;
      }
    }

    final totalExpense = totalCashExpense + totalLaborValueExpense;
    final avgIQS = returnCount > 0 ? totalIQS / returnCount : 0.0;

    // CI 值从设置中获取
    final ciValue = settings.ciValue;

    // 健康等级
    final level = ciValue >= 1.0
        ? HealthLevel.healthy
        : ciValue >= 0.3
        ? HealthLevel.warning
        : HealthLevel.critical;

    // Interaction 统计
    double totalWaitMinutes = 0;
    int interactionCount = 0;

    try {
      final interactions = HiveService.interactions.values
          .where((e) => e.status == WaitStatus.finished && e.endTime != null)
          .toList();
      for (final InteractionEntity e in interactions) {
        totalWaitMinutes += e.waitDurationMinutes;
        interactionCount++;
      }
    } catch (_) {
      // Hive not ready
    }

    // 7日每日统计
    final stats = List.generate(7, (i) {
      final date = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: 6 - i));
      final nextDate = date.add(const Duration(days: 1));
      final dayTxs = last7.where(
        (tx) => !tx.timestamp.isBefore(date) && tx.timestamp.isBefore(nextDate),
      );

      double cashExp = 0, laborExp = 0, inc = 0;
      for (final tx in dayTxs) {
        switch (tx.type) {
          case TransactionType.expense:
            cashExp += tx.monetaryAmount;
            break;
          case TransactionType.labor:
          case TransactionType.timeFriction:
            laborExp += tx.totalValue;
            break;
          case TransactionType.return_:
            inc += effectiveReturnValue(tx);
            break;
          case TransactionType.aiVerdict:
            break;
        }
      }
      return DailyStats(
        date: date,
        cashExpense: cashExp,
        laborExpense: laborExp,
        totalReturn: inc,
      );
    });

    final snarkLine = _snarkLineFor(
      ci: ciValue,
      avgIQS: avgIQS,
      ciDeclineDays: settings.ciDeclineDays,
    );

    return DashboardData(
      ciValue: ciValue,
      totalInvestment: totalExpense,
      totalReturn: totalReturn,
      totalCashInvestment: totalCashExpense,
      totalLaborValueInvestment: totalLaborValueExpense,
      avgIQS: avgIQS,
      totalWaitMinutes: totalWaitMinutes,
      totalInteractionCount: interactionCount,
      last7Days: stats,
      healthLevel: level,
      snarkLine: snarkLine,
      equivalentPreferences: settings.equivalentPreferences,
      lastNegativeFeedback: lastNegativeFeedback,
    );
  }

  void refresh() => ref.invalidateSelf();
}
