import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import '../helpers/translations.dart';
import '../providers/cart_provider.dart';
import '../models/cart_response.dart';

const _kPink = Color(0xFFDB2777);
const _kDarkBg = Color(0xFF0D1B2E);
const _kCardBg = Color(0xFF14233D);
const _kCardBorder = Color(0xFF1E3050);

class CartScreen extends ConsumerStatefulWidget {
  final ValueNotifier<List<Map<String, dynamic>>>? cartItemsNotifier;
  final Function(int)? onIncrement;
  final Function(int)? onDecrement;
  final Function(int)? onRemove;
  final Future<bool> Function(Map<String, dynamic>)? validateItemExists;

  const CartScreen({
    super.key,
    this.cartItemsNotifier,
    this.onIncrement,
    this.onDecrement,
    this.onRemove,
    this.validateItemExists,
  });

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  bool _isProcessing = false;
  final Map<int, bool> _itemAvailability = {};
  bool _hasCheckedAvailability = false;
  int _lastCartItemCount = 0;
  bool _paymentCompleted = false;

  // ── Price helpers ──────────────────────────────────────────────────────────
  double _parsePrice(dynamic priceValue) {
    if (priceValue == null) return 0.0;
    if (priceValue is num) return priceValue.toDouble();
    final s = priceValue.toString().trim().toLowerCase();
    if (s == 'free' || s.isEmpty) return 0.0;
    final clean = s.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(clean) ?? 0.0;
  }

  double _calculateTotal(List<Map<String, dynamic>> items) {
    return items.fold(0.0, (sum, item) {
      final qty = (item['quantity'] as int?) ?? 1;
      return sum + _parsePrice(item['price']) * qty;
    });
  }

  // ── Availability ───────────────────────────────────────────────────────────
  Future<void> _checkItemAvailability(List<Map<String, dynamic>> items) async {
    if (widget.validateItemExists == null) return;
    _itemAvailability.clear();
    for (int i = 0; i < items.length; i++) {
      _itemAvailability[i] = await widget.validateItemExists!(items[i]);
    }
    if (mounted) setState(() => _hasCheckedAvailability = true);
  }

  // ── Payment ────────────────────────────────────────────────────────────────
  Future<void> _processPayment(List<Map<String, dynamic>> cartItems) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    List<Map<String, dynamic>> available = List.from(cartItems);

