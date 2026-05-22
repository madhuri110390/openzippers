import 'dart:async';
import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/mock_data.dart';
import '../helpers/translations.dart';
import 'package:audioplayers/audioplayers.dart';
import 'media_player_widgets.dart';
import 'package:path/path.dart' as p;


class AlbumsView extends StatelessWidget {
  final MockUser currentUser;
  final List<Map<String, dynamic>> albums;
  final VoidCallback onCreateAlbum;
  final Function(Map<String, dynamic>) onDeleteAlbum;
  final Function(Map<String, dynamic>) onEditAlbum;
  final Function(Map<String, dynamic>) onViewAlbum;
  final Function(Map<String, dynamic>)? onShowDetails;
  final bool isOwner;
  final bool isScrollable; 
  final bool showCreateButton;
  final bool fromProfile;


  final Function(Map<String, dynamic>)? onAddToCart;

  const AlbumsView({
    super.key,
    required this.currentUser,
    this.albums = const [],
    required this.onCreateAlbum,
    required this.onDeleteAlbum,
    required this.onEditAlbum,
    required this.onViewAlbum,
    this.onShowDetails,
    this.onAddToCart,
    this.isOwner = false,
    this.isScrollable = true, 
    this.showCreateButton = true,
    this.fromProfile= false,

  });





  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final List<Map<String, dynamic>> displayAlbums = albums;

    final content = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    InkWell(
                      onTap: () {
                         // Heading tap interaction
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.photo_library_outlined, size: 28, color: Color(0xFFDB2777)),
                            const SizedBox(width: 8),
                            Text(
                              isOwner ? context.tr.myAlbums : context.tr.albums,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (showCreateButton && isOwner)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: ElevatedButton.icon(
                          onPressed: onCreateAlbum,
                          icon: const Icon(Icons.add_circle_outline, size: 20),
                          label: Text(
                            context.tr.createAlbum,
                            style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDB2777),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            elevation: 2,
                            shadowColor: const Color(0xFFDB2777).withOpacity(0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                if (isOwner) ...[
                  const SizedBox(height: 4),
                  Text(
                    context.tr.manageAlbumsSubtitle,
                    style: TextStyle(
                      color: theme.hintColor,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 32),
            if (displayAlbums.isEmpty)
              _buildEmptyAlbumState(context, theme)
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.of(context).size.width > 600 ? 5 : 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                itemCount: displayAlbums.length,
                itemBuilder: (context, index) {
                  final album = displayAlbums[index];
                  return _buildAlbumCard(context, theme, album);
                },
              ),
          ],
        ),
      );

    if (isScrollable) {
      return SingleChildScrollView(child: content);
    }
    return content;
  }

  Widget _buildEmptyAlbumState(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.only(top: 40),
      alignment: Alignment.center,
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: theme.dividerColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.music_note, size: 48, color: theme.hintColor),
          ),
          const SizedBox(height: 24),
          Text(
            context.tr.noAlbumsYet,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          if (showCreateButton && isOwner) ...[
            const SizedBox(height: 12),
            Text(
              context.tr.createFirstAlbumDesc,
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.hintColor, fontSize: 14, height: 1.5),
              maxLines: 2,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onCreateAlbum,
              icon: const Icon(Icons.edit, size: 20),
              label: Text(context.tr.createYourFirstAlbum),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDB2777),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAlbumCard(BuildContext context, ThemeData theme, Map<String, dynamic> album) {
    return GestureDetector(
      onTap: () => onViewAlbum(album),
      child: Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (album['cover'] != null && album['cover'].toString().isNotEmpty && album['cover'].toString().startsWith('http'))
                    Image.network(
                      album['cover'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.album, size: 50, color: Colors.grey),
                      ),
                    )
                  else if (album['cover'] != null && album['cover'].toString().isNotEmpty && File(album['cover']).existsSync())
                    Image.file(
                      File(album['cover']),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.album, size: 50, color: Colors.grey),
                      ),
                    )
                  else
                    Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.album, size: 50, color: Colors.grey),
                    ),
                  // Center Play Button removed for cleaner UI as per user request
                  // Interaction is still available via card tap or visibility icon
                  // Only show price label if it is paid (not free/0)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        context.tr.tracksCount(album['trackCount'] ?? 0),
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {}, // Absorb all taps to prevent parent card tap
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isOwner && !fromProfile ) ...[
                            _buildActionIcon(Icons.visibility, onTap: () => onShowDetails?.call(album)),
                            const SizedBox(width: 4),
                            _buildActionIcon(Icons.edit, onTap: () => onEditAlbum(album)),
                            const SizedBox(width: 4),
                            _buildActionIcon(Icons.delete, onTap: () => onDeleteAlbum(album)),
                          ] else if (!isOwner && onAddToCart != null && album['isPrivate'] != 1 && album['isPrivate'] != true) ...[
                            const SizedBox(width: 4),
                            _buildActionIcon(Icons.shopping_cart, isPrimary: true, onTap: () => onAddToCart!(album)),
                          ]
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0), 
            child: Row( 
              children: [
                Expanded(
                  child: Text(
                    album['title'] ?? context.tr.unknownAlbum,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  album['year'] ?? '',
                  style: TextStyle(color: theme.hintColor, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildActionIcon(IconData icon, {bool isPrimary = false, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: () {
        onTap();
      },
      behavior: HitTestBehavior.opaque, // Absorb the tap, don't let it propagate
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
              color: const Color(0xFFDB2777),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: isPrimary ? 30 : 26, color: Colors.white),
      ),
    );
  }
}

class AlbumPlayerDialog extends StatefulWidget {
  final Map<String, dynamic> album;
  final int initialIndex;
  final List<Map<String, dynamic>>? allAlbums;
  final int currentAlbumIndex;

  const AlbumPlayerDialog({
    super.key, 
    required this.album, 
    this.initialIndex = 0,
    this.allAlbums,
    this.currentAlbumIndex = -1,
  });

  static void show(BuildContext context, Map<String, dynamic> album, {int initialIndex = 0, List<Map<String, dynamic>>? allAlbums, int currentAlbumIndex = -1}) {
    showGeneralPage(
      context,
      AlbumPlayerDialog(
        album: album, 
        initialIndex: initialIndex,
        allAlbums: allAlbums,
        currentAlbumIndex: currentAlbumIndex,
      ),
    );
  }

  @override
  State<AlbumPlayerDialog> createState() => _AlbumPlayerDialogState();
}

void showGeneralPage(BuildContext context, Widget child) {
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    ),
  );
}


