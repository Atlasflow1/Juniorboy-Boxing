import '../theme/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../resources/app_sizes.dart';

/// Drop-in replacement for [Icon] that renders an SVG from [AppIcons].
/// Size and color fall back to the ambient [IconTheme], so it works inside
/// IconButton, ListTile, NavigationBar, etc.
class AppIcon extends StatelessWidget {
  const AppIcon(this.asset, {super.key, this.size, this.color});

  final String asset;
  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final s = size ?? theme.size ?? AppSizes.iconMedium;
    final c = color ?? theme.color ?? context.palette.textPrimary;
    return SvgPicture.asset(
      asset,
      width: s,
      height: s,
      colorFilter: ColorFilter.mode(c, BlendMode.srcIn),
    );
  }
}
