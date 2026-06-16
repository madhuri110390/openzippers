// screens/subscriptions_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../helpers/translations.dart';
import '../models/mock_data.dart';
import '../models/subscriptions_list_response.dart';
import '../providers/subscriptions_list_provider.dart';
import '../viewmodels/subscription_list_viewmodel.dart';

class SubscriptionsPage extends ConsumerStatefulWidget {
  final MockUser currentUser;
  final String? highlightUser;

  const SubscriptionsPage({
    super.key,
    required this.currentUser,
    this.highlightUser,
  });

  @override
  ConsumerState<SubscriptionsPage> createState() =>
      _SubscriptionsPageState();
}

class _SubscriptionsPageState extends ConsumerState<SubscriptionsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    if (widget.highlightUser != null) {
      _tabController.index = 1;
    }
    _tabController.addListener(() => setState(() {}));

    // Trigger fetch on open
    Future.microtask(() =>
        ref.read(subscriptionListProvider.notifier).fetchSubscriptions());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(subscriptionListProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          context.tr.subscriptions,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFFDB2777),
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFDB2777)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: state.isLoading && !state.hasData
          ? const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFDB2777),
        ),
      )
          : state.hasError && !state.hasData
          ? _buildError(theme, state)
          : _buildBody(theme, state),
    );
  }

  Widget _buildError(ThemeData theme, SubscriptionListState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 56, color: theme.hintColor.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              'Failed to load subscriptions',
              style: TextStyle(
                  fontSize: 16, color: theme.textTheme.bodyLarge?.color),
            ),
            const SizedBox(height: 8),
            Text(
              state.errorMessage ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: theme.hintColor),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref
                  .read(subscriptionListProvider.notifier)
                  .refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDB2777),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme, SubscriptionListState state) {
    final subscriptions = state.asSubscriber; // plans I'm on
    final subscribers = state.asArtist;       // fans subscribed to me

    return CustomScrollView(
      slivers: [
        // ── Stats card ──────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: _StatsCard(
            state: state,
            subscriptionsCount: subscriptions.length,
            subscribersCount: subscribers.length,
            isLoading: state.isLoading,
            onRefresh: () => ref
                .read(subscriptionListProvider.notifier)
                .refresh(),
          ),
        ),

        // ── Tab bar ─────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dividerColor),
            ),
            child: TabBar(
              controller: _tabController,
              onTap: (_) => setState(() {}),
              labelColor: Colors.white,
              unselectedLabelColor: theme.textTheme.bodyMedium?.color,
              indicator: BoxDecoration(
                color: const Color(0xFFDB2777),
                borderRadius: BorderRadius.circular(8),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.subscriptions, size: 18),
                      const SizedBox(width: 8),
                      Text(context.tr.subscriptions),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.people, size: 18),
                      const SizedBox(width: 8),
                      Text(context.tr.subscribers),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 10)),

        // ── Tab content ─────────────────────────────────────────────────
        if (_tabController.index == 0)
          ..._buildSubscriptionSlivers(theme, subscriptions)
        else
          ..._buildSubscriberSlivers(theme, subscribers),
      ],
    );
  }

  // ── MY SUBSCRIPTIONS (plans I pay for) ───────────────────────────────────

  List<Widget> _buildSubscriptionSlivers(
      ThemeData theme, List<SubscriptionItem> items) {
    if (items.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: _EmptyState(
              icon: Icons.receipt_long_outlined,
              title: context.tr.noSubscriptionsFound,
              subtitle: context.tr.subscriptionHistoryDesc,
            ),
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.only(bottom: 24),
        sliver: SliverList(
          delegate: SliverChildListDelegate([
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: Text(
                      context.tr.yourSubscriptions,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.titleMedium?.color,
                      ),
                    ),
                  ),
                  ...items.asMap().entries.map((e) {
                    final idx = e.key;
                    final item = e.value;
                    return _SubscriptionCard(
                      index: idx,
                      item: item,
                      isLast: idx == items.length - 1,
                      theme: theme,
                      // In asSubscriber the API may return artist info
                      // use artist field if present, else show artistId
                      displayName: item.artist != null
                          ? '@${item.artist!.username}'
                          : 'Artist #${item.artistId}',
                      avatarUrl: item.artist?.avatarUrl,
                      role: 'Artist',
                    );
                  }),
                ],
              ),
            ),
          ]),
        ),
      ),
    ];
  }

  // ── MY SUBSCRIBERS (fans paying me) ──────────────────────────────────────

  List<Widget> _buildSubscriberSlivers(
      ThemeData theme, List<SubscriptionItem> items) {
    if (items.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: _EmptyState(
              icon: Icons.people_outline,
              title: context.tr.noSubscribersFound,
              subtitle: context.tr.subscriberListDesc,
            ),
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.only(bottom: 24),
        sliver: SliverList(
          delegate: SliverChildListDelegate([
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: Text(
                      context.tr.yourSubscribersList,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.titleMedium?.color,
                      ),
                    ),
                  ),
                  ...items.asMap().entries.map((e) {
                    final idx = e.key;
                    final item = e.value;
                    final isHighlighted = widget.highlightUser != null &&
                        item.subscriber?.username == widget.highlightUser;
                    return _SubscriberCard(
                      index: idx,
                      item: item,
                      isLast: idx == items.length - 1,
                      isHighlighted: isHighlighted,
                      theme: theme,
                    );
                  }),
                ],
              ),
            ),
          ]),
        ),
      ),
    ];
  }
}

