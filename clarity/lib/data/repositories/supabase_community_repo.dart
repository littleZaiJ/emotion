import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/graduation_record.dart';
import 'community_repository.dart';

class SupabaseCommunityRepo implements CommunityRepository {
  SupabaseCommunityRepo({
    SupabaseClient? client,
    String tableName = 'graduations',
    String interactRpc = 'increment_interaction',
    String createdAtColumn = 'created_at',
  })  : _client = client ?? Supabase.instance.client,
        _tableName = tableName,
        _interactRpc = interactRpc,
        _createdAtColumn = createdAtColumn;

  final SupabaseClient _client;
  final String _tableName;
  final String _interactRpc;
  final String _createdAtColumn;

  Future<T> _run<T>(
    Future<T> Function() action, {
    required Duration timeout,
    int maxAttempts = 2,
  }) async {
    Object? lastError;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        return await action().timeout(timeout);
      } on TimeoutException catch (e) {
        lastError = e;
        if (attempt >= maxAttempts) rethrow;
        await Future<void>.delayed(Duration(milliseconds: 250 * attempt));
      } catch (e) {
        lastError = e;
        rethrow;
      }
    }
    throw lastError ?? StateError('Supabase request failed');
  }

  @override
  Future<void> publishGraduation(GraduationRecord record) async {
    final payload = Map<String, dynamic>.from(record.toJson())
      ..removeWhere((key, value) => value == null);
    final payloadCamel = <String, dynamic>{
      'id': record.id,
      'deviceId': record.deviceId,
      'userAlias': record.userAlias,
      'userTitle': record.userTitle,
      'exitType': record.exitType,
      'totalInvestment': record.totalInvestment,
      'finalCi': record.finalCi,
      'aiSummary': record.aiSummary,
      'hugCount': record.hugCount,
      'cheersCount': record.cheersCount,
      'warningCount': record.warningCount,
      'createdAt': record.createdAt?.toIso8601String(),
    }..removeWhere((key, value) => value == null);

    try {
      await _run(
        () => _client.from(_tableName).insert(payload),
        timeout: const Duration(seconds: 12),
      );
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST204') {
        // If schema uses camelCase, fall back (helps local/dev mismatches).
        final fallback = Map<String, dynamic>.from(payloadCamel);
        try {
          await _run(
            () => _client.from(_tableName).insert(fallback),
            timeout: const Duration(seconds: 12),
          );
          return;
        } on PostgrestException catch (e2) {
          if (e2.code == 'PGRST204') {
            final fallbackTrimmed = Map<String, dynamic>.from(fallback)
              ..remove('clarityCount'); // legacy key, kept for safety
            if (fallbackTrimmed.length != fallback.length) {
              await _run(
                () => _client.from(_tableName).insert(fallbackTrimmed),
                timeout: const Duration(seconds: 12),
              );
              return;
            }
          }
          rethrow;
        }
      }
      rethrow;
    }
  }

  @override
  Future<List<GraduationRecord>> fetchHallOfClarity() async {
    dynamic data;
    try {
      data = await _run(
        () => _client
            .from(_tableName)
            .select()
            .order(_createdAtColumn, ascending: false)
            .limit(50),
        timeout: const Duration(seconds: 10),
      );
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST204' && _createdAtColumn != 'createdAt') {
        data = await _run(
          () => _client
              .from(_tableName)
              .select()
              .order('createdAt', ascending: false)
              .limit(50),
          timeout: const Duration(seconds: 10),
        );
      } else {
        rethrow;
      }
    }

    return (data as List)
        .map((e) =>
            GraduationRecord.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(growable: false);
  }

  @override
  Future<void> interact(String recordId, String type) async {
    await _run(
      () => _client.rpc(_interactRpc, params: <String, dynamic>{
        'row_id': recordId,
        'interaction_type': type,
      }),
      timeout: const Duration(seconds: 8),
    );
  }
}
