import 'dart:ui';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/album_model.dart';
import '../models/album_response.dart';
import '../viewmodels/album_viewmodel.dart';
import '../widgets/media_player_widgets.dart';
import 'create_edit_album_dialog.dart';

class AlbumsScreen extends ConsumerStatefulWidget {
  const AlbumsScreen({super.key});

  @override
  ConsumerState<AlbumsScreen> createState() => _AlbumsScreenState();
}
class _AlbumPlayerScreen extends StatefulWidget {
  final List<Map<String, dynamic>> tracks;
  const _AlbumPlayerScreen({required this.tracks});

  @override
  State<_AlbumPlayerScreen> createState() => _AlbumPlayerScreenState();
}

class _AlbumPlayerScreenState extends State<_AlbumPlayerScreen> {
  int _currentIndex = 0;
  AudioPlayer? _audioPlayer;

  @override
  void initState() {
    super.initState();
    _startTrack(0);
  }

  @override
  void dispose() {
    _audioPlayer?.dispose();
    super.dispose();
  }

  void _startTrack(int index) {
    if (index < 0 || index >= widget.tracks.length) return;
    final track = widget.tracks[index];
    if (track['postType'] == 'video') {
      _audioPlayer?.stop();
    }
    setState(() => _currentIndex = index);
  }

  void _next() => _startTrack(_currentIndex + 1);
  void _prev() => _startTrack(_currentIndex - 1);

  @override
  Widget build(BuildContext context) {
    final track = widget.tracks[_currentIndex];
    final isVideo = track['postType'] == 'video';
    final filePath = track['filePath'] ?? '';
    final coverPath = track['coverPath'] ?? '';
    final hasNext = _currentIndex < widget.tracks.length - 1;
    final hasPrev = _currentIndex > 0;
    debugPrint('TRACK filePath: $filePath, postType: ${track['postType']}');
// Replace this in _AlbumPlayerScreen.build
    if (isVideo) {
      return FullScreenVideoPlayer(
        key: ValueKey('video_$_currentIndex'),
        tracks: widget.tracks
            .asMap()
            .entries
            .where((e) => e.value['postType'] == 'video')
            .map((e) => {
          ...e.value,
          'coverPath': e.value['coverPath'], // shows while video loads
        })
            .toList(),
        initialIndex: 0,
        onTrackChanged: (i) {
          final videoTracks = widget.tracks
              .asMap()
              .entries
              .where((e) => e.value['postType'] == 'video')
              .toList();
          if (i < videoTracks.length) {
            _startTrack(videoTracks[i].key);
          }
        },
      );
    }

    // Audio track
    _audioPlayer ??= AudioPlayer();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background cover
          Container(color: const Color(0xff08142D)),

          // Blur overlay
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.black.withOpacity(0.5)),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          track['title'] ?? 'Track',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${_currentIndex + 1}/${widget.tracks.length}',
                        style: const TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                    ],
                  ),
                ),

                // Audio player
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: AudioPlayerWidget(
                      key: ValueKey('audio_$_currentIndex'),
                      audioPath: filePath,
                      coverPath: track['albumCover'] ?? '',
                      autoPlay: true,
                      showEnlargeButton: false,
                      showInfoButton: false,
                      onFinished: hasNext ? _next : null,
                    ),
                  ),
                ),

                // Prev / Next controls
                Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.skip_previous_rounded,
                          color: hasPrev ? Colors.white : Colors.white30,
                          size: 48,
                        ),
                        onPressed: hasPrev ? _prev : null,
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.skip_next_rounded,
                          color: hasNext ? Colors.white : Colors.white30,
                          size: 48,
                        ),
                        onPressed: hasNext ? _next : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
