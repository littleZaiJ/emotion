import 'package:hive_flutter/hive_flutter.dart';

part 'user_settings_entity.g.dart';

/// 等价物偏好标签
@HiveType(typeId: 11)
enum EquivalentPreference {
  @HiveField(0)
  digital, // 数码
  @HiveField(1)
  beauty, // 美妆
  @HiveField(2)
  gaming, // 游戏
  @HiveField(3)
  food, // 美食
  @HiveField(4)
  travel, // 旅行
  @HiveField(5)
  fashion, // 时尚
}

@HiveType(typeId: 5)
class UserSettingsEntity extends HiveObject {
  /// 时薪基准（元/小时）
  @HiveField(0)
  double hourlyRate = 50.0;

  /// 等待阈值（分钟）
  @HiveField(1)
  int dignityThresholdMin = 240;

  /// LongCat API Key（OpenAI 兼容格式）
  @HiveField(2)
  String claudeApiKey = '';

  /// 等价物偏好标签列表
  @HiveField(3)
  List<String> equivalentPreferences = ['digital'];

  /// 当前 CI 值（初始1.0）
  @HiveField(4)
  double ciValue = 1.0;

  /// 最后记录日期（用于自然衰减判断）
  @HiveField(5)
  DateTime? lastRecordDate;

  /// CI 连续下降天数
  @HiveField(6)
  int ciDeclineDays = 0;

  /// CI 连续上升天数
  @HiveField(7)
  int ciRiseDays = 0;

  /// 是否已完成 Onboarding
  @HiveField(8)
  bool hasCompletedOnboarding = false;

  /// 自动结算等待时间（分钟）
  @HiveField(9)
  int autoMarkAfterMin = 30;

  /// 调试模式：在首页显示调试控制（CI/等待时长轴）
  @HiveField(10)
  bool debugMode = false;

  /// 更新 CI 值
  /// 变化量：正数增加，负数减少
  /// 最高不超过 1.0，最低不低于 0
  void updateCI(double delta) {
    ciValue = (ciValue + delta).clamp(0.0, 1.0);
  }

  /// 检查是否需要自然衰减恢复
  /// 连续3天无记录，CI 恢复 0.1
  bool shouldNaturalRecovery() {
    if (lastRecordDate == null) return false;
    if (ciValue >= 1.0) return false;

    final now = DateTime.now();
    final lastDate = DateTime(
      lastRecordDate!.year,
      lastRecordDate!.month,
      lastRecordDate!.day,
    );
    final today = DateTime(now.year, now.month, now.day);
    final daysSinceLastRecord = today.difference(lastDate).inDays;

    return daysSinceLastRecord >= 3;
  }

  /// 执行自然衰减恢复
  void applyNaturalRecovery() {
    if (shouldNaturalRecovery()) {
      updateCI(0.1);
      lastRecordDate = DateTime.now();
    }
  }
}
