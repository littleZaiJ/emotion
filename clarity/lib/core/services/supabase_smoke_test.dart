import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/graduation_record.dart';
import '../../data/repositories/supabase_community_repo.dart';

const _uuid = Uuid();

class SupabaseSmokeTest {
  static Future<void> run() async {
    final repo = SupabaseCommunityRepo(
      // Change these if your DB uses snake_case.
      createdAtColumn: 'created_at',
    );

    try {
      final record = GraduationRecord(
        deviceId: _uuid.v4(),
        userAlias: 'dev_smoke_${DateTime.now().millisecondsSinceEpoch}',
        userTitle: '新晋脱海者',
        exitType: 'SMART',
        totalInvestment: 1234.0,
        finalCi: 0.93,
        aiSummary: 'supabase smoke test',
      );

      debugPrint('[SupabaseSmokeTest] inserting record...');
      await repo.publishGraduation(record);
      debugPrint('[SupabaseSmokeTest] insert done');

      debugPrint('[SupabaseSmokeTest] fetching hall...');
      final list = await repo.fetchHallOfClarity();
      debugPrint('[SupabaseSmokeTest] fetched: ${list.length}');
      if (list.isNotEmpty) {
        final top = list.first;
        debugPrint(
          '[SupabaseSmokeTest] top: id=${top.id} alias=${top.userAlias} createdAt=${top.createdAt}',
        );
      }
    } catch (e, st) {
      debugPrint('[SupabaseSmokeTest] failed: $e');
      debugPrint(st.toString());
      rethrow;
    }
  }
}
