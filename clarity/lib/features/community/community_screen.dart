import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../input/input_provider.dart';

class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txCount = ref.watch(transactionsRepositoryProvider).getAll().length;
    final unlocked = txCount >= 5;
    final left = (5 - txCount).clamp(0, 5);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('战况大厅'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Community MVP',
              style: GoogleFonts.robotoMono(
                fontSize: 12,
                color: AppColors.textTertiary,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              unlocked ? '已解锁发布权限' : '未解锁发布权限',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: unlocked ? AppColors.expense : AppColors.warning,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              unlocked
                  ? '只能发布系统生成的标准化《战况卡片》（不支持自定义图片）。'
                  : '需要本地记账记录 ≥ 5 条才可发布。\n当前 $txCount 条，还差 $left 条。',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: unlocked ? AppColors.income : AppColors.surfaceVariant,
                  foregroundColor: unlocked ? Colors.white : AppColors.textTertiary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: !unlocked
                    ? null
                    : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('占位：战况卡片生成/发布流程待实现'),
                            backgroundColor: AppColors.surface,
                          ),
                        );
                      },
                child: Text(
                  unlocked ? '发布战况卡片（占位）' : '先去记满 5 笔',
                  style: GoogleFonts.spaceGrotesk(fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

