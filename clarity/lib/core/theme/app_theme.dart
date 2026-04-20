import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 中国股市配色：绿=跌/亏损/支出，红=涨/盈利/回馈
class AppColors {
  // Base
  static const Color background = Color(0xFF000000);
  static const Color surface = Color(0xFF0D0D0D);
  static const Color surfaceVariant = Color(0xFF1A1A1A);
  static const Color surfaceElevated = Color(0xFF242424);
  static const Color border = Color(0xFF2A2A2A);
  static const Color borderBright = Color(0xFF3A3A3A);

  // 支出/亏损 = 绿色（中国股市：绿=跌）
  static const Color expense = Color(0xFF00C087);
  static const Color expenseLight = Color(0x2200C087);
  static const Color expenseDark = Color(0xFF007A56);

  // 回馈/盈利 = 红色（中国股市：红=涨）
  static const Color income = Color(0xFFFF3B30);
  static const Color incomeLight = Color(0x22FF3B30);

  // 警告
  static const Color warning = Color(0xFFFF9500);
  static const Color warningLight = Color(0x22FF9500);

  // CI 分级色
  static const Color safe = expense; // 绿色：人间清醒
  static const Color danger = Color(0xFFFF6B00); // 橙色：重度内耗
  static const Color critical = Color(0xFFB00020); // 深红：彻底沦陷

  // 文字
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8E8E93);
  // 提升对比度：原来的 tertiary/quaternary 在纯黑背景下过暗，易读性差
  static const Color textTertiary = Color(0xFF6D6D72);
  static const Color textQuaternary = Color(0xFF5A5A5E);

  // 评级颜色
  static const Color ratingAAA = Color(0xFF00C087);
  static const Color ratingBBB = Color(0xFF0A84FF);
  static const Color ratingBB = Color(0xFFFF9500);
  static const Color ratingCC = Color(0xFFFF3B30);
  static const Color ratingD = Color(0xFF636366);
}

Color getCiColor(double ci) {
  if (ci >= 0.8) {
    return AppColors.safe; // 绿色：人间清醒
  } else if (ci >= 0.5) {
    return AppColors.warning; // 黄色：单方上头
  } else if (ci >= 0.2) {
    return AppColors.danger; // 橙色：重度内耗
  } else {
    return AppColors.critical; // 深红：彻底沦陷
  }
}

String getCiLabel(double ci) {
  if (ci >= 0.8) return '人间清醒';
  if (ci >= 0.5) return '单方上头';
  if (ci >= 0.2) return '重度内耗';
  return '彻底沦陷';
}

class AppTheme {
  static ThemeData get dark {
    final base = ThemeData.dark();
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.surface,
        primary: AppColors.expense,
        secondary: AppColors.income,
        error: AppColors.income,
        onSurface: AppColors.textPrimary,
        onPrimary: AppColors.textPrimary,
      ),
      textTheme: GoogleFonts.spaceGroteskTextTheme(base.textTheme).apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: -0.3,
        ),
        iconTheme: const IconThemeData(color: AppColors.textSecondary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
        elevation: 0,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 0,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.expense,
        inactiveTrackColor: AppColors.border,
        thumbColor: AppColors.expense,
        overlayColor: AppColors.expenseLight,
        valueIndicatorColor: AppColors.surfaceVariant,
        valueIndicatorTextStyle: GoogleFonts.robotoMono(
          color: AppColors.expense,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.surfaceElevated;
            }
            return AppColors.surface;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.textPrimary;
            }
            return AppColors.textSecondary;
          }),
          side: WidgetStateProperty.all(
            const BorderSide(color: AppColors.border),
          ),
          textStyle: WidgetStateProperty.all(
            GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.textPrimary,
        unselectedItemColor: AppColors.textTertiary,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.expense, width: 1.5),
        ),
        hintStyle: const TextStyle(color: AppColors.textTertiary),
      ),
    );
  }

  /// 根据金额获取颜色（支出=绿，回馈=红）
  static Color colorForAmount(double amount, {bool isExpense = true}) {
    return isExpense ? AppColors.expense : AppColors.income;
  }

  /// 根据 ROI 获取颜色
  static Color colorForRoi(double roi) {
    if (roi > 0.8) return AppColors.expense;
    if (roi > 0.3) return AppColors.warning;
    return AppColors.income;
  }

  /// 根据清醒指数 CI 获取颜色
  static Color colorForClarityIndex(double ci) {
    return getCiColor(ci);
  }
}
