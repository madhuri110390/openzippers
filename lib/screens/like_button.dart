import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/like_viewmodel.dart';

class LikeButton extends ConsumerWidget {
  final int postId;
  final bool initialIsLiked;
  final int initialLikesCount;

  const LikeButton({
    super.key,
    required this.postId,
    required this.initialIsLiked,
    required this.initialLikesCount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Seed state from API data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(likeProvider(postId).notifier).init(initialIsLiked, initialLikesCount);
    });

    final state = ref.watch(likeProvider(postId));

    return GestureDetector(
      onTap: () => ref.read(likeProvider(postId).notifier).toggleLike(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            state.isLiked ? Icons.favorite : Icons.favorite_border,
            color: state.isLiked ? const Color(0xFFDB2777) : Colors.grey,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            '${state.likesCount}',
            style: TextStyle(
              color: state.isLiked ? const Color(0xFFDB2777) : Colors.grey,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}