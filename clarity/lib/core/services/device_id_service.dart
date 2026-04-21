import 'package:uuid/uuid.dart';

import '../../data/local/hive_service.dart';

const _uuid = Uuid();

class DeviceIdService {
  static const _key = 'deviceId';

  static Future<String> getOrCreate() async {
    final existing = HiveService.meta.get(_key);
    if (existing is String && existing.trim().isNotEmpty) return existing;
    final id = _uuid.v4();
    await HiveService.meta.put(_key, id);
    return id;
  }
}
