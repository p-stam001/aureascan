import 'package:aureascan_app/utils/app_colors.dart';
import 'package:aureascan_app/widgets/face_scan_loading_spinner.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AnalysisProcessingPlaceholder extends StatelessWidget {
  final String title;
  final String overlayMessage;
  final String? imageUrl;
  final Color backgroundColor;
  final Color headerColor;
  final Color titleColor;
  final Color overlayTint;

  const AnalysisProcessingPlaceholder({
    super.key,
    required this.title,
    required this.overlayMessage,
    required this.imageUrl,
    this.backgroundColor = Colors.black,
    this.headerColor = Colors.transparent,
    this.titleColor = Colors.white,
    this.overlayTint = Colors.black54,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          Positioned.fill(child: _buildBackgroundImage()),
          Positioned.fill(child: Container(color: overlayTint)),
          SafeArea(
            child: Column(
              children: [
                Container(
                  color: headerColor.withValues(alpha: 0.3),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: titleColor),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Expanded(
                        child: Text(
                          title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: titleColor,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const FaceScanLoadingSpinner(size: 220),
                        const SizedBox(height: 32),
                        Text(
                          overlayMessage,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Estamos preparando seus resultados. Isso pode levar alguns segundos.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundImage() {
    final fallback = _buildEmptyFallback();

    if (imageUrl == null || imageUrl!.isEmpty) {
      return fallback;
    }

    return CachedNetworkImage(
      imageUrl: imageUrl!,
      fit: BoxFit.cover,
      alignment: Alignment.center,
      imageBuilder: (context, provider) => DecoratedBox(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: provider,
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
        ),
      ),
      fadeInDuration: const Duration(milliseconds: 200),
      fadeOutDuration: const Duration(milliseconds: 200),
      placeholder: (_, __) => fallback,
      errorWidget: (_, __, ___) {
        // Log error for debugging
        debugPrint('Failed to load background image: $imageUrl');
        return fallback;
      },
      // Add cache key to ensure proper loading
      cacheKey: imageUrl,
    );
  }

  Widget _buildEmptyFallback() {
    return Container(
      color: AppColors.boderGray,
      child: const Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: AppColors.textSecondary,
          size: 48,
        ),
      ),
    );
  }
}
