import '../../data/local/hive_service.dart';

class BroadcastService {
  static const _itemsKey = 'items';
  static const int _maxItems = 50;

  static List<String> getAll() {
    final raw = HiveService.broadcasts.get(_itemsKey, defaultValue: const <dynamic>[]);
    return List<String>.from(raw as List);
  }

  static Future<void> add(String message) async {
    final items = getAll();
    items.insert(0, message);
    if (items.length > _maxItems) {
      items.removeRange(_maxItems, items.length);
    }
    await HiveService.broadcasts.put(_itemsKey, items);
  }

  static List<String> getOrSample() {
    final items = getAll();
    if (items.isNotEmpty) return items;
    return const [
      '一位坚持了 128 天的用户，终于不再等那句晚安，带着 0.95 的清醒指数成功毕业。',
      '某匿名用户，及时止损 ¥4500（约等于一台 PS5），退出了这场单人游戏。',
    ];
  }
}

