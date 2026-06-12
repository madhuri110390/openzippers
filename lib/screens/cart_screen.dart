import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/cart_provider.dart';
import '../models/cart_response.dart';
import '../providers/wallet_payment_provider.dart';

const _kPink = Color(0xFFDB2777);
const _kDarkBg = Color(0xFF0D1B2E);
const _kCardBg = Color(0xFF14233D);
const _kCardBorder = Color(0xFF1E3050);

class CartScreen extends ConsumerStatefulWidget {
  final Function(int)? onRemove;

  const CartScreen({
    super.key,
    this.onRemove,
  });

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  bool _isProcessing = false;
  bool _paymentCompleted = false;
  final Set<int> _removedPostIds = {};

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(cartProvider);
    });
  }

  // ── Price helper ───────────────────────────────────────────────────────────
  double _parsePrice(String price) =>
      double.tryParse(price.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;

  // ── Payment ────────────────────────────────────────────────────────────────
  Future<void> _processPayment(List<CartItem> cartItems) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      bool anySuccess = false;

      for (final item in cartItems) {
        await ref.read(walletPaymentProvider.notifier).pay(postId: item.postId);
        final payState = ref.read(walletPaymentProvider);

        if (!payState.success) {
          final error = payState.error ?? '';
          final alreadyPurchased = error.toLowerCase().contains(
              'already purchased');

          if (alreadyPurchased) {
            // Mark as skipped but don't fail — item is already owned
            ref.read(walletPaymentProvider.notifier).reset();
            continue;
          }

          // Real failure — stop and report
          setState(() => _isProcessing = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Payment failed: $error'),
              backgroundColor: _kPink,
            ));
          }
          // Refresh cart anyway so UI stays in sync
          ref.invalidate(cartProvider);
          return;
        }

        anySuccess = true;
        ref.read(walletPaymentProvider.notifier).reset();
      }

      // All items processed (paid or already owned) — refresh cart + confirm
      ref.invalidate(cartProvider);
      setState(() {
        _isProcessing = false;
        _paymentCompleted = true;
      });

      if (anySuccess) {
        _showOrderConfirmation(cartItems);
      } else {
        // Every item was already purchased
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('You already own all items in your cart'),
            backgroundColor: _kPink,
          ));
        }
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: _kPink,
        ));
      }
    }
  }
  void _showOrderConfirmation(List<CartItem> items) {
    final total = items.fold(0.0, (s, i) => s + _parsePrice(i.price));
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: _kCardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: _kPink.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle, color: _kPink, size: 44),
              ),
              const SizedBox(height: 20),
              const Text(
                'Order Placed!',
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold, color: _kPink),
              ),
              const SizedBox(height: 10),
              const Text(
                'Your order has been placed successfully.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                'Total: \$${total.toStringAsFixed(2)}',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: _kPink),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPink,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('OK',
                      style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final cartAsync = ref.watch(cartProvider);

    return Scaffold(
      backgroundColor: _kDarkBg,
      appBar: AppBar(
        backgroundColor: _kDarkBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _kPink),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Row(
          children: [
            Icon(Icons.shopping_cart_outlined, color: _kPink, size: 22),
            SizedBox(width: 8),
            Text(
              'My Cart',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20),
            ),
          ],
        ),
      ),
      body: cartAsync.when(
        loading: () =>
        const Center(child: CircularProgressIndicator(color: _kPink)),
        error: (e, _) {
          debugPrint('=== CART SCREEN ERROR: $e');
          return _buildEmptyCart();
        },
        data: (cartResponse) {
          // Filter out optimistically removed items
          final cartItems = cartResponse.cartItems
              .where((item) => !_removedPostIds.contains(item.postId))
              .toList();

          if (cartItems.isEmpty) return _buildEmptyCart();

          // Compute totals from visible items only
          final subtotal =
          cartItems.fold(0.0, (s, i) => s + _parsePrice(i.price));
          final vatPercent = cartResponse.vatPercent;
          final tax = subtotal * (vatPercent / 100);
          final total = subtotal + tax;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Item count label
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                child: Text(
                  '${cartItems.length} item${cartItems.length == 1 ? '' : 's'} in cart',
                  style:
                  const TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ),

              // Scrollable item list
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: cartItems.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _buildCartItem(cartItems, i),
                ),
              ),

              // Order summary pinned at bottom
              _buildOrderSummary(subtotal, tax, vatPercent, total, cartItems),
            ],
          );
        },
      ),
    );
  }

  // ── Empty state ────────────────────────────────────────────────────────────
  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: _kPink.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shopping_cart_outlined,
                size: 64, color: _kPink),
          ),
          const SizedBox(height: 24),
          const Text(
            'Your cart is empty',
            style: TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add items to get started',
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // ── Single item card ───────────────────────────────────────────────────────
  Widget _buildCartItem(List<CartItem> items, int index) {
    final item = items[index];
    final price = _parsePrice(item.price);

    return Container(
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kCardBorder, width: 1),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Thumbnail ──────────────────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 64,
              height: 64,
              color: Colors.white10,
              child: item.image.isNotEmpty
                  ? Image.network(
                item.image,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                    Icons.image_rounded,
                    color: Colors.white38,
                    size: 28),
              )
                  : const Icon(Icons.image_rounded,
                  color: Colors.white38, size: 28),
            ),
          ),
          const SizedBox(width: 12),

          // ── Title + author ─────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.authorName.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'By ${item.authorName}',
                    style:
                    const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),

          // ── Price + Remove ─────────────────────────────────────────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price == 0 ? 'Free' : '\$${price.toStringAsFixed(2)}',
                style: const TextStyle(
                    color: _kPink, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _confirmRemove(context, item, index),
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.close, color: Colors.white, size: 12),
                      SizedBox(width: 4),
                      Text(
                        'Remove',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmRemove(BuildContext context, CartItem item, int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _kCardBg,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Item',
            style: TextStyle(color: _kPink, fontWeight: FontWeight.bold)),
        content: Text(
          'Remove "${item.title}" from cart?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Optimistic local removal — wire remove API here later
              setState(() => _removedPostIds.add(item.postId));
              widget.onRemove?.call(index);
            },
            child: const Text('Remove',
                style:
                TextStyle(color: _kPink, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ── Order summary ──────────────────────────────────────────────────────────
  Widget _buildOrderSummary(
      double subtotal,
      double tax,
      double vatPercent,
      double total,
      List<CartItem> cartItems,
      ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Row(
            children: [
              Icon(Icons.shopping_cart_outlined, color: _kPink, size: 18),
              SizedBox(width: 8),
              Text(
                'Order Summary',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: _kCardBorder, height: 1),
          const SizedBox(height: 12),

          _summaryRow('Subtotal', '\$${subtotal.toStringAsFixed(2)}'),
          const SizedBox(height: 8),
          _summaryRow(
            'Tax (${vatPercent.toStringAsFixed(0)}%)',
            '\$${tax.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 12),
          const Divider(color: _kCardBorder, height: 1),
          const SizedBox(height: 12),

          // Total row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
              Text(
                '\$${total.toStringAsFixed(2)}',
                style: const TextStyle(
                    color: _kPink, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Checkout button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed:
              _isProcessing ? null : () => _processPayment(cartItems),
              icon: _isProcessing
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
                  : const Icon(Icons.shopping_cart_checkout_rounded,
                  color: Colors.white, size: 20),
              label: Text(
                _isProcessing ? 'Processing…' : 'Checkout',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPink,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade700,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 14)),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
      ],
    );
  }
}