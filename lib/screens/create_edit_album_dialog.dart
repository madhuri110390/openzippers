import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CreateEditAlbumDialog extends StatefulWidget {
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
  State<CreateEditAlbumDialog> createState() => _CreateEditAlbumDialogState();
}

class _CreateEditAlbumDialogState extends State<CreateEditAlbumDialog> {
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  bool _isPublic = true;
  File? _pickedImage;
  final ImagePicker _picker = ImagePicker();

  final List<Map<String, dynamic>> _songs = [
    {"id": 1, "title": "Travis Scott Type Beat", "duration": "3:24", "selected": false},
    {"id": 2, "title": "Shawn Mendes – Treat You Better", "duration": "3:12", "selected": false},
  ];

  final List<Map<String, dynamic>> _videos = [
    {"id": 3, "title": "Rolling Loud 2021 Kanye West", "duration": "5:10", "selected": false},
    {"id": 4, "title": "Zayn singing Night Changes by One Direction", "duration": "4:02", "selected": false},
    {"id": 5, "title": "test", "duration": "0:00", "selected": false},
  ];

  int get _selectedCount =>
      _songs.where((s) => s["selected"]).length +
          _videos.where((v) => v["selected"]).length;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.initialTitle ?? '';
    _priceController.text = widget.initialPrice?.toStringAsFixed(2) ?? '0.00';
    _isPublic = widget.initialIsPublic ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
    if (file != null) setState(() => _pickedImage = File(file.path));
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
                    onPressed: () => Navigator.pop(context),
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
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            "Add 6 to 15 tracks — $_selectedCount / 15 tracks",
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 20),

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
                    style: TextStyle(
                        color: Color(0xffFF3B9D), fontSize: 13)),
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
                    style: TextStyle(
                        color: Color(0xffFF3B9D), fontSize: 13)),
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
      ),
    );
  }

  Widget _mediaTile(List<Map<String, dynamic>> list, int index) {
    final item = list[index];
    return GestureDetector(
      onTap: () => setState(() => item["selected"] = !item["selected"]),
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
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: item["selected"],
                activeColor: const Color(0xffFF3B9D),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                onChanged: (v) =>
                    setState(() => item["selected"] = v ?? false),
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