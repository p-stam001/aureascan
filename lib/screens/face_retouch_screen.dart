import 'dart:ui';

import 'package:aureascan_app/state/analysis_state.dart';
import 'package:aureascan_app/utils/app_colors.dart';
import 'package:aureascan_app/widgets/analysis_processing_placeholder.dart';
import 'package:aureascan_app/widgets/task_processing_loading_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FaceRetouchScreen extends StatefulWidget {
  const FaceRetouchScreen({super.key});

  @override
  State<FaceRetouchScreen> createState() => _FaceRetouchScreenState();
}

class _FaceRetouchScreenState extends State<FaceRetouchScreen> {
  bool _hasTriggeredAnalysis = false;
  double _sliderPosition = 0.5; // 0.0 = all "Antes", 1.0 = all "Depois"

  @override
  void initState() {
    super.initState();
    _triggerAnalysisIfNeeded();
  }

  void _triggerAnalysisIfNeeded() {
    final analysisState = Provider.of<AnalysisState>(context, listen: false);
    if (!analysisState.hasRetouchResults &&
        !analysisState.isProcessingRetouch &&
        analysisState.fileId != null &&
        !_hasTriggeredAnalysis) {
      _hasTriggeredAnalysis = true;
      analysisState.triggerRetouchAnalysis().catchError((e) {
        if (mounted) {
          debugPrint('Error triggering retouch analysis: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao iniciar análise: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      });
    } else if (analysisState.fileId == null) {
      // If fileId is null, show error
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Erro: Nenhuma imagem foi carregada. Por favor, volte e tente novamente.'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 4),
              ),
            );
            Navigator.of(context).pop();
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final analysisState = Provider.of<AnalysisState>(context);
    final retouchResults = analysisState.retouchResults;
    final isLoading = analysisState.isProcessingRetouch;
    final originalImageUrl = analysisState.fileUrl;

    if (isLoading) {
      return AnalysisProcessingPlaceholder(
        title: 'Retoque Facial',
        overlayMessage: 'Processando retoque facial...',
        imageUrl: analysisState.uncroppedImagePath,
        backgroundColor: const Color(0xFFF5E6E8),
      );
    }

    if (retouchResults == null || originalImageUrl == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      color: AppColors.boderGray,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Análise não encontrada',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Não foi possível carregar os resultados da análise.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Voltar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5E6E8), // Light pink background
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text(
                      'Retoque Facial',
                      textAlign: TextAlign.center,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                    ),
                  ),
                  const SizedBox(width: 48), // Balance the back button
                ],
              ),
            ),
            // Before/After comparison view
            Expanded(
              child: _BeforeAfterComparison(
                originalImageUrl: originalImageUrl,
                retouchedImageUrl: retouchResults.url,
                sliderPosition: _sliderPosition,
                onSliderPositionChanged: (position) {
                  setState(() {
                    _sliderPosition = position;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Before/After Comparison Widget
class _BeforeAfterComparison extends StatefulWidget {
  final String originalImageUrl;
  final String retouchedImageUrl;
  final double sliderPosition;
  final ValueChanged<double> onSliderPositionChanged;

  const _BeforeAfterComparison({
    required this.originalImageUrl,
    required this.retouchedImageUrl,
    required this.sliderPosition,
    required this.onSliderPositionChanged,
  });

  @override
  State<_BeforeAfterComparison> createState() => _BeforeAfterComparisonState();
}

class _BeforeAfterComparisonState extends State<_BeforeAfterComparison> {
  late double _currentSliderPosition;
  bool _isOriginalImageLoaded = false;
  bool _isRetouchedImageLoaded = false;

  @override
  void initState() {
    super.initState();
    _currentSliderPosition = widget.sliderPosition;
  }

  @override
  void didUpdateWidget(_BeforeAfterComparison oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sliderPosition != widget.sliderPosition) {
      _currentSliderPosition = widget.sliderPosition;
    }
    // Reset loading states if URLs changed
    if (oldWidget.originalImageUrl != widget.originalImageUrl) {
      _isOriginalImageLoaded = false;
    }
    if (oldWidget.retouchedImageUrl != widget.retouchedImageUrl) {
      _isRetouchedImageLoaded = false;
    }
  }

  void _updateSliderPosition(double position) {
    setState(() {
      _currentSliderPosition = position.clamp(0.0, 1.0);
    });
    widget.onSliderPositionChanged(_currentSliderPosition);
  }

  bool get _isLoading => !_isOriginalImageLoaded || !_isRetouchedImageLoaded;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final dividerX = screenWidth * _currentSliderPosition;

    return Stack(
      children: [
        // "Depois" (After) image - full screen
        Positioned.fill(
          child: _ImageWithLoadingTracker(
            imageUrl: widget.retouchedImageUrl,
            onImageLoaded: () {
              if (mounted) {
                setState(() {
                  _isRetouchedImageLoaded = true;
                });
              }
            },
            placeholder: Container(
              color: AppColors.boderGray,
            ),
            errorWidget: Container(
              color: AppColors.boderGray,
              child: const Center(
                child: Icon(Icons.error_outline,
                    size: 48, color: AppColors.textSecondary),
              ),
            ),
            fit: BoxFit.cover,
          ),
        ),
        // "Antes" (Before) image - clipped to left side
        Positioned(
          left: 0,
          top: 0,
          width: dividerX,
          bottom: 0,
          child: ClipRect(
            child: OverflowBox(
              maxWidth: screenWidth,
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: screenWidth,
                height: screenHeight,
                child: _ImageWithLoadingTracker(
                  imageUrl: widget.originalImageUrl,
                  onImageLoaded: () {
                    if (mounted) {
                      setState(() {
                        _isOriginalImageLoaded = true;
                      });
                    }
                  },
                  placeholder: Container(
                    color: AppColors.boderGray,
                  ),
                  errorWidget: Container(
                    color: AppColors.boderGray,
                    child: const Center(
                      child: Icon(Icons.error_outline,
                          size: 48, color: AppColors.textSecondary),
                    ),
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
        // Single centered loading spinner - shown when either image is loading
        if (_isLoading)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
              child: Container(
                color: Colors.black.withValues(alpha: 0.3),
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
            ),
          ),
        // Divider line
        Positioned(
          left: dividerX - 1,
          top: 0,
          bottom: 0,
          child: Container(
            width: 2,
            color: Colors.white,
          ),
        ),
        // Slider handle
        Positioned(
          left: dividerX - 20,
          top: screenHeight * 0.4,
          child: GestureDetector(
            onPanUpdate: (details) {
              final newPosition =
                  (details.globalPosition.dx / screenWidth).clamp(0.0, 1.0);
              _updateSliderPosition(newPosition);
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.swap_horiz,
                color: Colors.black87,
                size: 24,
              ),
            ),
          ),
        ),
        // "Antes" label top-left
        Positioned(
          top: 28,
          left: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 238, 238, 238)
                  .withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Antes',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
        // "Depois" label bottom-right
        Positioned(
          bottom: 28,
          right: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 238, 238, 238)
                  .withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Depois',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Widget that tracks image loading state
class _ImageWithLoadingTracker extends StatefulWidget {
  final String imageUrl;
  final VoidCallback onImageLoaded;
  final Widget placeholder;
  final Widget errorWidget;
  final BoxFit fit;

  const _ImageWithLoadingTracker({
    required this.imageUrl,
    required this.onImageLoaded,
    required this.placeholder,
    required this.errorWidget,
    required this.fit,
  });

  @override
  State<_ImageWithLoadingTracker> createState() =>
      _ImageWithLoadingTrackerState();
}

class _ImageWithLoadingTrackerState extends State<_ImageWithLoadingTracker> {
  bool _hasLoaded = false;
  bool _hasError = false;
  bool _callbackScheduled = false;

  @override
  void didUpdateWidget(_ImageWithLoadingTracker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _hasLoaded = false;
      _hasError = false;
      _callbackScheduled = false;
    }
  }

  void _markAsLoaded() {
    if (!_hasLoaded && mounted && !_callbackScheduled) {
      _callbackScheduled = true;
      // Wait one frame to ensure the image is actually painted
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_hasLoaded) {
          setState(() {
            _hasLoaded = true;
          });
          // Call onImageLoaded in next microtask to avoid build conflicts
          Future.microtask(() {
            if (mounted) {
              widget.onImageLoaded();
            }
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return widget.errorWidget;
    }

    // Use Image widget with CachedNetworkImageProvider to ensure
    // we're displaying the same image we tracked loading for
    return Image(
      image: CachedNetworkImageProvider(widget.imageUrl),
      fit: widget.fit,
      errorBuilder: (context, error, stackTrace) {
        if (!_hasError && mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_hasError) {
              setState(() {
                _hasError = true;
              });
              // Call onImageLoaded in next microtask to avoid build conflicts
              Future.microtask(() {
                if (mounted) {
                  widget.onImageLoaded();
                }
              });
            }
          });
        }
        return widget.errorWidget;
      },
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        // Only mark as loaded when we have a valid frame
        if (frame != null) {
          // Frame is ready, mark as loaded after ensuring it's painted
          _markAsLoaded();
          return child;
        } else {
          // No frame yet, show placeholder
          return widget.placeholder;
        }
      },
    );
  }
}
