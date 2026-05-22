import 'package:flutter/material.dart';
import '../helpers/translations.dart';

class PaymentHistoryScreen extends StatelessWidget {
  const PaymentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Hardcoded dummy data as per original SettingsScreen
    final payments = [
      {
        'id': '1',
        'amount': 11.00,
        'tax': 1.00,
        'tax_percent': 10.00,
        'type': 'Payment Received', // Will be localized if possible but string keys might vary
        'sub_type': 'Subscription (Subscription)', 
        'recipient': '@priyap',
        'gateway': 'Stripe',
        'status': 'Completed',
        'reference': 'cs_test_a1...',
        'date': '2025-Nov-26',
        'is_incoming': true,
      },
       {
        'id': '2',
        'amount': 5.00,
        'tax': 0.00,
        'tax_percent': 0.00,
        'type': 'Payment Sent',
        'sub_type': 'Tip',
        'recipient': '@alex_d',
        'gateway': 'Wallet',
        'status': 'Pending',
        'reference': 'wt_29ad...',
        'date': '2025-Dec-01',
        'is_incoming': false,
      }
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr.paymentHistory),
        centerTitle: true,
      ),
      body: payments.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.credit_card_outlined,
                    size: 64,
                    color: theme.hintColor.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.tr.noPaymentHistory,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.tr.paymentHistoryDesc,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.hintColor,
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: payments.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final payment = payments[index];
                final isIncoming = payment['is_incoming'] as bool;
                final amount = payment['amount'] as num;
                
                // Manual localization attempt based on dummy strings
                String typeDisplay = payment['type'] as String;
                if (typeDisplay == 'Payment Received') typeDisplay = context.tr.paymentReceived;
                if (typeDisplay == 'Payment Sent') typeDisplay = context.tr.paymentSent;

                String gatewayDisplay = payment['gateway'] as String;
                if (gatewayDisplay == 'Stripe') gatewayDisplay = context.tr.gatewayStripe;
                if (gatewayDisplay == 'Wallet') gatewayDisplay = context.tr.gatewayWallet;

                String statusDisplay = payment['status'] as String;
                if (statusDisplay == 'Completed') statusDisplay = context.tr.paymentStatusCompleted;
                if (statusDisplay == 'Pending') statusDisplay = context.tr.paymentStatusPending;

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isIncoming 
                                      ? const Color(0xFF4CAF50).withValues(alpha: 0.1)
                                      : const Color(0xFFF44336).withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isIncoming ? Icons.arrow_downward : Icons.arrow_upward,
                                  color: isIncoming ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    typeDisplay,
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: theme.textTheme.bodyLarge?.color),
                                  ),
                                  Text(
                                    payment['recipient'] as String,
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF3B82F6)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Text(
                            "${context.tr.currencySymbol}${amount.toStringAsFixed(2)}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isIncoming ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1, thickness: 1),
                      const SizedBox(height: 12),
                      Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: _buildDetailItem(theme, context.tr.tax, "${context.tr.currencySymbol}${(payment['tax'] as num).toStringAsFixed(2)}")),
                              const SizedBox(width: 8),
                              Expanded(child: _buildDetailItem(theme, context.tr.gateway, gatewayDisplay)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: _buildDetailItem(theme, context.tr.date, payment['date'] as String)),
                              const SizedBox(width: 8),
                              Expanded(child: _buildDetailItem(theme, context.tr.status, statusDisplay, color: const Color(0xFF4CAF50))),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildDetailItem(ThemeData theme, String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: theme.hintColor)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color ?? theme.textTheme.bodyMedium?.color)),
      ],
    );
  }
}
