import '../../../../core/theme/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/resources/app_sizes.dart';

/// Plays a directly-hosted video file (e.g. an mp4 URL) as a silent,
/// looping, chrome-free background clip. Used as the fallback for
/// [promoVideoUrl] values that aren't a YouTube link — some YouTube
/// videos block embedded playback (a Content ID claim on the audio is
/// the usual cause) regardless of what any app does, so a direct file
/// URL sidesteps that restriction entirely.
class DirectVideoBackgroundPlayer extends StatefulWidget {
  const DirectVideoBackgroundPlayer({super.key, required this.url});
  final String url;
  @override
  State<DirectVideoBackgroundPlayer> createState() =>
      _DirectVideoBackgroundPlayerState();
}

class _DirectVideoBackgroundPlayerState
    extends State<DirectVideoBackgroundPlayer>
    with WidgetsBindingObserver {
  late final controller = VideoPlayerController.networkUrl(
    Uri.parse(widget.url),
  );
  bool ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    controller.initialize().then((_) {
      if (!mounted) return;
      controller
        ..setVolume(0)
        ..setLooping(true)
        ..play();
      setState(() => ready = true);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // A locked screen or a quick app switch pauses playback — without this,
    // the banner would stay frozen on whatever frame it paused on until the
    // widget rebuilds from scratch.
    if (!ready) return;
    if (state == AppLifecycleState.resumed) {
      controller.play();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(AppSizes.radius16),
    child: AspectRatio(
      aspectRatio: ready ? controller.value.aspectRatio : 16 / 9,
      child: ready
          ? VideoPlayer(controller)
          : ColoredBox(color: context.palette.background),
    ),
  );
}
