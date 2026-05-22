import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../helpers/translations.dart';


const double kVideoPlayPauseButtonSize = 44.0;
const double kVideoPlayPauseButtonContainerSize = 44.0;
const EdgeInsets kVideoPlayPauseButtonPadding = EdgeInsets.all(10);


// Video Initialization Throttler
class VideoInitializer {
  static final VideoInitializer _instance = VideoInitializer._internal();
  factory VideoInitializer() => _instance;
  VideoInitializer._internal();

  final int _maxConcurrent = 2; // Increased to 2 for better multitasking
  int _current = 0;
  final List<_QueuedTask> _queue = [];

  // Returns a cancellation function
  Function initialize(Future<void> Function() initTask, {bool isHighPriority = false}) {
    if (_current < _maxConcurrent) {
      _current++;
      // Run immediately (not cancellable once started, but that's fine)
      _runTask(initTask);
      return () {}; // Nothing to cancel if already started
    } else {
      // Queue execution
      final task = _QueuedTask(initTask);
      if (isHighPriority) {
        // High priority: Add to FRONT of queue to run next
        _queue.insert(0, task);
      } else {
        // Normal priority: Add to BACK of queue
        _queue.add(task);
      }
      return () {
        // Cancel callback
        _queue.remove(task);
      };
    }
  }

  Future<void> _runTask(Future<void> Function() task) async {
    try {
      await task();
    } finally {
      _current--;
      _processNext();
    }
  }

  void _processNext() {
    if (_queue.isNotEmpty && _current < _maxConcurrent) {
      final queuedTask = _queue.removeAt(0);
      _current++;
      _runTask(queuedTask.task);
    }
  }
}

class _QueuedTask {
  final Future<void> Function() task;
  _QueuedTask(this.task);
}

class VideoPlayerWidget extends StatefulWidget {
  final String videoPath;
  final String? coverPath;
  final bool autoPlay;
  final bool hideReplay;
  final bool showControls;
  final bool looping;
  final bool showPlayButton;
  final VoidCallback? onVideoTap;
  final VoidCallback? onFinished; // Callback for sequential playback
  final void Function(VideoPlayerController)? onControllerCreated;

  final BoxFit fit;
  final bool allowCustomControls;
  final Duration? startPosition;
  final bool showEnlargeButton;
  final VoidCallback? onEnlargeTap;

  final void Function(bool isPlaying)? onPlayStateChanged;

