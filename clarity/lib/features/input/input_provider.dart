import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/local/entities/transaction_entity.dart';
import '../../data/repositories/transactions_repository.dart';
import '../../core/services/ci_service.dart';
import '../dashboard/dashboard_provider.dart';

part 'input_provider.g.dart';

@riverpod
TransactionsRepository transactionsRepository(TransactionsRepositoryRef ref) {
  return TransactionsRepository();
}

/// 记账表单状态
class InputFormState {
  /// 交易类型：花钱/出力/回馈
  final TransactionType type;

  /// v2.9.1: 顶级方向（二元）
  final TransactionDirection directionV2;

  /// v2.9.1: 二元树下分类
  final ExpenseCategoryV2? expenseCategoryV2;
  final ReturnCategoryV2? returnCategoryV2;
  final IntimacyAction? intimacyAction;
  final EmotionalValueAction? emotionalValueAction;

  // 花钱模式分类
  final ExpenseCategory? expenseCategory;
  final ExpenseSubCategory? expenseSubCategory;

  // 出力模式分类
  final LaborCategory? laborCategory;
  final LaborSubCategory? laborSubCategory;

  // 回馈模式分类
  final ReturnCategory? returnCategory;
  final ReturnSubCategory? returnSubCategory;

  // 回馈评分
  final Attitude? attitude;
  final Medium? medium;

  // 金额/时长
  final double monetaryAmount;
  final double laborHours;
  final String note;

  const InputFormState({
    this.type = TransactionType.expense,
    this.directionV2 = TransactionDirection.expense,
    this.expenseCategoryV2 = ExpenseCategoryV2.financial,
    this.returnCategoryV2,
    this.intimacyAction,
    this.emotionalValueAction,
    this.expenseCategory,
    this.expenseSubCategory,
    this.laborCategory,
    this.laborSubCategory,
    this.returnCategory,
    this.returnSubCategory,
    this.attitude,
    this.medium,
    this.monetaryAmount = 0.0,
    this.laborHours = 0.0,
    this.note = '',
  });

  InputFormState copyWith({
    TransactionType? type,
    TransactionDirection? directionV2,
    ExpenseCategoryV2? expenseCategoryV2,
    ReturnCategoryV2? returnCategoryV2,
    IntimacyAction? intimacyAction,
    EmotionalValueAction? emotionalValueAction,
    ExpenseCategory? expenseCategory,
    ExpenseSubCategory? expenseSubCategory,
    LaborCategory? laborCategory,
    LaborSubCategory? laborSubCategory,
    ReturnCategory? returnCategory,
    ReturnSubCategory? returnSubCategory,
    Attitude? attitude,
    Medium? medium,
    double? monetaryAmount,
    double? laborHours,
    String? note,
    bool clearExpenseCategory = false,
    bool clearLaborCategory = false,
    bool clearReturnCategory = false,
    bool clearAttitude = false,
    bool clearMedium = false,
    bool clearV2Categories = false,
  }) {
    return InputFormState(
      type: type ?? this.type,
      directionV2: directionV2 ?? this.directionV2,
      expenseCategoryV2: clearV2Categories
          ? null
          : (expenseCategoryV2 ?? this.expenseCategoryV2),
      returnCategoryV2: clearV2Categories
          ? null
          : (returnCategoryV2 ?? this.returnCategoryV2),
      intimacyAction: clearV2Categories
          ? null
          : (intimacyAction ?? this.intimacyAction),
      emotionalValueAction: clearV2Categories
          ? null
          : (emotionalValueAction ?? this.emotionalValueAction),
      expenseCategory: clearExpenseCategory
          ? null
          : (expenseCategory ?? this.expenseCategory),
      expenseSubCategory: clearExpenseCategory
          ? null
          : (expenseSubCategory ?? this.expenseSubCategory),
      laborCategory: clearLaborCategory
          ? null
          : (laborCategory ?? this.laborCategory),
      laborSubCategory: clearLaborCategory
          ? null
          : (laborSubCategory ?? this.laborSubCategory),
      returnCategory: clearReturnCategory
          ? null
          : (returnCategory ?? this.returnCategory),
      returnSubCategory: clearReturnCategory
          ? null
          : (returnSubCategory ?? this.returnSubCategory),
      attitude: clearAttitude ? null : (attitude ?? this.attitude),
      medium: clearMedium ? null : (medium ?? this.medium),
      monetaryAmount: monetaryAmount ?? this.monetaryAmount,
      laborHours: laborHours ?? this.laborHours,
      note: note ?? this.note,
    );
  }

  /// 获取当前权重
  double get weight {
    if (type == TransactionType.labor) {
      return TransactionEntity.getLaborWeight(laborCategory);
    }
    if (type == TransactionType.return_) {
      if (returnCategoryV2 == ReturnCategoryV2.intimacy ||
          returnCategoryV2 == ReturnCategoryV2.emotionalValue) {
        return 1.0;
      }
      return getReturnWeight(returnCategory);
    }
    if (type == TransactionType.timeFriction) {
      return expenseCategoryV2 == ExpenseCategoryV2.emotionalDrain ? 1.0 : 1.2;
    }
    return 1.0;
  }

