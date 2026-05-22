import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/rating_response.dart';
import '../repositories/rating_repository.dart';
import '../viewmodels/rating_viewmodel.dart';
import 'api_client_provider.dart';


final ratingRepositoryProvider = Provider<RatingRepository>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return RatingRepository(apiClient);
});

final ratingProvider =
FutureProvider.family<RatingResponse, int>((ref, postId) async {
  final repository = ref.read(ratingRepositoryProvider);
  return repository.getRatings(postId);
});

final submitRatingProvider =
StateNotifierProvider<RatingViewModel, RatingState>((ref) {
  return RatingViewModel(
    ref.read(ratingRepositoryProvider),
  );
});