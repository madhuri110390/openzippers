import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/mock_data.dart';
import '../helpers/database_helper.dart';
import '../helpers/translations.dart';
import '../providers/wallet_history_provider.dart';
import '../providers/wallet_provider.dart';

class WalletScreen extends ConsumerStatefulWidget {
  final MockUser currentUser;

  const WalletScreen({
    super.key,
    required this.currentUser,
  });

  @override
  ConsumerState<WalletScreen> createState() =>
      _WalletScreenState();
}

class _WalletScreenState
    extends ConsumerState<WalletScreen> with SingleTickerProviderStateMixin {

  double? _walletBalance;
  final TextEditingController _amountController = TextEditingController();
  final FocusNode _amountFocusNode = FocusNode();
  List<Map<String, dynamic>> _transactions = [];
 // final List<double> _quickAmounts = [10, 25, 50, 100, 200, 500];
  bool _isLoadingBalance = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _loadSavedAmount();
    _amountController.addListener(_saveAmount);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.removeListener(_saveAmount);
    _amountController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadSavedAmount() async {
    final prefs = await SharedPreferences.getInstance();
    final savedAmount = prefs.getString('wallet_amount_${widget.currentUser.username}');
    if (savedAmount != null && savedAmount.isNotEmpty && _amountController.text.isEmpty) {
      _amountController.text = savedAmount;
    }
  }

  Future<void> _saveAmount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('wallet_amount_${widget.currentUser.username}', _amountController.text);
  }



  Future<void> _deposit(double amount) async {
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr.pleaseEnterValidAmount)),
      );
      return;
    }

    final currentBalance = _walletBalance ?? 0.0;
    final newBalance = currentBalance + amount;
    
    setState(() {
      _walletBalance = newBalance;
      _isLoadingBalance = false;
    });
    

    
    _amountController.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('wallet_amount_${widget.currentUser.username}');
    

    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr.successfullyDeposited('${context.tr.currencySymbol}${amount.toStringAsFixed(2)}'))),
      );
    }
  }

  String _localizeDescription(String description, double amount) {
     if (description == 'Wallet deposit') {
       return context.tr.walletDeposit('${context.tr.currencySymbol}${amount.toStringAsFixed(2)}');
     }
     return description;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(context.tr.wallet),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFDB2777),
          labelColor: const Color(0xFFDB2777),
          unselectedLabelColor: theme.hintColor,
          tabs: [
            Tab(text: context.tr.wallet),
            Tab(text: context.tr.history),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildWalletTab(theme),
          _buildHistoryTab(theme),
        ],
      ),
    );
  }

  Widget _buildWalletTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(context.tr.currentBalance, style: TextStyle(fontSize: 14, color: theme.textTheme.bodyMedium?.color)),
                    const Spacer(),
                    ref.watch(walletProvider).when(
                      loading: () => const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                      error: (_, __) => const Text(
                        "\$0.00",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFDB2777),
                        ),
                      ),
                      data: (response) => Text(
                        "\$${response.data.balance.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFDB2777),
                        ),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    //Text(context.tr.quickAmounts, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: theme.textTheme.bodyMedium?.color)),
                    const Spacer(),

                    // OutlinedButton(
                    //   onPressed: () {
                    //     _amountController.clear();
                    //     ScaffoldMessenger.of(context).showSnackBar(
                    //       SnackBar(
                    //         content: Text(context.tr.amountCleared),
                    //         duration: const Duration(seconds: 1),
                    //       ),
                    //     );
                    //   },
                    //   style: OutlinedButton.styleFrom(
                    //     backgroundColor: theme.brightness == Brightness.light
                    //       ? const Color(0xFFF8F9FA)
                    //       : theme.colorScheme.surfaceContainerHighest,
                    //     foregroundColor: theme.textTheme.bodyMedium?.color,
                    //     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    //     minimumSize: const Size(0, 32),
                    //     shape: RoundedRectangleBorder(
                    //       borderRadius: BorderRadius.circular(8),
                    //       side: BorderSide(color: theme.dividerColor),
                    //     ),
                    //     elevation: 0,
                    //   ),
                    //   child: Row(
                    //     mainAxisSize: MainAxisSize.min,
                    //     children: [
                    //       Icon(Icons.clear, size: 14, color: theme.textTheme.bodyMedium?.color),
                    //       const SizedBox(width: 4),
                    //       Text(context.tr.clear, style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color)),
                    //     ],
                    //   ),
                    // ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                   // itemCount: _quickAmounts.length,
                    itemBuilder: (context, index) {
                     // final amount = _quickAmounts[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        // child: ElevatedButton(
                        //   // onPressed: () {
                        //   //   _amountController.text = amount.toStringAsFixed(0);
                        //   // },
                        //   style: ElevatedButton.styleFrom(
                        //     backgroundColor: theme.brightness == Brightness.light
                        //       ? const Color(0xFFF8F9FA)
                        //       : theme.colorScheme.surfaceContainerHighest,
                        //     foregroundColor: theme.textTheme.bodyMedium?.color,
                        //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        //     shape: RoundedRectangleBorder(
                        //       borderRadius: BorderRadius.circular(8),
                        //       side: BorderSide(color: theme.dividerColor),
                        //     ),
                        //     elevation: 0,
                        //   ),
                        //   child: Text("+${context.tr.currencySymbol}${amount.toStringAsFixed(0)}"),
                        // ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                //
                // Row(
                //   children: [
                //     Expanded(
                //       child: TextField(
                //         controller: _amountController,
                //         focusNode: _amountFocusNode,
                //         keyboardType: const TextInputType.numberWithOptions(decimal: true),
                //         decoration: InputDecoration(
                //           hintText: context.tr.enterAmount,
                //           hintStyle: TextStyle(color: theme.hintColor),
                //           border: OutlineInputBorder(
                //             borderRadius: BorderRadius.circular(8),
                //             borderSide: const BorderSide(color: Color(0xFFDB2777), width: 1.5),
                //           ),
                //           enabledBorder: OutlineInputBorder(
                //             borderRadius: BorderRadius.circular(8),
                //             borderSide: const BorderSide(color: Color(0xFFDB2777), width: 1.5),
                //           ),
                //           focusedBorder: OutlineInputBorder(
                //             borderRadius: BorderRadius.circular(8),
                //             borderSide: const BorderSide(color: Color(0xFFDB2777), width: 2.5),
                //           ),
                //           disabledBorder: OutlineInputBorder(
                //             borderRadius: BorderRadius.circular(8),
                //             borderSide: BorderSide(color: theme.dividerColor, width: 1),
                //           ),
                //           contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                //           filled: true,
                //           fillColor: theme.brightness == Brightness.light
                //             ? const Color(0xFFF8F9FA)
                //             : theme.colorScheme.surfaceContainerHighest,
                //         ),
                //       ),
                //     ),
                //     const SizedBox(width: 12),
                //     ElevatedButton(
                //       onPressed: () {
                //         final amount = double.tryParse(_amountController.text) ?? 0.0;
                //         _deposit(amount);
                //       },
                //       style: ElevatedButton.styleFrom(
                //         backgroundColor: const Color(0xFFDB2777),
                //         foregroundColor: Colors.white,
                //         padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                //         shape: RoundedRectangleBorder(
                //           borderRadius: BorderRadius.circular(8),
                //         ),
                //       ),
                //       child: Text(context.tr.deposit),
                //     ),
                //   ],
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(ThemeData theme) {
    final historyAsync = ref.watch(walletHistoryProvider);

    return historyAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFFDB2777)),
      ),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                color: theme.hintColor, size: 48),
            const SizedBox(height: 16),
            Text('Failed to load history',
                style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                    fontSize: 16)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => ref.invalidate(walletHistoryProvider),
              child: const Text('Retry',
                  style: TextStyle(color: Color(0xFFDB2777))),
            ),
          ],
        ),
      ),
      data: (response) {
        if (response.data.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.account_balance_wallet_outlined,
                    size: 64,
                    color: theme.hintColor.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                Text(
                  context.tr.noWalletTransactions,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: theme.textTheme.bodyLarge?.color),
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr.walletTransactionHistoryDesc,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: theme.hintColor),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: response.data.length,
          itemBuilder: (context, index) {
            final tx = response.data[index];
            final isDeposit = tx.type == 'deposit';

            // Format date
            String formattedDate = tx.createdAt;
            try {
              final dt = DateTime.parse(tx.createdAt);
              formattedDate =
              '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
                  '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
            } catch (_) {}

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: theme.dividerColor.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  // ── Icon ──────────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDeposit
                          ? const Color(0xFF4CAF50).withValues(alpha: 0.1)
                          : const Color(0xFFDB2777).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isDeposit
                          ? Icons.arrow_downward
                          : Icons.arrow_upward,
                      color: isDeposit
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFFDB2777),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // ── Description + date ─────────────────────────────────
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isDeposit ? 'Wallet Deposit' : 'Payment',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: theme.textTheme.bodyLarge?.color),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formattedDate,
                          style: TextStyle(
                              fontSize: 12, color: theme.hintColor),
                        ),
                        const SizedBox(height: 2),
                        // Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: tx.status == 'completed'
                                ? const Color(0xFF4CAF50).withValues(alpha: 0.12)
                                : tx.status == 'pending'
                                ? Colors.orange.withValues(alpha: 0.12)
                                : Colors.red.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            tx.status[0].toUpperCase() +
                                tx.status.substring(1),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: tx.status == 'completed'
                                  ? const Color(0xFF4CAF50)
                                  : tx.status == 'pending'
                                  ? Colors.orange
                                  : Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Amount ─────────────────────────────────────────────
                  Text(
                    '${isDeposit ? '+' : '-'}${context.tr.currencySymbol}'
                        '${double.tryParse(tx.amount)?.toStringAsFixed(2) ?? tx.amount}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDeposit
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFFDB2777),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
