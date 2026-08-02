import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:stleaf_trading/core/theme/app_colors.dart';

/// A reusable widget that displays a product image with:
/// - Disk + memory caching (loads instantly on repeat views)
/// - Shimmer placeholder while loading
/// - Fallback icon if no image or load fails
class CachedProductImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final double iconSize;

  const CachedProductImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.iconSize = 40,
  });

  @override
  Widget build(BuildContext context) {
    final Widget fallback = Center(
      child: Icon(
        Icons.eco_rounded,
        size: iconSize,
        color: AppColors.primary.withOpacity(0.3),
      ),
    );

    if (imageUrl == null || imageUrl!.isEmpty) {
      return _wrap(fallback);
    }

    return _wrap(
      CachedNetworkImage(
        imageUrl: imageUrl!,
        width: width,
        height: height,
        fit: fit,
        // Show shimmer while loading
        placeholder: (context, url) => const _ShimmerBox(),
        // Show fallback icon on error
        errorWidget: (context, url, error) => fallback,
        // Cache images for 7 days
        maxWidthDiskCache: 800,
        maxHeightDiskCache: 800,
      ),
    );
  }

  Widget _wrap(Widget child) {
    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: child);
    }
    return child;
  }
}

/// Shimmer loading placeholder
class _ShimmerBox extends StatefulWidget {
  const _ShimmerBox();

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => Container(
        color: AppColors.mint.withOpacity(_animation.value),
      ),
    );
  }
}
