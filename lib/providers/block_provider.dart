import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/block_response.dart';

import '../network/api_client.dart';
import '../repositories/block_repository.dart';
import '../viewmodels/register_view_model.dart';


final blockRepositoryProvider = Provider<BlockRepository>((ref) {

  final dio = ref.watch(dioProvider);

  final apiClient = ApiClient(dio);

  return BlockRepository(apiClient);
});

class BlockNotifier extends StateNotifier<AsyncValue<BlockResponse?>> {

  final BlockRepository repository;

  BlockNotifier(this.repository)
      : super(const AsyncValue.data(null));

  Future<BlockResponse?> toggleBlock(int userId) async {

    try {

      state = const AsyncLoading();

      final response = await repository.toggleBlock(userId);

      state = AsyncData(response);

      return response;

    } catch (e, st) {

      state = AsyncError(e, st);

      rethrow;
    }
  }
}

final blockProvider = StateNotifierProvider<
    BlockNotifier,
    AsyncValue<BlockResponse?>>((ref) {

  return BlockNotifier(
    ref.watch(blockRepositoryProvider),
  );
});