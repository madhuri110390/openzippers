// providers/subscription_list_provider.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../repositories/subscriptions_list_repository.dart';
import '../viewmodels/subscription_list_viewmodel.dart';

// ── Authenticated Dio provider ─────────────────────────────────────────────
// If you already have a global dioProvider, reuse that instead of this one.

final subscriptionDioProvider = FutureProvider<Dio>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token') ?? '';
  final dio = Dio();
  dio.options.baseUrl = 'https://openzippers.com/api/v1/';
  dio.options.headers = {
    'Accept': 'application/json',
    'Authorization': 'Bearer $token',
  };
  dio.interceptors.add(
    LogInterceptor(requestBody: true, responseBody: true),
  );
  return dio;
});

// ── Repository provider ────────────────────────────────────────────────────

final subscriptionListRepositoryProvider =
Provider<SubscriptionListRepository?>((ref) {
  final dioAsync = ref.watch(subscriptionDioProvider);
  return dioAsync.whenOrNull(
    data: (dio) => SubscriptionListRepository(dio),
  );
});

// ── StateNotifier provider ─────────────────────────────────────────────────

final subscriptionListProvider = StateNotifierProvider<
    SubscriptionListNotifier, SubscriptionListState>((ref) {
  final repo = ref.watch(subscriptionListRepositoryProvider);
  final notifier = SubscriptionListNotifier(
    repo ?? SubscriptionListRepository(Dio()), // fallback; repo loads async
  );

  // Auto-fetch when provider is first read
  Future.microtask(() => notifier.fetchSubscriptions());
  return notifier;
});

// ── Convenience read-only providers ───────────────────────────────────────

/// Just the active subscriber count — use this in ProfileScreen stat card
final activeSubscriberCountProvider = Provider<int>((ref) {
  return ref.watch(subscriptionListProvider).activeSubscribersCount;
});

/// Total earnings
final totalEarningsProvider = Provider<double>((ref) {
  return ref.watch(subscriptionListProvider).totalEarnings;
});