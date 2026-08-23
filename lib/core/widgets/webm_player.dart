import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// A custom widget that plays local banner assets (.mp4, .webm, .webp, .png) in a loop
/// mimicking an animated banner for auth screens.
class WebmPlayer extends StatefulWidget {
  const WebmPlayer({
    super.key,
    required this.assetPath,
    this.fallbackAsset = 'assets/banner.png',
    this.width,
    this.height,
  });

  final String assetPath;
  final String? fallbackAsset;
  final double? width;
  final double? height;

  @override
  State<WebmPlayer> createState() => _WebmPlayerState();
}

class _WebmPlayerState extends State<WebmPlayer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  void _initPlayer() {
    final isVideo = widget.assetPath.endsWith('.webm') || widget.assetPath.endsWith('.mp4');
    if (!isVideo) {
      return;
    }

    _controller = VideoPlayerController.asset(widget.assetPath)
      ..initialize().then((_) {
        debugPrint('WebmPlayer: Initialized video player for ${widget.assetPath}');
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
          _controller?.setLooping(true);
          _controller?.play();
        }
      }).catchError((dynamic error) {
        if (mounted) {
          setState(() {
            _hasError = true;
          });
        }
      });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isVideo = widget.assetPath.endsWith('.webm') || widget.assetPath.endsWith('.mp4');

    if (!isVideo || !_isInitialized || _hasError) {
      final String imageAsset = isVideo ? (widget.fallbackAsset ?? 'assets/banner.png') : widget.assetPath;

      return Image.asset(
        imageAsset,
        width: widget.width,
        height: widget.height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('WebmPlayer: Failed to load image $imageAsset: $error');
          if (imageAsset != 'assets/banner.png') {
            return Image.asset(
              'assets/banner.png',
              width: widget.width,
              height: widget.height,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Image.asset(
                'assets/onboarding.png',
                width: widget.width,
                height: widget.height,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => SizedBox(
                  width: widget.width,
                  height: widget.height,
                ),
              ),
            );
          }
          return Image.asset(
            'assets/onboarding.png',
            width: widget.width,
            height: widget.height,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => SizedBox(
              width: widget.width,
              height: widget.height,
            ),
          );
        },
      );
    }

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: AspectRatio(
        aspectRatio: _controller!.value.aspectRatio,
        child: RepaintBoundary(
          child: VideoPlayer(_controller!),
        ),
      ),
    );
  }
}
