import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import 'entities/transaction_entity.dart';
import 'entities/interaction_entity.dart';
import 'entities/user_settings_entity.dart';
import 'entities/equivalent_entity.dart';

class HiveService {
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    await Hive.initFlutter();

    // 注册所有 Adapter
    // typeId: 0-2 花钱分类
    Hive.registerAdapter(ExpenseCategoryAdapter());
    Hive.registerAdapter(ExpenseSubCategoryAdapter());
    Hive.registerAdapter(LaborCategoryAdapter());
    // typeId: 3 交易类型
    Hive.registerAdapter(TransactionTypeAdapter());
    // typeId: 4 InteractionEntity
    Hive.registerAdapter(InteractionEntityAdapter());
    // typeId: 5 UserSettingsEntity
    Hive.registerAdapter(UserSettingsEntityAdapter());
    // typeId: 6 出力二级分类
    Hive.registerAdapter(LaborSubCategoryAdapter());
    // typeId: 7 回馈分类
    Hive.registerAdapter(ReturnCategoryAdapter());
    // typeId: 14 回馈二级分类
    Hive.registerAdapter(ReturnSubCategoryAdapter());
    // typeId: 8-9 态度和媒介
    Hive.registerAdapter(AttitudeAdapter());
    Hive.registerAdapter(MediumAdapter());
    // typeId: 10 等待状态
    Hive.registerAdapter(WaitStatusAdapter());
    // typeId: 11 等价物偏好
    Hive.registerAdapter(EquivalentPreferenceAdapter());
    // typeId: 12 等价物实体
    Hive.registerAdapter(EquivalentEntityAdapter());
    // typeId: 13 TransactionEntity
    Hive.registerAdapter(TransactionEntityAdapter());

    // Web dev-server on some setups can block IndexedDB and make `openBox`
    // hang indefinitely. In debug, prefer in-memory boxes so the app can boot.
    final useInMemoryBoxes = kIsWeb && kDebugMode;
    if (useInMemoryBoxes) {
      await Hive.openBox<TransactionEntity>('transactions', bytes: Uint8List(0));
      await Hive.openBox<InteractionEntity>('interactions', bytes: Uint8List(0));
      await Hive.openBox<UserSettingsEntity>('settings', bytes: Uint8List(0));
      await Hive.openBox('meta', bytes: Uint8List(0));
      await Hive.openBox('broadcasts', bytes: Uint8List(0));
    } else {
      await Hive.openBox<TransactionEntity>('transactions');
      await Hive.openBox<InteractionEntity>('interactions');
      await Hive.openBox<UserSettingsEntity>('settings');
      await Hive.openBox('meta');
      await Hive.openBox('broadcasts');
    }

    _initialized = true;
  }

  static Box<TransactionEntity> get transactions =>
      Hive.box<TransactionEntity>('transactions');

  static Box<InteractionEntity> get interactions =>
      Hive.box<InteractionEntity>('interactions');

  static Box<UserSettingsEntity> get settings =>
      Hive.box<UserSettingsEntity>('settings');

  static Box get meta => Hive.box('meta');

  static Box get broadcasts => Hive.box('broadcasts');
}
