import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

/// Extracts an 11-character YouTube video id from any common URL shape
/// (watch?v=, youtu.be/, embed/). Returns null if none is found.
String? extractYoutubeId(String url) {
  for (final pattern in [
    RegExp(r'(?:v=|/)([a-zA-Z0-9_-]{11})(?:$|[?&])'),
    RegExp(r'youtu\.be/([a-zA-Z0-9_-]{11})'),
  ]) {
    final match = pattern.firstMatch(url);
    if (match != null) return match.group(1);
  }
  return null;
}

/// Plays a YouTube video as a silent, looping, chrome-free background
/// clip using the official IFrame Player API (via youtube_player_iframe,
/// which handles the origin/autoplay quirks a hand-rolled WebView embed
/// runs into). An [AbsorbPointer] keeps it purely decorative.
class YoutubeBackgroundPlayer extends StatefulWidget {
  const YoutubeBackgroundPlayer({super.key, required this.videoId});
  final String videoId;
  @override
  State<YoutubeBackgroundPlayer> createState() =>
      _YoutubeBackgroundPlayerState();
}

class _YoutubeBackgroundPlayerState extends State<YoutubeBackgroundPlayer>
    with WidgetsBindingObserver {
  late final controller = YoutubePlayerController.fromVideoId(
    videoId: widget.videoId,
    autoPlay: true,
    params: const YoutubePlayerParams(
      showControls: false,
      showFullscreenButton: false,
      mute: true,
      loop: true,
      enableJavaScript: true,
      strictRelatedVideos: true,
      showVideoAnnotations: false,
      playsInline: true,
    ),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // A locked screen or a quick app switch pauses the embedded webview's
    // playback — without this, the banner stays frozen on return.
    if (state == AppLifecycleState.resumed) {
      controller.playVideo();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: AspectRatio(
      aspectRatio: 16 / 9,
      child: AbsorbPointer(
        child: YoutubePlayer(controller: controller),
      ),
    ),
  );
}
