import 'package:hive_flutter/hive_flutter.dart';
import 'transaction_entity.dart';

part 'interaction_entity.g.dart';

/// 等待计时器状态
@HiveType(typeId: 10)
enum WaitStatus {
  @HiveField(0)
  idle, // 空闲
  @HiveField(1)
  running, // 计时中
  @HiveField(2)
  evaluating, // 评估中（Ta回复了）
  @HiveField(3)
  finished, // 已结算
}

@HiveType(typeId: 4)
class InteractionEntity extends HiveObject {
  @HiveField(0)
  late String id;
  @HiveField(1)
  late DateTime startTime;
  @HiveField(2)
  DateTime? endTime;
  @HiveField(3)
  bool isCompleted = false;

  // 态度评分
  @HiveField(4)
  Attitude? attitude;

  // 媒介类型
  @HiveField(5)
  Medium? medium;

  // 计算得到的 IQS
  @HiveField(6)
  double? calculatedIQS;

  // 等待成本（TI）
  @HiveField(7)
  double? calculatedTI;

  // 是否自动触发（超时自动结算）
  @HiveField(8)
  bool isAutoTriggered = false;

  // 当前状态
  @HiveField(9)
  WaitStatus status = WaitStatus.idle;

  // 时薪快照
  @HiveField(10)
  double hourlyRateSnapshot = 50.0;

  /// 获取等待时长（分钟）
  double get waitDurationMinutes {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime).inSeconds / 60.0;
  }

  /// 获取等待时长（小时）
  double get waitDurationHours => waitDurationMinutes / 60.0;

  /// 计算 IQS
  double calculateIQS() {
    return (TransactionEntity.getAttitudeScore(attitude) +
            TransactionEntity.getMediumScore(medium))
        .toDouble();
  }

  /// 计算等待成本（TI）
  /// v2.9: 时间磨损权重提升，强调“被动消耗更伤身”
  double calculateTI() {
    return waitDurationHours * hourlyRateSnapshot * 1.2;
  }
}
