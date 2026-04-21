import 'package:flutter/foundation.dart';

const _kSupabaseSmokeTestEnv = bool.fromEnvironment(
  'SUPABASE_SMOKE_TEST',
  defaultValue: false,
);

bool get kEnableSupabaseSmokeTest => kDebugMode && _kSupabaseSmokeTestEnv;

