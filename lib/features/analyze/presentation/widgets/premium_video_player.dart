import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class PremiumVideoPlayer extends StatefulWidget {
  final VideoPlayerController controller;
  final bool autoPlay;
  final bool showControls;

  const PremiumVideoPlayer({
    super.key,
    required this.controller,
    this.autoPlay = false,
    this.showControls = true,
  });

  @override
  State<PremiumVideoPlayer> createState() => _PremiumVideoPlayerState();
}

class _PremiumVideoPlayerState extends State<PremiumVideoPlayer> {
  bool _showOverlay = true;

  String _formatTime(double seconds) {
    int m = (seconds / 60).floor();
    int s = (seconds % 60).floor();
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    if (widget.autoPlay) {
      widget.controller.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.controller.value.isInitialized) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black12,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: widget.controller.value.aspectRatio,
            child: Stack(
              alignment: Alignment.center,
              children: [
                VideoPlayer(widget.controller),
                if (widget.showControls) _buildVideoOverlay(),
              ],
            ),
          ),
          if (widget.showControls) _buildControlHUD(),
        ],
      ),
    );
  }

  Widget _buildVideoOverlay() {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (widget.controller.value.isPlaying) {
            widget.controller.pause();
          } else {
            widget.controller.play();
          }
        });
      },
      child: Container(
        color: Colors.transparent,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: !widget.controller.value.isPlaying
              ? Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 40,
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ),
    );
  }

  Widget _buildControlHUD() {
    return Container(
      color: Colors.black87,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          ValueListenableBuilder(
            valueListenable: widget.controller,
            builder: (context, VideoPlayerValue value, child) {
              return Text(
                _formatTime(value.position.inSeconds.toDouble()),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              );
            },
          ),
          Expanded(
            child: VideoProgressIndicator(
              widget.controller,
              allowScrubbing: true,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              colors: const VideoProgressColors(
                playedColor: Color(0xFFE53935), // Scout Crimson
                bufferedColor: Colors.white24,
                backgroundColor: Colors.white12,
              ),
            ),
          ),
          Text(
            _formatTime(widget.controller.value.duration.inSeconds.toDouble()),
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
