import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/follow_response.dart';
import '../network/api_client.dart';
import '../repositories/follow_repository.dart';
import '../viewmodels/register_view_model.dart';


final followRepositoryProvider =
Provider<FollowRepository>((ref) {

  final dio = ref.watch(dioProvider);

  final apiClient = ApiClient(dio);

  return FollowRepository(apiClient);
});

class FollowNotifier extends
StateNotifier<AsyncValue<FollowResponse?>> {

  final FollowRepository repository;

  FollowNotifier(this.repository)
      : super(const AsyncData(null));

  Future<FollowResponse?> toggleFollow(
      int userId,
      ) async {

    try {

      state = const AsyncLoading();

      final response =
      await repository.toggleFollow(userId);

      state = AsyncData(response);

      return response;

    } catch (e, st) {

      state = AsyncError(e, st);

      rethrow;
    }
  }
}

final followProvider =
StateNotifierProvider<
    FollowNotifier,
    AsyncValue<FollowResponse?>>((ref) {

  return FollowNotifier(
    ref.watch(followRepositoryProvider),
  );
});