import 'package:uuid/uuid.dart';
import '../local/hive_service.dart';
import '../local/entities/interaction_entity.dart';
import '../local/entities/transaction_entity.dart';
import './transactions_repository.dart';
import './settings_repository.dart';

const _uuid = Uuid();

class InteractionsRepository {
  /// 保存 Interaction
  void save(InteractionEntity entity) {
    if (entity.id.isEmpty) entity.id = _uuid.v4();
    HiveService.interactions.put(entity.id, entity);
  }

  /// 获取当前活动的等待（未完成）
  InteractionEntity? getActive() {
    try {
      return HiveService.interactions.values.firstWhere(
        (e) =>
            e.status == WaitStatus.running || e.status == WaitStatus.evaluating,
      );
    } catch (_) {
      return null;
    }
  }

  /// 获取所有已完成的 Interaction
  List<InteractionEntity> getAllCompleted() {
    return HiveService.interactions.values
        .where((e) => e.status == WaitStatus.finished)
        .toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
  }

  /// 获取所有 Interaction
  List<InteractionEntity> getAll() {
    return HiveService.interactions.values.toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
  }

  /// 删除 Interaction
  void delete(String id) {
    HiveService.interactions.delete(id);
  }

  /// 结算等待并更新 CI
  /// 返回生成的 Transaction（如果有等待成本）
  TransactionEntity? settleAndWaitUpdateCI({
    required InteractionEntity interaction,
    required Attitude attitude,
    required Medium medium,
  }) {
    interaction.attitude = attitude;
    interaction.medium = medium;
    interaction.calculatedIQS = interaction.calculateIQS();
    interaction.calculatedTI = interaction.calculateTI();
    interaction.endTime = DateTime.now();
    interaction.status = WaitStatus.finished;
    interaction.isCompleted = true;
    save(interaction);

    // v2.9.1: 时间磨损固定扣除（-0.1），IQS 仅用于“奖励/判定”
    final settings = SettingsRepository();
    const frictionDelta = -0.1;
    var netDelta = frictionDelta;
    settings.updateCI(frictionDelta);
    if (interaction.calculatedIQS! >= 0) {
      // 正向反馈奖励
      const bonus = 0.05;
      netDelta += bonus;
      settings.updateCI(bonus);
      settings.recordCIRise();
    } else {
      settings.recordCIDecline();
    }

    // v2.9: 如果有等待成本，生成 TIME_FRICTION Transaction（等待独立化）
    if (interaction.calculatedTI! > 0) {
      final ciDelta = netDelta;
      final tx = TransactionEntity()
        ..type = TransactionType.timeFriction
        ..laborDurationHours = interaction.waitDurationHours
        ..hourlyRateSnapshot = interaction.hourlyRateSnapshot
        ..weight = 1.2
        ..monetaryAmount = 0
        ..note = '时间磨损'
        ..actionTaken = 'CI ${ciDelta.toStringAsFixed(2)}'
        ..ciDelta = ciDelta
        ..timestamp = interaction.startTime;
      TransactionsRepository().add(tx);
      return tx;
    }
    return null;
  }

  /// 自动结算（超时未回复）
  void autoSettle(InteractionEntity interaction) {
    interaction.isAutoTriggered = true;
    interaction.attitude = Attitude.cold; // 默认冷暴力
    interaction.medium = Medium.text;
    interaction.calculatedIQS = interaction.calculateIQS();
    interaction.calculatedTI = interaction.calculateTI();
    interaction.endTime = DateTime.now();
    interaction.status = WaitStatus.finished;
    interaction.isCompleted = true;
    save(interaction);

    // 自动结算视为负向反馈
    const ciDelta = -0.1;
    SettingsRepository().updateCI(ciDelta);
    SettingsRepository().recordCIDecline();

    // v2.9: 生成 TIME_FRICTION Transaction（TI）
    if (interaction.calculatedTI != null && interaction.calculatedTI! > 0) {
      final tx = TransactionEntity()
        ..type = TransactionType.timeFriction
        ..laborDurationHours = interaction.waitDurationHours
        ..hourlyRateSnapshot = interaction.hourlyRateSnapshot
        ..weight = 1.2
        ..monetaryAmount = 0
        ..note = '时间磨损（自动结算）'
        ..actionTaken = 'CI ${ciDelta.toStringAsFixed(2)}'
        ..ciDelta = ciDelta
        ..timestamp = interaction.startTime;
      TransactionsRepository().add(tx);
    }
  }
}
