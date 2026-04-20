import '../../data/local/entities/transaction_entity.dart';

/// 指标计算器 — 公式来自 PRD v1.1，纯函数，无副作用
enum TimerColorZone { green, yellow, red }

class MetricsCalculator {
  MetricsCalculator._();

  // ─── IQS（互动质量分）────────────────────────────────────────────
  // IQS = 态度分 + 媒介分
  // 态度: 冷暴力=-10, 敷衍=-5, 正常=0, 主动=+5
  // 媒介: 文本=1, 语音=2, 图片/视频=3
  static double calculateIQS({
    required Attitude attitude,
    required Medium medium,
  }) {
    return (getAttitudeScore(attitude) + getMediumScore(medium)).toDouble();
  }

  static int getAttitudeScore(Attitude attitude) {
    switch (attitude) {
      case Attitude.cold:
        return -10;
      case Attitude.dismissive:
        return -5;
      case Attitude.normal:
        return 0;
      case Attitude.proactive:
        return 5;
    }
  }

  static int getMediumScore(Medium medium) {
    switch (medium) {
      case Medium.text:
        return 1;
      case Medium.voice:
        return 2;
      case Medium.media:
        return 3;
    }
  }

  // ─── TI（沉没成本）────────────────────────────────────────────
  // TI = Σ 花钱金额 + Σ (出力时长 × hourlyRate × 分类权重)
  // 权重：情绪价值=1.5x, 体力劳动=1.0x, 时间沉没=0.8x
  static double calculateTI({
    required double totalExpense,      // 花钱总额
    required double totalLaborValue,   // 出力折算总额（已加权）
  }) {
    return totalExpense + totalLaborValue;
  }

  /// 获取出力分类权重
  static double getLaborWeight(LaborCategory? category) {
    switch (category) {
      case LaborCategory.emotional:
        return 1.5;
      case LaborCategory.physical:
        return 1.0;
      case LaborCategory.timeSunk:
        return 0.8;
      default:
        return 1.0;
    }
  }

  /// 计算单笔出力的折算金额
  static double calculateLaborValue({
    required double hours,
    required double hourlyRate,
    required LaborCategory? category,
  }) {
    return hours * hourlyRate * getLaborWeight(category);
  }

  // ─── CI（清醒指数）────────────────────────────────────────────
  // PRD v1.1: CI 不再是简单比值，而是动态调整值
  // 初始值 1.0，根据事件调整
  // 此处保留计算方法供参考（基于投入产出比）
  static double calculateCIRatio({
    required double totalInvestment,
    required double totalReturn,
  }) {
    if (totalInvestment <= 0) return 1.0;
    return totalReturn / totalInvestment;
  }

  // CI 进度条百分比（CI 映射到 [0, 1]，用于进度条显示）
  static double ciProgressValue(double ci) => ci.clamp(0.0, 1.0);

  // ─── 计时器颜色区间（固定阈值）
  // t < 1h → 绿；1h ≤ t < 4h → 黄；t ≥ 4h → 红
  static TimerColorZone timerColorZone(double elapsedMinutes) {
    if (elapsedMinutes < 60) return TimerColorZone.green;
    if (elapsedMinutes < 240) return TimerColorZone.yellow;
    return TimerColorZone.red;
  }

  // ─── 等价物数量计算 ─────────────────────────────────────────────
  static int calculateEquivalentCount({
    required double totalAmount,
    required double unitPrice,
  }) {
    if (unitPrice <= 0) return 0;
    return (totalAmount / unitPrice).floor();
  }
}
