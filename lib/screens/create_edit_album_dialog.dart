import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/album_provider.dart';

class CreateEditAlbumDialog extends ConsumerStatefulWidget {
  final bool isEdit;
  final String? initialTitle;
  final bool? initialIsPublic;
  final double? initialPrice;
  final String? initialCoverImage;

  const CreateEditAlbumDialog({
    super.key,
    this.isEdit = false,
    this.initialTitle,
    this.initialIsPublic,
    this.initialPrice,
    this.initialCoverImage,
  });

  @override
  ConsumerState<CreateEditAlbumDialog> createState() =>
      _CreateEditAlbumDialogState();
}

class _CreateEditAlbumDialogState extends ConsumerState<CreateEditAlbumDialog> {
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  bool _isPublic = true;
  File? _pickedImage;
  String? _imageBase64;

  final ImagePicker _picker = ImagePicker();

  List<Map<String, dynamic>> _songs = [];
  List<Map<String, dynamic>> _videos = [];
  bool _isLoadingPosts = true;

  int get _selectedCount =>
      _songs.where((s) => s["selected"]).length +
          _videos.where((v) => v["selected"]).length;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.initialTitle ?? '';
    _priceController.text = widget.initialPrice?.toStringAsFixed(2) ?? '0.00';
    _isPublic = widget.initialIsPublic ?? true;
    _loadUserPosts();
  }

  Future<void> _loadUserPosts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      final dio = Dio(BaseOptions(
        baseUrl: 'https://openzippers.com/api/v1/',
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ));

      // Step 1: get username
      final userResponse = await dio.get('user');
      final username =
          userResponse.data?['data']?['user']?['username'] ?? '';
      if (username.isEmpty) {
        if (mounted) setState(() => _isLoadingPosts = false);
        return;
      }

      // Step 2: get posts — they come at root level, not inside data.posts
      final userId = userResponse.data?['data']?['user']?['id'];
      if (userId == null) {
        if (mounted) setState(() => _isLoadingPosts = false);
        return;
      }

