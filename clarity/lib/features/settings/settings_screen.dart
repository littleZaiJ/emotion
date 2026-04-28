import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../core/utils/metrics_calculator.dart';
import '../../core/theme/app_theme.dart';
import '../../data/local/entities/transaction_entity.dart';
import '../../data/local/hive_service.dart';
import '../dashboard/dashboard_provider.dart';
import '../input/input_provider.dart';
import 'settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  Future<bool> _confirmDangerousAction({
    required String title,
    required String message,
  }) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          title,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          message,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              '取消',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              '继续',
              style: TextStyle(
                color: AppColors.income,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    return confirm == true;
  }

  Future<void> _applySimulationPreset(_SimulationPreset preset) async {
    final ok = await _confirmDangerousAction(
      title: '加载模拟数据',
      message: '将清空你当前所有账单和等待记录，并写入一组模拟数据。\n\n确定加载：${preset.title}？',
    );
    if (!ok) return;

    await HiveService.transactions.clear();
    try {
      await HiveService.interactions.clear();
    } catch (_) {
      // optional
    }

    final txRepo = ref.read(transactionsRepositoryProvider);
    final now = DateTime.now();
    for (final tx in preset.buildTransactions(now: now)) {
      txRepo.add(tx);
    }

    ref
        .read(settingsNotifierProvider.notifier)
        .applyDebugPreset(
          hourlyRate: preset.hourlyRate,
          dignityThresholdMin: preset.dignityThresholdMin,
          autoMarkAfterMin: preset.autoMarkAfterMin,
          equivalentPreferences: preset.equivalentPreferences,
          ciValue: preset.ciValue,
          ciDeclineDays: preset.ciDeclineDays,
          ciRiseDays: preset.ciRiseDays,
          debugMode: true,
        );

    ref.invalidate(transactionsRepositoryProvider);
    ref.invalidate(dashboardNotifierProvider);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已加载模拟数据：${preset.title}'),
        backgroundColor: AppColors.surface,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionTitle('时间价值'),
          const Gap(12),
          _SettingRow(
            label: '我的时薪',
            subtitle: '用于将劳务时长折算为金钱价值',
            trailing: _EditableValue(
              value: settings.hourlyRate.toStringAsFixed(0),
              prefix: '¥',
              suffix: '/h',
              onSave: (v) {
                final rate = double.tryParse(v);
                if (rate != null && rate > 0) {
                  ref
                      .read(settingsNotifierProvider.notifier)
                      .updateHourlyRate(rate);
                }
              },
            ),
          ),
          const Gap(8),
          _SettingRow(
            label: '尊严阈值',
            subtitle: '等待超过此时长时触发红色警告',
            trailing: _EditableValue(
              value: settings.dignityThresholdMin.toString(),
              suffix: '分钟',
              onSave: (v) {
                final min = int.tryParse(v);
                if (min != null && min > 0) {
                  ref
                      .read(settingsNotifierProvider.notifier)
                      .updateDignityThreshold(min);
                }
              },
            ),
          ),
          const Gap(8),
          _SettingRow(
            label: '自动判定已读不回',
            subtitle: '超过尊严阈值后，再等多久自动记账为"已读不回"',
            trailing: _EditableValue(
              value: settings.autoMarkAfterMin.toString(),
              suffix: '分钟',
              onSave: (v) {
                final min = int.tryParse(v);
                if (min != null && min >= 0) {
                  ref
                      .read(settingsNotifierProvider.notifier)
                      .updateAutoMarkAfterMin(min);
                }
              },
            ),
          ),
          const Gap(24),

          _SectionTitle('清醒指数'),
          const Gap(12),
          _CICard(settings: settings),
          const Gap(24),

          _SectionTitle('AI 毒舌助理（可选）'),
          const Gap(12),
          _ApiKeyRow(
            apiKey: settings.claudeApiKey,
            onSave: (v) =>
                ref.read(settingsNotifierProvider.notifier).updateApiKey(v),
          ),
          const Gap(24),

          _SectionTitle('调试工具'),
          const Gap(12),
          _SettingRow(
            label: 'Debug 模式',
            subtitle: '首页显示 CI / 等待时长调试轴',
            trailing: Switch(
              value: settings.debugMode,
              onChanged: (v) =>
                  ref.read(settingsNotifierProvider.notifier).setDebugMode(v),
              activeThumbColor: AppColors.expense,
            ),
          ),
          const Gap(8),
          _DebugButton(
            label: '重置清醒指数为 1.0',
            icon: Icons.refresh,
            color: AppColors.expense,
            onTap: () {
              ref.read(settingsNotifierProvider.notifier).resetCI();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('清醒指数已重置为 1.0'),
                  backgroundColor: AppColors.surface,
                ),
              );
            },
          ),
          const Gap(8),
          _DebugButton(
            label: '设定 CI = 1.00（健康）',
            icon: Icons.favorite,
            color: AppColors.expense,
            onTap: () {
              ref.read(settingsNotifierProvider.notifier).setCIValue(1.0);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('CI 已设为 1.00'),
                  backgroundColor: AppColors.surface,
                ),
              );
            },
          ),
          const Gap(8),
          _DebugButton(
            label: '设定 CI = 0.60（警告）',
            icon: Icons.warning_amber_outlined,
            color: AppColors.warning,
            onTap: () {
              ref.read(settingsNotifierProvider.notifier).setCIValue(0.6);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('CI 已设为 0.60'),
                  backgroundColor: AppColors.surface,
                ),
              );
            },
          ),
          const Gap(8),
          _DebugButton(
            label: '设定 CI = 0.20（危险）',
            icon: Icons.health_and_safety_outlined,
            color: AppColors.income,
            onTap: () {
              ref.read(settingsNotifierProvider.notifier).setCIValue(0.2);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('CI 已设为 0.20'),
                  backgroundColor: AppColors.surface,
                ),
              );
            },
          ),
          const Gap(8),
          _DebugButton(
            label: '清空所有数据',
            icon: Icons.delete_sweep_outlined,
            color: AppColors.income,
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppColors.surface,
                  title: const Text(
                    '清空数据',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                  content: const Text(
                    '确定清空所有账单记录？',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text(
                        '取消',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text(
                        '清空',
                        style: TextStyle(
                          color: AppColors.income,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await HiveService.transactions.clear();
                ref.invalidate(transactionsRepositoryProvider);
                ref.invalidate(dashboardNotifierProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('数据已清空'),
                      backgroundColor: AppColors.surface,
                    ),
                  );
                }
              }
            },
          ),
          const Gap(24),
          _SectionTitle('模拟数据'),
          const Gap(12),
          _DebugButton(
            label: '加载模拟：等价物暴击（亏损期 + CI=0.20）',
            icon: Icons.bolt,
            color: AppColors.expense,
            onTap: () =>
                _applySimulationPreset(_SimulationPreset.lossCritical()),
          ),
          const Gap(8),
          _DebugButton(
            label: '加载模拟：情绪盈余（盈余期 + CI=1.00）',
            icon: Icons.trending_up,
            color: AppColors.income,
            onTap: () =>
                _applySimulationPreset(_SimulationPreset.profitHealthy()),
          ),
          const Gap(8),
          _DebugButton(
            label: '加载模拟：小额暴击（<¥25 文案 + CI=0.60）',
            icon: Icons.speaker_notes_outlined,
            color: AppColors.warning,
            onTap: () =>
                _applySimulationPreset(_SimulationPreset.tinyLossWarning()),
          ),
        ],
      ),
    );
  }
}

