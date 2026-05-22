import 'dart:io';
import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:video_player/video_player.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import '../helpers/translations.dart';
import '../viewmodels/post_viewmodel.dart';
import '../widgets/media_player_widgets.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  final String? initialType;
  final Map<String, dynamic>? existingPost;
  const CreatePostScreen({super.key, this.initialType, this.existingPost});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  late String _selectedType;
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _contentController = TextEditingController();
  final _titleFocusNode = FocusNode();
  final _priceFocusNode = FocusNode();
  final _contentFocusNode = FocusNode();
  String _selectedLanguage = ''; 
  String _selectedLanguageCode = '';
  bool _isUploading = false;
  final List<String> _attachedFileNames = [];
  final List<String> _attachedFilePaths = [];
  String? _attachedFileName;
  String? _attachedFilePath;
  
  String? _coverImageName;
  String? _coverImagePath;
  bool _isCoverUploading = false;
  
  // Preview video for paid posts
  String? _previewVideoName;
  String? _previewVideoPath;
  bool _isPreviewUploading = false;
  
  String _selectedGenre = 'Select Genre';
  bool _isZippfansHidden = false;
  bool _isStreamingAllowed = true;
  final List<String> _genres = [
    'Alternative', 'Ambient', 'Blues', 'Classical', 'Country', 'Dance', 'Disco', 
    'Drum & Bass', 'Dubstep', 'Electronic', 'Experimental', 'Folk', 'Funk', 
    'Gospel', 'Hip Hop', 'House', 'Indie', 'Instrumental', 'Jazz', 'Latin', 
    'Merengue', 'Metal', 'Motown', 'Neo-Soul', 'Noise Music', 'Old School Hip Hop', 
    'Opera', 'Outlaw Country', 'Pop', 'Pop Punk', 'Punk Rock', 'R&B', 'Rap', 
    'Reggae', 'Reggaeton', 'Rock', 'Salsa', 'Smooth Jazz', 'Soca', 'Soul', 
    'Techno', 'Trance', 'Trap', 'Vaporwave', 'Video Game Music', 
    'World Fusion', 'World Music'
  ];

  
  // Rich text editor for Literature posts
  late quill.QuillController _quillController;
  final FocusNode _quillFocusNode = FocusNode();
  final ScrollController _editorScrollController = ScrollController(); // Added for editor scrollbar manually
  
  // Track expanded state for literature word pad dropdown
  bool _wordPadExpanded = false; // Will be set to true in initState if Literature is selected

  @override
  void initState() {
    super.initState();
    _selectedType = widget.existingPost?['type'] ?? widget.initialType ?? 'Image';
    if (_selectedType == 'Reels') _selectedType = 'Reel'; // Normalize type name
    _quillController = quill.QuillController.basic();
    _priceController.text = "0.00"; // Default to 0.00
    _priceController.addListener(() {
      if (mounted) setState(() {});
    });
    
    if (widget.existingPost != null) {
      _titleController.text = widget.existingPost!['title'] ?? '';

      // Robust Price Parsing
      final dynamic rawPrice = widget.existingPost!['price'];
      if (rawPrice == null || rawPrice.toString().toLowerCase() == 'free') {
        _priceController.text = "0.00";
      } else {
        // Strip $ and maintain decimal format
        String pStr = rawPrice.toString().replaceAll('\$', '').trim();
        if (pStr.isEmpty) {
          _priceController.text = "0.00";
        } else {
          _priceController.text = pStr;
        }
      }

      final content = widget.existingPost!['content'] ?? '';
      _contentController.text = content;

      if (_selectedType == 'Literature' && content.isNotEmpty) {
        try {
          if (content.startsWith('[') || content.startsWith('{')) {
            _quillController = quill.QuillController(
              document: quill.Document.fromJson(jsonDecode(content)),
              selection: const TextSelection.collapsed(offset: 0),
            );
          } else {
            // Support plain text content for Literature posts
            _quillController = quill.QuillController(
              document: quill.Document()
                ..insert(0, content),
              selection: const TextSelection.collapsed(offset: 0),
            );
          }
          // Expand word pad if there's content to edit - Reverted to false to match Create mode state
          _wordPadExpanded = false;
        } catch (e) {
          debugPrint("Error loading quill content: $e");
        }
      }

      // Fix Genre fallback
      _selectedGenre = widget.existingPost!['genre'] ?? 'Select Genre';
      if (!_genres.contains(_selectedGenre) &&
          _selectedGenre != 'Select Genre') {
        _selectedGenre = 'Select Genre';
      }

      _selectedLanguage = widget.existingPost!['language'] ?? 'English';

      if (_selectedLanguage.isNotEmpty) {
        final langItem = AppTranslations.ALL_LANGUAGES.firstWhere(
              (l) => l['name'] == _selectedLanguage,
          orElse: () => <String, dynamic>{'code': 'en', 'name': 'English (US)'},
        );
        _selectedLanguageCode = (langItem['code'] as String?) ?? 'en';

        // Load toggle states
        final zippfansVal = widget.existingPost!['zippfansStatus'];
        _isZippfansHidden = (zippfansVal == true || zippfansVal == 1);

        final streamingVal = widget.existingPost!['streamingStatus'];
        // Default to true if null (for old posts)
        _isStreamingAllowed =
            streamingVal == null || (streamingVal == true || streamingVal == 1);

        // ROBUST MEDIA MAPPING for Edit Mode
        // 1. Main Media
        final post = widget.existingPost!;
        final dynamic mainFile = post['filePath'] ?? post['videoPath'] ??
            post['media'] ?? post['url'] ?? post['previewPath'];

        if (mainFile != null && mainFile
            .toString()
            .isNotEmpty) {
          _attachedFilePath = mainFile.toString();
          _attachedFileName = p.basename(_attachedFilePath!);
        } else if (post['image'] != null && post['image']
            .toString()
            .isNotEmpty) {
          final img = post['image'].toString();
          // If it's a video type and the image ends with a video extension, prioritize it as main file
          final isVideo = _selectedType == 'Video' || _selectedType == 'Reel';
          final hasVideoExt = img.toLowerCase().endsWith('.mp4') ||
              img.toLowerCase().endsWith('.mov') ||
              img.toLowerCase().endsWith('.avi');

          if (img.contains('/') || img.contains('\\') || img.contains('http') ||
              (isVideo && hasVideoExt)) {
            _attachedFilePath = img;
            _attachedFileName = p.basename(img);
          } else {
            _attachedFileName = img;
          }
        }

        // 2. Cover image
        // Check multiple possible keys: 'coverPath', 'covers', 'cover'
        final dynamic coverVal = post['coverPath'] ?? post['covers'] ??
            post['cover'];
        _coverImagePath = coverVal?.toString();

        // Fallback: if it's a video/reel and we have an 'image' field, that's often the thumbnail
        if ((_coverImagePath == null || _coverImagePath!.isEmpty) &&
            (_selectedType == 'Video' || _selectedType == 'Reel')) {
          _coverImagePath = post['image']?.toString();
        }

        if (_coverImagePath != null && _coverImagePath!.isNotEmpty) {
          _coverImageName = p.basename(_coverImagePath!);
          if (_coverImageName!.isEmpty || _coverImageName == '.' ||
              _coverImageName == '/') {
            _coverImageName = "Cover Image";
          }
        }

        // 3. Preview Video Mapping
        final dynamic previewVal = post['previewPath'];
        if (previewVal != null && previewVal
            .toString()
            .isNotEmpty) {
          _previewVideoPath = previewVal.toString();
          _previewVideoName = p.basename(_previewVideoPath!);
        }
      }
    }

    // Auto-expand word pad if Literature is selected and we're not editing (or if editing managed above)
    if (_selectedType == 'Literature' && widget.existingPost == null) {
      _wordPadExpanded = false;
    }
    
    // Add listeners to update preview when text changes
    _titleController.addListener(() => setState(() {}));
    _contentController.addListener(() => setState(() {}));
    _quillController.document.changes.listen((event) => setState(() {}));
  }

  // Using a standard base size; the global TextScaler in main.dart handles the rest
  double get baseFontSize => 15.0;

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _contentController.dispose();
    _titleFocusNode.dispose();
    _priceFocusNode.dispose();
    _contentFocusNode.dispose();
    _quillController.dispose();
    _quillFocusNode.dispose();
    _editorScrollController.dispose();
    super.dispose();
  }

  void _onMakeFree() {
    setState(() {
      _priceController.text = "0";
    });
  }

  Future<void> _pickFile({bool isCover = false, bool isPreview = false}) async {
    try {
      if (!isCover && !isPreview && _selectedType == 'Image') {
         // Use crop for main image
         await _pickImageWithCrop();
         return;
      }

      FileType pickType = FileType.any;
      List<String>? allowedExtensions;

      if (isCover) {
        pickType = FileType.custom;
        allowedExtensions = ['jpg', 'jpeg', 'png', 'gif'];
      } else if (isPreview) {
        pickType = FileType.custom;
        if (_selectedType == 'Song') {
          allowedExtensions = ['mp3', 'wav', 'ogg', 'm4a'];
        } else {
          allowedExtensions = ['mp4', 'mov', 'avi'];
        }
      } else {
        if (_selectedType == 'Song') {
          pickType = FileType.custom;
          allowedExtensions = ['mp3', 'wav', 'ogg', 'm4a'];
        } else if (_selectedType == 'Video') {
          pickType = FileType.custom;
          allowedExtensions = ['mp4', 'mov', 'avi'];
        } else if (_selectedType == 'Reel') {
          pickType = FileType.custom;
          allowedExtensions = ['mp4', 'mov', 'avi'];
        } else if (_selectedType == 'Literature') {
          pickType = FileType.custom;
          allowedExtensions = ['pdf']; 
        }
      }

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: pickType,
        allowedExtensions: allowedExtensions,
      );

      if (result != null && result.files.single.path != null) {
        if (isCover) {
          setState(() => _isCoverUploading = true);
        } else if (isPreview) {
          setState(() => _isPreviewUploading = true);
        } else {
          setState(() => _isUploading = true);
        }
        
        final String originalPath = result.files.single.path!;
        final String fileName = result.files.single.name;
        
        if (allowedExtensions != null) {
          final ext = p.extension(fileName).toLowerCase().replaceAll('.', '');
          if (!allowedExtensions.contains(ext)) {
             throw Exception("Invalid file type. Please select $allowedExtensions");
          }
        }

        final appDir = await getApplicationDocumentsDirectory();
        final String permanentPath = p.join(appDir.path, "uploads", fileName);
        
        final uploadsDir = Directory(p.join(appDir.path, "uploads"));
        if (!await uploadsDir.exists()) {
          await uploadsDir.create(recursive: true);
        }
        
        await File(originalPath).copy(permanentPath);

        // Validation for Reel or Preview
        if (isPreview || (!isCover && _selectedType == 'Reel')) {
          try {
            final controller = VideoPlayerController.file(File(permanentPath));
            await controller.initialize();
            final duration = controller.value.duration;
            await controller.dispose();
            
            final durationSeconds = duration.inSeconds;
            
            if (isPreview) {
               // Preview should be short (3-5s recommended, let's enforce max 10s for flexibility)
               if (durationSeconds > 10) {
                 await File(permanentPath).delete();
                 throw Exception("Preview must be short (max 10 seconds). Your media is $durationSeconds seconds.");
               }
            } else if (_selectedType == 'Reel') {
               if (durationSeconds > 5) {
                 await File(permanentPath).delete();
                 throw Exception("Reel must be maximum 15 seconds long. Your video is $durationSeconds seconds.");
               }
            }
          } catch (e) {
            if (mounted) {
              setState(() {
                if (isPreview) {
                  _isPreviewUploading = false;
                } else {
                  _isUploading = false;
                }
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("${context.tr.error}: $e")),
              );
            }
            return;
          }
        }

        if (mounted) {
          setState(() {
            if (isCover) {
              _coverImageName = fileName;
              _coverImagePath = permanentPath;
              _isCoverUploading = false;
            } else if (isPreview) {
              _previewVideoName = fileName;
              _previewVideoPath = permanentPath;
              _isPreviewUploading = false;
            } else {
              _attachedFileName = fileName;
              _attachedFilePath = permanentPath;
              // Auto-populate title if empty
              if (_titleController.text.trim().isEmpty) {
                _titleController.text = p.basenameWithoutExtension(fileName).replaceAll('_', ' ').replaceAll('-', ' ');
              }
              // Clear multi-list just in case
              _attachedFileNames.clear();
              _attachedFilePaths.clear();
              _isUploading = false;
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _isCoverUploading = false;
          _isPreviewUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${context.tr.error}: $e")),
        );
      }
    }
  }

  // Pick image with crop option (Instagram-like)
  Future<void> _pickImageWithCrop() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );

      if (image != null) {
        setState(() => _isUploading = true);
        final CroppedFile? croppedFile = await ImageCropper().cropImage(
          sourcePath: image.path,
          aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: context.tr.cropImageTitle,
              toolbarColor: const Color(0xFFDB2777),
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: false,
            ),
            IOSUiSettings(
              title: 'Crop Image',
              aspectRatioLockEnabled: false,
            ),
          ],
        );
        
        if (croppedFile != null) {
          final String croppedPath = croppedFile.path;
          final String fileName = 'cropped_${DateTime.now().millisecondsSinceEpoch}${p.extension(croppedPath)}';
          
          final appDir = await getApplicationDocumentsDirectory();
          final String permanentPath = p.join(appDir.path, "uploads", fileName);
          
          final uploadsDir = Directory(p.join(appDir.path, "uploads"));
          if (!await uploadsDir.exists()) {
            await uploadsDir.create(recursive: true);
          }
          await File(croppedPath).copy(permanentPath);
          
          if (mounted) {
            setState(() {
              _attachedFileName = fileName;
              _attachedFilePath = permanentPath;
              _isUploading = false;
            });
            

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.tr.imageCroppedReady),
                duration: Duration(seconds: 2),
                backgroundColor: Color(0xFFDB2777),
              ),
            );
          }
        } else {

          if (mounted) {
            setState(() {
              _isUploading = false;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${context.tr.error}: $e")),
        );
      }
    }
  }

  // Helper method to check if text contains emojis
    bool _containsEmoji(String text) {
      final emojiRegex = RegExp(
        r'[\u1F300-\u1F9FF]|[\u2600-\u26FF]|[\u2700-\u27BF]|[\u1F600-\u1F64F]'
        r'|[\u1F680-\u1F6FF]|[\u1F1E0-\u1F1FF]|[\u1F900-\u1F9FF]'
        r'|[\u1FA00-\u1FA6F]|[\u1FA70-\u1FAFF]',
      );
      return emojiRegex.hasMatch(text);
    }

  // Helper to shorten language names for UI constraints
  String _getShortLanguageName(String name) {
    if (name.contains('Chinese (Simplified)')) return 'Chinese (Simp)';
    if (name.contains('Chinese (Traditional)')) return 'Chinese (Trad)';
    if (name.contains(' (')) {
      return name.split(' (')[0];
    }
    return name;
  }


  bool _isUselessText(String text) {
    if (text.isEmpty) return true;
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) return true;
    

    if (_containsEmoji(trimmedText)) {
      return false;
    }
    

    if (trimmedText.isEmpty) return true;
    
    final uselessPatterns = [
      'hget', 'ddd', 'get', '...', 'etc', 'test', 'temp', 
      'vhhh', 'fvghhh', 'gghj', 'vvbbb', 'vvv', 'bbb', 'ggg', 'hhh', 'jjj', 'fff',
      'aaa', 'ccc', 'eee', 'iii', 'lll', 'mmm', 'nnn', 'ooo', 'ppp', 'qqq', 'rrr', 'sss', 'ttt', 'uuu', 'www', 'xxx', 'yyy', 'zzz'
    ];
    final lowerText = trimmedText.toLowerCase();
    for (var pattern in uselessPatterns) {
      if (lowerText == pattern || lowerText.contains(pattern)) {
        return true;
      }
    }
    

    if (trimmedText.length <= 10) {
      final uniqueChars = trimmedText.split('').toSet().length;
      if (uniqueChars == 1) {
        return true;
      }
      if (trimmedText.length <= 6 && uniqueChars <= 2) {
        return true;
      }
    }
    

    if (trimmedText.length <= 10) {
      final charCounts = <String, int>{};
      for (var char in trimmedText.split('')) {
        charCounts[char] = (charCounts[char] ?? 0) + 1;
      }
      final maxCount = charCounts.values.reduce((a, b) => a > b ? a : b);
      if (maxCount / trimmedText.length > 0.5) {
        return true;
      }
      final uniqueChars = charCounts.keys.length;
      if (trimmedText.length >= 4 && uniqueChars <= 2) {
        return true;
      }
      if (trimmedText.length >= 6 && uniqueChars <= 3) {
        return true;
      }
    }
    

    if (trimmedText.length <= 12) {
      final chars = trimmedText.split('');
      final charFrequency = <String, int>{};
      for (var char in chars) {
        charFrequency[char] = (charFrequency[char] ?? 0) + 1;
      }
      final maxFreq = charFrequency.values.reduce((a, b) => a > b ? a : b);
      if (maxFreq / trimmedText.length >= 0.4 && trimmedText.length <= 8) {
        return true;
      }
    }
    

    if (trimmedText.length <= 8) {
      int consecutiveCount = 1;
      String? lastChar;
      for (var char in trimmedText.split('')) {
        if (char == lastChar) {
          consecutiveCount++;
          if (consecutiveCount >= 3) {
            return true;
          }
        } else {
          consecutiveCount = 1;
        }
        lastChar = char;
      }
    }
    

    if (trimmedText.length <= 5) {
      final vowels = ['a', 'e', 'i', 'o', 'u'];
      final hasVowel = trimmedText.toLowerCase().split('').any((char) => vowels.contains(char));
      if (!hasVowel && trimmedText.length >= 3) {
        return true;
      }
    }
    
    return false;
  }

  Future<void> _createPost() async {
    final title = _titleController.text.trim();
    String content = '';

    if (title.isEmpty) {
      _showError(context.tr.enterTitleError);
      return;
    }
    if (_selectedLanguage.isEmpty) {
      _showError(context.tr.selectLanguageError);
      return;
    }

    // Build content
    try {
      if (_selectedType == 'Literature') {
        final wordPadText = _quillController.document.toPlainText().trim();
        final regularContent = _contentController.text.trim();
        if (wordPadText.isNotEmpty) {
          try {
            content = jsonEncode(_quillController.document.toDelta().toJson());
          } catch (_) {
            content = wordPadText;
          }
        } else if (regularContent.isNotEmpty) {
          content = regularContent;
        } else {
          content = jsonEncode([]);
        }
      } else {
        content = _contentController.text.trim();
      }
    } catch (e) {
      _showError(context.tr.contentProcessingError);
      return;
    }

    // Validate files
    if (_selectedType == 'Literature') {
      if (_attachedFilePath == null || !File(_attachedFilePath!).existsSync()) {
        _showError(context.tr.uploadPdfError);
        return;
      }
      final wordPadText = _quillController.document.toPlainText().trim();
      if (wordPadText.isEmpty && _contentController.text.trim().isEmpty) {
        _showError(context.tr.writeContentError);
        return;
      }
    } else {
      if (_attachedFilePath == null || !File(_attachedFilePath!).existsSync()) {
        final fileType = _selectedType == 'Song'
            ? context.tr.audioLabel
            : (_selectedType == 'Video' || _selectedType == 'Reel')
            ? context.tr.videoLabel
            : context.tr.imageLabel;
        _showError(context.tr.uploadFileError(fileType));
        return;
      }
    }

    if ((_selectedType == 'Song' || _selectedType == 'Video') &&
        (_coverImagePath == null || _coverImagePath!.isEmpty)) {
      _showError(context.tr.uploadCoverImageError);
      return;
    }

    // Map UI type → API values
    final postTypeMap = {
      'Image': 'post',
      'Song': 'song',
      'Video': 'video',
      'Reel': 'video',
      'Literature': 'literature',
    };
    final postTypeEnumMap = {
      'Image': PostType.post,
      'Song': PostType.song,
      'Video': PostType.video,
      'Reel': PostType.video,
      'Literature': PostType.literature,
    };

    final price = _priceController.text.trim().isEmpty
        ? '0'
        : _priceController.text.trim().replaceAll('\$', '');

    // Get language ID from selected language name
    const languageCodeToId = <String, String>{
      'en': '1', 'es': '2', 'fr': '3', 'de': '4', 'it': '5',
      'pt': '6', 'ru': '7', 'zh': '8', 'zh_Hant': '9', 'ja': '10',
      'ko': '11', 'hi': '12', 'ar': '13', 'th': '14', 'vi': '15',
      'nl': '16', 'sv': '17', 'no': '18', 'da': '19', 'fi': '20',
      'pl': '21', 'cs': '22', 'hu': '23', 'ro': '24', 'el': '25',
      'tr': '26', 'id': '27', 'ms': '28', 'fil': '29', 'sw': '30',
      'ur': '31', 'bn': '32',
    };
    final languageId = languageCodeToId[_selectedLanguageCode] ?? '1';

    // Wire ViewModel
    final vm = ref.read(createPostViewModelProvider.notifier);
    vm.setTitle(title);
    vm.setBody(content);
    vm.setLanguageId(languageId);
    vm.setPrice(price);
    vm.setFansStatus(_isZippfansHidden ? '0' : '1');
    vm.setGenreId('1');
    vm.setPostType(postTypeEnumMap[_selectedType] ?? PostType.post);

    final attachedFile =
    _attachedFilePath != null ? File(_attachedFilePath!) : null;
// Reset all files first
    vm.setSelectedImage(null);
    vm.setSelectedVideo(null);
    vm.setSelectedSong(null);
    vm.setSelectedLiterature(null);
    vm.setSelectedCoverImage(_coverImagePath != null ? File(_coverImagePath!) : null);
    switch (_selectedType) {
      case 'Image':
        vm.setSelectedImage(attachedFile);
        break;
      case 'Video':
      case 'Reel':
        vm.setSelectedVideo(attachedFile);
        break;
      case 'Song':
        vm.setSelectedSong(attachedFile);
        break;
      case 'Literature':
        vm.setSelectedLiterature(attachedFile);
        break;
    }

    final success = await vm.createPost();

    if (!mounted) return;

    if (success) {
      if (_selectedType == 'Image') {
        final resultMap = <String, dynamic>{
          'type': _selectedType,
          'title': _titleController.text.trim(),
          'price': _priceController.text.trim().isEmpty ? 'Free' : '\$${_priceController.text.trim()}',
          'content': content,
          'language': _selectedLanguage,
          'image': _attachedFileName,
          'filePath': _attachedFilePath,
          'date': DateTime.now(),
          'comments': [],
        };
        if (mounted) Navigator.pop(context, resultMap);
      } else {
        if (mounted) {
          Navigator.pop(context, {
          'type': _selectedType,
          'title': _titleController.text.trim(),
          'price': _priceController.text
              .trim()
              .isEmpty ? 'Free' : _priceController.text.trim().replaceAll(
              '\$', ''),
          'content': content,
          'language': _selectedLanguage,
          'image': _coverImagePath,
          'filePath': _attachedFilePath,
          'date': DateTime.now(),
          'comments': [],
        });
        }
      }
    }else {
      final error = ref.read(createPostViewModelProvider).error ?? 'Failed to create post';
      debugPrint('POST ERROR: $error');
      _showError(error);
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFFDB2777),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createPostViewModelProvider);
    final theme = Theme.of(context);
    final isEditing = widget.existingPost != null;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 10.0),
              child: _buildHeader(context, theme),
            ),
            Expanded(
              child: ScrollbarTheme(
                data: ScrollbarThemeData(
                  thickness: WidgetStateProperty.all(8.0),
                  radius: const Radius.circular(10.0),
                  thumbVisibility: WidgetStateProperty.all(true),
                  thumbColor: WidgetStateProperty.resolveWith((states) {
                    final isDark = theme.brightness == Brightness.dark;
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
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24.0, 10.0, 24.0, 24.0),
                    physics: const ClampingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel(context.tr.chooseType),
                        const SizedBox(height: 15),
                        _buildTypeGrid(),
                        const SizedBox(height: 30),
                        _buildPostInfoCard(theme),
                        const SizedBox(height: 30),
                        _buildMediaSection(theme),
                        const SizedBox(height: 40),
                        _buildFooter(context, theme, isLoading: state.isLoading),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    final isEditing = widget.existingPost != null;
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.close, color: theme.iconTheme.color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing ? context.tr.editPostTitle : context.tr.createNewPost,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.textTheme.titleLarge?.color),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                context.tr.shareContentWithCommunity,
                style: TextStyle(color: theme.hintColor, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildTypeGrid() {
    final isEditing = widget.existingPost != null;
    return Row(
      children: [
        Expanded(child: _TypeCard(icon: Icons.image_outlined, label: context.tr.image, isSelected: _selectedType == 'Image', enabled: !isEditing, onTap: () => _changeType('Image'))),
        const SizedBox(width: 10),
        Expanded(child: _TypeCard(icon: Icons.music_note_outlined, label: context.tr.song, isSelected: _selectedType == 'Song', enabled: !isEditing, onTap: () => _changeType('Song'))),
        const SizedBox(width: 10),
        Expanded(child: _TypeCard(icon: Icons.videocam_outlined, label: context.tr.video, isSelected: _selectedType == 'Video', enabled: !isEditing, onTap: () => _changeType('Video'))),
        const SizedBox(width: 10),
        Expanded(child: _TypeCard(icon: Icons.menu_book, label: context.tr.literature, isSelected: _selectedType == 'Literature', enabled: !isEditing, onTap: () {
          _changeType('Literature');
          _wordPadExpanded = false;
        })),
        const SizedBox(width: 10),
        Expanded(child: _TypeCard(icon: Icons.movie_filter_outlined, label: context.tr.reel, isSelected: _selectedType == 'Reel', enabled: !isEditing, onTap: () => _changeType('Reel'))),
      ],
    );
  }

  void _changeType(String newType) {
    if (_selectedType != newType) {
      setState(() {
        _selectedType = newType;
        _attachedFileName = null;
        _attachedFilePath = null;
        _attachedFileNames.clear();
        _attachedFilePaths.clear();
        // Cover image should not reset if once set
        if (_selectedType != 'Song' && _selectedType != 'Video' && _selectedType != 'Reel') {
           _selectedGenre = 'Select Genre';
        }
      });
    }
  }

  Widget _buildPostInfoCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_selectedType == 'Song' || _selectedType == 'Video' || _selectedType == 'Reel')
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 9,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel(context.tr.title),
                      const SizedBox(height: 8),
                      _buildInput(controller: _titleController, hint: context.tr.enterTitle, theme: theme, focusNode: _titleFocusNode),
                    ],
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  flex: 11,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel(context.tr.genre),
                      const SizedBox(height: 8),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          return MenuAnchor(
                            alignmentOffset: const Offset(0, 5),
                            style: MenuStyle(
                              backgroundColor: WidgetStatePropertyAll(theme.brightness == Brightness.light ? Colors.white : const Color(0xFF1E1E2E)),
                              elevation: const WidgetStatePropertyAll(15),
                              shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                              surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
                              shadowColor: WidgetStatePropertyAll(Colors.black.withOpacity(0.5)),
                              fixedSize: WidgetStatePropertyAll(Size(constraints.maxWidth, 300)),
                              maximumSize: WidgetStatePropertyAll(Size(constraints.maxWidth, 400)),
                              padding: const WidgetStatePropertyAll(EdgeInsets.zero),
                            ),
                            menuChildren: [
                              MenuItemButton(
                                style: ButtonStyle(
                                   backgroundColor: _selectedGenre == 'Select Genre' || _selectedGenre == context.tr.selectGenre ? const WidgetStatePropertyAll(Color(0xFFDB2777)) : null,
                                   minimumSize: WidgetStatePropertyAll(Size(constraints.maxWidth, 45)),
                                   padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16)),
                                   shape: const WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
                                ),
                                onPressed: () => setState(() => _selectedGenre = context.tr.selectGenre),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        context.tr.selectGenre,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: _selectedGenre == 'Select Genre' || _selectedGenre == context.tr.selectGenre ? FontWeight.bold : FontWeight.normal,
                                          color: _selectedGenre == 'Select Genre' || _selectedGenre == context.tr.selectGenre ? Colors.white : theme.textTheme.bodyLarge?.color,
                                        ),
                                      ),
                                    ),
                                    if (_selectedGenre == 'Select Genre' || _selectedGenre == context.tr.selectGenre) const Icon(Icons.check, color: Colors.white, size: 16),
                                  ],
                                ),
                              ),
                              ..._genres.map((genre) {
                                final isSelected = _selectedGenre == genre;
                                return MenuItemButton(
                                  style: ButtonStyle(
                                    backgroundColor: isSelected ? const WidgetStatePropertyAll(Color(0xFFDB2777)) : null,
                                    minimumSize: WidgetStatePropertyAll(Size(constraints.maxWidth, 45)),
                                    padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16)),
                                    shape: const WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
                                  ),
                                  onPressed: () => setState(() => _selectedGenre = genre),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          genre,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                            color: isSelected ? Colors.white : theme.textTheme.bodyLarge?.color,
                                          ),
                                        ),
                                      ),
                                      if (isSelected) const Icon(Icons.check, color: Colors.white, size: 16),
                                    ],
                                  ),
                                );
                              }),
                            ],
                            builder: (context, controller, child) {
                              return InkWell(
                                onTap: () {
                                  if (controller.isOpen) {
                                    controller.close();
                                  } else {
                                    controller.open();
                                  }
                                },
                                borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    width: double.infinity,
                                    height: 48,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: theme.brightness == Brightness.light ? Colors.white : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFDB2777), width: 1.5),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              _selectedGenre == 'Select Genre' ? context.tr.selectGenre : _selectedGenre,
                                              style: TextStyle(
                                                color: theme.textTheme.bodyMedium?.color,
                                                fontSize: baseFontSize,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(Icons.unfold_more_rounded, color: theme.hintColor, size: 20),
                                      ],
                                    ),
                                  ),
                              );
                            },
                          );
                        }
                      ),
                    ],
                  ),
                ),
              ],
            )
          else 
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel(context.tr.title),
                const SizedBox(height: 8),
                _buildInput(controller: _titleController, hint: context.tr.enterTitle, theme: theme, focusNode: _titleFocusNode),
              ],
            ),
          const SizedBox(height: 20),
          
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmallWidth = constraints.maxWidth < 500;
              
              Widget languageField = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel(context.tr.language),
                  const SizedBox(height: 8),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return MenuAnchor(
                        alignmentOffset: const Offset(0, 5),
                        style: MenuStyle(
                          backgroundColor: WidgetStatePropertyAll(theme.brightness == Brightness.light ? Colors.white : const Color(0xFF1E1E2E)),
                          elevation: const WidgetStatePropertyAll(15),
                          shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
                          shadowColor: WidgetStatePropertyAll(Colors.black.withOpacity(0.5)),
                          fixedSize: WidgetStatePropertyAll(Size(constraints.maxWidth, 300)),
                          maximumSize: WidgetStatePropertyAll(Size(constraints.maxWidth, 400)),
                          padding: const WidgetStatePropertyAll(EdgeInsets.zero),
                        ),
                        menuChildren: [
                          MenuItemButton(
                            style: ButtonStyle(
                              backgroundColor: _selectedLanguageCode.isEmpty ? const WidgetStatePropertyAll(Color(0xFFDB2777)) : null,
                              minimumSize: WidgetStatePropertyAll(Size(constraints.maxWidth, 45)),
                              padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16)),
                              shape: const WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
                            ),
                            onPressed: () => setState(() {
                              _selectedLanguage = '';
                              _selectedLanguageCode = '';
                            }),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    context.tr.selectLanguage,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: _selectedLanguageCode.isEmpty ? FontWeight.bold : FontWeight.normal,
                                      color: _selectedLanguageCode.isEmpty ? Colors.white : theme.textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                ),
                                if (_selectedLanguageCode.isEmpty) const Icon(Icons.check, color: Colors.white, size: 16),
                              ],
                            ),
                          ),
                          ...AppTranslations.ALL_LANGUAGES.map((e) {
                            final isSelected = _selectedLanguageCode == e['code'];
                            return MenuItemButton(
                              style: ButtonStyle(
                                backgroundColor: isSelected ? const WidgetStatePropertyAll(Color(0xFFDB2777)) : null,
                                minimumSize: WidgetStatePropertyAll(Size(constraints.maxWidth, 45)),
                                padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16)),
                                shape: const WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
                              ),
                              onPressed: () => setState(() {
                                _selectedLanguage = e['name']!;
                                _selectedLanguageCode = e['code']!;
                              }),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _getShortLanguageName(e['name']!),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        color: isSelected ? Colors.white : theme.textTheme.bodyLarge?.color,
                                      ),
                                    ),
                                  ),
                                  if (isSelected) const Icon(Icons.check, color: Colors.white, size: 16),
                                ],
                              ),
                            );
                          }),
                        ],
                        builder: (context, controller, child) {
                          return InkWell(
                            onTap: () {
                              if (controller.isOpen) {
                                controller.close();
                              } else {
                                controller.open();
                              }
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: double.infinity,
                              height: 48,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: theme.brightness == Brightness.light ? Colors.white : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFDB2777), width: 1.5),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        _selectedLanguage.isEmpty 
                                            ? context.tr.selectLanguage 
                                            : _getShortLanguageName(_selectedLanguage),
                                        style: TextStyle(
                                          color: theme.textTheme.bodyMedium?.color,
                                          fontSize: baseFontSize,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(Icons.unfold_more_rounded, color: theme.hintColor, size: 20),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    }
                  ),
                ],
              );

              Widget priceField = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel(context.tr.price, required: false),
                  const SizedBox(height: 8),
                  Stack(
                    alignment: Alignment.centerRight,
                    children: [
                      _buildInput(
                        controller: _priceController, 
                        hint: "0.00", 
                        inputType: const TextInputType.numberWithOptions(decimal: true),
                        scrollPhysics: const NeverScrollableScrollPhysics(),
                        theme: theme,
                        focusNode: _priceFocusNode,
                        contentPadding: const EdgeInsets.fromLTRB(12, 12, 36, 12),
                      ),
                    ],
                  ),
                ],
              );

              if (isSmallWidth) {
                return Column(
                  children: [
                    languageField,
                    const SizedBox(height: 20),
                    priceField,
                  ]
                );
              }

              return Row(
                children: [
                  Expanded(
                    flex: 3, 
                    child: languageField,
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    flex: 2, 
                    child: priceField,
                  ),
                ],
              );
            }
          ),
          const SizedBox(height: 20),
          _buildLabel(context.tr.content, required: false),
          const SizedBox(height: 8),
          // Simple dropdown for Literature posts
          if (_selectedType == 'Literature') ...[
            GestureDetector(
              onTap: () {
                setState(() {
                  _wordPadExpanded = !_wordPadExpanded;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.brightness == Brightness.light ? Colors.white : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFDB2777), width: 1.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.edit_note,
                          color: const Color(0xFFDB2777),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _wordPadExpanded ? context.tr.wordPad : context.tr.wordPad,
                          style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      _wordPadExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: const Color(0xFFDB2777),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          // Content box
          if (_selectedType == 'Literature')
            _buildRichTextEditor(theme, showToolbar: _wordPadExpanded)
          else
            _buildInput(controller: _contentController, hint: context.tr.describeYourPost, maxLines: 4, theme: theme, focusNode: _contentFocusNode),
        ],
      ),
    );
  }

  Widget _buildMediaSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedType == 'Song' || _selectedType == 'Video' || _selectedType == 'Reel' || _selectedType == 'Literature') ...[
          _buildLabel(context.tr.coverImage),
          const SizedBox(height: 10),
          _MediaUploadBox(
            fileName: _coverImageName,
            isUploading: _isCoverUploading,
            label: context.tr.uploadCover,
            subLabel: context.tr.pngJpgGifUpTo10MB,
            icon: Icons.image_outlined,
            onTap: () => _pickFile(isCover: true),
            filePath: _coverImagePath,
            selectedType: 'Image', // Cover is always an image
            onRemove: () => setState(() {
              _coverImageName = null;
              _coverImagePath = null;
            }),
          ),
          const SizedBox(height: 25),
        ],

        _buildLabel(_selectedType == 'Song' ? context.tr.audioFile : _selectedType == 'Video' ? context.tr.videoFile : _selectedType == 'Reel' ? context.tr.reelVideo : _selectedType == 'Literature' ? context.tr.document : context.tr.imageFile),
        const SizedBox(height: 10),
        
        _MediaUploadBox(
          fileName: _attachedFileName,
          isUploading: _isUploading,
          label: _selectedType == 'Song' ? context.tr.uploadAudio : _selectedType == 'Video' ? context.tr.uploadVideo : _selectedType == 'Reel' ? context.tr.uploadReel : _selectedType == 'Literature' ? context.tr.uploadDocument : context.tr.uploadImage,
          subLabel: _selectedType == 'Song' ? context.tr.mp3WavUpTo50MB : _selectedType == 'Video' ? context.tr.mp4AviUpTo500MB : _selectedType == 'Reel' ? context.tr.mp4AviUpTo50MBMax15Sec : _selectedType == 'Literature' ? context.tr.pdfDocxSupported : context.tr.jpgPngSupported,
          icon: _selectedType == 'Song' ? Icons.music_note_outlined : _selectedType == 'Video' ? Icons.videocam_outlined : _selectedType == 'Reel' ? Icons.movie_filter_outlined : _selectedType == 'Literature' ? Icons.menu_book : Icons.image_outlined,
          onTap: () => _pickFile(),
          filePath: _attachedFilePath,
          selectedType: _selectedType, // Pass the active post type
          previewPath: _coverImagePath, // Pass the cover image as a preview for videos/songs
          onRemove: () => setState(() {
            _attachedFileName = null;
            _attachedFilePath = null;
          }),
        ),


        // Visibility Toggles for Songs & Videos
        if (_selectedType == 'Song' || _selectedType == 'Video') ...[
          const SizedBox(height: 30),
          _buildStatusToggleRow(
            title: "Zippfans Status",
            description: "Hide this track from the Zippfans feed.",
            icon: Icons.lock_outline,
            statusLabel: _isZippfansHidden ? "Hidden on Zippfans" : "Visible on Zippfans",
            value: _isZippfansHidden,
            onChanged: (val) => setState(() => _isZippfansHidden = val),
            activeColor: const Color(0xFF22C55E),
          ),
          const SizedBox(height: 20),
          _buildStatusToggleRow(
            title: "Streaming Status",
            description: "Allow listeners to stream this track.",
            icon: Icons.settings_input_antenna,
            statusLabel: _isStreamingAllowed ? "Visible on Streaming" : "Hidden on Streaming",
            value: _isStreamingAllowed,
            onChanged: (val) => setState(() => _isStreamingAllowed = val),
            activeColor: const Color(0xFF22C55E), // Green for streaming allowed
          ),
        ],

      ],
    );
  }

  Widget _buildStatusToggleRow({
    required String title,
    required String description,
    required IconData icon,
    required String statusLabel,
    required bool value,
    required ValueChanged<bool> onChanged,
    Color? activeColor,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left part: Icon Box + Status Label
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: isDark ? Colors.white60 : Colors.grey[600], size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              statusLabel,
              style: TextStyle(
                fontSize: 10,
                color: theme.hintColor,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),
        
        // Center part: Title + Description
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4), // Align with icon top
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: theme.hintColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        
        // Right part: Toggle Switch
        Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: activeColor ?? const Color(0xFFDB2777), // Default pink, or custom green
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: isDark ? Colors.grey[800] : Colors.grey[300],
          ),
        ),
      ],
    );
  }



  Widget _buildFooter(BuildContext context, ThemeData theme, {bool isLoading = false}) {
    final isEditing = widget.existingPost != null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Text
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing ? context.tr.readyToUpdate : context.tr.readyToPost,
                style: TextStyle(
                  fontWeight: FontWeight.bold, 
                  fontSize: 16,
                  color: theme.textTheme.titleMedium?.color
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isEditing ? context.tr.reviewAndUpdate : context.tr.shareContentWithCommunity,
                style: TextStyle(
                  color: theme.hintColor, 
                  fontSize: 12
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Primary Actions Row (Cancel + Update)
          // Actions Row
          Row(
            children: [
              Expanded(
                flex: 1,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.textTheme.bodyMedium?.color,
                    side: BorderSide(color: theme.dividerColor),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(context.tr.cancel),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: ElevatedButton(
                  onPressed: isLoading ? null : () => _createPost(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDB2777),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 2, // Match Update Album button elevation if it has one (default is 2)
                    ),
                  child: isLoading
                      ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                      : Text(isEditing ? context.tr.updatePostBtn : context.tr.createPost),
                  ),
              ),
              
              if (isEditing) ...[
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: ElevatedButton.icon(
                    onPressed: () {
                       showDialog(
                         context: context,
                         builder: (ctx) => AlertDialog(
                           title: Text(context.tr.deletePostQuestion),
                           content: Text(context.tr.deletePostConfirmation),
                           actions: [
                             TextButton(
                               onPressed: () => Navigator.pop(ctx), 
                               child: Text(context.tr.cancel)
                             ),
                             TextButton(
                               onPressed: () {
                                 Navigator.pop(ctx); 
                                 Navigator.pop(context, {'deleted': true, 'id': widget.existingPost?['id']});
                               },
                               child: Text(context.tr.deleteButton, style: const TextStyle(color: Colors.red)),
                             ),
                           ],
                         ),
                       );
                    },
                    icon: const Icon(Icons.delete_outline, size: 20),
                    label: Text(context.tr.delete),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD32F2F), // Bright red
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'Image': return Icons.image_outlined;
      case 'Song': return Icons.music_note_outlined;
      case 'Video': return Icons.videocam_outlined;
      case 'Literature': return Icons.menu_book;
      case 'Reel': return Icons.movie_filter_outlined;
      default: return Icons.post_add;
    }
  }

  Widget _buildLabel(String text, {bool required = true}) {
    return Row(
      children: [
        Text(text, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Theme.of(context).textTheme.bodyLarge?.color)),
        if (required) const Text(" *", style: TextStyle(color: Color(0xFFDB2777))),
      ],
    );
  }


  Widget _buildRichTextEditor(ThemeData theme, {required bool showToolbar}) {
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = const Color(0xFFDB2777);

    return Container(
      clipBehavior: Clip.none,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: borderColor.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showToolbar)
            Container(
              clipBehavior: Clip.none,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10.5),
                  topRight: Radius.circular(10.5),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? Colors.white10 : Colors.black12,
                    width: 1,
                  ),
                ),
              ),
              child: quill.QuillSimpleToolbar(
                controller: _quillController,
                config: const quill.QuillSimpleToolbarConfig(
                  toolbarIconAlignment: WrapAlignment.start,
                  multiRowsDisplay: true,
                  showFontFamily: true,
                  showFontSize: true,
                  showBoldButton: true,
                  showItalicButton: true,
                  showSmallButton: true,
                  showUnderLineButton: true,
                  showLineHeightButton: true,
                  showStrikeThrough: true,
                  showInlineCode: true,
                  showColorButton: true,
                  showBackgroundColorButton: true,
                  showClearFormat: false,
                  showAlignmentButtons: true,
                  showLeftAlignment: true,
                  showCenterAlignment: true,
                  showRightAlignment: true,
                  showJustifyAlignment: true,
                  showHeaderStyle: true,
                  showListNumbers: true,
                  showListBullets: true,
                  showListCheck: true,
                  showCodeBlock: true,
                  showQuote: true,
                  showIndent: true,
                  showLink: true,
                  showUndo: true,
                  showRedo: true,
                  showDirection: true,
                  showSearchButton: true,
                  showSubscript: true,
                  showSuperscript: true,
                ),
              ),
            ),
          // Editor
          Container(
            constraints: const BoxConstraints(minHeight: 300, maxHeight: 500),
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: showToolbar ? Radius.zero : const Radius.circular(10.5),
                topRight: showToolbar ? Radius.zero : const Radius.circular(10.5),
                bottomLeft: const Radius.circular(10.5),
                bottomRight: const Radius.circular(10.5),
              ),
            ),
            child: Scrollbar(
              controller: _editorScrollController, // Explicit controller to prevent crash
              thumbVisibility: true, // Always show scrollbar
              thickness: 3.0, // Resemble "morning" style
              radius: const Radius.circular(2),
              child: SingleChildScrollView(
                controller: _editorScrollController, // Same controller
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 300),
                  child: quill.QuillEditor.basic(
                    controller: _quillController,
                    focusNode: _quillFocusNode,
                      config: quill.QuillEditorConfig(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24), // Extra bottom padding for scrollbar
                        scrollable: false, // Internal scrolling disabled
                        autoFocus: false,
                        expands: false,
                        showCursor: true,
                        placeholder: context.tr.describeYourPost,
                      ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller, 
    required String hint, 
    required ThemeData theme,
    int maxLines = 1, 
    IconData? suffixIcon,
    Widget? suffix,
    TextInputType inputType = TextInputType.text,
    ScrollPhysics? scrollPhysics,
    FocusNode? focusNode,
    EdgeInsetsGeometry? contentPadding,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      maxLines: maxLines,
      keyboardType: inputType,
      scrollPhysics: scrollPhysics,
      style: TextStyle(color: theme.textTheme.bodyMedium?.color),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: theme.hintColor, fontSize: 13),
        filled: true,
        fillColor: theme.brightness == Brightness.light ? Colors.white : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
        contentPadding: contentPadding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        isDense: false,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8), 
          borderSide: const BorderSide(color: Color(0xFFDB2777), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8), 
          borderSide: const BorderSide(color: Color(0xFFDB2777), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8), 
          borderSide: const BorderSide(color: Color(0xFFDB2777), width: 2.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8), 
          borderSide: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5), width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFDB2777), width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFDB2777), width: 2.5),
        ),
        suffixIcon: suffix ?? (suffixIcon != null ? Icon(suffixIcon, color: theme.hintColor, size: 18) : null),
      ),
      cursorColor: const Color(0xFFDB2777),
    );
  }
}

