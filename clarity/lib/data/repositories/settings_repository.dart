import '../local/hive_service.dart';
import '../local/entities/user_settings_entity.dart';

class SettingsRepository {
  static const _singletonKey = 'singleton';

  /// 获取设置
  UserSettingsEntity get() {
    return HiveService.settings.get(_singletonKey) ?? UserSettingsEntity();
  }

  /// 保存设置
  void save(UserSettingsEntity settings) {
    HiveService.settings.put(_singletonKey, settings);
  }

  /// 更新 CI 值
  /// delta: 变化量，正数增加，负数减少
  void updateCI(double delta) {
    final settings = get();
    settings.updateCI(delta);
    settings.lastRecordDate = DateTime.now();
    save(settings);
  }

  /// 记录 CI 下降
  void recordCIDecline() {
    final settings = get();
    settings.ciDeclineDays++;
    settings.ciRiseDays = 0;
    save(settings);
  }

  /// 记录 CI 上升
  void recordCIRise() {
    final settings = get();
    settings.ciRiseDays++;
    settings.ciDeclineDays = 0;
    save(settings);
  }

  /// 重置 CI 趋势计数
  void resetCITrend() {
    final settings = get();
    settings.ciDeclineDays = 0;
    settings.ciRiseDays = 0;
    save(settings);
  }

  /// 检查并执行自然衰减恢复
  void checkNaturalRecovery() {
    final settings = get();
    if (settings.shouldNaturalRecovery()) {
      settings.applyNaturalRecovery();
      save(settings);
    }
  }

  /// 回滚 CI（删除记录时调用）
  /// delta: 需要回滚的变化量（反向）
  void rollbackCI(double delta) {
    final settings = get();
    settings.updateCI(delta);
    save(settings);
  }

  /// 更新时薪
  void updateHourlyRate(double rate) {
    final settings = get();
    settings.hourlyRate = rate;
    save(settings);
  }

  /// 更新等价物偏好
  void updateEquivalentPreferences(List<String> preferences) {
    final settings = get();
    settings.equivalentPreferences = preferences;
    save(settings);
  }

  /// 完成 Onboarding
  void completeOnboarding({
    required double hourlyRate,
    required List<String> equivalentPreferences,
  }) {
    final settings = get();
    settings.hourlyRate = hourlyRate;
    settings.equivalentPreferences = equivalentPreferences;
    settings.hasCompletedOnboarding = true;
    settings.lastRecordDate = DateTime.now();
    save(settings);
  }

  /// 是否已完成 Onboarding
  bool hasCompletedOnboarding() {
    return get().hasCompletedOnboarding;
  }
}
