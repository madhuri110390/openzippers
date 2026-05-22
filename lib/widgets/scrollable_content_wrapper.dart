import 'package:flutter/material.dart';

class ScrollableContentWrapper extends StatefulWidget {
  final Widget child;
  const ScrollableContentWrapper({super.key, required this.child});

  @override
  State<ScrollableContentWrapper> createState() => _ScrollableContentWrapperState();
}

class _ScrollableContentWrapperState extends State<ScrollableContentWrapper> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScrollbarTheme(
      data: ScrollbarThemeData(
        thickness: WidgetStateProperty.all(8.0),
        radius: const Radius.circular(10.0),
        thumbVisibility: WidgetStateProperty.all(true),
        thumbColor: WidgetStateProperty.resolveWith((states) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          if (states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.dragged) ||
              states.contains(WidgetState.pressed)) {
            return isDark
                ? Colors.white.withOpacity(0.6)
                : Colors.black.withOpacity(0.6);
          }
          return isDark
              ? Colors.white.withOpacity(0.4)
              : Colors.black.withOpacity(0.4);
        }),
        minThumbLength: 2.0,
        crossAxisMargin: 2.0,
      ),
      child: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const ClampingScrollPhysics(),
          child: widget.child,
        ),
      ),
    );
  }
}
