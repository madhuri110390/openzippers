import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:ui';
import '../helpers/translations.dart';
import '../helpers/database_helper.dart';

class CreatorVerificationScreen extends StatefulWidget {
  final dynamic currentUser; // Using dynamic to avoid circular imports if MockUser isn't easily available, or import it. Best to use MockUser if possible.
  
  const CreatorVerificationScreen({super.key, required this.currentUser});

  @override
  State<CreatorVerificationScreen> createState() => _CreatorVerificationScreenState();
}

class _CreatorVerificationScreenState extends State<CreatorVerificationScreen> {
  File? _govIdFront;
  File? _govIdBack;
  File? _livePhoto;
  bool _isEmailVerified = false;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _isEmailVerified = widget.currentUser.isEmailVerified;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          context.tr.verification,
          style: TextStyle(
            color: theme.textTheme.titleLarge?.color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Text(
                context.tr.verificationSubtitle,
                style: TextStyle(
                  fontSize: 16,
                  color: theme.hintColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.tr.verificationDesc,
                style: TextStyle(
                  fontSize: 14,
                  color: theme.hintColor,
                ),
              ),
              const SizedBox(height: 32),

              _buildEmailVerificationSection(theme),

              const SizedBox(height: 32),

              _buildBecomeArtistSection(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmailVerificationSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isEmailVerified
              ? const Color(0xFF22C55E).withValues(alpha: 0.3)
              : theme.dividerColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _isEmailVerified
                  ? const Color(0xFF22C55E).withValues(alpha: 0.1)
                  : theme.dividerColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              _isEmailVerified ? Icons.check_circle : Icons.circle_outlined,
              color: _isEmailVerified
                  ? const Color(0xFF22C55E)
                  : theme.hintColor.withValues(alpha: 0.5),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr.confirmEmail,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isEmailVerified
                      ? context.tr.emailVerifiedSuccess
                      : context.tr.verifyEmailDesc,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.hintColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (_isEmailVerified)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check,
                    color: Color(0xFF22C55E),
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    context.tr.verifiedBtn,
                    style: TextStyle(
                      color: const Color(0xFF22C55E),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          else
            InkWell(
              onTap: () {
                setState(() {
                  _isEmailVerified = true;
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFDB2777),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  context.tr.verifyBtn,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBecomeArtistSection(ThemeData theme) {
    if (widget.currentUser.isArtist) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF22C55E).withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified, color: Color(0xFF22C55E), size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              context.tr.verified,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.titleMedium?.color,
              ),
            ),
             const SizedBox(height: 8),
             Text(
              "You are already a verified artist.",
              style: TextStyle(color: theme.hintColor),
             ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                context.tr.becomeArtist,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            context.tr.becomeArtistDesc,
            style: TextStyle(
              fontSize: 13,
              color: theme.hintColor,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            context.tr.becomeArtistInstructions,
            style: TextStyle(
              fontSize: 13,
              color: theme.hintColor,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),

          LayoutBuilder(
            builder: (context, constraints) {
              final isSmallScreen = constraints.maxWidth < 600;
              
              final card1 = _buildUploadCard(
                theme,
                context.tr.govIdFront,
                context.tr.govIdFrontDesc,
                _govIdFront,
                () => _pickImage('govIdFront'),
                Icons.cloud_upload_outlined,
              );
              
              final card2 = _buildUploadCard(
                theme,
                context.tr.govIdBack,
                context.tr.govIdBackDesc,
                _govIdBack,
                () => _pickImage('govIdBack'),
                Icons.cloud_upload_outlined,
              );
              
              final card3 = _buildUploadCard(
                theme,
                context.tr.livePhoto,
                context.tr.livePhotoDesc,
                _livePhoto,
                () => _pickImage('livePhoto'),
                Icons.camera_alt_outlined,
              );

              if (isSmallScreen) {
                return Column(
                  children: [
                    card1,
                    const SizedBox(height: 16),
                    card2,
                    const SizedBox(height: 16),
                    card3,
                  ],
                );
              } else {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: card1),
                    const SizedBox(width: 16),
                    Expanded(child: card2),
                    const SizedBox(width: 16),
                    Expanded(child: card3),
                  ],
                );
              }
            },
          ),
          
          const SizedBox(height: 32),

          Align(
            alignment: Alignment.center,
            child: Column(
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 200),
                  child: ElevatedButton(
                    onPressed: _isUploading || !_allDocumentsSelected() || !_isEmailVerified
                      ? null 
                      : _uploadAllDocuments,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDB2777),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                      disabledBackgroundColor: theme.disabledColor,
                    ),
                    child: _isUploading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          context.tr.convertToArtist,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  context.tr.takeAllPhotos,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.hintColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadCard(
    ThemeData theme,
    String title,
    String subtitle,
    File? selectedFile,
    VoidCallback onTap,
    IconData icon,
  ) {
    final isDark = theme.brightness == Brightness.dark;
    // Border color: Pink if selected, otherwise darker grey for visibility
    final Color dashedColor = selectedFile != null 
        ? const Color(0xFFDB2777) 
        : (isDark ? Colors.grey.shade400 : Colors.grey.shade500);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          splashColor: const Color(0xFFDB2777).withValues(alpha: 0.2),
          highlightColor: const Color(0xFFDB2777).withValues(alpha: 0.1),
          child: CustomPaint(
            foregroundPainter: DashedRectPainter(
              color: dashedColor, 
              strokeWidth: 1.5, 
              gap: 6.0
            ),
            child: Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                  color: isDark
                      ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.1)
                      : const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(8),
                ),
              child: selectedFile != null
                  ? Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.file(
                              selectedFile,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                if (title.contains("Front")) {
                                  _govIdFront = null;
                                } else if (title.contains("Back")) _govIdBack = null;
                                else _livePhoto = null;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.close, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            icon,
                            color: isDark ? Colors.white : Colors.black,
                            size: 32,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            subtitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.hintColor,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage(String type) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          switch (type) {
            case 'govIdFront':
              _govIdFront = File(image.path);
              break;
            case 'govIdBack':
              _govIdBack = File(image.path);
              break;
            case 'livePhoto':
              _livePhoto = File(image.path);
              break;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr.errorPickingImage(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool _allDocumentsSelected() {
    return _govIdFront != null && _govIdBack != null && _livePhoto != null;
  }

  Future<void> _uploadAllDocuments() async {
    if (!_allDocumentsSelected()) return;

    setState(() {
      _isUploading = true;
    });

    try {
      // 1. Simulate Upload
      await Future.delayed(const Duration(seconds: 2));

      // 2. Update User Status in DB
      final updatedUser = widget.currentUser.copyWith(
        isArtist: true,
        isEmailVerified: true,
      );
      
      await _dbHelper.insertUser(updatedUser.toJson());

      if (mounted) {
        // 3. Show Success Toast (Pink Color)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr.verificationSubmitted),
            backgroundColor: const Color(0xFFDB2777), // Fixed to Pink as requested
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${context.tr.error}: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }
}

class DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  DashedRectPainter({required this.color, this.strokeWidth = 1.0, this.gap = 5.0});

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    var path = Path();
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(8),
    ));

    Path dashPath = Path();
    double dashWidth = gap + 4.0; 
    double dashSpace = gap;
    double distance = 0.0;
    
    for (PathMetric pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        dashPath.addPath(
          pathMetric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
