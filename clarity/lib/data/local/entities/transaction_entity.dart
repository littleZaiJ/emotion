import 'package:hive_flutter/hive_flutter.dart';

part 'transaction_entity.g.dart';

/// 花钱模式一级分类
@HiveType(typeId: 0)
enum ExpenseCategory {
  @HiveField(0)
  gift, // 礼物
  @HiveField(1)
  date, // 约会
  @HiveField(2)
  transfer, // 转账
  @HiveField(3)
  other, // 其他
}

/// 花钱模式二级分类
@HiveType(typeId: 1)
enum ExpenseSubCategory {
  // 礼物
  @HiveField(0)
  jewelryBags, // 首饰包包
  @HiveField(1)
  digitalGear, // 数码外设
  @HiveField(2)
  flowersHandmade, // 鲜花手工
  // 约会
  @HiveField(3)
  fineDining, // 高档餐饮
  @HiveField(4)
  movieShow, // 电影演出
  @HiveField(5)
  escapeBoard, // 密室桌游
  // 转账
  @HiveField(6)
  clearCart, // 清空购物车
  @HiveField(7)
  holidayRedPacket, // 节日红包
  @HiveField(8)
  payBills, // 帮还账单
  @HiveField(9)
  other, // 其他
}

/// 出力模式一级分类（带权重）
@HiveType(typeId: 2)
enum LaborCategory {
  @HiveField(0)
  emotional, // 情绪价值 (1.5x)
  @HiveField(1)
  physical, // 体力劳动 (1.0x)
  @HiveField(2)
  timeSunk, // 时间沉没 (0.8x)
  @HiveField(3)
  other, // 其他
}

/// 出力模式二级分类
@HiveType(typeId: 6)
enum LaborSubCategory {
  // 情绪价值
  @HiveField(0)
  lateNightComfort, // 深夜树洞安慰
  @HiveField(1)
  breakIce, // 吵架主动破冰
  @HiveField(2)
  prepareSurprise, // 精心准备惊喜
  // 体力劳动
  @HiveField(3)
  errandsPickup, // 跑腿接送
  @HiveField(4)
  movingCleaning, // 搬家打扫
  @HiveField(5)
  queueBuying, // 排队代买
  // 时间沉没
  @HiveField(6)
  longWaiting, // 单方面漫长等待
  @HiveField(7)
  boringActivity, // 陪做不感兴趣的事
  @HiveField(8)
  other, // 其他
}

/// 回馈模式一级分类（带权重）
@HiveType(typeId: 7)
enum ReturnCategory {
  @HiveField(0)
  material, // 物质回馈 (1.0x)
  @HiveField(1)
  emotional, // 情绪回馈 (1.2x)
  @HiveField(2)
  action, // 行动回馈 (1.0x)
  @HiveField(3)
  other, // 其他
}

/// 回馈模式二级分类
@HiveType(typeId: 14)
enum ReturnSubCategory {
  // 物质回馈
  @HiveField(0)
  receivedGift, // 收到礼物
  @HiveField(1)
  treatMeal, // 对方买单
  @HiveField(2)
  moneyTransfer, // 资金转账
  // 情绪回馈 (1.2x)
  @HiveField(3)
  deepTalk, // 走心沟通
  @HiveField(4)
  emotionalSupport, // 情绪支持
  @HiveField(5)
  surprise, // 制造惊喜
  // 行动回馈 (1.0x)
  @HiveField(6)
  shareTask, // 分担任务
  @HiveField(7)
  dedicatedTime, // 专属陪伴
  @HiveField(8)
  other, // 其他
}

/// 交易类型
@HiveType(typeId: 3)
enum TransactionType {
  @HiveField(0)
  expense, // 花钱（支出）
  @HiveField(1)
  labor, // 出力（劳务折算）
  @HiveField(2)
  return_, // 回馈（收入）
  @HiveField(3)
  aiVerdict, // AI 截图判案（确诊单）
  @HiveField(4)
  timeFriction, // 时间磨损（等待独立化）
}

/// v2.9.1: 顶级方向（复式记账：支出/回血 二元化）
@HiveType(typeId: 15)
enum TransactionDirection {
  @HiveField(0)
  expense, // 支出/投入
  @HiveField(1)
  return_, // 血回/回血
}

/// v2.9.1: 支出子类（ExpenseCategory 二元树下扩）
@HiveType(typeId: 16)
enum ExpenseCategoryV2 {
  @HiveField(0)
  financial, // 财务开销
  @HiveField(1)
  effort, // 行动付出
  @HiveField(2)
  timeFriction, // 时间磨损
  @HiveField(3)
  emotionalDrain, // 情绪消耗
  @HiveField(4)
  other, // 其他
}

/// v2.9.1: 回血子类（ReturnCategory 二元树下扩）
@HiveType(typeId: 17)
enum ReturnCategoryV2 {
  @HiveField(0)
  material, // 物质回血（1:1）
  @HiveField(1)
  intimacy, // 亲密接触（高杠杆）
  @HiveField(2)
  emotionalValue, // 情绪甜头（中高杠杆）
  @HiveField(3)
  other, // 其他
}

@HiveType(typeId: 18)
enum IntimacyAction {
  @HiveField(0)
  handHold, // 牵手
  @HiveField(1)
  hug, // 拥抱
  @HiveField(2)
  kiss, // 亲吻
}

@HiveType(typeId: 19)
enum EmotionalValueAction {
  @HiveField(0)
  sweetTalk, // 主动说好听话
  @HiveField(1)
  activeCare, // 主动关心
  @HiveField(2)
  apology, // 主动道歉/修复
}

