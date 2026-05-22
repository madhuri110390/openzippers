import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/mock_data.dart'; // For MockUser
import '../helpers/translations.dart';
import 'dart:async';

class TipDialog extends StatefulWidget {
  final MockUser user;

  const TipDialog({super.key, required this.user});

  @override
  State<TipDialog> createState() => _TipDialogState();
}

class _TipDialogState extends State<TipDialog> {
  final TextEditingController _amountController = TextEditingController(text: "1");
  static double _lastTipAmount = 1.0;
  double _tipAmount = 1.0;
  String _selectedMethod = 'wallet'; // 'wallet' or 'card'
  final List<int> _quickAmounts = [1, 5, 10, 25, 50, 100];
  String? _inlineError;
  Timer? _errorTimer;
  
  @override
  void initState() {
    super.initState();
    _tipAmount = _lastTipAmount;
    _amountController.text = _tipAmount == _tipAmount.toInt().toDouble() 
        ? _tipAmount.toInt().toString() 
        : _tipAmount.toString();
    _amountController.addListener(_onAmountChanged);
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    _errorTimer?.cancel();
    super.dispose();
  }

  void _onAmountChanged() {
    // Handling text change to update state
    String text = _amountController.text;
    
    // Allow empty string for backspacing
    if (text.isEmpty) {
      if (_tipAmount != 0.0) {
        setState(() {
          _tipAmount = 0.0;
        });
      }
      return;
    }

    double val = double.tryParse(text) ?? 0.0;

    // Strict validation: Revert input on invalid values
    if (val < 0) {
      _showErrorToast(context.tr.negativeAmountError);
      _restoreValidValue();
      return;
    } else if (val > 5000) {
      // Allow typing up to limit but warn if exceeded (though logic below reverts strictly)
      _showErrorToast(context.tr.maxAmountError);
      _restoreValidValue();
      return;
    }

    // No auto-correction for 0 yet to allow typing "10" (start with 1, delete to 0, type 0?) - actually 0 is blocked below by Min check on Submit
    
    if (val != _tipAmount) {
      setState(() {
        _tipAmount = val;
        _lastTipAmount = val; // Persist setting
      });
    }
  }

  void _restoreValidValue() {
    String validText = _tipAmount > 0 
        ? (_tipAmount == _tipAmount.toInt().toDouble() ? _tipAmount.toInt().toString() : _tipAmount.toString()) 
        : "";
    if (_amountController.text != validText) {
      _amountController.value = TextEditingValue(
        text: validText,
        selection: TextSelection.collapsed(offset: validText.length),
      );
    }
  }