  const VideoPlayerWidget({
    super.key,
    required this.videoPath,
    this.coverPath,
    this.autoPlay = false,
    this.hideReplay = false,
    this.showControls = false,
    this.looping = false,
    this.showPlayButton = true,
    this.onVideoTap,
    this.onFinished,
    this.onControllerCreated,
    this.onPlayStateChanged, // Added here
    this.fit = BoxFit.contain,
    this.allowCustomControls = true,
    this.startPosition,
    this.showEnlargeButton = false,
    this.onEnlargeTap,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  // Global Registry for Active Players to prevent OOM
  static final List<_VideoPlayerWidgetState> _activePlayers = [];

  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  Timer? _controlsTimer;
  bool _hasError = false;
  String? _errorMessage;
  bool _isInitialized = false;
  bool _isPlaying = false;
  final bool _isManuallyPaused = false;
  bool _showReplayButton = false;
  String? _initializingPath;
  Function? _cancelInit;
  Timer? _debounceTimer; // Timer for scroll debounce
  double _volume = 1.0;
  bool _areControlsVisible = false;
  String? _fileSize; // Changed to nullable to handle initial N/A state via translation
  
  // Transition safety
  DateTime? _lastToggleTime;
  final bool _isSyncing = false;


  void _startHideTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _areControlsVisible = false;
        });
      }
    });
  }

  Future<void> _calculateFileSize() async {
    try {
      if (widget.videoPath.startsWith('http')) {
        _fileSize = mounted ? context.tr.stream : "Stream";
      } else {
        final file = File(widget.videoPath);
        if (await file.exists()) {
          final bytes = await file.length();
          _fileSize = _formatBytes(bytes);
        }
      }
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Error size: $e");
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return "$bytes B";
    if (bytes < 1024 * 1024) return "${(bytes / 1024).toStringAsFixed(1)} KB";
    if (bytes < 1024 * 1024 * 1024) return "${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB";
    return "${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB";
  }

  @override
  void initState() {
    super.initState();
    // ... rest of initState logic (will be called by framework)
    // We don't register here, we register only when we actually consume RAM (initializePlayer)

    final hasCover = widget.coverPath != null && widget.coverPath!.isNotEmpty;

    if (widget.autoPlay) {
      // Priority load for AutoPlay (Detail View) - No debounce
      _initializePlayer(forcePlay: true);
    } else {
      // Grid View / Thumbnails
      if (!hasCover || widget.showControls || widget.looping) {
        // DEBOUNCE: Wait 100ms (Balanced).
        // Fast enough to feel responsive, slow enough to skip fast scrolls.
        _debounceTimer = Timer(const Duration(milliseconds: 100), () {
          if (mounted) {
            _initializePlayer();
          }
        });
      } else {
        // Has cover - wait 100ms too (consistency)
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && !_isInitialized) {
            _initializePlayer();
          }
        });
      }
    }
  }



  // Force dispose to free memory when bumped by new players
  void _forceDispose() {
    if (mounted) {
      _disposeControllers();
      setState(() {
        // UI update to show cover/loading state
        _isInitialized = false;
      });
    } else {
      _disposeControllers();
    }
  }

  // Need to add Timer import if not present, but dart:async is already imported for Completer.


  @override
  void didUpdateWidget(VideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!mounted) return;


    if (widget.videoPath != oldWidget.videoPath) {
      _debounceTimer?.cancel();
      _cancelInit?.call();
      _disposeControllers();

      // ALWAYS re-initialize if the path changed, regardless of cover.
      // The memory management is already handled by the _activePlayers queue.
      _initializePlayer();
      return;
    }

    // ... rest of didUpdateWidget remains same ...
    // Note: Use exact original code for rest of method to avoid errors
    if (widget.autoPlay != oldWidget.autoPlay) {
      if (widget.autoPlay && !_isPlaying && !_isManuallyPaused) {
        if (_isInitialized && _videoPlayerController != null && _chewieController != null) {
          _lastToggleTime = DateTime.now(); // Reset grace period on auto-play
          _chewieController!.play();
          _videoPlayerController!.play();
          if (mounted) setState(() => _isPlaying = true);
        } else if (!_isInitialized) {
          _initializePlayer(forcePlay: true);
        }
      } else if (!widget.autoPlay && _isPlaying) {
        // Accessibility/Visibility lost - PAUSE
        if (_chewieController != null && _videoPlayerController != null && mounted) {
          _chewieController!.pause();
          _videoPlayerController!.pause();
          if (mounted) setState(() => _isPlaying = false);
        }
      }
    }
  }

  void _disposeControllers() {
    _debounceTimer?.cancel(); // Cancel debounce on dispose
    _controlsTimer?.cancel();
    _activePlayers.remove(this); // Remove from global registry
    _cancelInit?.call();
    _cancelInit = null;
    try {
      // ... existing disposal logic ...
      _videoPlayerController?.removeListener(_videoListener);

      // EXPLICIT PAUSE before dispose to ensure audio stops immediately
      try {
        _chewieController?.pause();
        _videoPlayerController?.pause();
      } catch (_) {}

      _chewieController?.dispose();
      _chewieController = null;
      _videoPlayerController?.dispose();
      _videoPlayerController = null;
      _isInitialized = false;
      _isPlaying = false;
      _showReplayButton = false;
      _initializingPath = null;
    } catch (e) {
      _chewieController = null;
      _videoPlayerController = null;
      _isInitialized = false;
      _isPlaying = false;
      _initializingPath = null;
    }
  }

  Future<void> _initializePlayer({bool forcePlay = false}) async {
    if (_isInitialized && _videoPlayerController != null && _initializingPath == widget.videoPath) {
      return;
    }

    if (mounted) {
      setState(() {
        _hasError = false;
        _errorMessage = null;
      });

    }

    _disposeControllers(); // This cancels previous task and removes us from registry

    // STRICT MEMORY MANAGEMENT: Global Cap of 6 Players
    // We register AFTER cleaning up our own previous state
    if (!_activePlayers.contains(this)) {
      // Expanded Limit: 6 active players.
      // Allows 6 thumbnails to be visible at once.
      while (_activePlayers.length >= 8) {
        final oldest = _activePlayers.removeAt(0);
        oldest._forceDispose();
      }
      _activePlayers.add(this);
    }

    final targetPath = widget.videoPath;
    _initializingPath = targetPath;

    // Use throttler with cancellation handle
    final isHighPriority = widget.autoPlay; // Zoom View (Detail) is always High Priority
    _cancelInit = VideoInitializer().initialize(isHighPriority: isHighPriority, () async {
      // Re-check mounting/path after wait
      if (!mounted || _initializingPath != targetPath) return;

      VideoPlayerController? controller;

      try {
        if (targetPath.isEmpty) throw Exception("Video path is empty");

        final options = VideoPlayerOptions(mixWithOthers: true);

        if (targetPath.startsWith('http') || targetPath.contains('ozvault')) {
          try {
            final uri = Uri.parse(
              Uri.encodeFull(
                targetPath.startsWith('http')
                    ? targetPath
                    : 'https://oz.ozvault.io/$targetPath',
              ),
            );// Fallback base URL for ozvault
            
             // Check if URI is valid
            if (!uri.hasScheme || uri.host.isEmpty) {
              throw Exception("Invalid video URL: $targetPath");
            }

            controller = VideoPlayerController.networkUrl(uri, videoPlayerOptions: options);
          } catch (e) {
             throw Exception("URL parsing failed: $e");
          }
        } else {
          File file = File(targetPath);
          bool exists = await file.exists();
          
          if (!exists) {
            // SMART PATH RESOLUTION: If absolute path shifted or is just a filename
            final isJustFileName = !targetPath.contains('/') && !targetPath.contains('\\');
            if (isJustFileName || targetPath.contains('uploads')) {
               try {
                 final fileName = isJustFileName ? targetPath : p.basename(targetPath);
                 final appDir = await getApplicationDocumentsDirectory();
                 final alternativePath = p.join(appDir.path, "uploads", fileName);
                 final altFile = File(alternativePath);
                 if (await altFile.exists()) {
                   debugPrint("Smart Path: Found file at $alternativePath");
                   file = altFile;
                 } else {
                   throw Exception("Local file missing: $fileName");
                 }
               } catch (e) {
                 throw Exception("Path Resolution Error: $e");
               }
            } else {
              throw Exception("File not found: $targetPath");
            }
          }
          controller = VideoPlayerController.file(file, videoPlayerOptions: options);
        }

        // Timeout protection: If init takes > 4s, abort to free up queue
        try {
          await controller.initialize().timeout(
            const Duration(seconds: 4),
          );
        } catch (e) {
          debugPrint("VIDEO INIT ERROR: $e");
          rethrow;
        }

        // rest of initialization logic
        // Check for Cancellation/Disposal
        if (!mounted || _initializingPath != targetPath) {
          await controller.dispose();
          _initializingPath = null;
          return;
        }

        if (controller.value.hasError) {
          throw Exception("Init Error: ${controller.value.errorDescription}");
        }

        if (widget.looping) {
          await controller.setLooping(true);
        }

        bool shouldPlay = widget.autoPlay || forcePlay;

        // CRITICAL SYNC: Update playing state BEFORE setting controllers to prevent listener from pausing us
        _isPlaying = shouldPlay;
        if (shouldPlay) {
          _lastToggleTime = DateTime.now();
        }

        if (shouldPlay) {
          if (widget.startPosition != null) {
              await controller.seekTo(widget.startPosition!);
          }
          await controller.play();
        } else {
             if (widget.startPosition != null) {
              await controller.seekTo(widget.startPosition!);
          }
          await controller.pause();
        }

        if (!mounted || _initializingPath != targetPath) {
          await controller.dispose();
          _initializingPath = null;
          return;
        }

        setState(() {
          _videoPlayerController = controller;
          _initializingPath = null;
          _videoPlayerController!.addListener(_videoListener);

          _chewieController = ChewieController(
            videoPlayerController: _videoPlayerController!,
            autoPlay: shouldPlay, // Explicitly use shouldPlay
            looping: widget.looping,
            aspectRatio: _videoPlayerController!.value.aspectRatio,
            showControls: widget.showControls,
            allowFullScreen: widget.showControls,
            allowMuting: true,
            materialProgressColors: ChewieProgressColors(
              playedColor: const Color(0xFFDB2777),
              handleColor: const Color(0xFFDB2777),
              backgroundColor: Colors.grey,
              bufferedColor: Colors.white.withOpacity(0.5),
            ),
            errorBuilder: (context, msg) => Center(child: Text(msg, style: const TextStyle(color: Colors.white))),
          );

          _isInitialized = true;
          _showReplayButton = false;
          _calculateFileSize(); // Calculate size when initialized

          if (widget.onControllerCreated != null) {
            widget.onControllerCreated!(_videoPlayerController!);
          }
        });

        // RE-VERIFY: Sometimes play() fails immediately after init, ensure it's actually playing if needed
        if (shouldPlay && mounted) {
          await Future.delayed(const Duration(milliseconds: 100));
          if (mounted && _videoPlayerController != null && !_videoPlayerController!.value.isPlaying) {
            _videoPlayerController!.play();
            _chewieController?.play();
          }
        }

      } catch (e) {
        controller?.dispose();
        _initializingPath = null;
        if (mounted) {
          setState(() {
            _hasError = true;
            _errorMessage = e.toString();
          });
        }
      }
    });
  }

  void _videoListener() {
    // Strict safety checks to prevent crashes during disposal or rapid switching
    if (!mounted || _videoPlayerController == null || _chewieController == null) return;

    try {
      // Double-check controller is still valid and initialized
      if (!_videoPlayerController!.value.isInitialized) return;

      // Verify controller hasn't been disposed
      if (_videoPlayerController!.value.duration == Duration.zero &&
          _videoPlayerController!.value.position == Duration.zero &&
          !_videoPlayerController!.value.isInitialized) {
        return;
      }

      final isCurrentlyPlaying = _videoPlayerController!.value.isPlaying;
      final position = _videoPlayerController!.value.position;
      final duration = _videoPlayerController!.value.duration;

      // Safety check: ensure duration is valid
      if (duration <= Duration.zero) return;

      // Update state if playing status changed or position reached end (with tolerance for long videos)
      // Use 100ms tolerance for end detection (faster response)
      final bool isEnd = (position >= duration || (duration - position).inMilliseconds < 100);

      if (isEnd && !widget.looping && widget.onFinished != null && isCurrentlyPlaying) {
        // Trigger onFinished callback
        // Ensure we don't trigger it repeatedly
        try {
          if (mounted) widget.onFinished!();
        } catch(e) {
          debugPrint("Error in onFinished callback: $e");
        }
      }

      // If looping and autoPlay is true, ensure video keeps playing continuously
      // ONLY if NOT manually paused (respected by _isPlaying)
      if (widget.looping && widget.autoPlay && isEnd && _isPlaying) {
        // Video reached end but should loop - restart immediately
        try {
          if (_videoPlayerController!.value.position >= duration) {
            _videoPlayerController!.seekTo(Duration.zero);
          }
          // Ensure video is playing (might have paused at end)
          if (!_videoPlayerController!.value.isPlaying) {
            _videoPlayerController!.play();
            _chewieController?.play();
          }
        } catch (e) {
          debugPrint("Error restarting loop: $e");
        }
      }

      // If looping, we NEVER consider it ended. The controller will loop itself.
      // We just need to make sure we stay in 'playing' state.
      final bool hasEnded = isEnd && !widget.looping;
      final bool isBuffering = _videoPlayerController!.value.isBuffering;
      
      // DEBOUNCE STATE SYNC: During the first 3000ms after a toggle or init, 
      // we trust the local intent (_isPlaying) more than the controller (which might be loading/starting)
      if (_lastToggleTime != null && 
          DateTime.now().difference(_lastToggleTime!).inMilliseconds < 3000) {
        // Just update UI for seek bar, don't flip _isPlaying yet
        if (_areControlsVisible && mounted) setState(() {});
        return;
      }

      // Sync state from controller to UI
      // We consider it "playing" if it's actually playing OR if it's buffering and we WANT it to play
      final bool actuallyPlaying = isCurrentlyPlaying;
      final bool shouldBePlaying = actuallyPlaying || (isBuffering && _isPlaying);

      if (hasEnded) {
        if (_isPlaying && mounted) {
          setState(() {
            _isPlaying = false;
            _showReplayButton = !widget.looping && !widget.hideReplay;
          });
        }
      } else if (shouldBePlaying != _isPlaying && !isBuffering) {
        if (mounted) {
          setState(() {
            _isPlaying = shouldBePlaying;
          });
          widget.onPlayStateChanged?.call(shouldBePlaying); // Notify parent
        }
      } else if (mounted) {
        // Just refresh UI (for seek bar/time)
        setState(() {});
      }

      // Force rebuild to update Seek Bar position if controls are visible
      if (_areControlsVisible && mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint("VideoListener error (non-fatal): $e");
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    if (_hasError) {
      // Check if we have cover to fall back to
      final isNetworkCover = widget.coverPath != null && widget.coverPath!.startsWith('http');
      final hasCover = widget.coverPath != null && widget.coverPath!.isNotEmpty && (isNetworkCover || File(widget.coverPath!).existsSync());

      if (hasCover) {
        // Show cover with error indicator small overlay
        return Stack(
          fit: StackFit.expand,
          children: [
            if (isNetworkCover)
              Image.network(widget.coverPath!, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: Colors.black26))
            else
              Image.file(File(widget.coverPath!), fit: BoxFit.cover),
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.white70, size: 30),
                      const SizedBox(height: 4),
                      Text(context.tr.videoError, style: const TextStyle(color: Colors.white70, fontSize: 10)),
                    ],
                  )
              ),
            ),
          ],
        );
      }

      if (_errorMessage?.contains("Local file missing") == true) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.videocam_off_outlined, color: Colors.white24, size: 40),
              const SizedBox(height: 8),
              Text(
                context.tr.videoNotAvailable,
                style: const TextStyle(color: Colors.white24, fontSize: 12),
              ),
            ],
          ),
        );
      }
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Color(0xFFDB2777), size: 40),
              const SizedBox(height: 10),
              Text(context.tr.errorLoadingVideo, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 5),
              Text(
                _errorMessage ?? context.tr.unknownError,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _hasError = false;
                    _errorMessage = null;
                  });
                  _initializePlayer(forcePlay: true);
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: Text(context.tr.retry),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
                ),
              )
            ],
          ),
        ),
      );
    }

    if (_isInitialized && _chewieController != null && _videoPlayerController != null && _videoPlayerController!.value.isInitialized) {
      try {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isSmall = constraints.maxHeight < 300;
            final buttonSize = isSmall ? 54.0 : 70.0;
            final iconSize = isSmall ? 32.0 : 44.0;
            final bottomPadding = isSmall ? 8.0 : 16.0;

            return ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
              if (widget.onVideoTap != null) {
                widget.onVideoTap!();
              } else {
                // FALLBACK: Toggle Playback on Tap (Matches Home Screen Behavior)
                if (widget.allowCustomControls) {
                   if (_videoPlayerController == null) {
                     // Lazy initialization on tap
                     _lastToggleTime = DateTime.now();
                     _initializePlayer(forcePlay: true);
                     return;
                   }

                   setState(() {
                     _lastToggleTime = DateTime.now();
                     _isPlaying = !_isPlaying;
                     // Also show controls briefly when toggling playback
                     _areControlsVisible = true;
                     _startHideTimer();
                   });
                   widget.onPlayStateChanged?.call(_isPlaying);

                   if (_isPlaying) {
                     _videoPlayerController?.play();
                     _chewieController?.play();
                   } else {
                     _videoPlayerController?.pause();
                     _chewieController?.pause();
                   }
                } else {
                  // Standard toggle for controls
                  setState(() {
                    _areControlsVisible = !_areControlsVisible;
                  });
                  if (_areControlsVisible) _startHideTimer();
                }
              }
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Video player (always in stack for initialization)
                Positioned.fill(
                  child: FittedBox(
                    fit: widget.fit,
                    clipBehavior: Clip.hardEdge,
                    child: SizedBox(
                      width: _videoPlayerController!.value.size.width > 0 ? _videoPlayerController!.value.size.width : 16,
                      height: _videoPlayerController!.value.size.height > 0 ? _videoPlayerController!.value.size.height : 9,
                      child: AspectRatio(
                        aspectRatio: _videoPlayerController!.value.aspectRatio,
                        child: Chewie(controller: _chewieController!),
                      ),
                    ),
                  ),
                ),
                // Cover image overlay when paused (on top of video)
                if (widget.coverPath != null && widget.coverPath!.isNotEmpty && !_isPlaying)
                  Builder(
                    builder: (context) {
                      final path = widget.coverPath!;
                      final isRemote = path.startsWith('http') || path.contains('ozvault');
                      final url = path.startsWith('http') ? path : 'https://oz.ozvault.io/$path';
                      
                      return Positioned.fill(
                        child: isRemote
                            ? Image.network(url, fit: widget.fit, errorBuilder: (c, e, s) => Container(color: Colors.transparent))
                            : Image.file(File(path), fit: widget.fit),
                      );
                    }
                  ),

                // Glass Overlay when controls are visible (Removed blur for clarity when paused)
                if (_areControlsVisible)
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                      child: Container(color: Colors.black.withOpacity(0.2)),
                    ),
                  ),

                // Controls Overlay with SafeArea
                if (_areControlsVisible || !_isPlaying)
                  Positioned.fill(
                    child: SafeArea(
                      child: Stack(
                        children: [
                          // Info Button (Top Left)
                          if (widget.allowCustomControls && widget.showControls)
                            Positioned(
                            top: 12,
                            left: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.videocam_outlined, color: Colors.white70, size: 14),
                                  const SizedBox(width: 4),

                          Text(
                            _fileSize ?? context.tr.dots, 
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)
                          ),
                        ],
                      ),
                    ),
                  ),

                // Centered Play/Pause Button
                if (widget.showPlayButton && (_areControlsVisible || !_isPlaying))
                  Center(
                    child: GestureDetector(
                      onTap: () async {
                        if (_videoPlayerController == null) {
                          // Lazy initialization on tap if not already initialized
                          _lastToggleTime = DateTime.now();
                          _initializePlayer(forcePlay: true);
                          return;
                        }
                        
                         setState(() {
                           _lastToggleTime = DateTime.now();
                           _isPlaying = !_isPlaying;
                           if (_areControlsVisible) _startHideTimer();
                         });
                         widget.onPlayStateChanged?.call(_isPlaying); // Notify parent

                         try {
                           if (_isPlaying) {
                             await _videoPlayerController!.play();
                             _chewieController?.play();
                             
                             // Triple-guard: many players skip the first play() if called too fast after pause
                             Future.delayed(const Duration(milliseconds: 150), () {
                               if (mounted && _isPlaying && _videoPlayerController != null && !_videoPlayerController!.value.isPlaying) {
                                 _videoPlayerController!.play();
                                 _chewieController?.play();
                               }
                             });
                           } else {
                             await _videoPlayerController!.pause();
                             _chewieController?.pause();
                           }
                         } catch (e) {
                           debugPrint("Error toggling playback: $e");
                         }
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: isSmall ? 16 : 24, vertical: isSmall ? 6 : 10),
                        decoration: BoxDecoration(
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.circular(20),
                          color: const Color(0xFFDB2777),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFDB2777).withOpacity(0.4),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, 
                          color: Colors.white, 
                          size: iconSize
                        ),
                      ),
                    ),
                  ),

                // Custom Controls (Bottom Bar)
                if (widget.allowCustomControls && !widget.showControls && (_areControlsVisible || !_isPlaying))
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.fromLTRB(16, isSmall ? 10 : 20, 16, bottomPadding),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                        ),
                      ),
                      child: SafeArea(
                        top: false,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Volume Bar (Left and Shorter)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                const Icon(Icons.volume_up, color: Colors.white70, size: 16),
                                SizedBox(
                                  width: 80,
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
                                        _videoPlayerController?.setVolume(v);
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Playback Seek Bar
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
                                value: _videoPlayerController!.value.position.inMilliseconds.toDouble(),
                                max: _videoPlayerController!.value.duration.inMilliseconds.toDouble().clamp(1.0, double.infinity),
                                onChanged: (v) {
                                  _videoPlayerController?.seekTo(Duration(milliseconds: v.toInt()));
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDuration(_videoPlayerController!.value.position),
                                    style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    _formatDuration(_videoPlayerController!.value.duration),
                                    style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Enlarge Button (Top Right)
                if (widget.showEnlargeButton && (_areControlsVisible || !_isPlaying))
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: const Icon(Icons.fullscreen, color: Colors.white, size: 28),
                      onPressed: widget.onEnlargeTap,
                    ),
                  ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
  } catch (e) {
        debugPrint("Error rendering video: $e");
        return Container(color: Colors.black);
      }
    }


    if (!_isInitialized) {
      final isNetworkCover = widget.coverPath != null && widget.coverPath!.startsWith('http');
      final hasValidCover = widget.coverPath != null && widget.coverPath!.isNotEmpty && (isNetworkCover || File(widget.coverPath!).existsSync());

      if (hasValidCover) {

        if (widget.autoPlay) {
          return Stack(
            fit: StackFit.expand,
            children: [
              if (isNetworkCover)
                Image.network(widget.coverPath!, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: Colors.black26))
              else
                Image.file(File(widget.coverPath!), fit: BoxFit.cover),
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(child: CircularProgressIndicator(color: Color(0xFFDB2777))),
              ),
            ],
          );
        }

        // Show cover with play button. Tap triggers initialization.
        return Stack(
          fit: StackFit.expand,
          children: [
            if (isNetworkCover)
              Image.network(widget.coverPath!, fit: widget.fit, errorBuilder: (c, e, s) => Container(color: Colors.black26))
            else
              Image.file(File(widget.coverPath!), fit: widget.fit),
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  _initializePlayer(forcePlay: true);
                },
                child: Container(
                  color: Colors.black.withOpacity(0.2),
                  child: Center(
                    child: _videoPlayerController != null
                        ? const CircularProgressIndicator(color: Color(0xFFDB2777))
                          : (widget.showPlayButton ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                              decoration: BoxDecoration(
                                shape: BoxShape.rectangle,
                                borderRadius: BorderRadius.circular(24),
                                color: const Color(0xFFDB2777),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFDB2777).withOpacity(0.4),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 60),
                            ) : null),
                  ),
                ),
              ),
            ),
          ],
        );
      }
    }

    // Case 3: Loading / Initializing / No Cover / Evicted
    // Use GestureDetector to allow manual reload if it got stuck or evicted
    final isLoading = _initializingPath == widget.videoPath;

    return Container(
      color: Colors.black,
      constraints: const BoxConstraints.expand(),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          // Manual revival
          _initializePlayer(forcePlay: true);
        },
        child: Center(
          child: isLoading
              ? const CircularProgressIndicator(color: Color(0xFFDB2777))
              : const Icon(Icons.play_circle_outline, color: Colors.white, size: 40), // Show Play if idle (evicted)
        ),
      ),
    );
  }
}