/// 态度评分
@HiveType(typeId: 8)
enum Attitude {
  @HiveField(0)
  cold, // 冷暴力 (-10)
  @HiveField(1)
  dismissive, // 敷衍 (-5)
  @HiveField(2)
  normal, // 正常 (0)
  @HiveField(3)
  proactive, // 主动 (+5)
}

/// 媒介类型
@HiveType(typeId: 9)
enum Medium {
  @HiveField(0)
  text, // 文本 (1)
  @HiveField(1)
  voice, // 语音 (2)
  @HiveField(2)
  media, // 图片/视频 (3)
}

@HiveType(typeId: 13)
class TransactionEntity extends HiveObject {
  @HiveField(0)
  late String id;
  @HiveField(1)
  late DateTime timestamp;
  @HiveField(2)
  late TransactionType type;

  // 花钱模式分类
  @HiveField(3)
  ExpenseCategory? expenseCategory;
  @HiveField(4)
  ExpenseSubCategory? expenseSubCategory;

  // 出力模式分类
  @HiveField(5)
  LaborCategory? laborCategory;
  @HiveField(6)
  LaborSubCategory? laborSubCategory;

  // 回馈模式分类
  @HiveField(7)
  ReturnCategory? returnCategory;
  @HiveField(16)
  ReturnSubCategory? returnSubCategory;

  // 回馈模式评分
  @HiveField(8)
  Attitude? attitude;
  @HiveField(9)
  Medium? medium;

  // 金额
  @HiveField(10)
  double monetaryAmount = 0.0;
  @HiveField(11)
  double laborDurationHours = 0.0;
  @HiveField(12)
  double hourlyRateSnapshot = 50.0;
  @HiveField(13)
  double weight = 1.0; // 分类权重

  // 备注
  @HiveField(14)
  String? note;

  // IQS (仅回馈模式)
  @HiveField(15)
  double? iqs;

  // AI 判案载荷（仅 aiVerdict）
  @HiveField(17)
  double? verdictScore; // 0~100 敷衍指数
  @HiveField(18)
  String? diagnosisText; // AI 毒舌解读
  @HiveField(19)
  String? actionTaken; // 影响描述（如：CI -0.1）
  @HiveField(20)
  double? ciDelta; // CI 变动值（用于回滚）

  // Crush 粉碎机三指标（仅 aiVerdict）
  @HiveField(21)
  double? crushDelusion; // 0~100 脑补浓度
  @HiveField(22)
  double? crushPerfunctory; // 0~100 敷衍指数（与 verdictScore 可并存）
  @HiveField(23)
  double? crushShatter; // 0~100 滤镜破碎度

  // v2.9.1: 复式分类树（新字段，老数据保持兼容）
  @HiveField(24)
  TransactionDirection? directionV2;
  @HiveField(25)
  ExpenseCategoryV2? expenseCategoryV2;
  @HiveField(26)
  ReturnCategoryV2? returnCategoryV2;
  @HiveField(27)
  IntimacyAction? intimacyAction;
  @HiveField(28)
  EmotionalValueAction? emotionalValueAction;
  @HiveField(29)
  double? baseValue; // 杠杆基值（如 INTIMACY=1000, EMOTIONAL_VALUE=300）
  @HiveField(30)
  double? leverageMultiplier; // 冲销乘数（可选，默认 1.0）

  /// 计算总价值
  double get totalValue {
    switch (type) {
      case TransactionType.expense:
        return monetaryAmount;
      case TransactionType.labor:
        return laborDurationHours * hourlyRateSnapshot * weight;
      case TransactionType.return_:
        // v2.9.1: 高杠杆回馈（用基值计算，不走“金额/时长”估值）
        if (returnCategoryV2 == ReturnCategoryV2.intimacy ||
            returnCategoryV2 == ReturnCategoryV2.emotionalValue) {
          final base = baseValue ?? 0.0;
          final k = leverageMultiplier ?? 1.0;
          return base * k;
        }
        // 物质回馈直接用金额，非物质回馈按时长计算
        if (returnCategory == ReturnCategory.material ||
            returnCategory == ReturnCategory.other) {
          return monetaryAmount;
        } else {
          return laborDurationHours * hourlyRateSnapshot * weight;
        }
      case TransactionType.aiVerdict:
        return 0.0;
      case TransactionType.timeFriction:
        return laborDurationHours * hourlyRateSnapshot * weight;
    }
  }

  /// 获取出力分类权重
  static double getLaborWeight(LaborCategory? cat) {
    switch (cat) {
      case LaborCategory.emotional:
        return 1.5;
      case LaborCategory.physical:
        return 1.0;
      case LaborCategory.timeSunk:
        return 0.8;
      default:
        return 1.0;
    }
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

  /// 获取态度分数
  static int getAttitudeScore(Attitude? att) {
    switch (att) {
      case Attitude.cold:
        return -10;
      case Attitude.dismissive:
        return -5;
      case Attitude.normal:
        return 0;
      case Attitude.proactive:
        return 5;
      default:
        return 0;
    }
  }

  /// 获取媒介分数
  static int getMediumScore(Medium? med) {
    switch (med) {
      case Medium.text:
        return 1;
      case Medium.voice:
        return 2;
      case Medium.media:
        return 3;
      default:
        return 1;
    }
  }

  /// 计算 IQS
  double calculateIQS() {
    if (type != TransactionType.return_) return 0;
    return (getAttitudeScore(attitude) + getMediumScore(medium)).toDouble();
  }
}
