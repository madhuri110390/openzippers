import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_pdfview/flutter_pdfview.dart';

/// Full-screen PDF viewer for Literature posts.
///
/// Accepts either:
///   • [pdfUrl]  – a remote https:// URL  (downloaded to a temp file)
///   • [pdfPath] – an absolute local file path
///
/// Usage (from _handlePostAction / any navigator call):
///   Navigator.of(context).push(MaterialPageRoute(
///     builder: (_) => LiteraturePdfViewerScreen(
///       title: post['title'] ?? 'Literature',
///       pdfUrl:  post['literature_url'],  // remote
///       pdfPath: post['local_pdf_path'],  // local  (pass whichever is non-null)
///     ),
///   ));
class LiteraturePdfViewerScreen extends StatefulWidget {
  final String title;
  final String? pdfUrl;
  final String? pdfPath;

  const LiteraturePdfViewerScreen({
    super.key,
    required this.title,
    this.pdfUrl,
    this.pdfPath,
  }) : assert(
  pdfUrl != null || pdfPath != null,
  'Provide at least one of pdfUrl or pdfPath',
  );

  @override
  State<LiteraturePdfViewerScreen> createState() =>
      _LiteraturePdfViewerScreenState();
}

class _LiteraturePdfViewerScreenState
    extends State<LiteraturePdfViewerScreen> {
  // ── state ──────────────────────────────────────────────────────────────────
  String? _localPath;
  bool _isLoading = true;
  String? _error;

  // PDFView controller state
  int _currentPage = 0;
  int _totalPages = 0;
  PDFViewController? _pdfController;

  // ── lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _resolvePdf();
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  /// Resolve the PDF to a local file path so [PDFView] can render it.
  Future<void> _resolvePdf() async {
    try {
      // 1. Already a local path → use directly
      if (widget.pdfPath != null && widget.pdfPath!.isNotEmpty) {
        final file = File(widget.pdfPath!);
        if (await file.exists()) {
          if (mounted) setState(() { _localPath = widget.pdfPath; _isLoading = false; });
          return;
        }
      }

      // 2. Remote URL → download to cache
      if (widget.pdfUrl != null && widget.pdfUrl!.isNotEmpty) {
        final url = widget.pdfUrl!.trim();

        // Derive a stable cache filename from the URL
        final fileName = _safeFileName(url);
        final dir = await getTemporaryDirectory();
        final filePath = p.join(dir.path, fileName);
        final cachedFile = File(filePath);

        // Use cache if already downloaded
        if (await cachedFile.exists()) {
          if (mounted) setState(() { _localPath = filePath; _isLoading = false; });
          return;
        }

        // Download
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          await cachedFile.writeAsBytes(response.bodyBytes, flush: true);
          if (mounted) setState(() { _localPath = filePath; _isLoading = false; });
        } else {
          throw Exception('Server returned ${response.statusCode}');
        }
        return;
      }

      throw Exception('No valid PDF source provided.');
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load PDF: $e';
          _isLoading = false;
        });
      }
    }
  }

  /// Convert a URL into a safe filesystem filename.
  String _safeFileName(String url) {
    try {
      final uri = Uri.parse(url);
      final name = p.basename(uri.path);
      if (name.isNotEmpty && name.contains('.')) return name;
    } catch (_) {}
    // Fallback: hash-based name
    return 'literature_${url.hashCode.abs()}.pdf';
  }

  // ── navigation helpers ─────────────────────────────────────────────────────
  void _goToPrev() {
    if (_currentPage > 0 && _pdfController != null) {
      _pdfController!.setPage(_currentPage - 1);
    }
  }

  void _goToNext() {
    if (_currentPage < _totalPages - 1 && _pdfController != null) {
      _pdfController!.setPage(_currentPage + 1);
    }
  }

  // ── build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const pink = Color(0xFFDB2777);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: theme.iconTheme.color, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: theme.textTheme.titleLarge?.color,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        // Page indicator in the action area
        actions: [
          if (_totalPages > 0)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Text(
                  '${_currentPage + 1} / $_totalPages',
                  style: TextStyle(
                    color: theme.hintColor,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(theme, pink),
      // Prev / Next bottom bar (only shown when PDF is loaded)
      bottomNavigationBar: (!_isLoading && _error == null && _totalPages > 1)
          ? _buildPageControls(theme, pink)
          : null,
    );
  }

  Widget _buildBody(ThemeData theme, Color pink) {
    // ── Loading state ──────────────────────────────────────────────────────
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Color(0xFFDB2777)),
            const SizedBox(height: 16),
            Text(
              'Loading PDF…',
              style: TextStyle(color: theme.hintColor, fontSize: 14),
            ),
          ],
        ),
      );
    }

    // ── Error state ────────────────────────────────────────────────────────
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.picture_as_pdf_outlined,
                  size: 64, color: theme.hintColor),
              const SizedBox(height: 16),
              Text(
                'Could not open PDF',
                style: TextStyle(
                  color: theme.textTheme.titleMedium?.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.hintColor, fontSize: 13),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() { _isLoading = true; _error = null; });
                  _resolvePdf();
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: pink,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ── PDF render ─────────────────────────────────────────────────────────
    return PDFView(
      filePath: _localPath!,
      defaultPage: 0,
      enableSwipe: true,
      swipeHorizontal: false,   // vertical scroll (book feel)
      autoSpacing: true,
      pageFling: false,
      pageSnap: false,
      fitPolicy: FitPolicy.BOTH,
      preventLinkNavigation: false,
      onRender: (pages) {
        if (mounted) setState(() => _totalPages = pages ?? 0);
      },
      onViewCreated: (controller) {
        _pdfController = controller;
      },
      onPageChanged: (page, total) {
        if (mounted) {
          setState(() {
            _currentPage = page ?? 0;
            _totalPages = total ?? _totalPages;
          });
        }
      },
      onError: (error) {
        if (mounted) setState(() => _error = error.toString());
      },
      onPageError: (page, error) {
        debugPrint('PDF page $page error: $error');
      },
    );
  }

  Widget _buildPageControls(ThemeData theme, Color pink) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Previous
          IconButton(
            onPressed: _currentPage > 0 ? _goToPrev : null,
            icon: Icon(
              Icons.arrow_back_ios_rounded,
              size: 18,
              color: _currentPage > 0 ? pink : theme.disabledColor,
            ),
            tooltip: 'Previous page',
          ),

          // Page dot indicators (up to 7 visible dots)
          Expanded(child: _buildDotIndicator(theme, pink)),

          // Next
          IconButton(
            onPressed: _currentPage < _totalPages - 1 ? _goToNext : null,
            icon: Icon(
              Icons.arrow_forward_ios_rounded,
              size: 18,
              color: _currentPage < _totalPages - 1 ? pink : theme.disabledColor,
            ),
            tooltip: 'Next page',
          ),
        ],
      ),
    );
  }

  Widget _buildDotIndicator(ThemeData theme, Color pink) {
    // Show condensed dots for large PDFs
    if (_totalPages <= 7) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_totalPages, (i) {
          final isActive = i == _currentPage;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: isActive ? 20 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive ? pink : theme.disabledColor,
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      );
    }

    // For long PDFs just show a slim progress bar
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: _totalPages > 1 ? _currentPage / (_totalPages - 1) : 0,
          minHeight: 6,
          backgroundColor: theme.disabledColor.withOpacity(0.3),
          valueColor: AlwaysStoppedAnimation<Color>(pink),
        ),
      ),
    );
  }
}