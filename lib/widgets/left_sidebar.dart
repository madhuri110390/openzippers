import 'package:flutter/material.dart';
import '../helpers/translations.dart';

class LeftSidebar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onIndexChanged;
  final bool isArtist;

  final VoidCallback? onCreatePostTap;
  final VoidCallback? onBecomeArtistTap;

  const LeftSidebar({
    super.key, 
    required this.currentIndex, 
    required this.onIndexChanged,
    this.isArtist = false,
    this.onCreatePostTap,
    this.onBecomeArtistTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tr = context.tr; // Easy access to translations!
    
    return Container(
      color: theme.scaffoldBackgroundColor,
      child: Column(
        children: [
          // Logo Area
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            child: Row(
              children: [
                const Icon(Icons.all_inclusive, color: Color(0xFFDB2777), size: 30),
                const SizedBox(width: 10),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      children: [
                        TextSpan(text: 'OPEN ', style: TextStyle(color: theme.textTheme.titleLarge?.color)),
                        const TextSpan(text: 'ZIPPERS', style: TextStyle(color: Color(0xFFDB2777))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Streaming Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.music_note),
              label: Text(tr.streaming),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.brightness == Brightness.light ? const Color(0xFFE9ECEF) : theme.colorScheme.surfaceContainerHighest,
                foregroundColor: theme.textTheme.bodyLarge?.color,
                minimumSize: const Size(double.infinity, 45),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),

          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: [
                if (isArtist) ...[
                  _MenuItem(
                    icon: Icons.add_box_outlined,
                    label: tr.createPost,
                    onTap: onCreatePostTap,
                  ),
                  const Divider(height: 20),
                ],
                _MenuItem(
                  icon: Icons.home, 
                  label: tr.home, 
                  isSelected: currentIndex == 0,
                  onTap: () => onIndexChanged(0),
                ),
                 _MenuItem(
                  icon: Icons.video_library_outlined, 
                  label: tr.reels,
                  isSelected: currentIndex == 1,
                  onTap: () => onIndexChanged(1),
                ),
                _MenuItem(
                  icon: Icons.people_outline, 
                  label: tr.connections, 
                  isSelected: currentIndex == 2,
                  onTap: () => onIndexChanged(2),
                ),
                 _MenuItem(
                  icon: Icons.person_outline, 
                  label: tr.profile, 
                  isSelected: currentIndex == 3,
                  onTap: () => onIndexChanged(3),
                ),
                 _MenuItem(
                  icon: Icons.settings_outlined, 
                  label: tr.settings, 
                  isSelected: currentIndex == 4,
                  onTap: () => onIndexChanged(4),
                ),
                const Divider(height: 30),
                _MenuItem(icon: Icons.search, label: tr.search),
                _MenuItem(
                  icon: Icons.videocam_outlined, 
                  label: tr.liveStreams,
                  isSelected: currentIndex == 5,
                  onTap: () => onIndexChanged(5),
                ),
                 _MenuItem(
                  icon: Icons.bookmark_border, 
                  label: tr.bookmark,
                  isSelected: currentIndex == 6,
                  onTap: () => onIndexChanged(6),
                ),
                _MenuItem(icon: Icons.shopping_cart_outlined, label: tr.cart),
                _MenuItem(icon: Icons.help_outline, label: tr.helpSupport),
              ],
            ),
          ),
          
          const Divider(height: 1),
          // Become Creator Button at bottom
          if (!isArtist)
          Padding(
            padding: const EdgeInsets.all(20),
            child: InkWell(
              onTap: onBecomeArtistTap,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFDB2777).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFDB2777)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.person_add_alt_1_outlined,
                      color: Color(0xFFDB2777),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      tr.becomeCreator,
                      style: const TextStyle(
                        color: Color(0xFFDB2777),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFDB2777) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : theme.hintColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: TextStyle(
                        color: isSelected ? Colors.white : theme.textTheme.bodyLarge?.color,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