// ── Stats Card ────────────────────────────────────────────────────────────

class _StatsCard extends StatelessWidget {
  final SubscriptionListState state;
  final int subscriptionsCount;
  final int subscribersCount;
  final bool isLoading;
  final VoidCallback onRefresh;

  const _StatsCard({
    required this.state,
    required this.subscriptionsCount,
    required this.subscribersCount,
    required this.isLoading,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeCount = state.activeSubscribersCount;
    final earnings = state.totalEarnings;

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr.subscriptions,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.titleMedium?.color,
                ),
              ),
              isLoading
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Color(0xFFDB2777)),
                ),
              )
                  : IconButton(
                icon: const Icon(Icons.refresh,
                    size: 20, color: Color(0xFFDB2777)),
                onPressed: onRefresh,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Total earnings
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr.totalEarnings,
                style: TextStyle(fontSize: 14, color: theme.hintColor),
              ),
              Text(
                '\$$earnings',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFDB2777),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 3 stat boxes
          Column(
            children: [
              _StatBox(
                label: 'Active Subscribers',
                value: activeCount.toString(),
                theme: theme,
                highlight: true,
              ),
              const SizedBox(height: 12),
              _StatBox(
                label: context.tr.yourSubscriptions,
                value: subscriptionsCount.toString(),
                theme: theme,
              ),
              const SizedBox(height: 12),
              _StatBox(
                label: context.tr.totalSubscriptions,
                value: (subscriptionsCount + subscribersCount).toString(),
                theme: theme,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;
  final bool highlight;

  const _StatBox({
    required this.label,
    required this.value,
    required this.theme,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlight
            ? const Color(0xFFDB2777).withOpacity(0.08)
            : (theme.brightness == Brightness.light
            ? const Color(0xFFF8F9FA)
            : theme.colorScheme.surfaceContainerHighest),
        borderRadius: BorderRadius.circular(8),
        border: highlight
            ? Border.all(color: const Color(0xFFDB2777).withOpacity(0.3))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(fontSize: 14, color: theme.hintColor)),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: highlight
                  ? const Color(0xFFDB2777)
                  : theme.textTheme.titleLarge?.color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Subscription card (I subscribed to artist) ────────────────────────────

class _SubscriptionCard extends StatelessWidget {
  final int index;
  final SubscriptionItem item;
  final bool isLast;
  final ThemeData theme;
  final String displayName;
  final String? avatarUrl;
  final String role;

  const _SubscriptionCard({
    required this.index,
    required this.item,
    required this.isLast,
    required this.theme,
    required this.displayName,
    this.avatarUrl,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(20, 0, 20, isLast ? 16 : 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.light
            ? const Color(0xFFF8F9FA)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Index + Status badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('#${index + 1}',
                  style: TextStyle(fontSize: 12, color: theme.hintColor)),
              _StatusBadge(status: item.status),
            ],
          ),
          const SizedBox(height: 12),

          // Avatar + name row
          if (avatarUrl != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage(avatarUrl!),
                    backgroundColor: theme.dividerColor,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    displayName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
            ),

          _InfoRow('Type', role, theme),
          const SizedBox(height: 8),
          _InfoRow('User', displayName, theme),
          const SizedBox(height: 8),
          _InfoRow('Amount', '\$${item.amount}', theme, isAmount: true),
          const SizedBox(height: 8),
          _InfoRow('Provider', _capitalize(item.provider), theme),
          const SizedBox(height: 8),
          _InfoRow('Expires', item.expiresAtFormatted, theme),
          const SizedBox(height: 8),
          _InfoRow('Since', item.createdAtFormatted, theme),
        ],
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ── Subscriber card (fan paying me) ──────────────────────────────────────

class _SubscriberCard extends StatelessWidget {
  final int index;
  final SubscriptionItem item;
  final bool isLast;
  final bool isHighlighted;
  final ThemeData theme;

  const _SubscriberCard({
    required this.index,
    required this.item,
    required this.isLast,
    required this.isHighlighted,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final sub = item.subscriber;
    final name = sub != null ? sub.name : 'Subscriber #${item.subscriberId}';
    final username = sub != null ? '@${sub.username}' : '';
    final avatarUrl = sub?.avatarUrl;

    return Container(
      margin: EdgeInsets.fromLTRB(20, 0, 20, isLast ? 16 : 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHighlighted
            ? const Color(0xFFDB2777).withOpacity(0.1)
            : (theme.brightness == Brightness.light
            ? const Color(0xFFF8F9FA)
            : theme.colorScheme.surfaceContainerHighest),
        borderRadius: BorderRadius.circular(8),
        border: isHighlighted
            ? Border.all(color: const Color(0xFFDB2777), width: 1.5)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Index + status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '#${index + 1}',
                style: TextStyle(
                  fontSize: 12,
                  color: isHighlighted
                      ? const Color(0xFFDB2777)
                      : theme.hintColor,
                  fontWeight:
                  isHighlighted ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              _StatusBadge(status: item.status),
            ],
          ),
          const SizedBox(height: 12),

          // Avatar + name
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: theme.dividerColor,
                backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                    ? NetworkImage(avatarUrl)
                    : null,
                child: avatarUrl == null || avatarUrl.isEmpty
                    ? Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                        overflow: TextOverflow.ellipsis),
                    if (username.isNotEmpty)
                      Text(username,
                          style: TextStyle(
                              fontSize: 12, color: theme.hintColor)),
                  ],
                ),
              ),
              // posts count badge
              if (sub != null && sub.postsCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDB2777).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${sub.postsCount} posts',
                    style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFDB2777),
                        fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          _InfoRow('Amount', '\$${item.amount}', theme, isAmount: true),
          const SizedBox(height: 8),
          _InfoRow('Provider', _capitalize(item.provider), theme),
          const SizedBox(height: 8),
          _InfoRow('Expires', item.expiresAtFormatted, theme),
          const SizedBox(height: 8),
          _InfoRow('Since', item.createdAtFormatted, theme),
        ],
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ── Shared widgets ────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isActive = status.toLowerCase() == 'active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (isActive ? Colors.green : Colors.orange).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: isActive ? Colors.green : Colors.orange,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;
  final bool isAmount;

  const _InfoRow(this.label, this.value, this.theme,
      {this.isAmount = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(fontSize: 13, color: theme.hintColor)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 14,
              fontWeight:
              isAmount ? FontWeight.bold : FontWeight.w500,
              color: isAmount
                  ? const Color(0xFFDB2777)
                  : theme.textTheme.bodyMedium?.color,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 64,
              color: theme.hintColor.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(title,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: theme.textTheme.bodyLarge?.color)),
          const SizedBox(height: 8),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: theme.hintColor)),
        ],
      ),
    );
  }
}