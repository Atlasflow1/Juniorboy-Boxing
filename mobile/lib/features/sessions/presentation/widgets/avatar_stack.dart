import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/resources/app_icons.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/app_icon.dart';

/// Small overlapping circles showing up to [maxVisible] member photos, with
/// a "+N" bubble for the rest — used on session cards to hint who's joined
/// without needing the full list (tapping the card shows full names).
class AvatarStack extends StatelessWidget {
  const AvatarStack({
    super.key,
    required this.photoUrls,
    required this.totalCount,
    this.maxVisible = 5,
    this.radius = 14,
  });

  final List<String> photoUrls;
  final int totalCount;
  final int maxVisible;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final visible = photoUrls.take(maxVisible).toList();
    final overflow = totalCount - visible.length;
    final step = radius * 1.3;
    return SizedBox(
      height: radius * 2,
      width: step * visible.length + (overflow > 0 ? step : 0) + (radius * 2 - step),
      child: Stack(
        children: [
          for (var i = 0; i < visible.length; i++)
            Positioned(
              left: i * step,
              child: CircleAvatar(
                radius: radius,
                backgroundColor: context.palette.background,
                child: CircleAvatar(
                  radius: radius - 2,
                  backgroundColor: context.palette.accentTint,
                  backgroundImage: CachedNetworkImageProvider(visible[i]),
                ),
              ),
            ),
          if (overflow > 0)
            Positioned(
              left: visible.length * step,
              child: CircleAvatar(
                radius: radius,
                backgroundColor: context.palette.background,
                child: CircleAvatar(
                  radius: radius - 2,
                  backgroundColor: context.palette.accent,
                  child: Text(
                    '+$overflow',
                    style: const TextStyle(fontSize: 10, color: Colors.white),
                  ),
                ),
              ),
            ),
          if (visible.isEmpty && overflow <= 0)
            Positioned(
              left: 0,
              child: CircleAvatar(
                radius: radius,
                backgroundColor: context.palette.accentTint,
                child: AppIcon(AppIcons.user, size: radius, color: context.palette.accent),
              ),
            ),
        ],
      ),
    );
  }
}
