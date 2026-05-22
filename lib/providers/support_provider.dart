import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';
import '../repositories/support_repository.dart';
import '../viewmodels/register_view_model.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final dio = ref.watch(dioProvider);
  return ApiClient(dio);
});

final supportRepositoryProvider = Provider<SupportRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SupportRepository(apiClient);
});