// Step 3: get posts via users/{id}
      final response = await dio.get('users/$userId');
      debugPrint('FULL KEYS: ${(response.data as Map).keys.toList()}');

      final posts = (response.data['posts'] ??
          response.data['data']?['posts'] ??
          []) as List;

      debugPrint('POST COUNT: ${posts.length}');

      debugPrint('POST COUNT AFTER FIX: ${posts.length}');

      final songs = <Map<String, dynamic>>[];
      final videos = <Map<String, dynamic>>[];

      for (final p in posts) {
        final post = Map<String, dynamic>.from(p as Map);
        final postType =
        (post['post_type'] ?? post['type'] ?? '').toString().toLowerCase();
        final title = post['title']?.toString() ?? 'Untitled';
        final id = post['id'];
        if (id == null) continue;

        String duration = '0:00';
        try {
          final meta = post['metadata'];
          if (meta != null) {
            final metaMap = meta is String
                ? <String, dynamic>{}
                : Map<String, dynamic>.from(meta as Map);
            final d = metaMap['media_info']?['format']?['duration'];
            if (d != null) {
              final secs = (d as num).toInt();
              final m = secs ~/ 60;
              final s = secs % 60;
              duration = '$m:${s.toString().padLeft(2, '0')}';
            }
          }
        } catch (_) {}

        if (postType == 'audio') {
          songs.add({
            'id': id,
            'title': title,
            'duration': duration,
            'selected': false,
            'type': 'song',
          });
        } else if (postType == 'video') {
          videos.add({
            'id': id,
            'title': title,
            'duration': duration,
            'selected': false,
            'type': 'post',
          });
        }
      }

      if (mounted) {
        setState(() {
          _songs = songs;
          _videos = videos;
          _isLoadingPosts = false;
        });
      }
    } catch (e) {
      debugPrint('_loadUserPosts error: $e');
      if (mounted) setState(() => _isLoadingPosts = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      final bytes = await file.readAsBytes();
      setState(() {
        _pickedImage = File(file.path);
        _imageBase64 = base64Encode(bytes);
      });
    }
  }

  void _selectAllSongs() {
    setState(() {
      for (var s in _songs) s["selected"] = true;
    });
  }

  void _selectAllVideos() {
    setState(() {
      for (var v in _videos) v["selected"] = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Dialog(
      backgroundColor: const Color(0xff1A2742),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Container(
        width: isMobile ? screenWidth * 0.95 : 600,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── HEADER ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
              child: Row(
                children: [
                  Text(
                    widget.isEdit ? "Edit Album" : "Create Album",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white12, height: 1),

            // ── BODY ──
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: isMobile ? _mobileLayout() : _desktopLayout(),
              ),
            ),

            // ── FOOTER ──
            const Divider(color: Colors.white12, height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel",
                        style: TextStyle(color: Colors.white70)),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xffFF3B9D),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () async {
                      debugPrint('CREATE TAPPED');
                      final selectedMedia = [
                        ..._songs.where((s) => s['selected']).map((s) => {
                          'type': 'song',
                          'id': s['id'],
                        }),
                        ..._videos.where((v) => v['selected']).map((v) => {
                          'type': 'video',
                          'id': v['id'],
                        }),
                      ];
                      debugPrint('CALLING CREATE API...');
                      try {
                        await ref.read(albumViewModelProvider.notifier).createAlbum(
                          title: _titleController.text.trim(),
                          isPublic: _isPublic,
                          price: double.tryParse(_priceController.text) ?? 0.0,
                          media: selectedMedia,
                          imageBase64: _imageBase64,
                        );
                        debugPrint('CREATE SUCCESS');
                        if (context.mounted) Navigator.pop(context);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Album created!')),
                          );
                        }
                      } catch (e) {
                        debugPrint('CREATE ERROR: $e');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed: $e')),
                          );
                        }
                      }
                    },
                    child: Text(
                      widget.isEdit ? "Update Album" : "Create Album",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _titleField(),
        const SizedBox(height: 16),
        _visibilityAndPrice(),
        const SizedBox(height: 16),
        _coverImagePicker(),
        const SizedBox(height: 24),
        _selectMediaSection(),
      ],
    );
  }

  Widget _desktopLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _titleField(),
                  const SizedBox(height: 16),
                  _visibilityAndPrice(),
                ],
              ),
            ),
            const SizedBox(width: 20),
            _coverImagePicker(),
          ],
        ),
        const SizedBox(height: 24),
        _selectMediaSection(),
      ],
    );
  }

  Widget _titleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Album Title",
            style: TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 8),
        TextField(
          controller: _titleController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Enter album title",
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: const Color(0xff243555),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _visibilityAndPrice() {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        const Text("Visibility",
            style: TextStyle(color: Colors.white70, fontSize: 13)),
        Switch(
          value: _isPublic,
          activeColor: const Color(0xffFF3B9D),
          onChanged: (v) => setState(() => _isPublic = v),
        ),
        Text(
          _isPublic ? "Public" : "Private",
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        const Text("Price",
            style: TextStyle(color: Colors.white70, fontSize: 13)),
        SizedBox(
          width: 90,
          child: TextField(
            controller: _priceController,
            keyboardType:
            const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "0.00",
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: const Color(0xff243555),
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _coverImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Album Cover",
            style: TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: const Color(0xff243555),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: _pickedImage != null
                ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(_pickedImage!, fit: BoxFit.cover),
            )
                : widget.initialCoverImage != null
                ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                widget.initialCoverImage!,
                fit: BoxFit.cover,
              ),
            )
                : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.image_outlined,
                    color: Colors.white38, size: 36),
                SizedBox(height: 8),
                Text("Click to upload",
                    style: TextStyle(
                        color: Colors.white54, fontSize: 12)),
                SizedBox(height: 4),
                Text("PNG, JPG, GIF up to 2MB",
                    style: TextStyle(
                        color: Colors.white38, fontSize: 10)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _selectMediaSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Select Media",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            "Add 6 to 15 tracks — $_selectedCount / 15 tracks",
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 20),
          if (_isLoadingPosts)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(color: Color(0xffFF3B9D)),
              ),
            )
          else ...[
            // ── SONGS ──
            Row(
              children: [
                const Text("🎵 ", style: TextStyle(fontSize: 16)),
                Text("Songs (${_songs.length})",
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w500)),
                const Spacer(),
                GestureDetector(
                  onTap: _selectAllSongs,
                  child: const Text("Select All",
                      style: TextStyle(color: Color(0xffFF3B9D), fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...List.generate(
              _songs.length,
                  (index) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _mediaTile(_songs, index),
              ),
            ),
            const SizedBox(height: 10),
            // ── VIDEOS ──
            Row(
              children: [
                const Text("🎥 ", style: TextStyle(fontSize: 16)),
                Text("Videos (${_videos.length})",
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w500)),
                const Spacer(),
                GestureDetector(
                  onTap: _selectAllVideos,
                  child: const Text("Select All",
                      style: TextStyle(color: Color(0xffFF3B9D), fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...List.generate(
              _videos.length,
                  (index) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _mediaTile(_videos, index),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _mediaTile(List<Map<String, dynamic>> list, int index) {
    final item = list[index];
    return InkWell(
      onTap: () => setState(() => list[index]["selected"] = !list[index]["selected"]),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: item["selected"]
              ? const Color(0xff1E3A5F)
              : const Color(0xff243555),
          borderRadius: BorderRadius.circular(10),
          border: item["selected"]
              ? Border.all(color: const Color(0xffFF3B9D), width: 1.5)
              : null,
        ),
        child: Row(
          children: [
            IgnorePointer(
              child: SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: item["selected"],
                  activeColor: const Color(0xffFF3B9D),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  onChanged: (_) {},
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item["title"],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 13),
                  ),
                  Text(
                    item["duration"],
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}