class _SimulationPreset {
  final String title;
  final double ciValue;
  final int ciDeclineDays;
  final int ciRiseDays;
  final double hourlyRate;
  final int dignityThresholdMin;
  final int autoMarkAfterMin;
  final List<String> equivalentPreferences;
  final List<TransactionEntity> Function({required DateTime now})
  buildTransactions;

  const _SimulationPreset({
    required this.title,
    required this.ciValue,
    required this.ciDeclineDays,
    required this.ciRiseDays,
    required this.hourlyRate,
    required this.dignityThresholdMin,
    required this.autoMarkAfterMin,
    required this.equivalentPreferences,
    required this.buildTransactions,
  });

  static TransactionEntity _expense({
    required DateTime at,
    required double amount,
    ExpenseCategory category = ExpenseCategory.gift,
    ExpenseSubCategory subCategory = ExpenseSubCategory.flowersHandmade,
    String? note,
  }) {
    final tx = TransactionEntity()
      ..timestamp = at
      ..type = TransactionType.expense
      ..expenseCategory = category
      ..expenseSubCategory = subCategory
      ..monetaryAmount = amount
      ..note = note;
    return tx;
  }

  static TransactionEntity _labor({
    required DateTime at,
    required double hours,
    required double hourlyRate,
    LaborCategory category = LaborCategory.emotional,
    LaborSubCategory subCategory = LaborSubCategory.lateNightComfort,
    String? note,
  }) {
    final weight = TransactionEntity.getLaborWeight(category);
    final tx = TransactionEntity()
      ..timestamp = at
      ..type = TransactionType.labor
      ..laborCategory = category
      ..laborSubCategory = subCategory
      ..laborDurationHours = hours
      ..hourlyRateSnapshot = hourlyRate
      ..weight = weight
      ..note = note;
    return tx;
  }