  /// 获取回馈分类权重
  static double getReturnWeight(ReturnCategory? cat) {
    switch (cat) {
      case ReturnCategory.material:
        return 1.0;
      case ReturnCategory.emotional:
        return 1.2;
      case ReturnCategory.action:
        return 1.0;
      default:
        return 1.0;
    }
  }

  /// 是否是物质回馈（需要金额输入）
  bool get isMaterialReturn =>
      type == TransactionType.return_ &&
      (returnCategory == ReturnCategory.material ||
          returnCategory == ReturnCategory.other);

  /// 是否是非物质回馈（需要时长输入）
  bool get isNonMaterialReturn =>
      type == TransactionType.return_ &&
      (returnCategory == ReturnCategory.emotional ||
          returnCategory == ReturnCategory.action);

  /// 是否可以保存
  bool get canSave {
    final noteTrim = note.trim();
    final otherRemarkRequired =
        (directionV2 == TransactionDirection.expense &&
            expenseCategoryV2 == ExpenseCategoryV2.other) ||
        (directionV2 == TransactionDirection.return_ &&
            returnCategoryV2 == ReturnCategoryV2.other) ||
        expenseCategory == ExpenseCategory.other ||
        expenseSubCategory == ExpenseSubCategory.other ||
        laborCategory == LaborCategory.other ||
        laborSubCategory == LaborSubCategory.other ||
        returnCategory == ReturnCategory.other ||
        returnSubCategory == ReturnSubCategory.other;

    if (otherRemarkRequired && noteTrim.isEmpty) return false;

    switch (type) {
      case TransactionType.expense:
        if (expenseCategoryV2 == ExpenseCategoryV2.other) {
          return monetaryAmount > 0 && noteTrim.isNotEmpty;
        }
        return monetaryAmount > 0 && expenseCategory != null;
      case TransactionType.labor:
        return laborHours > 0 && laborCategory != null;
      case TransactionType.return_:
        if (returnCategoryV2 == ReturnCategoryV2.other) {
          return monetaryAmount > 0 && noteTrim.isNotEmpty;
        }
        if (returnCategoryV2 == ReturnCategoryV2.intimacy) {
          return intimacyAction != null;
        }
        if (returnCategoryV2 == ReturnCategoryV2.emotionalValue) {
          return emotionalValueAction != null;
        }
        if (isMaterialReturn) {
          // ReturnCategory.other 不强制二级；其他类别仍需选择二级（含“其他”）。
          if (returnCategory == ReturnCategory.other) {
            return monetaryAmount > 0 && noteTrim.isNotEmpty;
          }
          return monetaryAmount > 0 && returnSubCategory != null;
        } else {
          return laborHours > 0 && returnSubCategory != null;
        }
      case TransactionType.aiVerdict:
        return false;
      case TransactionType.timeFriction:
        return laborHours > 0;
    }
  }
}

@riverpod
class AddTransactionController extends _$AddTransactionController {
  @override
  InputFormState build() => const InputFormState();

  void setType(TransactionType type) {
    // v2.9.1: preserve v2 direction/category state; only clear irrelevant
    // per-type input fields to avoid "sticky default chip" bugs.
    state = state.copyWith(
      type: type,
      monetaryAmount: 0.0,
      laborHours: 0.0,
      note: '',
      clearExpenseCategory: type != TransactionType.expense,
      clearLaborCategory: type != TransactionType.labor,
      clearReturnCategory: type != TransactionType.return_,
      clearAttitude: type != TransactionType.return_,
      clearMedium: type != TransactionType.return_,
    );
  }

  void setDirectionV2(TransactionDirection dir) {
    if (dir == TransactionDirection.expense) {
      state = state.copyWith(
        directionV2: dir,
        returnCategoryV2: null,
        clearReturnCategory: true,
        clearAttitude: true,
        clearMedium: true,
      );
    } else {
      state = state.copyWith(
        directionV2: dir,
        expenseCategoryV2: null,
        clearExpenseCategory: true,
        clearLaborCategory: true,
      );
    }
  }

  void setExpenseCategoryV2(ExpenseCategoryV2 cat) {
    state = state.copyWith(expenseCategoryV2: cat, clearV2Categories: false);
  }

  void setReturnCategoryV2(ReturnCategoryV2 cat) {
    state = state.copyWith(returnCategoryV2: cat, clearV2Categories: false);
  }

  void setIntimacyAction(IntimacyAction action) {
    state = state.copyWith(intimacyAction: action);
  }

  void setEmotionalValueAction(EmotionalValueAction action) {
    state = state.copyWith(emotionalValueAction: action);
  }

  void setExpenseCategory(ExpenseCategory cat) {
    final shouldClearSub = state.expenseCategory != cat;
    state = state.copyWith(
      expenseCategory: cat,
      expenseSubCategory: shouldClearSub ? null : state.expenseSubCategory,
      clearLaborCategory: true,
      clearReturnCategory: true,
    );
  }