  void _showErrorToast(String message) {
    if (!mounted) return;
    
    // Update inline error state
    _errorTimer?.cancel();
    setState(() => _inlineError = message);
    _errorTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _inlineError = null);
    });

    // Show SnackBar toast
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _setAmount(int amount) {
    setState(() {
      _tipAmount = amount.toDouble();
      _lastTipAmount = _tipAmount; // Persist setting
      _amountController.text = amount.toString();
      // Move cursor to end
      _amountController.selection = TextSelection.fromPosition(
        TextPosition(offset: _amountController.text.length),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final isDark = theme.brightness == Brightness.dark;
    
    final backgroundColor = isDark ? const Color(0xFF334155) : theme.scaffoldBackgroundColor;
    final cardColor = isDark ? const Color(0xFF475569) : theme.cardColor;
    const primaryPink = Color(0xFFDB2777);
    final textWhite = isDark ? Colors.white : theme.textTheme.bodyLarge?.color ?? Colors.black;
    final textGrey = isDark ? const Color(0xFFE2E8F0) : theme.hintColor;
    final borderColor = isDark ? const Color(0xFF64748B) : theme.dividerColor;

    return Dialog(
      backgroundColor: backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: 500, // Max width constraint
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: widget.user.avatar.startsWith('http')
                        ? NetworkImage(widget.user.avatar)
                        : null,
                    backgroundColor: Colors.grey[800],
                    child: !widget.user.avatar.startsWith('http') ? const Icon(Icons.person, color: Colors.white) : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "@${widget.user.username}",
                          style: TextStyle(
                            color: textWhite,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.star, size: 12, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text("4.9 (240)", style: TextStyle(color: textGrey, fontSize: 11)),
                            const SizedBox(width: 8),
                            Icon(Icons.access_time, size: 12, color: textGrey),
                            const SizedBox(width: 4),
                            Text(context.tr.artistRate('\$12.00'), style: TextStyle(color: textGrey, fontSize: 11)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () {
                            // Logic to rate artist
                          },
                          child: Row(
                            children: List.generate(5, (index) => const Icon(Icons.star_border, size: 14, color: Colors.amber)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: textGrey),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Tip Amount Input
              Text(
                context.tr.tipAmountMinMax,
                style: TextStyle(color: textGrey, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: backgroundColor, // Input bg
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor),
                ),
                child: TextField(
                  controller: _amountController,
                  style: TextStyle(color: textWhite),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    isDense: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                ),
              ),
              if (_inlineError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.red.withOpacity(0.5)),
                    ),
                     child: Row(
                       mainAxisSize: MainAxisSize.min,
                       children: [
                         const Icon(Icons.error_outline, size: 16, color: Colors.red),
                         const SizedBox(width: 8),
                         Text(_inlineError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                       ],
                     ),
                  ),
                ),
              const SizedBox(height: 16),

              // Quick Amounts
              Text(
                context.tr.quickAmounts,
                style: TextStyle(color: textGrey, fontSize: 13),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                child: Row(
                  children: _quickAmounts.map((amt) {
                    final isSelected = _tipAmount == amt.toDouble();
                    return Expanded(
                      child: Container(
                        margin: EdgeInsets.only(right: amt == 100 ? 0 : 8), // Spacing
                        child: ElevatedButton(
                          onPressed: () => _setAmount(amt),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSelected ? primaryPink : Colors.transparent,
                            foregroundColor: isSelected ? Colors.white : textGrey,
                            elevation: 0,
                            padding: EdgeInsets.zero,
                            side: BorderSide(
                               color: isSelected ? primaryPink : borderColor,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4), // Slightly square as in ss
                            ),
                          ),
                          child: Text("${context.tr.currencySymbol}$amt", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),

              // Totals
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                     Row(
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       children: [
                         Text("${context.tr.tipAmount}:", style: TextStyle(color: textGrey, fontSize: 13)),
                         Text("${context.tr.currencySymbol}${_tipAmount.toStringAsFixed(2)}", style: TextStyle(color: textGrey, fontSize: 13)),
                       ],
                     ),
                     const SizedBox(height: 8),
                     Row(
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       children: [
                         Text("${context.tr.time}:", style: TextStyle(color: textGrey, fontSize: 13)),
                         Text(TimeOfDay.now().format(context), style: TextStyle(color: textGrey, fontSize: 13)),
                       ],
                     ),
                     const SizedBox(height: 12),
                     Divider(color: borderColor, height: 1),
                     const SizedBox(height: 12),
                     Row(
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       children: [
                         Text("${context.tr.total}:", style: TextStyle(color: textWhite, fontWeight: FontWeight.bold, fontSize: 16)),
                         Text("${context.tr.currencySymbol}${_tipAmount.toStringAsFixed(2)}", style: TextStyle(color: textWhite, fontWeight: FontWeight.bold, fontSize: 16)),
                       ],
                     ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Payment Method
              Text(context.tr.selectPaymentMethod, style: TextStyle(color: textGrey, fontSize: 13)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildPaymentMethodCard(
                      id: 'wallet',
                      title: context.tr.wallet,
                      subtitle: '\$10.00',
                      icon: Icons.account_balance_wallet_outlined,
                      isSelected: _selectedMethod == 'wallet',
                      color: primaryPink,
                      bg: backgroundColor,
                      borderColor: primaryPink,
                      textWhite: textWhite,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildPaymentMethodCard(
                      id: 'card',
                      title: context.tr.card,
                      subtitle: context.tr.securePayment,
                      icon: Icons.credit_card,
                      isSelected: _selectedMethod == 'card',
                      color: textGrey,
                      bg: cardColor,
                      borderColor: borderColor,
                      textWhite: textWhite,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Action Buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                     if (_tipAmount < 1) {
                       _showErrorToast(context.tr.minTipAmount);
                       return;
                     }
                     if (_tipAmount > 5000) {
                       _showErrorToast(context.tr.maxTipAmount);
                       return;
                     }

                     Navigator.of(context).pop();
                     ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(content: Text(context.tr.tipSent("${context.tr.currencySymbol}${_tipAmount.toStringAsFixed(2)}")))
                     );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryPink,
                    disabledBackgroundColor: primaryPink.withOpacity(0.5), // Visual feedback for disabled
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: Text(context.tr.sendTip("${context.tr.currencySymbol}${_tipAmount.toStringAsFixed(2)}"), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                   onPressed: () => Navigator.of(context).pop(),
                   style: TextButton.styleFrom(
                     foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54,
                     padding: const EdgeInsets.symmetric(vertical: 16),
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                   ),
                   child: Text(context.tr.cancel, style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required Color color,
    required Color bg,
    required Color borderColor,
    required Color textWhite,
  }) {
    // Wallet in SS has pink border, others grey.
    final border = isSelected ? const Color(0xFFDB2777) : const Color(0xFF334155);
    
    return InkWell(
      onTap: () => setState(() => _selectedMethod = id),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: border, width: isSelected ? 2 : 1),
        ),
        child: Stack(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFDB2777).withOpacity(0.1) : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: isSelected ? const Color(0xFFDB2777) : textWhite.withOpacity(0.7), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: textWhite, fontSize: 13)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: TextStyle(color: textWhite.withOpacity(0.6), fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
            if (isSelected)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Color(0xFFDB2777), // Pink check bg? No, SS just shows check icon.
                    // Looking closely at SS, the Wallet card has a small tick icon top right.
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 10),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
