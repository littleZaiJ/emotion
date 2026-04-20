import '../../data/local/hive_service.dart';
import '../../data/local/entities/transaction_entity.dart';
import '../../features/dashboard/dashboard_provider.dart';
import 'broadcast_service.dart';
import 'package:characters/characters.dart';

class GraduationService {
  static const _keyGraduatedAt = 'graduatedAt';
  static const _keyStampText = 'graduationStamp';
  static const _keySnapshot = 'graduationSnapshot';
  static const _keyNickname = 'graduationNickname';
  static const _keyGeneratedTitle = 'graduationGeneratedTitle';

  static bool get isGraduated => HiveService.meta.get(_keyGraduatedAt) != null;

  static DateTime? get graduatedAt {
    final raw = HiveService.meta.get(_keyGraduatedAt);
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }

  static String? get stampText =>
      HiveService.meta.get(_keyStampText) as String?;

  static String? get nickname => HiveService.meta.get(_keyNickname) as String?;

  static String? get generatedTitle =>
      HiveService.meta.get(_keyGeneratedTitle) as String?;

  static Map<String, dynamic>? get snapshot {
    final raw = HiveService.meta.get(_keySnapshot);
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  static String generateTitle({
    required double ci,
    required double totalInvestment,
    required double totalWaitMinutes,
  }) {
    if (ci > 0.8 && totalInvestment > 5000) return '理智大债主';
    if (totalWaitMinutes / 60.0 > 100) return '耐力冠军';
    return '新晋脱海者';
  }

  static Future<void> graduate({
    required DashboardData dashboard,
    required List<TransactionEntity> transactions,
    String? nickname,
  }) async {
    final now = DateTime.now();
    final days = _daysSinceFirstRecord(transactions, now: now);
    final stopLoss = dashboard.sunkCost;
    final ci = dashboard.ciValue;
    final generatedTitle = generateTitle(
      ci: ci,
      totalInvestment: dashboard.totalInvestment,
      totalWaitMinutes: dashboard.totalWaitMinutes,
    );
    final finalNickname = (nickname ?? '').trim().isEmpty
        ? '匿名清醒者'
        : nickname!.trim().characters.take(8).toString();

    final stamp = stopLoss > 0 ? '及时止损' : '成功脱海';

    final message = stopLoss > 0
        ? '某匿名用户，及时止损 ¥${stopLoss.toStringAsFixed(0)}（约等于一台 PS5），退出了这场单人游戏。'
        : '一位坚持了 $days 天的用户，终于不再等那句晚安，带着 ${ci.toStringAsFixed(2)} 的清醒指数成功毕业。';

    await HiveService.meta.put(_keyGraduatedAt, now.toIso8601String());
    await HiveService.meta.put(_keyStampText, stamp);
    await HiveService.meta.put(_keyNickname, finalNickname);
    await HiveService.meta.put(_keyGeneratedTitle, generatedTitle);
    await HiveService.meta.put(_keySnapshot, <String, dynamic>{
      'ci': ci,
      'days': days,
      'totalInvestment': dashboard.totalInvestment,
      'totalReturn': dashboard.totalReturn,
      'sunkCost': stopLoss,
      'totalWaitMinutes': dashboard.totalWaitMinutes,
      'healthLevel': dashboard.healthLevel.toString(),
      'stamp': stamp,
      'nickname': finalNickname,
      'generatedTitle': generatedTitle,
    });

    await BroadcastService.add(message);
  }

  static int _daysSinceFirstRecord(
    List<TransactionEntity> transactions, {
    required DateTime now,
  }) {
    if (transactions.isEmpty) return 0;
    transactions.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final first = transactions.first.timestamp;
    final d0 = DateTime(first.year, first.month, first.day);
    final d1 = DateTime(now.year, now.month, now.day);
    return d1.difference(d0).inDays + 1;
  }
}
