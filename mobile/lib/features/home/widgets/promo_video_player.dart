import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Plays the gym's promo video file (uploaded by the admin to Firebase
/// Storage) as a silent, looping, chrome-free background clip. Being a
/// plain MP4 the admin owns, there are no embedding restrictions or
/// third-party branding to work around.
class PromoVideoPlayer extends StatefulWidget {
  const PromoVideoPlayer({super.key, required this.url});
  final String url;
  @override
  State<PromoVideoPlayer> createState() => _PromoVideoPlayerState();
}

class _PromoVideoPlayerState extends State<PromoVideoPlayer> {
  late final controller = VideoPlayerController.networkUrl(
    Uri.parse(widget.url),
  );
  bool ready = false;

  @override
  void initState() {
    super.initState();
    controller
      ..setLooping(true)
      ..setVolume(0)
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => ready = true);
        controller.play();
      });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: AspectRatio(
      aspectRatio: ready ? controller.value.aspectRatio : 16 / 9,
      child: ready
          ? AbsorbPointer(child: VideoPlayer(controller))
          : const ColoredBox(color: Colors.black),
    ),
  );
}
