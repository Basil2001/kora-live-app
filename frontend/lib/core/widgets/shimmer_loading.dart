import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../app/theme/app_theme.dart';

class ShimmerLoading extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const ShimmerLoading({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppTheme.darkSurfaceCard,
      highlightColor: AppTheme.borderGrey,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppTheme.darkSurfaceCard,
          borderRadius: borderRadius ?? BorderRadius.circular(12),
        ),
      ),
    );
  }
}