  static TransactionEntity _return({
    required DateTime at,
    required double amount,
    required Attitude attitude,
    required Medium medium,
    ReturnSubCategory subCategory = ReturnSubCategory.treatMeal,
    String? note,
  }) {
    final tx = TransactionEntity()
      ..timestamp = at
      ..type = TransactionType.return_
      ..returnCategory = ReturnCategory.material
      ..returnSubCategory = subCategory
      ..monetaryAmount = amount
      ..attitude = attitude
      ..medium = medium
      ..iqs = MetricsCalculator.calculateIQS(attitude: attitude, medium: medium)
      ..note = note;
    return tx;
  }

  factory _SimulationPreset.lossCritical() {
    return _SimulationPreset(
      title: '等价物暴击（亏损期）',
      ciValue: 0.2,
      ciDeclineDays: 3,
      ciRiseDays: 0,
      hourlyRate: 120,
      dignityThresholdMin: 240,
      autoMarkAfterMin: 30,
      equivalentPreferences: const ['digital', 'gaming'],
      buildTransactions: ({required DateTime now}) => [
        _expense(
          at: now.subtract(const Duration(days: 6, hours: 4)),
          amount: 800,
          category: ExpenseCategory.gift,
          subCategory: ExpenseSubCategory.jewelryBags,
          note: '“我觉得你会喜欢”',
        ),
        _labor(
          at: now.subtract(const Duration(days: 5, hours: 3)),
          hours: 3,
          hourlyRate: 120,
          category: LaborCategory.emotional,
          subCategory: LaborSubCategory.lateNightComfort,
          note: '深夜情绪安抚',
        ),
        _expense(
          at: now.subtract(const Duration(days: 4, hours: 2)),
          amount: 1200,
          category: ExpenseCategory.date,
          subCategory: ExpenseSubCategory.fineDining,
          note: '高档餐厅',
        ),
        _labor(
          at: now.subtract(const Duration(days: 3, hours: 5)),
          hours: 6,
          hourlyRate: 120,
          category: LaborCategory.timeSunk,
          subCategory: LaborSubCategory.longWaiting,
          note: '单方面漫长等待',
        ),
        _expense(
          at: now.subtract(const Duration(days: 2, hours: 1)),
          amount: 500,
          category: ExpenseCategory.transfer,
          subCategory: ExpenseSubCategory.payBills,
          note: '“先垫一下”',
        ),
        _return(
          at: now.subtract(const Duration(days: 1, hours: 2)),
          amount: 200,
          attitude: Attitude.dismissive,
          medium: Medium.text,
          subCategory: ReturnSubCategory.moneyTransfer,
          note: '敷衍转账',
        ),
        _return(
          at: now.subtract(const Duration(hours: 3)),
          amount: 50,
          attitude: Attitude.cold,
          medium: Medium.voice,
          subCategory: ReturnSubCategory.treatMeal,
          note: '冷暴力语音',
        ),
      ],
    );
  }

  factory _SimulationPreset.profitHealthy() {
    return _SimulationPreset(
      title: '情绪盈余（盈余期）',
      ciValue: 1.0,
      ciDeclineDays: 0,
      ciRiseDays: 1,
      hourlyRate: 80,
      dignityThresholdMin: 180,
      autoMarkAfterMin: 20,
      equivalentPreferences: const ['food', 'travel'],
      buildTransactions: ({required DateTime now}) => [
        _expense(
          at: now.subtract(const Duration(days: 3, hours: 2)),
          amount: 200,
          category: ExpenseCategory.date,
          subCategory: ExpenseSubCategory.movieShow,
          note: '一起看演出',
        ),
        _labor(
          at: now.subtract(const Duration(days: 2, hours: 1)),
          hours: 2,
          hourlyRate: 80,
          category: LaborCategory.physical,
          subCategory: LaborSubCategory.errandsPickup,
          note: '接送跑腿',
        ),
        _return(
          at: now.subtract(const Duration(days: 1, hours: 4)),
          amount: 1200,
          attitude: Attitude.proactive,
          medium: Medium.media,
          subCategory: ReturnSubCategory.receivedGift,
          note: '主动送礼',
        ),
      ],
    );
  }