class AudioPlayerWidget extends StatefulWidget {
  final String audioPath;
  final String? coverPath;
  final bool autoPlay;
  final VoidCallback? onFinished;
  final VoidCallback? onAudioTap; // Callback for manual interaction
  final bool showCoverBackground; // Control background image display
  final Color? backgroundColor; // Control container background color
  final bool showEnlargeButton;
  final bool showInfoButton;
  final AudioPlayer? controller; // External controller

  const AudioPlayerWidget({
    super.key,
    required this.audioPath,
    this.coverPath,
    this.autoPlay = true,
    this.onFinished,
    this.onAudioTap,
    this.showCoverBackground = true,
    this.backgroundColor,
    this.showEnlargeButton = true,
    this.showInfoButton = true,
    this.controller,
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  late AudioPlayer _audioPlayer;
  bool _hasError = false;
  bool _isPlaying = false;
  final bool _isExpanded = false;
  final double _currentVolume = 1.0;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  String? _fileSize;

  Future<void> _calculateFileSize() async {
    try {
      if (widget.audioPath.startsWith('http')) {
        _fileSize = mounted ? context.tr.stream : "Stream";
      } else {
        final file = File(widget.audioPath);
        if (await file.exists()) {
          final bytes = await file.length();
          _fileSize = _formatBytes(bytes);
        }
      }
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Error size: $e");
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return "$bytes B";
    if (bytes < 1024 * 1024) return "${(bytes / 1024).toStringAsFixed(1)} KB";
    if (bytes < 1024 * 1024 * 1024) return "${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB";
    return "${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB";
  }

  @override
  void initState() {
    super.initState();
    _audioPlayer = widget.controller ?? AudioPlayer();

    _audioPlayer.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });

    _audioPlayer.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero; // Reset position
        });

