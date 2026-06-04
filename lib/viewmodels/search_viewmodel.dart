import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../models/search_response.dart';
import '../providers/api_client_provider.dart';
import '../repositories/search_repository.dart';


class SearchState {
  final bool isLoading;
  final List<SearchUser> users;
  final String? error;

  SearchState({
    this.isLoading = false,
    this.users = const [],
    this.error,
  });

  SearchState copyWith({
    bool? isLoading,
    List<SearchUser>? users,
    String? error,
  }) {
    return SearchState(
      isLoading: isLoading ?? this.isLoading,
      users: users ?? this.users,
      error: error,
    );
  }
}

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return SearchRepository(apiClient);
});

final searchProvider =
StateNotifierProvider<SearchViewModel, SearchState>((ref) {
  final repository = ref.read(searchRepositoryProvider);
  return SearchViewModel(repository);
});

class SearchViewModel extends StateNotifier<SearchState> {
  final SearchRepository repository;

  SearchViewModel(this.repository) : super(SearchState());

  Future<void> searchUsers(String query) async {
    if (query.trim().isEmpty) {
      state = state.copyWith(users: []);
      return;
    }

    try {
      state = state.copyWith(
        isLoading: true,
        error: null,
      );

      final response = await repository.globalSearch(query);

      state = state.copyWith(
        isLoading: false,
        users: response.users,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
  void clear() {
    state = state.copyWith(users: [], isLoading: false, error: null);
  }
  void clearSearch() {
    state = SearchState();
  }
}