  factory _SimulationPreset.tinyLossWarning() {
    return _SimulationPreset(
      title: '小额暴击（亏损期 < ¥25）',
      ciValue: 0.6,
      ciDeclineDays: 1,
      ciRiseDays: 0,
      hourlyRate: 60,
      dignityThresholdMin: 240,
      autoMarkAfterMin: 30,
      equivalentPreferences: const ['food'],
      buildTransactions: ({required DateTime now}) => [
        _expense(
          at: now.subtract(const Duration(hours: 6)),
          amount: 20,
          category: ExpenseCategory.gift,
          subCategory: ExpenseSubCategory.flowersHandmade,
          note: '小礼物',
        ),
        _return(
          at: now.subtract(const Duration(hours: 2)),
          amount: 0,
          attitude: Attitude.dismissive,
          medium: Medium.text,
          subCategory: ReturnSubCategory.deepTalk,
          note: '“嗯”',
        ),
      ],
    );
  }
}

class _CICard extends ConsumerWidget {
  final dynamic settings;

  const _CICard({required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ci = settings.ciValue as double;
    final declineDays = settings.ciDeclineDays as int;
    final riseDays = settings.ciRiseDays as int;

    Color statusColor;
    String statusLabel;
    if (ci >= 1.0) {
      statusColor = AppColors.expense;
      statusLabel = '健康';
    } else if (ci >= 0.3) {
      statusColor = AppColors.warning;
      statusLabel = '警告';
    } else {
      statusColor = AppColors.income;
      statusLabel = '危险';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '当前清醒指数 (CI)',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const Gap(12),
          Text(
            ci.toStringAsFixed(2),
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: statusColor,
            ),
          ),
          const Gap(8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: ci.clamp(0.0, 1.0),
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation(statusColor),
              minHeight: 4,
            ),
          ),
          const Gap(12),
          Row(
            children: [
              Text(
                '连续下降: $declineDays 天',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textTertiary,
                ),
              ),
              const Gap(16),
              Text(
                '连续上升: $riseDays 天',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        color: AppColors.textTertiary,
        letterSpacing: 1.5,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final String label;
  final String subtitle;
  final Widget trailing;

  const _SettingRow({
    required this.label,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Gap(2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _DebugButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _DebugButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withAlpha(10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const Gap(10),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ApiKeyRow extends StatelessWidget {
  final String apiKey;
  final ValueChanged<String> onSave;
  const _ApiKeyRow({required this.apiKey, required this.onSave});

  String get _masked {
    if (apiKey.isEmpty) return '未配置';
    if (apiKey.length <= 8) return '••••••••';
    return '${apiKey.substring(0, 8)}••••••••';
  }

  void _showEdit(BuildContext context) {
    final ctrl = TextEditingController(text: apiKey);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'LongCat API Key',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: ctrl,
              obscureText: true,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
              decoration: const InputDecoration(
                hintText: 'ak_...',
                hintStyle: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 13,
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.expense),
                ),
              ),
              autofocus: true,
            ),
            const Gap(8),
            const Text(
              '配置后 Crush 粉碎机 / 短评将更毒舌（可选），留空则使用内置规则引擎',
              style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              '取消',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              onSave(ctrl.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text(
              '保存',
              style: TextStyle(
                color: AppColors.expense,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasKey = apiKey.isNotEmpty;
    return GestureDetector(
      onTap: () => _showEdit(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'API Key',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Gap(2),
                  const Text(
                    '用于 AI 生成更毒舌短评，不填则使用规则引擎',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: hasKey
                      ? AppColors.expense.withAlpha(80)
                      : AppColors.border,
                ),
              ),
              child: Text(
                _masked,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: hasKey ? AppColors.expense : AppColors.textTertiary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditableValue extends StatelessWidget {
  final String value;
  final String? prefix;
  final String? suffix;
  final ValueChanged<String> onSave;

  const _EditableValue({
    required this.value,
    this.prefix,
    this.suffix,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showEdit(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          '${prefix ?? ''}$value${suffix ?? ''}',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.expense,
          ),
        ),
      ),
    );
  }

  void _showEdit(BuildContext context) {
    final ctrl = TextEditingController(text: value);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          '修改数值',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
          ],
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 20),
          decoration: InputDecoration(
            prefixText: prefix,
            suffixText: suffix,
            prefixStyle: const TextStyle(
              color: AppColors.expense,
              fontSize: 20,
            ),
            suffixStyle: const TextStyle(color: AppColors.textSecondary),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.expense),
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              '取消',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              onSave(ctrl.text);
              Navigator.pop(ctx);
            },
            child: const Text(
              '保存',
              style: TextStyle(
                color: AppColors.expense,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