        if (widget.onFinished != null) {
          widget.onFinished!();
        }
      }
    });

    _initAudio();
    _calculateFileSize();
  }

  Source? _audioSource;
  bool _isInitialized = false;

  Future<void> _initAudio() async {
    debugPrint("AudioPlayerWidget: _initAudio called for ${widget.audioPath}");
    try {
      Source source;
      if (widget.audioPath.startsWith('http')) {
        source = UrlSource(widget.audioPath);
      } else {
        final file = File(widget.audioPath);
        if (!await file.exists()) {
          debugPrint("AudioPlayerWidget: Local file missing at ${widget.audioPath}");
          throw Exception("Local audio file missing");
        }
        source = DeviceFileSource(widget.audioPath);
      }

      _audioSource = source;
      if (mounted) setState(() => _hasError = false);

      if (widget.autoPlay) {
        debugPrint("AudioPlayerWidget: AutoPlay is TRUE in _initAudio. Calling play().");
        await _audioPlayer.play(source);
        if (mounted) setState(() => _isInitialized = true);
      } else {
        debugPrint("AudioPlayerWidget: AutoPlay is FALSE in _initAudio. Calling setSource().");
        await _audioPlayer.setSource(source);
      }
    } catch (e) {
      debugPrint("Audio Init Error: $e");
      if (mounted) setState(() => _hasError = true);
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _audioPlayer.dispose();
    }
    super.dispose();
  }

  bool _isManuallyPaused = false;

  @override
  void didUpdateWidget(AudioPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.audioPath != oldWidget.audioPath) {
      _audioPlayer.stop();
      _hasError = false;
      _isPlaying = false;
      _isManuallyPaused = false;
      _position = Duration.zero;
      _duration = Duration.zero;
      _initAudio();
      return;
    }

    if (widget.autoPlay != oldWidget.autoPlay) {
      if (widget.autoPlay && !_isPlaying && !_isManuallyPaused) {
        if (!_hasError) {
          if (!_isInitialized && _audioSource != null) {
            debugPrint("AudioPlayerWidget: AutoPlay enabled, first play with play(_audioSource).");
            _audioPlayer.play(_audioSource!);
            setState(() {
              _isInitialized = true;
              _isPlaying = true;
            });
          } else {
            debugPrint("AudioPlayerWidget: AutoPlay enabled, resuming.");
            _audioPlayer.resume();
            setState(() => _isPlaying = true);
          }
        }
      } else if (!widget.autoPlay && _isPlaying) {
        debugPrint("AudioPlayerWidget: AutoPlay disabled (visibility lost), pausing.");
        _audioPlayer.pause();
        setState(() => _isPlaying = false);
      }
    }
  }

  void _togglePlay() async {
    widget.onAudioTap?.call();
    if (_hasError) return;

    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
        if (mounted) setState(() {
          _isPlaying = false;
          _isManuallyPaused = true;
        });
      } else {
        // restart if finished
        if (_position >= _duration && _duration > Duration.zero) {
          await _audioPlayer.seek(Duration.zero);
        }

        if (!_isInitialized) {
          // source not loaded yet — play directly
          if (_audioSource != null) {
            await _audioPlayer.play(_audioSource!);
            if (mounted) setState(() => _isInitialized = true);
          } else {
            // re-init from scratch
            await _initAudio();
            return;
          }
        } else {
          // ← FIX: always use resume() once source is set
          await _audioPlayer.resume();
        }

        if (mounted) setState(() {
          _isPlaying = true;
          _isManuallyPaused = false;
        });
      }
    } catch (e) {
      debugPrint("Toggle Play Error: $e");
      // retry init on error
      if (mounted) {
        setState(() => _hasError = false);
        await _initAudio();
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  Widget _buildCover() {
    final isNetworkCover = widget.coverPath != null && widget.coverPath!.startsWith('http');
    final hasCover = widget.coverPath != null && widget.coverPath!.isNotEmpty;

    if (!hasCover) {
      return Container(
        width: double.infinity,
        height: _isExpanded ? 200 : 80,
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.music_note, color: Colors.grey, size: 50),
      );
    }

    return Container(
      width: double.infinity,
      height: _isExpanded ? 200 : 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        image: DecorationImage(
          image: isNetworkCover
              ? NetworkImage(widget.coverPath!)
              : FileImage(File(widget.coverPath!)) as ImageProvider,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
        ),
        child: Row(
          children: [
            const Icon(Icons.broken_image_outlined, color: Colors.grey),
            const SizedBox(width: 12),
            Text(context.tr.audioUnavailable, style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
          ],
        ),
      );
    }

    final hasCover = widget.coverPath != null && widget.coverPath!.isNotEmpty;
    ImageProvider? coverImage;
    if (hasCover) {
      if (widget.coverPath!.startsWith('http')) {
        coverImage = NetworkImage(widget.coverPath!);
      } else {
        coverImage = FileImage(File(widget.coverPath!));
      }
    }

    return Container(
      width: double.infinity,
      height: 200, // Fixed height to prevent distortion
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        image: (hasCover && widget.showCoverBackground) ? DecorationImage(
          image: coverImage!,
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.4), BlendMode.darken),
        ) : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), // Subtle glass effect
          child: Container(
            color: Colors.black.withOpacity(0.2),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isSmall = constraints.maxHeight < 190;
                final buttonSize = isSmall ? 54.0 : 70.0;
                final iconSize = isSmall ? 32.0 : 44.0;
                final bottomPadding = isSmall ? 8.0 : 16.0;

                return SafeArea(
                  child: Stack(
                    children: [
                      // 1. Info Button (Top Left)
                    if (widget.showInfoButton)
                      Positioned(
                        top: 12,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.info_outline, color: Colors.white70, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                _fileSize ?? context.tr.dots, 
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)
                              ),
                            ],
                          ),
                        ),
                      ),

                    // 2. Enlarge Button (Top Right)
                    if (widget.showEnlargeButton)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton(
                          icon: const Icon(Icons.fullscreen, color: Colors.white, size: 28),
                          onPressed: () {
                            final tracks = [{
                              'filePath': widget.audioPath,
                              'coverPath': widget.coverPath ?? '',
                              'title': context.tr.untitled,
                            }];

                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => FullScreenAudioPlayer(
                                audioPlayer: _audioPlayer,
                                tracks: tracks,
                                initialIndex: 0,
                              ),
                            ));
                          },
                        ),
                      ),

                    // 3. Play/Pause Button (Center)
                    Center(
                      child: GestureDetector(
                        onTap: _togglePlay,
                        child: Container(
                          width: buttonSize,
                          height: buttonSize * 0.8, // Rectangular aspect
                          decoration: BoxDecoration(
                            shape: BoxShape.rectangle,
                            borderRadius: BorderRadius.circular(16),
                            color: const Color(0xFFDB2777),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFDB2777).withOpacity(0.4),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, 
                            color: Colors.white, 
                            size: iconSize
                          ),
                        ),
                      ),
                    ),

                    // 4. Volume & Seek Bar (Bottom)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.fromLTRB(16, isSmall ? 10 : 20, 16, bottomPadding),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.8),
                            ],
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Seek Bar
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                thumbShape: RoundSliderThumbShape(enabledThumbRadius: isSmall ? 4 : 6),
                                trackHeight: isSmall ? 2 : 4,
                                overlayShape: RoundSliderOverlayShape(overlayRadius: isSmall ? 8 : 12),
                                activeTrackColor: const Color(0xFFDB2777),
                                inactiveTrackColor: Colors.white24,
                                thumbColor: Colors.white,
                              ),
                              child: Slider(
                                min: 0,
                                max: _duration.inMilliseconds.toDouble() > 0 ? _duration.inMilliseconds.toDouble() : 1.0,
                                value: _position.inMilliseconds.toDouble().clamp(0, _duration.inMilliseconds.toDouble() > 0 ? _duration.inMilliseconds.toDouble() : 1.0),
                                onChanged: (v) => _audioPlayer.seek(Duration(milliseconds: v.toInt())),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDuration(_position), 
                                    style: TextStyle(color: Colors.white70, fontSize: isSmall ? 9 : 11, fontWeight: FontWeight.bold)
                                  ),
                                  Text(
                                    _formatDuration(_duration), 
                                    style: TextStyle(color: Colors.white70, fontSize: isSmall ? 9 : 11, fontWeight: FontWeight.bold)
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
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}