    if (widget.validateItemExists != null) {
      await _checkItemAvailability(cartItems);
      available = [
        for (int i = 0; i < cartItems.length; i++)
          if (_itemAvailability[i] == true) cartItems[i],
      ];
      if (available.isEmpty) {
        setState(() => _isProcessing = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(context.tr.allItemsNoLongerAvailable),
            backgroundColor: _kPink,
          ));
        }
        return;
      }
    }

    await Future.delayed(const Duration(seconds: 1));
    final total = _calculateTotal(available);

    // Remove purchased items
    if (widget.cartItemsNotifier != null && widget.onRemove != null) {
      final keys = {for (var i in available) '${i['title']}_${i['author']}'};
      int removed = 0;
      while (removed < available.length) {
        final snap = List<Map<String, dynamic>>.from(widget.cartItemsNotifier!.value);
        bool found = false;
        for (int i = 0; i < snap.length; i++) {
          if (keys.contains('${snap[i]['title']}_${snap[i]['author']}')) {
            widget.onRemove!(i);
            removed++;
            found = true;
            break;
          }
        }
        if (!found) break;
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    setState(() {
      _isProcessing = false;
      _paymentCompleted = true;
    });

    _showOrderConfirmation(available, total);
  }

  void _showOrderConfirmation(List<Map<String, dynamic>> items, double total) {
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
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: _kPink,
                ),
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
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _kPink,
                ),
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
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Image helper ───────────────────────────────────────────────────────────
  DecorationImage? _getImageProvider(Map<String, dynamic> item) {
    final cover = item['coverPath']?.toString() ?? '';
    if (cover.isNotEmpty) {
      return DecorationImage(image: FileImage(File(cover)), fit: BoxFit.cover);
    }
    final img = item['image']?.toString() ?? '';
    if (img.isNotEmpty) {
      if (img.startsWith('http')) {
        return DecorationImage(image: NetworkImage(img), fit: BoxFit.cover);
      }
      return DecorationImage(image: AssetImage(img), fit: BoxFit.cover);
    }
    final fp = item['filePath']?.toString() ?? '';
    if (fp.isNotEmpty && item['type'] == 'Image') {
      return DecorationImage(image: FileImage(File(fp)), fit: BoxFit.cover);
    }
    return null;
  }

  IconData _typeIcon(String? type) {
    switch (type) {
      case 'Video':
      case 'Reel':
        return Icons.videocam_rounded;
      case 'Song':
      case 'Audio':
        return Icons.music_note_rounded;
      case 'Literature':
      case 'PDF':
        return Icons.picture_as_pdf_rounded;
      default:
        return Icons.image_rounded;
    }
  }

  // ── CartItem → Map helper ──────────────────────────────────────────────────
  Map<String, dynamic> _cartItemToMap(CartItem item) {
    return {
      'id': item.id,
      'post_id': item.postId,
      'title': item.title,
      'price': item.price,
      'author': item.authorName,
      'image': item.authorAvatar, // avatar used as thumbnail
    };
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
                color: _kPink,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
      body: cartAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: _kPink),
        ),
        error: (e, _) => Center(
          child: Text(
            'Error: $e',
            style: const TextStyle(color: Colors.white70),
          ),
        ),
        data: (cartResponse) {
          // Access items via CartResponse → CartData → CartSummary → items
          final summary = cartResponse.data.data;
          final cartItems = summary.items; // List<CartItem>

          if (cartItems.isEmpty) return _buildEmptyCart();

          final mapped = cartItems.map(_cartItemToMap).toList();

          // Use server-provided totals from CartSummary
          final subtotal = summary.subtotal;
          final tax = summary.taxAmount;
          final total = summary.total;

          // Availability check
          if (widget.validateItemExists != null &&
              !_hasCheckedAvailability &&
              !_paymentCompleted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _checkItemAvailability(mapped);
            });
          }

          return Column(
            children: [
              // Item count subtitle
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${cartItems.length} item${cartItems.length == 1 ? '' : 's'} in cart',
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ),
              ),

              // Items list
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: mapped.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) =>
                      _buildCartItem(mapped, index),
                ),
              ),

              // Order summary (uses server values)
              _buildOrderSummary(subtotal, tax, total, mapped),
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
            child: const Icon(
              Icons.shopping_cart_outlined,
              size: 64,
              color: _kPink,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Your cart is empty',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
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

  // ── Cart item card ─────────────────────────────────────────────────────────
  Widget _buildCartItem(List<Map<String, dynamic>> items, int index) {
    final item = items[index];
    final isAvailable = _itemAvailability[index] ?? true;
    final price = _parsePrice(item['price']);
    final author = item['author']?.toString() ?? '';
    final imageDeco = _getImageProvider(item);

    return Container(
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kCardBorder, width: 1),
      ),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white10,
                image: imageDeco,
              ),
              child: imageDeco == null
                  ? Icon(_typeIcon(item['type']?.toString()),
                  color: Colors.white38, size: 32)
                  : null,
            ),
          ),

          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title']?.toString() ?? 'Unknown',
                    style: TextStyle(
                      color: isAvailable ? Colors.white : Colors.white38,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      decoration: isAvailable ? null : TextDecoration.lineThrough,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (author.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        'By $author',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Price + Remove
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 12, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price == 0 ? 'Free' : '\$${price.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: isAvailable ? _kPink : Colors.white38,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    decoration: isAvailable ? null : TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => _confirmRemove(context, item, index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade700,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.close, color: Colors.white, size: 13),
                        SizedBox(width: 4),
                        Text(
                          'Remove',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmRemove(
      BuildContext context, Map<String, dynamic> item, int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _kCardBg,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Item',
            style: TextStyle(color: _kPink, fontWeight: FontWeight.bold)),
        content: Text(
          'Remove "${item['title']}" from cart?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
            const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              widget.onRemove?.call(index);
              ref.invalidate(cartProvider);
              Navigator.pop(context);
            },
            child: const Text('Remove',
                style: TextStyle(
                    color: _kPink, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ── Order summary ──────────────────────────────────────────────────────────
  Widget _buildOrderSummary(
      double subtotal,
      double tax,
      double total,
      List<Map<String, dynamic>> items,
      ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: const [
              Icon(Icons.shopping_cart_outlined, color: _kPink, size: 18),
              SizedBox(width: 8),
              Text(
                'Order Summary',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: _kCardBorder, height: 1),
          const SizedBox(height: 14),

          // Subtotal
          _summaryRow(
            'Subtotal',
            '\$${subtotal.toStringAsFixed(2)}',
            valueColor: Colors.white,
          ),
          const SizedBox(height: 8),

          // Tax
          _summaryRow(
            'Tax (18.00%)',
            '\$${tax.toStringAsFixed(2)}',
            valueColor: Colors.white,
          ),
          const SizedBox(height: 14),
          const Divider(color: _kCardBorder, height: 1),
          const SizedBox(height: 14),

          // Total
          _summaryRow(
            'Total',
            '\$${total.toStringAsFixed(2)}',
            labelStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16),
            valueColor: _kPink,
            valueSize: 18,
          ),
          const SizedBox(height: 18),

          // Checkout button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed:
              _isProcessing ? null : () => _processPayment(items),
              icon: _isProcessing
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Icon(Icons.shopping_cart_checkout_rounded,
                  color: Colors.white, size: 20),
              label: Text(
                _isProcessing ? 'Processing…' : 'Checkout',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPink,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade700,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(
      String label,
      String value, {
        TextStyle? labelStyle,
        Color valueColor = Colors.white70,
        double valueSize = 14,
      }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: labelStyle ??
              const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: valueSize,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}