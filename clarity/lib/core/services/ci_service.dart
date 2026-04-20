import '../../data/local/entities/transaction_entity.dart';
import '../../data/repositories/settings_repository.dart';

/// CI (清醒指数) 动态调整服务
/// PRD v1.1 规则：
/// - 初始值 1.0
/// - 单次大额未回馈 → CI -0.1
/// - 收到正向反馈（高 IQS）→ CI +0.05
/// - 连续 3 天无记录 → CI +0.1（自然恢复）
/// - 最高不超过 1.0，最低不低于 0
class CIService {
  CIService._();

  /// 大额未回馈的阈值（元）
  static const double largeExpenseThreshold = 500.0;

  /// 高 IQS 阈值
  static const double highIQSThreshold = 0.0;

  /// 自然恢复间隔（天）
  static const int naturalRecoveryDays = 3;

  /// 自然恢复增量
  static const double naturalRecoveryDelta = 0.1;

  /// 负向反馈减少量
  static const double negativeFeedbackDelta = -0.1;

  /// 正向反馈增加量
  static const double positiveFeedbackDelta = 0.05;

  /// 记录大额支出
  /// 判断是否需要减少 CI
  static void recordLargeExpense(TransactionEntity tx) {
    if (tx.type != TransactionType.expense) return;
    if (tx.monetaryAmount < largeExpenseThreshold) return;

    final settings = SettingsRepository();
    settings.updateCI(negativeFeedbackDelta);
    settings.recordCIDecline();
  }

  /// 记录 IQS 反馈
  /// 根据反馈质量调整 CI
  static void recordIQSFeedback(double iqs) {
    final settings = SettingsRepository();

    if (iqs >= highIQSThreshold) {
      // 正向反馈
      settings.updateCI(positiveFeedbackDelta);
      settings.recordCIRise();
    } else {
      // 负向反馈
      settings.updateCI(negativeFeedbackDelta);
      settings.recordCIDecline();
    }
  }

  /// 记录等待超时
  /// 超过阈值未回复视为负向反馈
  static void recordWaitTimeout() {
    final settings = SettingsRepository();
    settings.updateCI(negativeFeedbackDelta);
    settings.recordCIDecline();
  }

  /// 记录 AI 判案结果对 CI 的影响
  static void recordAiVerdict(double delta) {
    final settings = SettingsRepository();
    settings.updateCI(delta);
    if (delta > 0) {
      settings.recordCIRise();
    } else if (delta < 0) {
      settings.recordCIDecline();
    }
  }

  /// 检查并执行自然恢复
  /// 连续 3 天无记录，CI 恢复 0.1
  static void checkNaturalRecovery() {
    SettingsRepository().checkNaturalRecovery();
  }

  /// 获取当前 CI 值
  static double getCurrentCI() {
    return SettingsRepository().get().ciValue;
  }

  /// 获取 CI 状态文案
  static String getCILabel(double ci) {
    if (ci >= 0.8) return '人间清醒';
    if (ci >= 0.5) return '单方上头';
    if (ci >= 0.2) return '重度内耗';
    return '彻底沦陷';
  }

  /// 获取 CI 状态描述
  static String getCIDescription(double ci) {
    if (ci >= 0.8) return '你是清醒的';
    if (ci >= 0.5) return '开始上头了';
    if (ci >= 0.2) return '你在重度内耗';
    return '你在倒贴人生';
  }

  /// 判断是否需要嘲讽文案
  /// CI 连续下降 3 天
  static bool shouldUseSarcasticComment() {
    final settings = SettingsRepository().get();
    return settings.ciDeclineDays >= 3;
  }

  /// 判断是否需要鼓励文案
  /// CI 连续上升
  static bool shouldUseEncouragingComment() {
    final settings = SettingsRepository().get();
    return settings.ciRiseDays >= 1;
  }

  /// 回滚 CI（删除记录时调用）
  /// 根据交易类型和内容，反向调整 CI
  static void rollbackTransaction(TransactionEntity tx) {
    final settings = SettingsRepository();

    // 回馈记录：根据 IQS 反向调整
    if (tx.type == TransactionType.return_ && tx.iqs != null) {
      final delta = tx.iqs! >= highIQSThreshold
          ? -positiveFeedbackDelta // 之前加了，现在减回去
          : -negativeFeedbackDelta; // 之前减了，现在加回去
      settings.rollbackCI(delta);
    }

    // 大额支出：加回之前减的
    if (tx.type == TransactionType.expense &&
        tx.monetaryAmount >= largeExpenseThreshold) {
      settings.rollbackCI(-negativeFeedbackDelta);
    }

    // v2.9: 只要记录了 ciDelta，就允许通用回滚（AI 判案 / 时间磨损等）
    if (tx.ciDelta != null) {
      settings.rollbackCI(-tx.ciDelta!);
    }
  }
}