class FullScreenAudioPlayer extends StatefulWidget {
  final AudioPlayer audioPlayer;
  final List<dynamic> tracks;
  final int initialIndex;
  final ValueChanged<int>? onTrackChanged;

  const FullScreenAudioPlayer({
    super.key,
    required this.audioPlayer,
    required this.tracks,
    required this.initialIndex,
    this.onTrackChanged,
  });

  @override
  State<FullScreenAudioPlayer> createState() => _FullScreenAudioPlayerState();
}

class _FullScreenAudioPlayerState extends State<FullScreenAudioPlayer> {
  Duration _position = Duration.zero;
  bool _isPlaying = false;
  double _currentVolume = 1.0;
  Duration _duration = Duration.zero;

  late int _currentIndex;
  bool _areControlsVisible = true;
  Timer? _hideTimer;

  void _startHideTimer() {
    _hideTimer?.cancel();
    if (_isPlaying) {
      _hideTimer = Timer(const Duration(seconds: 4), () {
        if (mounted && _isPlaying) {
          setState(() {
            _areControlsVisible = false;
          });
        }
      });
    }
  }

  void _toggleControls() {
    setState(() {
      _areControlsVisible = !_areControlsVisible;
    });
    if (_areControlsVisible && _isPlaying) {
      _startHideTimer();
    }
  }

