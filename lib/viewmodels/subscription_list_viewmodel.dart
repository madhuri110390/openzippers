// viewmodels/subscription_list_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/subscriptions_list_response.dart';
import '../repositories/subscriptions_list_repository.dart';

// ── State ──────────────────────────────────────────────────────────────────

enum SubscriptionListStatus { initial, loading, success, error }

class SubscriptionListState {
  final SubscriptionListStatus status;
  final SubscriptionListData? data;
  final String? errorMessage;

  const SubscriptionListState({
    this.status = SubscriptionListStatus.initial,
    this.data,
    this.errorMessage,
  });

  bool get isLoading => status == SubscriptionListStatus.loading;
  bool get hasError => status == SubscriptionListStatus.error;
  bool get hasData => status == SubscriptionListStatus.success && data != null;

  // Convenience getters — safe even before data loads
  List<SubscriptionItem> get asArtist => data?.asArtist ?? [];
  List<SubscriptionItem> get asSubscriber => data?.asSubscriber ?? [];
  List<SubscriptionItem> get activeSubscribers => data?.activeAsArtist ?? [];
  int get activeSubscribersCount => data?.activeSubscribersCount ?? 0;
  int get myActiveSubscriptionsCount => data?.myActiveSubscriptionsCount ?? 0;
  double get totalEarnings => data?.totalEarnings ?? 0;

  SubscriptionListState copyWith({
    SubscriptionListStatus? status,
    SubscriptionListData? data,
    String? errorMessage,
  }) {
    return SubscriptionListState(
      status: status ?? this.status,
      data: data ?? this.data,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// ── Notifier ───────────────────────────────────────────────────────────────

class SubscriptionListNotifier
    extends StateNotifier<SubscriptionListState> {
  final SubscriptionListRepository _repository;

  SubscriptionListNotifier(this._repository)
      : super(const SubscriptionListState());

  Future<void> fetchSubscriptions() async {
    state = state.copyWith(status: SubscriptionListStatus.loading);
    try {
      final response = await _repository.getSubscriptions();
      state = state.copyWith(
        status: SubscriptionListStatus.success,
        data: response.data,
      );
    } catch (e) {
      state = state.copyWith(
        status: SubscriptionListStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> refresh() => fetchSubscriptions();
}