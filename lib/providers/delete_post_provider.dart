import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';
import '../repositories/delete_post_repository.dart';
import '../viewmodels/delete_post_viewmodel.dart';
import '../viewmodels/register_view_model.dart';


// Provide ApiClient using Dio
final apiClientProvider = Provider<ApiClient>((ref) {
  final dio = ref.watch(dioProvider);
  return ApiClient(dio);
});

// Provide Repository
final deletePostRepositoryProvider = Provider<DeletePostRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DeletePostRepository(apiClient);
});

// Provide ViewModel (StateNotifier)
final deletePostViewModelProvider =
StateNotifierProvider<DeletePostViewModel, DeletePostState>((ref) {
  final repository = ref.watch(deletePostRepositoryProvider);
  return DeletePostViewModel(repository);
});