  @override
  void initState() {
    super.initState();

    _currentIndex = widget.initialIndex;
    _isPlaying = widget.audioPlayer.state == PlayerState.playing;
    _areControlsVisible = true;
    _startHideTimer();

    _syncState();

    widget.audioPlayer.onPositionChanged.listen((p) {
      if(mounted) setState(() => _position = p);
    });

    widget.audioPlayer.onDurationChanged.listen((d) {
      if(mounted && d != Duration.zero) setState(() => _duration = d);
    });

    widget.audioPlayer.onPlayerStateChanged.listen((s) {
      if(mounted) {
        setState(() => _isPlaying = s == PlayerState.playing);
        _startHideTimer();
      }
    });

    widget.audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) _next();
    });
  }

  Future<void> _syncState() async {
    final p = await widget.audioPlayer.getCurrentPosition();
    final d = await widget.audioPlayer.getDuration();
    if (mounted) {
      setState(() {
        if (p != null) _position = p;
        if (d != null && d != Duration.zero) _duration = d;
      });
    }
  }

  String get _currentFileSize {
    // Placeholder: If tracks have size info
    return context.tr.unknown;
  }

  ImageProvider? get _currentCover {
    if (_currentIndex < 0 || _currentIndex >= widget.tracks.length) return null;
    final track = widget.tracks[_currentIndex];
    String? cover = track['coverPath'] ?? track['covers'] ?? track['image'];
    if (cover != null && cover.trim().isNotEmpty) {
      if (cover.startsWith('http')) return NetworkImage(cover);
      return FileImage(File(cover));
    }
    return null;
  }

  String get _currentTitle {
    if (_currentIndex < 0 || _currentIndex >= widget.tracks.length) return context.tr.untitled;
    final track = widget.tracks[_currentIndex];
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

  void _next() {
    if (_currentIndex < widget.tracks.length - 1) {
      setState(() {
        _currentIndex++;
      });
      widget.onTrackChanged?.call(_currentIndex);
      if (_areControlsVisible && _isPlaying) {
        _startHideTimer();
      }
    }
  }

  void _prev() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      widget.onTrackChanged?.call(_currentIndex);
      if (_areControlsVisible && _isPlaying) {
        _startHideTimer();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cover = _currentCover;
    final hasNext = _currentIndex < widget.tracks.length - 1;
    final hasPrev = _currentIndex > 0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Cover
            if (cover != null)
              Image(
                image: cover,
                fit: BoxFit.cover,
              )
            else
              Container(color: Colors.grey[900]),

            // Glass Overlay when controls are visible
            AnimatedOpacity(
              opacity: _areControlsVisible || !_isPlaying ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: IgnorePointer(
                ignoring: !_areControlsVisible && _isPlaying,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(color: Colors.black.withOpacity(0.4)),
                ),
              ),
            ),

            // Controls Layer
            AnimatedOpacity(
              opacity: _areControlsVisible || !_isPlaying ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: IgnorePointer(
                ignoring: !_areControlsVisible && _isPlaying,
                child: Stack(
                  children: [
                    // Close Button
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 10,
                      right: 16,
                      child: IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                             color: Colors.black.withOpacity(0.3), 
                             borderRadius: BorderRadius.circular(12), // Rectangular with rounded corners
                             shape: BoxShape.rectangle,
                          ),
                          child: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),

                    // Title & Album Info
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 80,
                      left: 20,
                      right: 20,
                      child: Column(
                        children: [
                          Text(
                            _currentTitle,
                            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Center playback controls
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            icon: Icon(Icons.skip_previous_rounded, color: hasPrev ? Colors.white : Colors.white38, size: 56),
                            onPressed: hasPrev ? _prev : null,
                          ),
                          GestureDetector(
                            onTap: () {
                              if (_isPlaying) {
                                widget.audioPlayer.pause();
                              } else {
                                widget.audioPlayer.resume();
                              }
                            },
                            child: Container(
                              width: 90,
                              height: 76, // Rectangular aspect
                              decoration: BoxDecoration(
                                shape: BoxShape.rectangle,
                                borderRadius: BorderRadius.circular(24),
                                color: const Color(0xFFDB2777),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFDB2777).withOpacity(0.4),
                                    blurRadius: 25,
                                    spreadRadius: 3,
                                  ),
                                ],
                              ),
                              child: Icon(
                                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, 
                                color: Colors.white, 
                                size: 64
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.skip_next_rounded, color: hasNext ? Colors.white : Colors.white38, size: 56),
                            onPressed: hasNext ? _next : null,
                          ),
                        ],
                      ),
                    ),

                    // Volume & Seek Bar
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).padding.bottom + 20), // Dynamic bottom padding
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
                            // Volume slider
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                const Icon(Icons.volume_up_rounded, color: Colors.white70, size: 20),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 120,
                                  child: SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4), 
                                      trackHeight: 2,
                                      activeTrackColor: Colors.white,
                                      inactiveTrackColor: Colors.white24,
                                      thumbColor: Colors.white,
                                    ),
                                    child: Slider(
                                      value: _currentVolume,
                                      min: 0, max: 1,
                                      onChanged: (v) {
                                        setState(() => _currentVolume = v);
                                        widget.audioPlayer.setVolume(v);
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Seek bar
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
                                min: 0,
                                max: _duration.inMilliseconds.toDouble() > 0 ? _duration.inMilliseconds.toDouble() : 1.0,
                                value: _position.inMilliseconds.toDouble().clamp(0.0, _duration.inMilliseconds.toDouble() > 0 ? _duration.inMilliseconds.toDouble() : 1.0),
                                onChanged: (v) {
                                  widget.audioPlayer.seek(Duration(milliseconds: v.toInt()));
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDuration(_position), 
                                    style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)
                                  ),
                                  Text(
                                    _formatDuration(_duration), 
                                    style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)
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
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }
}


