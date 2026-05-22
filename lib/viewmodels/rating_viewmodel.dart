import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/rating_response.dart';
import '../repositories/rating_repository.dart';



class RatingState {
  final bool isLoading;
  final RatingResponse? response;
  final String? error;

  RatingState({
    this.isLoading = false,
    this.response,
    this.error,
  });

  RatingState copyWith({
    bool? isLoading,
    RatingResponse? response,
    String? error,
  }) {
    return RatingState(
      isLoading: isLoading ?? this.isLoading,
      response: response ?? this.response,
      error: error,
    );
  }
}

class RatingViewModel extends StateNotifier<RatingState> {
  final RatingRepository repository;

  RatingViewModel(this.repository) : super(RatingState());

  Future<void> submitRating({
    required int postId,
    required int rating,
  }) async {
    try {
      state = state.copyWith(isLoading: true);

      final response = await repository.submitRating(
        postId: postId,
        rating: rating,
      );

      state = state.copyWith(
        isLoading: false,
        response: response,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}