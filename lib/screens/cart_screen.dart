import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import '../helpers/translations.dart';
import '../providers/cart_provider.dart';

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

  double _calculateTotal(List<Map<String, dynamic>> cartItems) {
    double total = 0.0;
    for (var item in cartItems) {
      final priceValue = item['price'];
      double price = 0.0;
      

      if (priceValue == null) {
        price = 0.0;
      } else if (priceValue is num) {

        price = priceValue.toDouble();
      } else {

        final priceStr = priceValue.toString().trim().toLowerCase();
        

        if (priceStr == 'free' || priceStr.isEmpty) {
          price = 0.0;
        } else {

          final cleanPrice = priceStr.replaceAll(RegExp(r'[^\d.]'), '');
          if (cleanPrice.isNotEmpty) {
            price = double.tryParse(cleanPrice) ?? 0.0;
          }
        }
      }
      
      final quantity = item['quantity'] as int? ?? 1;
      total += price * quantity;
    }
    return total;
  }

  void _showOrderConfirmation(List<Map<String, dynamic>> cartItems, double total) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDB2777).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Color(0xFFDB2777),
                    size: 50,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  context.tr.orderPlaced,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFDB2777),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  context.tr.orderPlacedSuccess,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Total: \$${total.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFDB2777),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDB2777),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      context.tr.ok,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _checkItemAvailability(List<Map<String, dynamic>> cartItems) async {
    if (widget.validateItemExists == null) return;
    _itemAvailability.clear();
    for (int i = 0; i < cartItems.length; i++) {
      final exists = await widget.validateItemExists!(cartItems[i]);
      _itemAvailability[i] = exists;
    }
    setState(() {
      _hasCheckedAvailability = true;
    });
  }

  Future<void> _processPayment(List<Map<String, dynamic>> cartItems) async {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
    });
    
    // Check availability before processing payment
    List<Map<String, dynamic>> availableItems = List.from(cartItems);
    int unavailableCount = 0;
    
    if (widget.validateItemExists != null) {
      await _checkItemAvailability(cartItems);
      
      // Filter out unavailable items - keep only available ones
      availableItems = [];
      final unavailableItems = <int>[];
      
      for (int i = 0; i < cartItems.length; i++) {
        if (_itemAvailability[i] == true) {
          availableItems.add(cartItems[i]);
        } else {
          unavailableItems.add(i);
        }
      }
      
      unavailableCount = unavailableItems.length;
      
      // If no items are available, show error and return
      if (availableItems.isEmpty) {
        setState(() {
          _isProcessing = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                unavailableCount == 1
                    ? context.tr.itemNoLongerAvailable
                    : context.tr.allItemsNoLongerAvailable,
              ),
              backgroundColor: const Color(0xFFDB2777),
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return;
      }
      
      // If some items are unavailable, proceed with payment for available items
      // Payment will proceed even if user didn't remove unavailable items manually
      // No toast message shown - payment proceeds silently for available items
    }

    // Proceed with payment for available items only
    // This happens regardless of whether unavailable items exist in cart
    // Simulate payment processing
    await Future.delayed(const Duration(seconds: 1));

    // Calculate total only for available items
    final total = _calculateTotal(availableItems);
    
    // Remove only available items from cart and database after successful payment
    // Keep unavailable items in cart so user can see and remove them manually
    if (widget.cartItemsNotifier != null && widget.onRemove != null) {
      final currentCart = List<Map<String, dynamic>>.from(widget.cartItemsNotifier!.value);
      
      // Create a set of available items for lookup (using title + author as unique identifier)
      final availableItemsSet = <String>{};
      for (var item in availableItems) {
        final key = '${item['title']}_${item['author']}';
        availableItemsSet.add(key);
      }
      
      // Remove available items from database one by one
      // Since onRemove reloads cart, we need to find items by their unique key each time
      int removedCount = 0;
      while (removedCount < availableItems.length) {
        final currentCartSnapshot = List<Map<String, dynamic>>.from(widget.cartItemsNotifier!.value);
        bool foundAndRemoved = false;
        
        // Find first available item in current cart and remove it
        for (int i = 0; i < currentCartSnapshot.length; i++) {
          final item = currentCartSnapshot[i];
          final key = '${item['title']}_${item['author']}';
          if (availableItemsSet.contains(key)) {
            widget.onRemove!(i);
            removedCount++;
            foundAndRemoved = true;
            break; // Break and reload cart for next iteration
          }
        }
        
        // If no item found, break to avoid infinite loop
        if (!foundAndRemoved) break;
        
        // Wait a bit for database update to complete
        await Future.delayed(const Duration(milliseconds: 100));
      }
      
      // Final update to ensure UI is in sync
      final finalCart = List<Map<String, dynamic>>.from(widget.cartItemsNotifier!.value);
      final remainingItems = finalCart.where((item) {
        final key = '${item['title']}_${item['author']}';
        return !availableItemsSet.contains(key);
      }).toList();
      widget.cartItemsNotifier!.value = remainingItems;
    } else if (widget.cartItemsNotifier != null) {
      // Fallback: just update notifier if onRemove callback not available
      final currentCart = List<Map<String, dynamic>>.from(widget.cartItemsNotifier!.value);
      final availableItemsSet = <String>{};
      for (var item in availableItems) {
        final key = '${item['title']}_${item['author']}';
        availableItemsSet.add(key);
      }
      final remainingItems = currentCart.where((item) {
        final key = '${item['title']}_${item['author']}';
        return !availableItemsSet.contains(key);
      }).toList();
      widget.cartItemsNotifier!.value = remainingItems;
    }

    setState(() {
      _isProcessing = false;
      _paymentCompleted = true;
    });


    _showOrderConfirmation(availableItems, total);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cartAsync = ref.watch(cartProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr.myCart, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFDB2777))),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: const Color(0xFFDB2777)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ValueListenableBuilder<List<Map<String, dynamic>>>(
        valueListenable: widget.cartItemsNotifier ?? ValueNotifier([]),
        builder: (context, cartItems, child) {

          if (cartItems.length != _lastCartItemCount) {

            if (_paymentCompleted && cartItems.length < _lastCartItemCount) {

              _lastCartItemCount = cartItems.length;
            } else {

              _lastCartItemCount = cartItems.length;
              _hasCheckedAvailability = false;
              _itemAvailability.clear();
              _paymentCompleted = false;
            }
          }
          

          if (widget.validateItemExists != null && 
              !_hasCheckedAvailability && 
              cartItems.isNotEmpty &&
              !_paymentCompleted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _checkItemAvailability(cartItems);
            });
          }
          
          final total = _calculateTotal(cartItems);
          
          return cartItems.isEmpty 
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                     Container(
                       padding: const EdgeInsets.all(24),
                       decoration: BoxDecoration(
                         color: const Color(0xFFDB2777).withOpacity(0.1),
                         shape: BoxShape.circle,
                       ),
                       child: const Icon(
                         Icons.shopping_cart_outlined, 
                         size: 80, 
                         color: Color(0xFFDB2777),
                       ),
                     ),
                     const SizedBox(height: 24),
                     Text(
                       context.tr.noItemsInCart,
                       style: TextStyle(
                         fontSize: 22, 
                         fontWeight: FontWeight.bold,
                         color: theme.textTheme.titleLarge?.color ?? const Color(0xFFDB2777),
                       ),
                     ),
                     const SizedBox(height: 12),
                     Text(
                       context.tr.addItemsToCart,
                       style: TextStyle(
                         fontSize: 16, 
                         color: theme.hintColor,
                       ),
                       textAlign: TextAlign.center,
                     ),
                  ],
                ),
              )
            : ListView.builder(
                itemCount: cartItems.length,
                itemBuilder: (context, index) {
                  final item = cartItems[index];
                  final isAvailable = _itemAvailability[index] ?? true;
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: !isAvailable 
                                ? Colors.grey.withOpacity(0.05) 
                                : theme.cardColor ?? Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: !isAvailable 
                                  ? Colors.grey.withOpacity(0.3) 
                                  : const Color(0xFFDB2777).withOpacity(0.2),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Opacity(
                            opacity: !isAvailable ? 0.5 : 1.0,
                            child: Row(
                              children: [
                                 if (item['type'] == 'Video' || item['type'] == 'Reel')
                                   _buildVideoThumbnail(item)
                                 else
                                   Container(
                                     width: 80,
                                     height: 80,
                                     decoration: BoxDecoration(
                                       color: Colors.grey[200],
                                       borderRadius: BorderRadius.circular(12),
                                       image: _getImageProvider(item),
                                     ),
                                     child: _getImageProvider(item) == null
                                          ? _buildFallbackIcon(item)
                                          : null,
                                   ),
                                 const SizedBox(width: 16),
                                 // Details
                                 Expanded(
                                   child: Column(
                                     crossAxisAlignment: CrossAxisAlignment.start,
                                     children: [
                                       Text(
                                         item['title'] ?? 'Unknown Item',
                                         style: TextStyle(
                                           fontWeight: FontWeight.bold,
                                           fontSize: 16,
                                           decoration: !isAvailable ? TextDecoration.lineThrough : null,
                                           color: !isAvailable 
                                               ? Colors.grey[600] 
                                               : theme.textTheme.titleLarge?.color,
                                         ),
                                       ),
                                       const SizedBox(height: 6),
                                       Text(
                                         item['price'] ?? 'Free',
                                         style: TextStyle(
                                           fontSize: 16,
                                           fontWeight: FontWeight.w600,
                                           color: !isAvailable 
                                               ? Colors.grey[500] 
                                               : const Color(0xFFDB2777),
                                           decoration: !isAvailable ? TextDecoration.lineThrough : null,
                                         ),
                                       ),
                                       if (!isAvailable)
                                         Padding(
                                           padding: const EdgeInsets.only(top: 6),
                                           child: Row(
                                             children: [
                                               Icon(
                                                 Icons.error_outline,
                                                 size: 14,
                                                 color: const Color(0xFFDB2777),
                                               ),
                                               const SizedBox(width: 4),
                                               Text(
                                                 context.tr.noLongerAvailable,
                                                 style: TextStyle(
                                                   color: const Color(0xFFDB2777),
                                                   fontSize: 12,
                                                   fontWeight: FontWeight.w500,
                                                 ),
                                               ),
                                             ],
                                           ),
                                         ),
                                       const SizedBox(height: 12),
                                     if (isAvailable)
                                       Container(
                                         decoration: BoxDecoration(
                                           color: theme.brightness == Brightness.dark 
                                               ? Colors.grey[800] 
                                               : Colors.grey[100],
                                           borderRadius: BorderRadius.circular(20),
                                           border: Border.all(
                                             color: const Color(0xFFDB2777).withOpacity(0.3),
                                             width: 1,
                                           ),
                                         ),
                                         child: Material(
                                           color: Colors.transparent,
                                           borderRadius: BorderRadius.circular(20),
                                           child: Row(
                                             mainAxisSize: MainAxisSize.min,
                                             children: [
                                               Material(
                                                 color: Colors.transparent,
                                                 child: InkWell(
                                                   onTap: () => widget.onDecrement?.call(index),
                                                   borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
                                                   child: Padding(
                                                     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                     child: const Icon(
                                                       Icons.remove, 
                                                       size: 18, 
                                                       color: Color(0xFFDB2777),
                                                     ),
                                                   ),
                                                 ),
                                               ),
                                               Container(
                                                 padding: const EdgeInsets.symmetric(horizontal: 12),
                                                 child: Text(
                                                   '${item['quantity'] ?? 1}', 
                                                   style: TextStyle(
                                                     fontWeight: FontWeight.bold,
                                                     fontSize: 16,
                                                     color: theme.textTheme.bodyLarge?.color,
                                                   ),
                                                 ),
                                               ),
                                               Material(
                                                 color: Colors.transparent,
                                                 child: InkWell(
                                                   onTap: () => widget.onIncrement?.call(index),
                                                   borderRadius: const BorderRadius.horizontal(right: Radius.circular(20)),
                                                   child: Padding(
                                                     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                     child: const Icon(
                                                       Icons.add, 
                                                       size: 18, 
                                                       color: Color(0xFFDB2777),
                                                     ),
                                                   ),
                                                 ),
                                               ),
                                             ],
                                           ),
                                         ),
                                       )
                                     else
                                       Container(
                                         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                         decoration: BoxDecoration(
                                           color: Colors.grey[200],
                                           borderRadius: BorderRadius.circular(20),
                                           border: Border.all(
                                             color: Colors.grey[300]!,
                                             width: 1,
                                           ),
                                         ),
                                         child: Text(
                                           '${context.tr.qty}: ${item['quantity'] ?? 1}', 
                                           style: TextStyle(
                                             fontWeight: FontWeight.w500,
                                             fontSize: 14,
                                             color: Colors.grey[600],
                                           ),
                                         ),
                                       ),
                                   ],
                                 ),
                               ),
                             ],
                           ),
                         ),
                        ),
                        // Remove Button
                        Positioned(
                          right: 8,
                          top: 8,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: Icon(
                              Icons.delete_outline, 
                              color: !isAvailable ? Colors.grey[400] : const Color(0xFFDB2777),
                            ),
                            onPressed: () {
                               showDialog(
                                 context: context,
                                 builder: (BuildContext context) {
                                   return AlertDialog(
                                     shape: RoundedRectangleBorder(
                                       borderRadius: BorderRadius.circular(16),
                                     ),
                                     title: Text(
                                       context.tr.removeItem,
                                       style: const TextStyle(color: Color(0xFFDB2777)),
                                     ),
                                     content: Text(context.tr.removeFromCartConfirm(item['title'] ?? '')),
                                     actions: [
                                       TextButton(
                                         onPressed: () => Navigator.of(context).pop(),
                                         child: Text(
                                           context.tr.cancel,
                                           style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                                         ),
                                       ),
                                       TextButton(
                                         onPressed: () {
                                           widget.onRemove?.call(index);
                                           Navigator.of(context).pop();
                                         },
                                         child: Text(
                                           context.tr.remove, 
                                           style: const TextStyle(color: Color(0xFFDB2777), fontWeight: FontWeight.bold),
                                         ),
                                       ),
                                     ],
                                   );
                                 },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
        }
      ),
      bottomNavigationBar: ValueListenableBuilder<List<Map<String, dynamic>>>(
        valueListenable: widget.cartItemsNotifier ?? ValueNotifier([]),
        builder: (context, cartItems, child) {
          if (cartItems.isEmpty) return const SizedBox.shrink();
          
          // Calculate total only for available items
          List<Map<String, dynamic>> availableItemsForTotal = cartItems;
          int unavailableCount = 0;
          if (_hasCheckedAvailability && widget.validateItemExists != null) {
            availableItemsForTotal = [];
            for (int i = 0; i < cartItems.length; i++) {
              if (_itemAvailability[i] == true) {
                availableItemsForTotal.add(cartItems[i]);
              } else {
                unavailableCount++;
              }
            }
          }
          if (availableItemsForTotal.isEmpty) {
            return const SizedBox.shrink();
          }
          
          final total = _calculateTotal(availableItemsForTotal);
          
          return Container(
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDB2777).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFDB2777).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                         context.tr.total,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFDB2777),
                          ),
                        ),
                        Text(
                          "\$${total.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFDB2777),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Payment Button
                  Builder(
                    builder: (context) {
                      bool hasAvailableItems = true;
                      int availableCount = cartItems.length;
                      int unavailableCount = 0;
                      
                      if (_hasCheckedAvailability && widget.validateItemExists != null) {
                        availableCount = _itemAvailability.values.where((available) => available == true).length;
                        unavailableCount = _itemAvailability.values.where((available) => available == false).length;
                        hasAvailableItems = availableCount > 0;
                      }
                      
                      final bool canProceed = !_isProcessing && 
                          cartItems.isNotEmpty && 
                          hasAvailableItems;
                      
                      return SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: canProceed 
                              ? () => _processPayment(cartItems)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDB2777),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey[400],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: _isProcessing
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.payment, size: 24),
                                    const SizedBox(width: 8),
                                     Text(
                                       (unavailableCount > 0 && availableCount > 0)
                                           ? context.tr.payForAvailableItems(availableCount)
                                           : context.tr.proceedToPayment,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFallbackIcon(Map<String, dynamic> item) {
    switch (item['type']) {
      case 'Video':
        return const Icon(Icons.videocam, color: Colors.grey, size: 30);
      case 'Song':
      case 'Audio':
        return const Icon(Icons.music_note, color: Colors.grey, size: 30);
      case 'Literature':
      case 'PDF':
        return const Icon(Icons.picture_as_pdf, color: Colors.grey, size: 30);
      default:
        return const Icon(Icons.image, color: Colors.grey, size: 30);
    }
  }

  DecorationImage? _getImageProvider(Map<String, dynamic> item) {

    if (item['coverPath'] != null && item['coverPath'].toString().isNotEmpty) {
       return DecorationImage(image: FileImage(File(item['coverPath'])), fit: BoxFit.cover);
    }


    if (item['filePath'] != null && item['filePath'].toString().isNotEmpty) {
      if (item['type'] == 'Image') {
         return DecorationImage(image: FileImage(File(item['filePath'])), fit: BoxFit.cover);
      }
    }
    

    if (item['image'] != null && item['image'].toString().isNotEmpty) {
      if (item['image'].startsWith('http')) {
        return DecorationImage(image: NetworkImage(item['image']), fit: BoxFit.cover);
      }
      return DecorationImage(image: AssetImage(item['image']), fit: BoxFit.cover);
    }
    return null;
  }

  Widget _buildVideoThumbnail(Map<String, dynamic> item) {
    final videoPath = item['filePath'] as String?;
    final coverPath = item['coverPath'] as String?;
    
    // If cover image exists, use it
    if (coverPath != null && coverPath.isNotEmpty && File(coverPath).existsSync()) {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          image: DecorationImage(
            image: FileImage(File(coverPath)),
            fit: BoxFit.cover,
          ),
        ),
      );
    }
    if (videoPath != null && videoPath.isNotEmpty && File(videoPath).existsSync()) {
      return _VideoThumbnailWidget(
        videoPath: videoPath,
        width: 80,
        height: 80,
      );
    }
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: _buildFallbackIcon(item),
    );
  }
}
class _VideoThumbnailWidget extends StatefulWidget {
  final String videoPath;
  final double width;
  final double height;

  const _VideoThumbnailWidget({
    required this.videoPath,
    required this.width,
    required this.height,
  });

  @override
  State<_VideoThumbnailWidget> createState() => _VideoThumbnailWidgetState();
}

class _VideoThumbnailWidgetState extends State<_VideoThumbnailWidget> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      final file = File(widget.videoPath);
      if (!file.existsSync()) {
        setState(() => _hasError = true);
        return;
      }

      _controller = VideoPlayerController.file(file);
      await _controller!.initialize();
      
      // Pause at first frame
      await _controller!.pause();
      await _controller!.seekTo(Duration.zero);
      
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      debugPrint('Error initializing video thumbnail: $e');
      if (mounted) {
        setState(() => _hasError = true);
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.videocam, color: Colors.grey, size: 30),
      );
    }

    if (!_isInitialized || _controller == null) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.black,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Video frame
            SizedBox(
              width: widget.width,
              height: widget.height,
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller!.value.size.width,
                  height: _controller!.value.size.height,
                  child: VideoPlayer(_controller!),
                ),
              ),
            ),
            // Play icon overlay
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: Icon(
                  Icons.play_circle_outline,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
