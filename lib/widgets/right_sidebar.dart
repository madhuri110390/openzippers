import 'package:flutter/material.dart';
import '../helpers/translations.dart';

class RightSidebar extends StatelessWidget {
  const RightSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.cardColor,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr.suggestions,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Row(
                children: [
                  IconButton(onPressed: () {}, icon: const Icon(Icons.style_outlined, size: 20, color: Colors.grey)),
                  IconButton(onPressed: () {}, icon: const Icon(Icons.refresh, size: 20, color: Colors.grey)),
                ],
              )
            ],
          ),
          const SizedBox(height: 10),
          
          // List
          Expanded(
            child: ListView(
              children: [
                 _SuggestionCard(name: "priyap", price: context.tr.free.toUpperCase(), gradientColors: const [Color(0xFF8E2DE2), Color(0xFF4A00E0)]),
                 _SuggestionCard(name: "sarahj", price: "\$10.00", gradientColors: const [Color(0xFFff9966), Color(0xFFff5e62)]),
                 _SuggestionCard(name: "nik", price: context.tr.free.toUpperCase(), gradientColors: const [Color(0xFF00c6ff), Color(0xFF0072ff)]),
              ],
            ),
          ),

          // New Post Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.edit, size: 18),
              label: Text(context.tr.newPost),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDB2777),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final String name;
  final String price;
  final List<Color> gradientColors;

  const _SuggestionCard({
    required this.name,
    required this.price,
    required this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(colors: gradientColors),
      ),
      child: Stack(
        children: [
          // Price Tag
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                price,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFDB2777),
                ),
              ),
            ),
          ),
          
          // Content
          Positioned(
            bottom: 10,
            left: 10,
            right: 10,
            child: Row(
              children: [
                 CircleAvatar(
                   radius: 16,
                   backgroundColor: Colors.white.withValues(alpha: 0.2),
                   child: const Icon(Icons.person, size: 20, color: Colors.white70),
                 ),
                 const SizedBox(width: 8),
                 Expanded(
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     mainAxisSize: MainAxisSize.min,
                     children: [
                       Text(
                         name,
                         style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                       ),
                       const SizedBox(height: 2),
                       const Row(
                         children: [
                           Icon(Icons.image, size: 12, color: Colors.white70),
                           SizedBox(width: 4),
                           Text("2", style: TextStyle(color: Colors.white70, fontSize: 10)),
                           SizedBox(width: 8),
                           Icon(Icons.videocam, size: 12, color: Colors.white70),
                           SizedBox(width: 4),
                           Text("3", style: TextStyle(color: Colors.white70, fontSize: 10)),
                         ],
                       )
                     ],
                   ),
                 )
              ],
            ),
          )
        ],
      ),
    );
  }
}