class FullScreenVideoPlayer extends StatefulWidget {
  final List<dynamic> tracks;
  final int initialIndex;
  final ValueChanged<int>? onTrackChanged;
  final Duration? startPosition;

  const FullScreenVideoPlayer({
    super.key,
    required this.tracks,
    required this.initialIndex,
    this.onTrackChanged,
    this.startPosition,
  });

  @override
  State<FullScreenVideoPlayer> createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<FullScreenVideoPlayer> {
  late int _currentIndex;
  VideoPlayerController? _videoController;
  bool _isPlaying = false;
  bool _areControlsVisible = false;
  Timer? _hideTimer;
  double _volume = 1.0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _areControlsVisible = true;
    _startHideTimer();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    if (_isPlaying) {
      _hideTimer = Timer(const Duration(seconds: 4), () {
        if (mounted && _isPlaying) {
          setState(() {
            _areControlsVisible = false;
          });
        }
      });
    }
  }

  void _toggleControls() {
    setState(() {
      _areControlsVisible = !_areControlsVisible;
    });
    if (_areControlsVisible && _isPlaying) {
      _startHideTimer();
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _videoController?.removeListener(_videoListener);
    super.dispose();
  }

  void _onControllerCreated(VideoPlayerController controller) {
    _videoController = controller;
    _videoController!.addListener(_videoListener);
    if (mounted) setState(() => _isPlaying = _videoController!.value.isPlaying);
  }

  void _videoListener() {
    if (!mounted || _videoController == null) return;
    if (_isPlaying != _videoController!.value.isPlaying) {
      setState(() => _isPlaying = _videoController!.value.isPlaying);
      if (_isPlaying && _areControlsVisible) {
        _startHideTimer();
      }
    }
  }

  void _next() {
    if (_currentIndex < widget.tracks.length - 1) {
      setState(() {
        _currentIndex++;
      });
      widget.onTrackChanged?.call(_currentIndex);
    }
  }

  void _prev() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      widget.onTrackChanged?.call(_currentIndex);
    }
  }

  BoxFit _fit = BoxFit.contain;

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
    final track = widget.tracks[_currentIndex];
    final videoPath = track['filePath'] ?? track['url'] ?? track['videoPath'] ?? track['mediaPath'] ?? '';
    // Determine cover path
    String? cover = track['coverPath'] ?? track['covers'] ?? track['image'] ?? track['thumbnail'];
    
    // Calculate hasNext/hasPrev for gesture logic logic (visuals removed)
    final hasNext = _currentIndex < widget.tracks.length - 1;
    final hasPrev = _currentIndex > 0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity! < 0 && hasNext) {
            _next();
          } else if (details.primaryVelocity! > 0 && hasPrev) {
            _prev();
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Video Player
            VideoPlayerWidget(
              key: ValueKey("$_currentIndex-$_fit"), // Force fresh initialization
              videoPath: videoPath,
              coverPath: cover ?? '',
              autoPlay: true,
              showControls: false,
              allowCustomControls: false, // Fix duplicate seek bar
              looping: false,
              fit: _fit,
              onFinished: hasNext ? _next : null,
              onControllerCreated: _onControllerCreated,
              startPosition: _currentIndex == widget.initialIndex ? widget.startPosition : null,
              onVideoTap: _toggleControls,
            ),

          // Close Button (Top Right)
          Positioned(
            top: MediaQuery.of(context).padding.top + 30,
            right: 18,
            child: AnimatedOpacity(
              opacity: _areControlsVisible || !_isPlaying ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: IgnorePointer(
                ignoring: !_areControlsVisible && _isPlaying,
                child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                 IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      shape: BoxShape.rectangle,
                    ),
                    child: Icon(_fit == BoxFit.contain ? Icons.transform : Icons.fit_screen, color: Colors.white, size: 24),
                  ),
                  onPressed: () {
                     setState(() {
                       _fit = _fit == BoxFit.contain ? BoxFit.cover : BoxFit.contain;
                     });
                     _startHideTimer();
                  },
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      shape: BoxShape.rectangle,
                    ),
                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
      ),

          // Title Overlay (Top)
          Positioned(
            top: MediaQuery.of(context).padding.top + 80, // Moved down to avoid overlap
            left: 20,
            right: 20,
            child: AnimatedOpacity(
              opacity: _areControlsVisible || !_isPlaying ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Text(
                _getDisplayTitle(track),
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black, blurRadius: 10)]),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Center Play/Pause Control (Swap/Skip buttons removed)
          Center(
            child: GestureDetector(
                  onTap: () {
                    if (_isPlaying) {
                      _videoController?.pause();
                    } else {
                      _videoController?.play();
                      _startHideTimer(); 
                    }
                  },
                  child: AnimatedOpacity(
                    opacity: _areControlsVisible || !_isPlaying ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                      decoration: BoxDecoration(
                        shape: BoxShape.rectangle,
                        borderRadius: BorderRadius.circular(24),
                        color: const Color(0xFFDB2777),
                        boxShadow: [BoxShadow(color: const Color(0xFFDB2777).withOpacity(0.4), blurRadius: 20, spreadRadius: 2)],
                      ),
                      child: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 60),
                    ),
                  ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              opacity: _areControlsVisible || !_isPlaying ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: IgnorePointer(
                ignoring: !_areControlsVisible && _isPlaying,
                child: Container(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).padding.bottom + 20), // Dynamic safe area
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
                      stops: const [0.0, 1.0],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Volume
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                           const Icon(Icons.volume_up_rounded, color: Colors.white70, size: 20),
                           const SizedBox(width: 8),
                           SizedBox(
                             width: 100,
                             child: SliderTheme(
                               data: SliderTheme.of(context).copyWith(thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5), trackHeight: 2),
                               child: Slider(
                                 value: _volume,
                                 min: 0, max: 1,
                                 activeColor: Colors.white,
                                 inactiveColor: Colors.white24,
                                 onChanged: (v) {
                                    setState(() => _volume = v);
                                    _videoController?.setVolume(v);
                                 },
                               ),
                             ),
                           ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Seek Bar
                      if (_videoController != null && _videoController!.value.isInitialized)
                        SizedBox(
                          height: 14,
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 0),
                              trackHeight: 4,
                              overlayShape: SliderComponentShape.noOverlay,
                              trackShape: const RectangularSliderTrackShape(),
                              activeTrackColor: const Color(0xFFDB2777),
                              inactiveTrackColor: Colors.white24,
                            ),
                            child: Slider(
                              min: 0,
                              max: _videoController!.value.duration.inMilliseconds.toDouble().clamp(1.0, double.infinity).toDouble(),
                              value: _videoController!.value.position.inMilliseconds.toDouble().clamp(0.0, _videoController!.value.duration.inMilliseconds.toDouble().clamp(1.0, double.infinity)).toDouble(),
                              onChanged: (v) {
                                _videoController?.seekTo(Duration(milliseconds: v.toInt()));
                              },
                            ),
                          ),
                        ),
                      if (_videoController != null && _videoController!.value.isInitialized)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "${_videoController!.value.position.inMinutes}:${(_videoController!.value.position.inSeconds % 60).toString().padLeft(2, '0')}",
                                style: const TextStyle(color: Colors.white60, fontSize: 12),
                              ),
                              Text(
                                "${_videoController!.value.duration.inMinutes}:${(_videoController!.value.duration.inSeconds % 60).toString().padLeft(2, '0')}",
                                style: const TextStyle(color: Colors.white60, fontSize: 12),
                              ),
                            ],
                          ),
                        )
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
}