class _AlbumsScreenState extends ConsumerState<AlbumsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(albumViewModelProvider.notifier).loadAlbums();
    });
  }
  void _playAlbum(BuildContext context, Album album) {
    if (album.items.isEmpty) return;

    final tracks = album.items.map((item) => {
      'title': item.title ?? 'Track',
      'filePath': item.fileUrl ?? '',
      'coverPath': album.coverImage ?? '',
      'albumCover': album.coverImage ?? '',  // ADD THIS
      'postType': item.postType ?? 'audio',
    }).toList();

    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _AlbumPlayerScreen(tracks: tracks),
    ));
  }
  // ✅ REMOVED deleteLocalAlbums from here — it belongs only in AlbumViewModel
  void _showAlbumDetails(BuildContext context, Album album) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xff1A2742),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: Container(
            width: MediaQuery.of(context).size.width * .95,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * .85,
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    const Text(
                      "Album Details",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
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
                const Divider(color: Colors.white12),
                const SizedBox(height: 12),

                // Cover + title + buttons row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: album.coverImage != null
                          ? Image.network(
                        album.coverImage!,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 70,
                          height: 70,
                          color: const Color(0xff33435F),
                          child: const Icon(Icons.music_note, color: Colors.white54),
                        ),
                      )
                          : _detailPlaceholder(),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            album.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${album.items.length} tracks",
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 10,
                            runSpacing: 8,
                            children: [
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xffFF3B9D),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                  _playAlbum(context, album);
                                },
                                icon: const Icon(Icons.play_arrow, color: Colors.white, size: 18),
                                label: const Text("Play Album", style: TextStyle(color: Colors.white)),
                              ),
                              // Show Buy Album only if not owner and album has price
                              if (album.isOwner != true && (album.price ?? 0) > 0 && album.isPurchased != true)
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xff2ECC71),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  ),
                                  onPressed: () async {
                                    Navigator.pop(context);
                                    try {
                                      await ref.read(albumViewModelProvider.notifier).purchaseAlbum(album.id);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Album purchased!')),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Purchase failed: $e')),
                                        );
                                      }
                                    }
                                  },
                                  icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 18),
                                  label: const Text("Buy Album", style: TextStyle(color: Colors.white)),
                                ),
                              // Show Edit only if owner
                              Visibility(
                                visible: false,
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Colors.white30),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  ),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _showEditAlbumDialog(context, album);
                                  },
                                  icon: const Icon(Icons.edit_outlined, color: Colors.white70, size: 16),
                                  label: const Text("Edit Album", style: TextStyle(color: Colors.white70)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Tracks header
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Tracks",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Tracks list
                Flexible(
                  child: album.items.isEmpty
                      ? const Center(
                    child: Text(
                      "No tracks",
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                      : ListView.separated(
                    shrinkWrap: true,
                    itemCount: album.items.length,
                    separatorBuilder: (_, __) =>
                    const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final item = album.items[i];
                      final isVideo = item.trackableType
                          .toLowerCase()
                          .contains('post'); // adjust if needed
                      // Try to get title from trackable if model has it
                      final title = item.title ?? "Track ${i + 1}";
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xff243550),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Text(
                              "${i + 1}",
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const Text(
                                    "0:00",
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: item.postType == 'video'
                                    ? const Color(0xffFF3B9D)
                                    : const Color(0xff2ECC71),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                item.postType == 'video'
                                    ? Icons.videocam
                                    : Icons.music_note,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailPlaceholder() {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        color: const Color(0xff33435F),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.music_note, color: Colors.white54, size: 40),
    );
  }

  Widget _trackTile(int index, String title) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xff33435F),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Text("$index", style: const TextStyle(color: Colors.white70)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 4),
                const Text(
                  "0:00",
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.music_note, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  void _showEditAlbumDialog(BuildContext context, Album album) {
    final titleController = TextEditingController(text: album.title);
    final priceController = TextEditingController(text: album.price?.toStringAsFixed(2) ?? '0.00');
    bool isPublic = album.isPublic ?? false;

    final List<Map<String, dynamic>> editSongs = album.items
        .where((i) => i.postType == 'audio')
        .map((i) => {
      'id': i.trackableId,
      'title': i.title ?? 'Unknown',
      'selected': true,
      'type': 'song',
    })
        .toList();
    final List<Map<String, dynamic>> editVideos = album.items
        .where((i) => i.postType == 'video')
        .map((i) => {
      'id': i.trackableId,
      'title': i.title ?? 'Unknown',
      'selected': true,
      'type': 'post',
    })
        .toList();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: const Color(0xff1A2742),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * .92,
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Text(
                            "Edit Album",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white12),
                      const SizedBox(height: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Album Title",
                            style: TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: titleController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xff33435F),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Center(
                            child: Column(
                              children: [
                                const Text(
                                  "Album Cover",
                                  style: TextStyle(color: Colors.white70),
                                ),
                                const SizedBox(height: 10),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: album.coverImage != null
                                      ? Image.network(
                                    album.coverImage!,
                                    width: 70,
                                    height: 70,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 70,
                                      height: 70,
                                      color: const Color(0xff33435F),
                                      child: const Icon(Icons.music_note, color: Colors.white54),
                                    ),
                                  )
                                      : Container(
                                          width: 130,
                                          height: 130,
                                          color: const Color(0xff33435F),
                                          child: const Icon(
                                            Icons.music_note,
                                            color: Colors.white54,
                                            size: 50,
                                          ),
                                        ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              const Text(
                                "Visibility",
                                style: TextStyle(color: Colors.white70),
                              ),
                              const SizedBox(width: 12),
                              Switch(
                                value: isPublic,
                                onChanged: (v) =>
                                    setDialogState(() => isPublic = v),
                              ),
                              Text(
                                isPublic ? "Public" : "Private",
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: priceController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: "0.00",
                              filled: true,
                              fillColor: const Color(0xff33435F),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white10),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Select Media",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                             Text(
                              "Add 6 to 15 tracks — ${album.items.length} / 15 tracks",
                              style: const TextStyle(color: Colors.white54),
                            ),
                            const SizedBox(height: 20),
                        Builder(builder: (context) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (editSongs.isNotEmpty) ...[
                                Text("🎵 Songs (${editSongs.length})",
                                    style: const TextStyle(color: Colors.white)),
                                const SizedBox(height: 10),
                                ...List.generate(editSongs.length, (i) {
                                  final item = editSongs[i];
                                  return InkWell(
                                    onTap: () => setDialogState(
                                            () => editSongs[i]['selected'] = !editSongs[i]['selected']),
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 10),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: item['selected']
                                            ? const Color(0xff1E3A5F)
                                            : const Color(0xff33435F),
                                        borderRadius: BorderRadius.circular(10),
                                        border: item['selected']
                                            ? Border.all(color: const Color(0xffFF3B9D), width: 1.5)
                                            : null,
                                      ),
                                      child: Row(children: [
                                        IgnorePointer(
                                          child: SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: Checkbox(
                                              value: item['selected'],
                                              activeColor: const Color(0xffFF3B9D),
                                              onChanged: (_) {},
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(item['title'],
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(color: Colors.white, fontSize: 13)),
                                        ),
                                      ]),
                                    ),
                                  );
                                }),
                                const SizedBox(height: 20),
                              ],
                              if (editVideos.isNotEmpty) ...[
                                Text("🎥 Videos (${editVideos.length})",
                                    style: const TextStyle(color: Colors.white)),
                                const SizedBox(height: 10),
                                ...List.generate(editVideos.length, (i) {
                                  final item = editVideos[i];
                                  return InkWell(
                                    onTap: () => setDialogState(
                                            () => editVideos[i]['selected'] = !editVideos[i]['selected']),
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 10),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: item['selected']
                                            ? const Color(0xff1E3A5F)
                                            : const Color(0xff33435F),
                                        borderRadius: BorderRadius.circular(10),
                                        border: item['selected']
                                            ? Border.all(color: const Color(0xffFF3B9D), width: 1.5)
                                            : null,
                                      ),
                                      child: Row(children: [
                                        IgnorePointer(
                                          child: SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: Checkbox(
                                              value: item['selected'],
                                              activeColor: const Color(0xffFF3B9D),
                                              onChanged: (_) {},
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(item['title'],
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(color: Colors.white, fontSize: 13)),
                                        ),
                                      ]),
                                    ),
                                  );
                                }),
                              ],
                            ],
                          );
                        }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              "Cancel",
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
            style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xffFF3B9D),
            ),
                            onPressed: () async {
                              debugPrint('UPDATE TAPPED');
                              final media = [
                                ...editSongs.where((s) => s['selected']).map((s) => {
                                  'type': 'song',
                                  'id': s['id'],
                                }),
                                ...editVideos.where((v) => v['selected']).map((v) => {
                                  'type': 'video',
                                  'id': v['id'],
                                }),
                              ];
                              debugPrint('CALLING UPDATE API...');
                              try {
                                await ref.read(albumViewModelProvider.notifier).updateAlbum(
                                  id: album.id,
                                  title: titleController.text.trim(),
                                  isPublic: isPublic,
                                  price: double.tryParse(priceController.text) ?? 0.0,
                                  media: media,
                                );
                                debugPrint('UPDATE SUCCESS');
                                if (context.mounted) Navigator.pop(context);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Album updated!')),
                                  );
                                }
                              } catch (e) {
                                debugPrint('UPDATE ERROR: $e');
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed: $e')),
                                  );
                                }
                              }
                            },
            child: const Text(
            "Update Album",
            style: TextStyle(color: Colors.white),
            ),
            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteAlbumDialog(BuildContext context, Album album) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xff1A2742),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * .85,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "Delete Album",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                        height: 1.5,
                      ),
                      children: [
                        const TextSpan(
                          text: "Are you sure you want to delete ",
                        ),
                        TextSpan(
                          text: '"${album.title}"',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const TextSpan(text: "? This action cannot be undone."),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 10,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    ),
                    SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        onPressed: () async {
                          Navigator.pop(context);
                          try {
                            await ref.read(albumViewModelProvider.notifier).deleteAlbum(album.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Album deleted')),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed: $e')),
                              );
                            }
                          }
                        },
                        child: const Text("Delete Album", style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _mediaTile(String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xff33435F),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Checkbox(value: false, onChanged: (_) {}),
          Expanded(
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(albumViewModelProvider);

    return Scaffold(
      backgroundColor: const Color(0xff08142D),
      appBar: AppBar(
        backgroundColor: const Color(0xff08142D),
        elevation: 0,
        title: const Text(
          "Albums",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xffFF3B9D),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => const CreateEditAlbumDialog(),
                );
              },
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                "Create",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xffFF3B9D),
          labelColor: const Color(0xffFF3B9D),
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: "My Albums"),
            Tab(text: "Public"),
            Tab(text: "Purchases"),
          ],
        ),
      ),
      body: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            e.toString(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        data: (response) => TabBarView(
          controller: _tabController,
          children: [
            _myAlbumsTab(response.albums),
            _publicAlbumsTab(response.publicAlbums),
            _purchasesTab(response.purchasedAlbums),
          ],
        ),
      ),
    );
  }

  Widget _myAlbumsTab(List<Album> albums) {
    if (albums.isEmpty) {
      return const Center(
        child: Text("No Albums Found", style: TextStyle(color: Colors.white)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: albums.length,
      itemBuilder: (context, index) {
        final album = albums[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xff122340),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: album.coverImage != null
                        ? Image.network(
                            album.coverImage!,
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: const Color(0xff33435F),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.music_note,
                              color: Colors.white54,
                            ),
                          ),
                  ),
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: Color(0xffFF3B9D),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          "${album.items.length}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      album.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      album.isPublic == true ? "Public" : "Private",
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.remove_red_eye_outlined),
                color: Colors.white70,
                onPressed: () => _showAlbumDetails(context, album),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                color: Colors.white70,
                onPressed: () => _showEditAlbumDialog(context, album),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                color: Colors.white70,
                onPressed: () => _showDeleteAlbumDialog(context, album),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _publicAlbumsTab(List<Album> albums) {
    if (albums.isEmpty) {
      return const Center(
        child: Text("No Public Albums", style: TextStyle(color: Colors.white)),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: albums.length,
      itemBuilder: (context, index) {
        final album = albums[index];
        final isFree = album.price == null || album.price == 0.0;
        final trackCount = album.items.length;
        final imageUrl = album.coverImage; // already fixed by _fixImageUrl in model

        return GestureDetector(
          onTap: () => _showAlbumDetails(context, album),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xff122340),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(14),
                      ),
                      child: imageUrl != null
                          ? Image.network(
                        imageUrl,
                        width: double.infinity,
                        height: 160,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholderCover(),
                      )
                          : _placeholderCover(),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isFree
                              ? const Color(0xff2ECC71)
                              : const Color(0xffFF3B9D),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isFree ? "free" : "₹${album.price}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    if (trackCount > 0)
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "$trackCount tracks",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        album.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (album.userName != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          album.userName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _placeholderCover() {
    return Container(
      width: double.infinity,
      height: 160,
      color: const Color(0xff33435F),
      child: const Icon(Icons.music_note, color: Colors.white54, size: 40),
    );
  }
  static String? _fixImageUrl(String? url) {
    if (url == null) return null;
    const base = 'https://dev-openzippers.s3.us-east-1.amazonaws.com/';
    if (url.contains(base + 'https://')) {
      return url.replaceFirst(base, '');
    }
    return url;
  }

  Widget _purchasesTab(List<Album> purchasedAlbums) {
    if (purchasedAlbums.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 45,
                backgroundColor: Color(0xff2A3C5A),
                child: Icon(Icons.music_note, size: 45, color: Colors.white54),
              ),
              const SizedBox(height: 20),
              const Text(
                "No purchased albums yet",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Albums you buy will appear here.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: purchasedAlbums.length,
      itemBuilder: (context, index) {
        final album = purchasedAlbums[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xff122340),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: album.coverImage != null
                    ? Image.network(
                  album.coverImage!,
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 70,
                    height: 70,
                    color: const Color(0xff33435F),
                    child: const Icon(Icons.music_note, color: Colors.white54),
                  ),
                )
                    : Container(
                  width: 70,
                  height: 70,
                  color: const Color(0xff33435F),
                  child: const Icon(Icons.music_note, color: Colors.white54),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      album.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${album.items.length} tracks",
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.play_circle_outline),
                color: const Color(0xffFF3B9D),
                iconSize: 36,
                onPressed: () => _playAlbum(context, album),
              ),
              IconButton(
                icon: const Icon(Icons.remove_red_eye_outlined),
                color: Colors.white70,
                onPressed: () => _showAlbumDetails(context, album),
              ),
            ],
          ),
        );
      },
    );
  }
}