class _TypeCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool enabled;

  const _TypeCard({
    required this.icon, 
    required this.label, 
    required this.isSelected, 
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? const Color(0xFFDB2777) : theme.dividerColor.withValues(alpha: 0.5)),
          boxShadow: isSelected ? [BoxShadow(color: const Color(0xFFDB2777).withValues(alpha: 0.05), blurRadius: 10)] : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? const Color(0xFFDB2777) : (theme.brightness == Brightness.dark ? Colors.white70 : Colors.black54), size: 28),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? const Color(0xFFDB2777) : theme.hintColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  _DashedBorderPainter({required this.color, required this.strokeWidth, required this.gap});

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    var path = Path();
    path.addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(12)));

    Path dashPath = Path();
    double dashWidth = 10.0;
    double distance = 0.0;
    
    for (PathMetric pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        dashPath.addPath(
          pathMetric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth;
        distance += gap;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) => color != oldDelegate.color;
}

class _MediaUploadBox extends StatelessWidget {
  final String? fileName;
  final String? filePath;
  final bool isUploading;
  final String label;
  final String subLabel;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback? onRemove;
  final String? previewPath;
  final String selectedType; // Explicit type check

  const _MediaUploadBox({
    required this.fileName,
    this.filePath,
    this.previewPath,
    required this.isUploading,
    required this.label,
    required this.subLabel,
    required this.icon,
    required this.onTap,
    this.onRemove,
    required this.selectedType,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lowerPath = filePath?.toLowerCase() ?? '';
    final isImage = lowerPath.contains('.jpg') || lowerPath.contains('.jpeg') || lowerPath.contains('.png') || lowerPath.contains('.gif') || lowerPath.contains('picsum');
    
    // Reliably identify video/audio based on post type or extension
    final isVideoFile = selectedType == 'Video' || selectedType == 'Reel' || lowerPath.endsWith('.mp4') || lowerPath.endsWith('.mov') || lowerPath.endsWith('.avi');
    final isAudioFile = selectedType == 'Song' || lowerPath.endsWith('.mp3') || lowerPath.endsWith('.wav') || lowerPath.endsWith('.m4a');
    
    // If main file is video/audio, check if we have an image preview (like cover image)
    final previewToUse = (isVideoFile || selectedType == 'Song' || !isImage) ? previewPath : filePath;
    final hasImageToPreview = previewToUse != null && (
      previewToUse.toLowerCase().contains('.jpg') || 
      previewToUse.toLowerCase().contains('.jpeg') || 
      previewToUse.toLowerCase().contains('.png') || 
      previewToUse.toLowerCase().contains('.gif') || 
      previewToUse.toLowerCase().contains('picsum') || 
      previewToUse.toLowerCase().contains('http') || 
      previewToUse.toLowerCase().contains('ozvault')
    );
    final isNetworkPreview = previewToUse?.startsWith('http') == true || previewToUse?.toLowerCase().contains('ozvault') == true;

    return CustomPaint(
      painter: _DashedBorderPainter(color: const Color(0xFFDB2777), strokeWidth: 0.0, gap: 0.0),
      child: Container(
        constraints: const BoxConstraints(minHeight: 140),
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
        child: isUploading 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFDB2777)))
          : fileName == null 
            ? InkWell( // Empty state: Click to pick
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 30, color: theme.brightness == Brightness.dark ? Colors.white : Colors.black),
                      const SizedBox(height: 8),
                      Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(subLabel, style: TextStyle(color: theme.hintColor, fontSize: 11)),
                    ],
                  ),
                ),
              )
            : Stack( // Filled state: Show Preview/Player
                alignment: Alignment.center,
                children: [
                   if (isVideoFile)
                      SizedBox(
                        height: selectedType == 'Reel' ? 400 : 250,
                        width: double.infinity,
                        child: ClipRect(
                          child: VideoPlayerWidget(
                            key: ValueKey('edit_preview_${filePath ?? 'none'}'),
                            videoPath: filePath!,
                            coverPath: previewToUse,
                            autoPlay: true,
                            looping: true,
                            showControls: false,
                            showPlayButton: true,
                            allowCustomControls: true,
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                   else if (isAudioFile)
                      SizedBox(
                        height: 180,
                        width: double.infinity,
                        child: AudioPlayerWidget(
                          key: ValueKey('edit_audio_${filePath ?? 'none'}'),
                          audioPath: filePath!,
                          coverPath: previewToUse,
                          autoPlay: true,
                          showCoverBackground: true,
                          showEnlargeButton: false,
                          showInfoButton: false,
                        ),
                      )
                   else if (hasImageToPreview)
                     ClipRRect(
                       borderRadius: BorderRadius.circular(8),
                       child: isNetworkPreview
                           ? Image.network(
                               previewToUse, 
                               height: 180, 
                               width: double.infinity, 
                               fit: BoxFit.cover, 
                               errorBuilder: (c, e, s) => Center(child: Icon(icon, size: 45, color: const Color(0xFFDB2777))),
                             )
                           : Image.file(
                               File(previewToUse), 
                               height: 180, 
                               width: double.infinity, 
                               fit: BoxFit.cover,
                             ),
                     )
                   else
                     Padding(
                       padding: const EdgeInsets.all(20),
                       child: Column(
                         children: [
                           Icon(icon, size: 50, color: const Color(0xFFDB2777)),
                           const SizedBox(height: 12),
                           Text(fileName!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center, maxLines: 1),
                         ],
                       ),
                     ),
                   
                   // Remove button ALWAYS on top and always clickable
                   Positioned(
                      top: 10,
                      right: 10,
                      child: GestureDetector(
                         onTap: onRemove,
                         child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4)]
                            ),
                            child: const Icon(Icons.close, color: Colors.white, size: 18),
                         ),
                      ),
                   ),

                   // Filename overlay at bottom for clarity
                   Positioned(
                     bottom: 0,
                     left: 0,
                     right: 0,
                     child: Container(
                       padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                       decoration: BoxDecoration(
                         gradient: LinearGradient(
                           begin: Alignment.topCenter,
                           end: Alignment.bottomCenter,
                           colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                         ),
                       ),
                       child: Text(
                         fileName!, 
                         style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                         textAlign: TextAlign.center,
                         maxLines: 1,
                         overflow: TextOverflow.ellipsis,
                       ),
                     ),
                   ),
                ],
              ),
      ),
    );
  }
}
