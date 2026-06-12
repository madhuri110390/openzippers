// lib/screens/payment_history_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../helpers/translations.dart';
import '../models/payment_transaction_response.dart';
import '../providers/repository_providers.dart';
import '../viewmodels/payment_history_viewmodel.dart';

class PaymentHistoryScreen extends ConsumerWidget {
  const PaymentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(paymentHistoryViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr.paymentHistory),
        centerTitle: true,
        actions: [
          if (!state.isLoading)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => ref
                  .read(paymentHistoryViewModelProvider.notifier)
                  .fetchTransactions(),
            ),
        ],
      ),
      body: _buildBody(context, theme, state, ref),
    );
  }

  Widget _buildBody(BuildContext context, ThemeData theme,
      PaymentHistoryState state, WidgetRef ref) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text('Something went wrong',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(state.error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: theme.hintColor)),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => ref
                    .read(paymentHistoryViewModelProvider.notifier)
                    .fetchTransactions(),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.credit_card_outlined,
                size: 64, color: theme.hintColor.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(context.tr.noPaymentHistory,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: theme.textTheme.bodyLarge?.color)),
            const SizedBox(height: 8),
            Text(context.tr.paymentHistoryDesc,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: theme.hintColor)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: state.transactions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        // Pass current user id from your auth provider if available
        // For now passing 0 — replace with ref.watch(authProvider).user.id
        return _TransactionCard(
          transaction: state.transactions[index],
          currentUserId: 0,
        );
      },
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final PaymentTransaction transaction;
  final int currentUserId;

  const _TransactionCard({
    required this.transaction,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isIncoming = transaction.isIncoming(currentUserId);

    final Color accentColor =
    isIncoming ? const Color(0xFF4CAF50) : const Color(0xFFF44336);

    final String gatewayLabel = transaction.paymentGateway != null
        ? transaction.paymentGateway![0].toUpperCase() +
        transaction.paymentGateway!.substring(1)
        : '-';

    final String statusLabel = transaction.status[0].toUpperCase() +
        transaction.status.substring(1);

    final Color statusColor = transaction.status == 'completed'
        ? const Color(0xFF4CAF50)
        : transaction.status == 'pending'
        ? const Color(0xFFFF9800)
        : const Color(0xFFF44336);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          // Top row: type icon + recipient + amount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isIncoming ? Icons.arrow_downward : Icons.arrow_upward,
                      color: accentColor,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        // e.g. "Subscription · subscription"
                        "${transaction.transactableLabel} · ${transaction.transactableVariant}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      if (transaction.recipient != null)
                        Text(
                          "@${transaction.recipient!.username}",
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF3B82F6)),
                        ),
                    ],
                  ),
                ],
              ),
              Text(
                "${transaction.currency} ${transaction.amount}",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: accentColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, thickness: 1),
          const SizedBox(height: 12),

          // Detail grid
          Row(
            children: [
              Expanded(
                child: _detail(theme, 'Tax',
                    "${transaction.currency} ${transaction.taxAmount} (${transaction.vatPercent}%)"),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _detail(theme, 'Gateway', gatewayLabel),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _detail(theme, context.tr.date, transaction.formattedDate),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _detail(theme, context.tr.status, statusLabel,
                    color: statusColor),
              ),
            ],
          ),

          // Reference ID if present
          if (transaction.paymentReferenceId != null) ...[
            const SizedBox(height: 12),
            _detail(theme, 'Reference',
                transaction.paymentReferenceId!,
                overflow: true),
          ],
        ],
      ),
    );
  }

  Widget _detail(ThemeData theme, String label, String value,
      {Color? color, bool overflow = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontSize: 11, color: theme.hintColor)),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: overflow ? 1 : null,
          overflow: overflow ? TextOverflow.ellipsis : null,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: color ?? theme.textTheme.bodyMedium?.color,
          ),
        ),
      ],
    );
  }
}