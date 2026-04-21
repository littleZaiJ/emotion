import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/community_repository.dart';
import '../../data/repositories/supabase_community_repo.dart';

final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  return SupabaseCommunityRepo();
});

