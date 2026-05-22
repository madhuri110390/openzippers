import 'package:flutter/material.dart';
import '../helpers/translations.dart';

class RatingDialog extends StatefulWidget {
  final Map<String, dynamic> post;
  final Function(int) onSubmit;

  const RatingDialog({
    super.key,
    required this.post,
    required this.onSubmit,
  });

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  int _selectedStars = 0;

  String _getRatingText(int stars) {
    switch (stars) {
      case 1:
        return context.tr.ratingPoor;
      case 2:
        return context.tr.ratingFair;
      case 3:
        return context.tr.ratingGood;
      case 4:
        return context.tr.ratingVeryGood;
      case 5:
        return context.tr.ratingExcellent;
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final averageRating = (widget.post['averageRating'] is num) 
        ? (widget.post['averageRating'] as num).toDouble() 
        : 0.0;
    
    // Handle totalRatings being int or null safely
    final dynamic rawTotal = widget.post['totalRatings'] ?? widget.post['ratingCount'];
    final int totalRatings = (rawTotal is int) ? rawTotal : 0;

    return Dialog(
      backgroundColor: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.tr.rateThisPost, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.textTheme.titleLarge?.color)),
                    Text(context.tr.shareYourThoughts, style: TextStyle(fontSize: 14, color: theme.hintColor)),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: theme.hintColor),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildStatRow(context.tr.averageRating, averageRating.toStringAsFixed(1)),
                  const SizedBox(height: 8),
                  _buildStatRow(context.tr.totalRatings, totalRatings.toString()),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starValue = index + 1;
                final isSelected = starValue <= _selectedStars;
                
                return IconButton(
                  onPressed: () {
                    setState(() {
                      _selectedStars = starValue;
                    });
                  },
                  icon: Icon(
                    isSelected ? Icons.star : Icons.star_border,
                    color: isSelected ? Colors.amber : (isDark ? Colors.grey[700] : Colors.grey[300]),
                    size: 36,
                  ),
                );
              }),
            ),
            if (_selectedStars == 0)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  "(Avg: ${averageRating.toStringAsFixed(1)})", 
                  style: TextStyle(color: theme.hintColor, fontSize: 12)
                ),
              ),
            const SizedBox(height: 8),
            if (_selectedStars > 0)
              Text(
                _getRatingText(_selectedStars),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              )
            else
              Text(context.tr.clickToRate, style: TextStyle(fontSize: 12, color: theme.hintColor)),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _selectedStars > 0 ? () {

                      final ratingToSubmit = _selectedStars;

                      debugPrint("Submitting rating: $ratingToSubmit");
                      widget.onSubmit(ratingToSubmit);

                      Navigator.pop(
                        context,
                        ratingToSubmit,
                      );

                    } : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDB2777),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFDB2777).withValues(alpha: 0.5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(context.tr.submitRating, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: theme.dividerColor),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(context.tr.cancel, style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
