import 'package:hive_flutter/hive_flutter.dart';

part 'equivalent_entity.g.dart';

/// 等价物库数据结构
@HiveType(typeId: 12)
class EquivalentEntity extends HiveObject {
  @HiveField(0) late String id;
  @HiveField(1) late String name;        // 名称
  @HiveField(2) late String unit;        // 单位
  @HiveField(3) late double price;       // 单价
  @HiveField(4) List<String> tags = [];  // 偏好标签
  @HiveField(5) String? feelingDesc;     // 获得感描述

  EquivalentEntity({
    required this.id,
    required this.name,
    required this.unit,
    required this.price,
    this.tags = const [],
    this.feelingDesc,
  });

  /// 计算可购买数量
  int calculateCount(double totalAmount) {
    if (price <= 0) return 0;
    return (totalAmount / price).floor();
  }

  /// 生成场景化文案
  String generateScenarioText(double totalAmount, String negativeFeedback) {
    final count = calculateCount(totalAmount);
    if (count == 0) {
      return '这些钱还不够买一$unit$name';
    }
    final feeling = feelingDesc ?? '足够让你开心很久';
    return '这些钱够你买 $count$unit$name，$feeling。而你只收到了 $negativeFeedback';
  }
}

/// 预置等价物库
class EquivalentPresets {
  static List<EquivalentEntity> getAll() => [
    // 数码类
    EquivalentEntity(
      id: 'switch_oled',
      name: 'Switch OLED',
      unit: '台',
      price: 2399,
      tags: ['digital', 'gaming'],
      feelingDesc: '足够你和兄弟通宵爽玩一整年',
    ),
    EquivalentEntity(
      id: 'airpods_pro',
      name: 'AirPods Pro',
      unit: '副',
      price: 1999,
      tags: ['digital'],
      feelingDesc: '听歌降噪，沉浸享受',
    ),
    EquivalentEntity(
      id: 'iphone',
      name: 'iPhone',
      unit: '部',
      price: 6999,
      tags: ['digital'],
      feelingDesc: '换新机，用三年不卡',
    ),
    EquivalentEntity(
      id: 'ps5',
      name: 'PS5',
      unit: '台',
      price: 3999,
      tags: ['digital', 'gaming'],
      feelingDesc: '游戏大作随便玩',
    ),

    // 美妆类
    EquivalentEntity(
      id: 'lipstick',
      name: '大牌口红',
      unit: '支',
      price: 380,
      tags: ['beauty', 'fashion'],
      feelingDesc: '每天一支换着涂',
    ),
    EquivalentEntity(
      id: 'skincare_set',
      name: '护肤套装',
      unit: '套',
      price: 1500,
      tags: ['beauty'],
      feelingDesc: '养出水嫩好皮肤',
    ),
    EquivalentEntity(
      id: 'perfume',
      name: '香水',
      unit: '瓶',
      price: 1200,
      tags: ['beauty', 'fashion'],
      feelingDesc: '每天都是精致女孩',
    ),

    // 游戏类
    EquivalentEntity(
      id: 'steam_game',
      name: 'Steam 3A大作',
      unit: '款',
      price: 298,
      tags: ['gaming'],
      feelingDesc: '沉浸在游戏世界里',
    ),
    EquivalentEntity(
      id: 'game_points',
      name: '游戏充值',
      unit: '次',
      price: 648,
      tags: ['gaming'],
      feelingDesc: '抽卡抽到爽',
    ),

    // 美食类
    EquivalentEntity(
      id: 'bubble_tea',
      name: '奶茶',
      unit: '杯',
      price: 25,
      tags: ['food'],
      feelingDesc: '每天一杯快乐水',
    ),
    EquivalentEntity(
      id: 'hotpot',
      name: '海底捞',
      unit: '顿',
      price: 300,
      tags: ['food'],
      feelingDesc: '和朋友吃顿好的',
    ),
    EquivalentEntity(
      id: 'starbucks',
      name: '星巴克',
      unit: '杯',
      price: 38,
      tags: ['food'],
      feelingDesc: '提神醒脑又好喝',
    ),

    // 旅行类
    EquivalentEntity(
      id: 'flight_ticket',
      name: '国内机票',
      unit: '张',
      price: 800,
      tags: ['travel'],
      feelingDesc: '说走就走的旅行',
    ),
    EquivalentEntity(
      id: 'hotel_night',
      name: '精品酒店',
      unit: '晚',
      price: 500,
      tags: ['travel'],
      feelingDesc: '住得舒服睡得香',
    ),

    // 时尚类
    EquivalentEntity(
      id: 'sneakers',
      name: '潮牌球鞋',
      unit: '双',
      price: 1299,
      tags: ['fashion'],
      feelingDesc: '走路都带风',
    ),
    EquivalentEntity(
      id: 'bag',
      name: '轻奢包包',
      unit: '个',
      price: 3000,
      tags: ['fashion'],
      feelingDesc: '百搭又好看',
    ),
  ];

  /// 根据偏好标签筛选等价物
  static List<EquivalentEntity> getByPreferences(List<String> preferences) {
    if (preferences.isEmpty) {
      // 默认返回前2个
      return getAll().take(2).toList();
    }
    final matched = getAll()
        .where((e) => e.tags.any((t) => preferences.contains(t)))
        .toList();
    // 如果匹配太少，补充一些通用的
    if (matched.length < 2) {
      final fallback = getAll()
          .where((e) => !matched.contains(e))
          .take(2 - matched.length);
      matched.addAll(fallback);
    }
    return matched.take(2).toList();
  }
}