  void setExpenseSubCategory(ExpenseSubCategory subCat) {
    state = state.copyWith(expenseSubCategory: subCat);
  }

  void setLaborCategory(LaborCategory cat) {
    final shouldClearSub = state.laborCategory != cat;
    state = state.copyWith(
      laborCategory: cat,
      laborSubCategory: shouldClearSub ? null : state.laborSubCategory,
      clearExpenseCategory: true,
      clearReturnCategory: true,
    );
  }

  void setLaborSubCategory(LaborSubCategory subCat) {
    state = state.copyWith(laborSubCategory: subCat);
  }

  void setReturnCategory(ReturnCategory cat) {
    final shouldClearSub = state.returnCategory != cat;
    state = state.copyWith(
      returnCategory: cat,
      returnSubCategory: shouldClearSub ? null : state.returnSubCategory,
      clearExpenseCategory: true,
      clearLaborCategory: true,
    );
  }

  void setReturnSubCategory(ReturnSubCategory subCat) {
    state = state.copyWith(returnSubCategory: subCat);
  }

  void setAttitude(Attitude att) {
    state = state.copyWith(attitude: att);
  }

  void setMedium(Medium med) {
    state = state.copyWith(medium: med);
  }

  void setMonetaryAmount(double amount) {
    state = state.copyWith(monetaryAmount: amount);
  }

  void setLaborHours(double hours) {
    state = state.copyWith(laborHours: hours);
  }

  void setNote(String note) {
    state = state.copyWith(note: note);
  }

  void save(double hourlyRate) {
    final tx = TransactionEntity()
      ..id = ''
      ..timestamp = DateTime.now()
      ..type = state.type
      ..directionV2 = state.directionV2
      ..expenseCategoryV2 = state.expenseCategoryV2
      ..returnCategoryV2 = state.returnCategoryV2
      ..intimacyAction = state.intimacyAction
      ..emotionalValueAction = state.emotionalValueAction
      ..expenseCategory = state.expenseCategory
      ..expenseSubCategory = state.expenseSubCategory
      ..laborCategory = state.laborCategory
      ..laborSubCategory = state.laborSubCategory
      ..returnCategory = state.returnCategory
      ..returnSubCategory = state.returnSubCategory
      ..attitude = state.attitude
      ..medium = state.medium
      ..monetaryAmount = state.monetaryAmount
      ..laborDurationHours = state.laborHours
      ..hourlyRateSnapshot = hourlyRate
      ..weight = state.weight
      ..note = state.note.trim().isEmpty ? null : state.note.trim();

    if (state.type == TransactionType.return_) {
      // v2.9.1: 杠杆回血不依赖 IQS（避免把“牵手”写成一套评分体系）
      if (state.returnCategoryV2 == ReturnCategoryV2.intimacy) {
        tx.baseValue = 1000;
        tx.leverageMultiplier = 1.0;
      } else if (state.returnCategoryV2 == ReturnCategoryV2.emotionalValue) {
        tx.baseValue = 300;
        tx.leverageMultiplier = 1.0;
      } else {
        // 计算并保存 IQS（仅旧回馈模式）
        if (tx.attitude != null && tx.medium != null) {
          tx.iqs = tx.calculateIQS();
          CIService.recordIQSFeedback(tx.iqs!);
        }
      }
    }

    // 检查大额支出
    if (state.type == TransactionType.expense &&
        state.monetaryAmount >= CIService.largeExpenseThreshold) {
      CIService.recordLargeExpense(tx);
    }

    ref.read(transactionsRepositoryProvider).add(tx);
    ref.invalidate(transactionsRepositoryProvider);
    ref.invalidate(dashboardNotifierProvider);
    state = const InputFormState();
  }

  void saveAiVerdict({
    required double verdictScore,
    required double delusion,
    required double perfunctory,
    required double shatter,
    required String diagnosisText,
    required double ciDelta,
    String? note,
  }) {
    final tx = TransactionEntity()
      ..id = ''
      ..timestamp = DateTime.now()
      ..type = TransactionType.aiVerdict
      ..verdictScore = verdictScore
      ..crushDelusion = delusion
      ..crushPerfunctory = perfunctory
      ..crushShatter = shatter
      ..diagnosisText = diagnosisText.trim().isEmpty
          ? null
          : diagnosisText.trim()
      ..ciDelta = ciDelta
      ..actionTaken = ciDelta == 0
          ? 'CI ±0.0'
          : (ciDelta > 0
                ? 'CI +${ciDelta.toStringAsFixed(2)}'
                : 'CI ${ciDelta.toStringAsFixed(2)}')
      ..note = (note ?? '').trim().isEmpty ? null : note!.trim();

    CIService.recordAiVerdict(ciDelta);

    ref.read(transactionsRepositoryProvider).add(tx);
    ref.invalidate(transactionsRepositoryProvider);
    ref.invalidate(dashboardNotifierProvider);
    state = const InputFormState();
  }
}
