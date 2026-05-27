import 'package:flutter/material.dart';
import '../helpers/translations.dart';
import '../models/mock_data.dart';
import '../helpers/database_helper.dart';

class SubscriptionsPage extends StatefulWidget {
  final MockUser currentUser;
  final String? highlightUser;
  const SubscriptionsPage({super.key, required this.currentUser, this.highlightUser});

  @override
  State<SubscriptionsPage> createState() => _SubscriptionsPageState();
}

class _SubscriptionsPageState extends State<SubscriptionsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _subscriptions = [];
  List<Map<String, dynamic>> _subscribers = [];
  String apiAmount = '\$12.00';
  String apiStatus = 'Active';
  String apiExpiresAt = 'N/A';
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    if (widget.highlightUser != null) {
      _tabController.index = 1;
    }

    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {

      final relationships = await _dbHelper.getRelationships(widget.currentUser.username);

      final List<Map<String, dynamic>> subs = [];
      final List<Map<String, dynamic>> fans = [];

      relationships.forEach((username, type) {
        if (type == 'subscribed') {
          subs.add({
            'type': 'Artist',
            'user': widget.currentUser.username,
            'amount': apiAmount,
            'status': apiStatus,
            'provider': 'Stripe',
            'nextBilling': apiExpiresAt,
            'created': 'Recent',
          });
        } else if (type == 'subscriber') {
          fans.add({
            'type': 'Fan',
            'user': '@$username',
            'amount': '\$12.00',
            'status': 'Active',
            'provider': 'Stripe',
            'nextBilling': 'N/A',
            'created': 'Recent'
          });
        }
      });

      if (mounted) {
        setState(() {
          _subscriptions = subs;
          _subscribers = fans;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading subscription data: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Use _subscriptions and _subscribers loaded from DB
    final subscriptions = _subscriptions;
    final subscribers = _subscribers;

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
      body: CustomScrollView(
        slivers: [
          // Stats Section
          SliverToBoxAdapter(
            child: Container(
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
                      _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFFDB2777),
                                ),
                              ),
                            )
                          : IconButton(
                              icon: const Icon(
                                Icons.refresh,
                                size: 20,
                                color: Color(0xFFDB2777),
                              ),
                              onPressed: _refreshData,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Total Earnings
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.tr.totalEarnings,
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.hintColor,
                        ),
                      ),
                      const Text(
                        '\$0.00',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFDB2777),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Stats in Column
                  Column(
                    children: [
                      Container(
                        width: double.infinity,
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
                            Text(
                              context.tr.activeSubscribers,
                              style: TextStyle(
                                fontSize: 14,
                                color: theme.hintColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${subscribers.length}',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: theme.textTheme.titleLarge?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
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
                            Text(
                              context.tr.yourSubscriptions,
                              style: TextStyle(
                                fontSize: 14,
                                color: theme.hintColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${subscriptions.length}',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: theme.textTheme.titleLarge?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
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
                            Text(
                              context.tr.totalSubscriptions,
                              style: TextStyle(
                                fontSize: 14,
                                color: theme.hintColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${subscriptions.length + subscribers.length}',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: theme.textTheme.titleLarge?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Tabs
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
                onTap: (index) {
                  setState(() {});
                },
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
          
          // Tab Content
          ...(_tabController.index == 0
              ? _buildSubscriptionSlivers(theme, subscriptions)
              : _buildSubscriberSlivers(theme, subscribers)),
        ],
      ),
    );
  }

  List<Widget> _buildSubscriptionSlivers(ThemeData theme, List<Map<String, dynamic>> subscriptions) {
    if (subscriptions.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 64,
                    color: theme.hintColor.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.tr.noSubscriptionsFound,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.tr.subscriptionHistoryDesc,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.hintColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.only(bottom: 10, top: 0),
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
                  ...subscriptions.asMap().entries.map((entry) {
                    final index = entry.key;
                    final sub = entry.value;
                    return Container(
                      margin: EdgeInsets.fromLTRB(20, 0, 20, index == subscriptions.length - 1 ? 16 : 12),
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '#${index + 1}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.hintColor,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  sub['status'] == 'Active' ? context.tr.active : sub['status']?.toString() ?? '',
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),


                          const SizedBox(height: 8),
                          _buildInfoRow(context.tr.subscriptionType, sub['type'] == 'Artist' ? context.tr.artist : sub['type']?.toString() ?? '', theme),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            context.tr.user,
                            sub['user']?.toString() ?? '',
                            theme,
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(context.tr.user, sub['user']?.toString() ?? '', theme),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            context.tr.amount,
                            sub['amount']?.toString() ?? '',
                            theme,
                            isAmount: true,
                          ),

                          const SizedBox(height: 8),
                          _buildInfoRow(context.tr.provider, sub['provider'] == 'Stripe' ? context.tr.gatewayStripe : sub['provider']?.toString() ?? '', theme),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            "Status",
                            sub['status']?.toString().toUpperCase() ?? '',
                            theme,
                          ),
                          _buildInfoRow(
                            context.tr.nextBilling,
                            sub['nextBilling']?.toString().split('T').first ?? '',
                            theme,
                          ),

                          const SizedBox(height: 8),
                          _buildInfoRow(context.tr.created, sub['created']?.toString() ?? '', theme),
                        ],
                      ),
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

  Widget _buildInfoRow(String label, String value, ThemeData theme, {bool isAmount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: theme.hintColor,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isAmount ? FontWeight.bold : FontWeight.w500,
              color: isAmount ? const Color(0xFFDB2777) : theme.textTheme.bodyMedium?.color,
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildSubscriberSlivers(ThemeData theme, List<Map<String, dynamic>> subscribers) {
    if (subscribers.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: theme.hintColor.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.tr.noSubscribersFound,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.tr.subscriberListDesc,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.hintColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.only(bottom: 20, top: 0),
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
                  ...subscribers.asMap().entries.map((entry) {
                    final index = entry.key;
                    final sub = entry.value;
                    final isHighlighted = widget.highlightUser != null && sub['user'] == widget.highlightUser;

                    return Container(
                      margin: EdgeInsets.fromLTRB(20, 0, 20, index == subscribers.length - 1 ? 16 : 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isHighlighted
                            ? const Color(0xFFDB2777).withValues(alpha: 0.1) // Pink highlight
                            : (theme.brightness == Brightness.light
                                ? const Color(0xFFF8F9FA)
                                : theme.colorScheme.surfaceContainerHighest),
                        borderRadius: BorderRadius.circular(8),
                        border: isHighlighted ? Border.all(color: const Color(0xFFDB2777), width: 1.5) : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '#${index + 1}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isHighlighted ? const Color(0xFFDB2777) : theme.hintColor,
                                  fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  sub['status'] == 'Active' ? context.tr.active : sub['status']?.toString() ?? '',
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(context.tr.subscriptionType, sub['type']?.toString() ?? '', theme),
                          const SizedBox(height: 8),
                          _buildInfoRow(context.tr.user, sub['user']?.toString() ?? '', theme),
                          const SizedBox(height: 8),
                          _buildInfoRow(context.tr.amount, sub['amount']?.toString() ?? '', theme, isAmount: true),
                          const SizedBox(height: 8),
                          _buildInfoRow(context.tr.provider, sub['provider'] == 'Stripe' ? context.tr.gatewayStripe : sub['provider']?.toString() ?? '', theme),
                          const SizedBox(height: 8),
                          _buildInfoRow(context.tr.nextBilling, sub['nextBilling']?.toString() ?? '', theme),
                          const SizedBox(height: 8),
                          _buildInfoRow(context.tr.created, sub['created']?.toString() ?? '', theme),
                        ],
                      ),
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

