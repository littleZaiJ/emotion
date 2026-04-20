import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import 'onboarding_provider.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(flex: 1),
              _Header(),
              const Gap(32),
              Expanded(flex: 4, child: _StepContent()),
              const Gap(24),
              _BottomActions(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(onboardingControllerProvider);

    return Column(
      children: [
        Text(
          '恋爱账单',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const Gap(8),
        Text(
          'CLARITY',
          style: GoogleFonts.robotoMono(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textTertiary,
            letterSpacing: 3,
          ),
        ),
        const Gap(8),
        Text(
          '帮你算清感情里的账',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        const Gap(24),
        // 步骤指示器
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _StepDot(isActive: form.currentStep == 0, label: '1'),
            Container(
              width: 40,
              height: 2,
              color: form.currentStep > 0
                  ? AppColors.expense
                  : AppColors.border,
            ),
            _StepDot(isActive: form.currentStep == 1, label: '2'),
          ],
        ),
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  final bool isActive;
  final String label;

  const _StepDot({required this.isActive, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isActive ? AppColors.expense : AppColors.surfaceVariant,
        shape: BoxShape.circle,
        border: Border.all(
          color: isActive ? AppColors.expense : AppColors.border,
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          label,
          style: GoogleFonts.robotoMono(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isActive ? Colors.white : AppColors.textTertiary,
          ),
        ),
      ),
    );
  }
}

class _StepContent extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(onboardingControllerProvider);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: form.currentStep == 0
          ? _HourlyRateStep(key: const ValueKey('step1'))
          : _PreferenceStep(key: const ValueKey('step2')),
    );
  }
}

class _HourlyRateStep extends ConsumerStatefulWidget {
  const _HourlyRateStep({super.key});

  @override
  ConsumerState<_HourlyRateStep> createState() => _HourlyRateStepState();
}

class _HourlyRateStepState extends ConsumerState<_HourlyRateStep> {
  late final TextEditingController _rateController;
  late final FocusNode _rateFocusNode;

  @override
  void initState() {
    super.initState();
    final rate = ref.read(onboardingControllerProvider).hourlyRate;
    _rateController = TextEditingController(text: rate.toStringAsFixed(0));
    _rateFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _rateController.dispose();
    _rateFocusNode.dispose();
    super.dispose();
  }

  void _setRate(double rate) {
    ref.read(onboardingControllerProvider.notifier).setHourlyRate(rate);
    _rateController.text = rate.toStringAsFixed(0);
    _rateController.selection = TextSelection.collapsed(
      offset: _rateController.text.length,
    );
    _rateFocusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);
    final rateText = form.hourlyRate.toStringAsFixed(0);
    if (!_rateFocusNode.hasFocus && _rateController.text != rateText) {
      _rateController.text = rateText;
      _rateController.selection =
          TextSelection.collapsed(offset: _rateController.text.length);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '你的时间值多少钱？',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const Gap(8),
        Text(
          '设定你的时薪基准，用于计算"出力"折算成多少钱',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const Gap(32),
        // 时薪输入
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '时薪基准（元/小时）',
                style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
              ),
              const Gap(12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '¥',
                    style: GoogleFonts.robotoMono(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.expense,
                    ),
                  ),
                  const Gap(8),
                  Expanded(
                    child: TextField(
                      controller: _rateController,
                      focusNode: _rateFocusNode,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}'),
                        ),
                      ],
                      style: GoogleFonts.robotoMono(
                        fontSize: 48,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: '50',
                        hintStyle: GoogleFonts.robotoMono(
                          fontSize: 48,
                          color: AppColors.textQuaternary,
                        ),
                      ),
                      onChanged: (v) {
                        final rate = double.tryParse(v) ?? 50.0;
                        controller.setHourlyRate(rate);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Gap(24),
        // 快捷选择
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [30.0, 50.0, 100.0, 200.0].map((rate) {
            final selected = (form.hourlyRate - rate).abs() < 0.01;
            return GestureDetector(
              onTap: () => _setRate(rate),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.expense.withAlpha(15)
                      : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: selected ? AppColors.expense : AppColors.border,
                  ),
                ),
                child: Text(
                  '¥${rate.toInt()}/h',
                  style: TextStyle(
                    fontSize: 13,
                    color: selected
                        ? AppColors.expense
                        : AppColors.textSecondary,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const Gap(24),
        // 说明
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant.withAlpha(50),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: AppColors.textTertiary),
              const Gap(8),
              Expanded(
                child: Text(
                  '例如：帮忙搬家 3 小时 = ¥${(form.hourlyRate * 3).toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PreferenceStep extends ConsumerWidget {
  const _PreferenceStep({super.key});

  static const _preferences = [
    {'id': 'digital', 'label': '数码', 'icon': '📱'},
    {'id': 'beauty', 'label': '美妆', 'icon': '💄'},
    {'id': 'gaming', 'label': '游戏', 'icon': '🕹️'},
    {'id': 'food', 'label': '美食', 'icon': '🍜'},
    {'id': 'travel', 'label': '旅行', 'icon': '🧳'},
    {'id': 'fashion', 'label': '时尚', 'icon': '👗'},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '你平时喜欢买什么？',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const Gap(8),
        Text(
          '选择 1-3 个，我们会用这些等价物来冲击你',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const Gap(24),
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: _preferences.map((pref) {
              final selected = form.selectedPreferences.contains(pref['id']);
              return GestureDetector(
                onTap: () => controller.togglePreference(pref['id'] as String),
                child: Container(
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.expense.withAlpha(15)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected ? AppColors.expense : AppColors.border,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        pref['icon'] as String,
                        style: const TextStyle(fontSize: 28),
                      ),
                      const Gap(8),
                      Text(
                        pref['label'] as String,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: selected
                              ? AppColors.expense
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _BottomActions extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);

    return Row(
      children: [
        if (form.currentStep > 0)
          Expanded(
            child: OutlinedButton(
              onPressed: () => controller.prevStep(),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('上一步'),
            ),
          ),
        if (form.currentStep > 0) const Gap(12),
        Expanded(
          flex: form.currentStep > 0 ? 2 : 1,
          child: ElevatedButton(
            onPressed: form.canProceed
                ? () {
                    if (form.currentStep == 0) {
                      controller.nextStep();
                    } else {
                      controller.complete();
                      context.go('/dashboard');
                    }
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expense,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.surfaceVariant,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              form.currentStep == 0 ? '下一步' : '开始记账',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