class _AlbumPlayerDialogState extends State<AlbumPlayerDialog> {
  late int _currentIndex;
  late int _currentAlbumIndex;
  late Map<String, dynamic> _currentAlbum;
  late List<dynamic> _tracks;
  late AudioPlayer _audioPlayer;
  VideoPlayerController? _videoController;
  bool _isVideoPlaying = false;
  Duration _videoPosition = Duration.zero;
  Duration _videoDuration = Duration.zero;
  double _volume = 1.0;
  Timer? _hideTimer;
  bool _areControlsVisible = true;
  Duration _audioPosition = Duration.zero;
  Duration _audioDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _currentIndex = widget.initialIndex;
    _currentAlbumIndex = widget.currentAlbumIndex;
    _currentAlbum = widget.album;
    final rawTracks = _currentAlbum['tracks'] ?? _currentAlbum['media'] ?? [];
    _tracks = List<Map<String, dynamic>>.from(rawTracks).where((t) {
      final type = (t['type'] ?? '').toString().toLowerCase();
      return type == 'song' || type == 'video' || type == 'reel' || type == 'reels';
    }).toList();
    // Adjust currentIndex if it's out of bounds after filtering
    if (_currentIndex >= _tracks.length) _currentIndex = 0;
    _setupAudioListeners();
    WidgetsBinding.instance.addPostFrameCallback((_) => _playTrack());
  }

  @override
  void dispose() {
    _videoController?.removeListener(_videoListener);
    _audioPlayer.dispose();
    _hideTimer?.cancel();
    super.dispose();
  }

  void _setupAudioListeners() {
    _audioPlayer.onPositionChanged.listen((p) {
      if (mounted) setState(() => _audioPosition = p);
    });
    _audioPlayer.onDurationChanged.listen((d) {
      if (mounted) setState(() => _audioDuration = d);
    });
    _audioPlayer.onPlayerStateChanged.listen((s) {
      if (mounted) {
         setState(() {}); 
         if (s == PlayerState.playing && _areControlsVisible) _startHideTimer();
      }
    });
    _audioPlayer.onPlayerComplete.listen((_) => _nextTrack());
  }

  Future<void> _playTrack() async {
    if (_tracks.isEmpty) return;
    final track = _tracks[_currentIndex];
    final type = (track['type'] ?? '').toString().toLowerCase();
    
    // Improved video detection
    final path = (track['filePath'] ?? track['url'] ?? track['videoPath'] ?? track['mediaPath'] ?? '').toString();
    final isVideo = type == 'video' || type == 'reel' || type == 'reels' || 
                    path.toLowerCase().endsWith('.mp4') || path.toLowerCase().endsWith('.mov') || path.toLowerCase().endsWith('.mkv');
    final isImage = type == 'image' || path.toLowerCase().endsWith('.jpg') || path.toLowerCase().endsWith('.jpeg') || path.toLowerCase().endsWith('.png');

    setState(() {
       _areControlsVisible = true;
       _startHideTimer();
       // Reset video state for UI when switching tracks
       if (!isVideo) {
         _videoController?.removeListener(_videoListener);
         _videoController = null;
         _isVideoPlaying = false;
       }
    });

    if (isVideo) {
      await _audioPlayer.stop();
    } else if (isImage) {
      _videoController?.pause();
      await _audioPlayer.stop();
    } else {
      String audioPath = track['filePath'] ?? track['audioPath'] ?? track['url'] ?? '';
      if (audioPath.isNotEmpty) {
        try {
          _videoController?.pause();
          await _audioPlayer.stop();
          if (audioPath.startsWith('http')) {
             await _audioPlayer.setSourceUrl(audioPath);
          } else {
             await _audioPlayer.setSourceDeviceFile(audioPath);
          }
          await _audioPlayer.resume();
        } catch (e) {
          debugPrint("Audio Error: $e");
        }
      }
    }
  }


  void _onVideoControllerCreated(VideoPlayerController controller) {
    _videoController = controller;
    _videoController!.addListener(_videoListener);
    if (mounted) {
       setState(() {
         _videoDuration = _videoController!.value.duration;
         _isVideoPlaying = _videoController!.value.isPlaying;
       });
    }
  }

  void _videoListener() {
    if (!mounted || _videoController == null) return;
    setState(() {
      _videoPosition = _videoController!.value.position;
      _videoDuration = _videoController!.value.duration;
      bool wasPlaying = _isVideoPlaying;
      _isVideoPlaying = _videoController!.value.isPlaying;
      if (!wasPlaying && _isVideoPlaying && _areControlsVisible) _startHideTimer();
      // Auto hide if playing and controls are visible
      if (_isVideoPlaying && _areControlsVisible && _hideTimer == null) _startHideTimer();
    });
  }

  void _nextTrack() {
    if (_currentIndex < _tracks.length - 1) {
      setState(() => _currentIndex++);
      _playTrack();
    } else if (widget.allAlbums != null && _currentAlbumIndex != -1 && _currentAlbumIndex < widget.allAlbums!.length - 1) {
      // Sequential play for all albums
      setState(() {
        _currentAlbumIndex++;
        _currentAlbum = widget.allAlbums![_currentAlbumIndex];
        _tracks = _currentAlbum['tracks'] ?? _currentAlbum['media'] ?? [];
        _currentIndex = 0;
      });
      _playTrack();
    }
  }

  void _prevTrack() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
      _playTrack();
    } else if (widget.allAlbums != null && _currentAlbumIndex > 0) {
      setState(() {
        _currentAlbumIndex--;
        _currentAlbum = widget.allAlbums![_currentAlbumIndex];
        _tracks = _currentAlbum['tracks'] ?? _currentAlbum['media'] ?? [];
        _currentIndex = _tracks.isNotEmpty ? _tracks.length - 1 : 0;
      });
      _playTrack();
    }
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && (_isVideoPlaying || _audioPlayer.state == PlayerState.playing)) {
        setState(() => _areControlsVisible = false);
      }
    });
  }

  void _toggleControls() {
    setState(() => _areControlsVisible = !_areControlsVisible);
    if (_areControlsVisible && (_isVideoPlaying || _audioPlayer.state == PlayerState.playing)) {
      _startHideTimer();
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  String _getDisplayTitle(Map<String, dynamic> track) {
    String title = track['title']?.toString() ?? '';
    if (title.isEmpty || title.toLowerCase() == 'untitled') {
      final path = track['filePath']?.toString() ?? track['url']?.toString() ?? track['videoPath']?.toString() ?? track['mediaPath']?.toString();
      if (path != null && path.isNotEmpty) {
        title = p.basenameWithoutExtension(path).replaceAll('_', ' ').replaceAll('-', ' ');
      } else {
        title = context.tr.untitled;
      }
    }
    return title;
  }

  @override
  Widget build(BuildContext context) {
    if (_tracks.isEmpty) return const Scaffold(backgroundColor: Colors.black);
    
    final track = _tracks[_currentIndex];
    final type = (track['type'] ?? '').toString().toLowerCase();
    final path = (track['filePath'] ?? track['url'] ?? track['videoPath'] ?? track['mediaPath'] ?? '').toString();
    final isVideo = type == 'video' || type == 'reel' || type == 'reels' || 
                    path.toLowerCase().endsWith('.mp4') || path.toLowerCase().endsWith('.mov') || path.toLowerCase().endsWith('.mkv');
    final isImage = type == 'image' || path.toLowerCase().endsWith('.jpg') || path.toLowerCase().endsWith('.jpeg') || path.toLowerCase().endsWith('.png');
                    
                    
    String? trackCover = track['coverPath'] ?? track['covers'] ?? track['image'];
    String? albumCover = _currentAlbum['cover'];
    final displayCover = (trackCover != null && trackCover.isNotEmpty) ? trackCover : (albumCover ?? '');

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity! < 0) {
            _nextTrack();
          } else if (details.primaryVelocity! > 0) _prevTrack();
        },
        child: SizedBox.expand(
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (isVideo)
                Positioned.fill(
                  child: VideoPlayerWidget(
                    key: ValueKey('$_currentAlbumIndex-$_currentIndex'),
                    videoPath: path,
                    coverPath: track['coverPath'] ?? track['covers'] ?? track['image'] ?? track['thumbnail'],
                    autoPlay: true,
                    looping: false,
                    showControls: false, 
                    allowCustomControls: false,
                    fit: BoxFit.contain,
                    onFinished: _nextTrack,
                    onVideoTap: _toggleControls,
                    onControllerCreated: _onVideoControllerCreated,
                    showEnlargeButton: false,
                  ),
                )
              else if (displayCover.isNotEmpty)
                GestureDetector(
                  onTap: _toggleControls,
                  child: displayCover.startsWith('http')
                      ? Image.network(displayCover, fit: BoxFit.cover, color: isImage ? null : Colors.black.withOpacity(0.4), colorBlendMode: isImage ? null : BlendMode.darken, errorBuilder: (_, _, _) => Container(color: Colors.grey[900]))
                      : Image.file(File(displayCover), fit: BoxFit.cover, color: isImage ? null : Colors.black.withOpacity(0.4), colorBlendMode: isImage ? null : BlendMode.darken, errorBuilder: (_, _, _) => Container(color: Colors.grey[900])),
                )
              else
                Container(color: Colors.grey[900]),

              // Glass Overlay when controls are visible
              AnimatedOpacity(
                opacity: _areControlsVisible || (!_isVideoPlaying && _audioPlayer.state != PlayerState.playing) ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: IgnorePointer(
                  ignoring: !_areControlsVisible && (_isVideoPlaying || _audioPlayer.state == PlayerState.playing),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(color: Colors.black.withOpacity(0.3)),
                  ),
                ),
              ),

              AnimatedOpacity(
                opacity: _areControlsVisible || (!_isVideoPlaying && _audioPlayer.state != PlayerState.playing) ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: IgnorePointer(
                  ignoring: !_areControlsVisible && (_isVideoPlaying || _audioPlayer.state == PlayerState.playing),
                  child: Stack(
                    children: [
                      // Header Controls
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 12,
                        left: 16,
                        right: 16,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), shape: BoxShape.circle),
                                child: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                            IconButton(
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), shape: BoxShape.circle),
                                child: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 24),
                              ),
                              onPressed: () {
                                if (isVideo) {
                                  Navigator.of(context).push(MaterialPageRoute(
                                    builder: (_) => FullScreenVideoPlayer(
                                      tracks: _tracks,
                                      initialIndex: _currentIndex,
                                      startPosition: _videoController?.value.position,
                                      onTrackChanged: (index) { if (mounted) setState(() => _currentIndex = index); },
                                    )
                                  ));
                                } else {
                                  Navigator.of(context).push(MaterialPageRoute(
                                    builder: (_) => FullScreenAudioPlayer(
                                      audioPlayer: _audioPlayer,
                                      tracks: _tracks,
                                      initialIndex: _currentIndex,
                                      onTrackChanged: (index) { if (mounted) setState(() => _currentIndex = index); },
                                    ),
                                  ));
                                }
                              }
                            ),
                          ],
                        ),
                      ),

                      // Track Info (Below Header)
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 80,
                        left: 20,
                        right: 20,
                        child: Column(
                          children: [
                            Text(
                              _getDisplayTitle(track), 
                              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold), 
                              textAlign: TextAlign.center, 
                              maxLines: 2, 
                              overflow: TextOverflow.ellipsis
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _currentAlbum['title'] ?? '',
                              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_currentAlbum['price'] != null && _currentAlbum['price'].toString().isNotEmpty && _currentAlbum['price'] != '0' && _currentAlbum['price'] != 'Free')
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDB2777),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _currentAlbum['price'],
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ),
                                if (_currentAlbum['price'] != null && _currentAlbum['price'].toString().isNotEmpty && _currentAlbum['price'] != '0' && _currentAlbum['price'] != 'Free')
                                  const SizedBox(width: 12),
                                  
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        (_currentAlbum['isPrivate'] == 1 || _currentAlbum['isPrivate'] == true) 
                                            ? Icons.lock_outline 
                                            : Icons.public,
                                        color: Colors.white70,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        (_currentAlbum['isPrivate'] == 1 || _currentAlbum['isPrivate'] == true) 
                                            ? 'Private' 
                                            : 'Public',
                                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Center Controls (Prev, Play/Pause, Next)
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 48),
                              onPressed: _prevTrack,
                            ),
                            GestureDetector(
                              onTap: () {
                                if (isVideo) {
                                  if (_isVideoPlaying) {
                                    _videoController?.pause();
                                  } else {
                                    _videoController?.play();
                                  }
                                } else {
                                  if (_audioPlayer.state == PlayerState.playing) {
                                    _audioPlayer.pause();
                                  } else {
                                    _audioPlayer.resume();
                                  }
                                }
                                setState(() {});
                                _startHideTimer();
                              },
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFFDB2777),
                                ),
                                child: Icon(
                                  (isVideo ? _isVideoPlaying : _audioPlayer.state == PlayerState.playing) 
                                      ? Icons.pause_rounded : Icons.play_arrow_rounded, 
                                  color: Colors.white, 
                                  size: 56
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 48),
                              onPressed: _nextTrack,
                            ),
                          ],
                        ),
                      ),

                      // Bottom Control Bar
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Volume
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  const Icon(Icons.volume_up_rounded, color: Colors.white70, size: 20),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 100,
                                    child: SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4), 
                                        trackHeight: 2,
                                        activeTrackColor: Colors.white,
                                        inactiveTrackColor: Colors.white24,
                                        thumbColor: Colors.white,
                                      ),
                                      child: Slider(
                                        value: _volume, 
                                        min: 0, max: 1, 
                                        onChanged: (v) { 
                                          setState(() => _volume = v); 
                                          _audioPlayer.setVolume(v); 
                                          _videoController?.setVolume(v); 
                                        }
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Seek Bar
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6), 
                                  trackHeight: 4, 
                                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                                  activeTrackColor: const Color(0xFFDB2777), 
                                  inactiveTrackColor: Colors.white24,
                                  thumbColor: Colors.white,
                                ),
                                child: Slider(
                                  value: (isVideo ? (_videoController?.value.position.inMilliseconds.toDouble() ?? 0.0) : (_audioPosition.inMilliseconds.toDouble())).clamp(0.0, (isVideo ? (_videoController?.value.duration.inMilliseconds.toDouble() ?? 1.0) : (_audioDuration.inMilliseconds.toDouble())).clamp(1.0, double.infinity)).toDouble(),
                                  max: (isVideo ? (_videoController?.value.duration.inMilliseconds.toDouble() ?? 1.0) : (_audioDuration.inMilliseconds.toDouble())).clamp(1.0, double.infinity).toDouble(),
                                  onChanged: (v) { 
                                    if (isVideo) {
                                      _videoController?.seekTo(Duration(milliseconds: v.toInt()));
                                    } else {
                                      _audioPlayer.seek(Duration(milliseconds: v.toInt()));
                                    } 
                                  },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatDuration(isVideo ? (_videoController?.value.position ?? Duration.zero) : _audioPosition), 
                                      style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)
                                    ),
                                    Text(
                                      _formatDuration(isVideo ? (_videoController?.value.duration ?? Duration.zero) : _audioDuration), 
                                      style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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
