import 'package:aureascan_app/utils/app_colors.dart';
import 'package:aureascan_app/widgets/task_processing_loading_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ProcessingImageOverlay extends StatelessWidget {
  final String? imageUrl;
  final double? height;
  final double? aspectRatio;
  final bool showOverlay;
  final String overlayMessage;
  final BorderRadius borderRadius;
  final BoxFit fit;

  const ProcessingImageOverlay({
    super.key,
    required this.imageUrl,
    this.height = 220,
    this.aspectRatio,
    this.showOverlay = false,
    this.overlayMessage = 'Processando...',
    this.borderRadius = const BorderRadius.all(Radius.circular(18)),
    this.fit = BoxFit.cover,
  }) : assert(height != null || aspectRatio != null,
            'Either height or aspectRatio must be provided');

  @override
  Widget build(BuildContext context) {
    final imageContent = Stack(
      fit: StackFit.expand,
      children: [
        if (imageUrl != null)
          ClipRRect(
            borderRadius: borderRadius,
            child: CachedNetworkImage(
              imageUrl: imageUrl!,
              fit: fit,
              placeholder: (context, url) => Container(
                color: AppColors.boderGray,
                child: const Center(
                  child: DotSpinner(
                    activeColor: Colors.black,
                    inactiveColor: Colors.white,
                    dotCount: 12,
                    dotSize: 8.0,
                    radius: 40.0,
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: AppColors.boderGray,
                child: const Center(
                  child: Icon(
                    Icons.error_outline,
                    color: AppColors.textSecondary,
                    size: 40,
                  ),
                ),
              ),
            ),
          )
        else
          Container(
            color: AppColors.boderGray,
            child: const Center(
              child: Icon(
                Icons.image_not_supported_outlined,
                color: AppColors.textSecondary,
                size: 48,
              ),
            ),
          ),
        if (showOverlay)
          Container(
            color: Colors.black.withValues(alpha: 0.55),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.4),
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                  ),
                  padding: const EdgeInsets.all(18),
                  child: const DotSpinner(
                    activeColor: Colors.black,
                    inactiveColor: Colors.white,
                    dotCount: 12,
                    dotSize: 8.0,
                    radius: 40.0,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  overlayMessage,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Isso pode levar alguns segundos',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
      ],
    );

    Widget sizedContent;
    if (aspectRatio != null) {
      sizedContent = AspectRatio(
        aspectRatio: aspectRatio!,
        child: imageContent,
      );
    } else {
      sizedContent = SizedBox(
        width: double.infinity,
        height: height,
        child: imageContent,
      );
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: sizedContent,
    );
  }
}
