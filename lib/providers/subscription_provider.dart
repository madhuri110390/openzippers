import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/subscription_status_response.dart';
import '../repositories/subscription_repository.dart';
import 'api_client_provider.dart';

final subscriptionRepositoryProvider =
Provider<SubscriptionRepository>((ref) {
  return SubscriptionRepository(
    ref.read(apiClientProvider),
  );
});

final subscriptionStatusProvider =
FutureProvider.family<
    SubscriptionStatusResponse,
    int>((ref, artistId) async {
  return ref
      .read(subscriptionRepositoryProvider)
      .getSubscriptionStatus(artistId);
});