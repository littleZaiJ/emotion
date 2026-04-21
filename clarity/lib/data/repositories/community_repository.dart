import '../models/graduation_record.dart';

abstract class CommunityRepository {
  /// 发布毕业记录到脱海大厅
  Future<void> publishGraduation(GraduationRecord record);

  /// 拉取脱海大厅列表 (按时间倒序，最多50条)
  Future<List<GraduationRecord>> fetchHallOfClarity();

  /// 触发卡片互动 (调用 RPC 云函数)
  /// type 可选值: 'hug', 'cheers', 'warning'
  Future<void> interact(String recordId, String type);
}
