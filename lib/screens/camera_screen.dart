import 'dart:io';
import 'dart:ui' as ui;
import 'package:aureascan_app/screens/analysis_selection_screen.dart';
import 'package:aureascan_app/state/analysis_state.dart';
import 'package:aureascan_app/utils/app_assets.dart';
import 'package:aureascan_app/widgets/task_processing_loading_screen.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  static const double _fourThreeRatio = 3 / 4;
  static const double _targetAspectRatio = 3 / 4; // 3:4 aspect ratio for crop
  static const double _cropScaleFactor = 0.95; // 5% smaller (95% of frame size)
  final _cameraKey = GlobalKey();
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _showInstructions = false;
  bool _isUploadDialogVisible = false;
  ui.Image? _overlayImage;
  bool _isOverlayImageLoaded = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _loadOverlayImage();
  }

  Future<void> _loadOverlayImage() async {
    try {
      // Try to load the face outline image from assets
      // If the image doesn't exist, we'll fall back to the CustomPaint overlay
      final ByteData data = await rootBundle.load(AppAssets.faceOutline);
      final Uint8List bytes = data.buffer.asUint8List();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();

      if (mounted) {
        setState(() {
          _overlayImage = frame.image;
          _isOverlayImageLoaded = true;
        });
      }
    } catch (e) {
      // Image not found or error loading - will use CustomPaint fallback
      if (mounted) {
        setState(() {
          _isOverlayImageLoaded = false;
        });
      }
    }
  }

  Future<void> _initializeCamera() async {
    if (!kIsWeb) {
      final cameraStatus = await Permission.camera.request();
      if (cameraStatus.isDenied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permissão de câmera negada')),
          );
        }
        return;
      }
      if (cameraStatus.isPermanentlyDenied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Permissão de câmera negada. Abra as configurações para habilitar.'),
              action: SnackBarAction(
                label: 'Configurações',
                onPressed: () => openAppSettings(),
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        }
        return;
      }
    }
    
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      final frontCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );
      _controller = CameraController(
        frontCamera,
        ResolutionPreset.ultraHigh,
        enableAudio: false,
        imageFormatGroup:
            kIsWeb ? ImageFormatGroup.bgra8888 : ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      if (!mounted) return;
      setState(() {
        _isCameraInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  // Get frame coordinates in screen space (rectangular boundary)
  Rect _getFrameRect() {
    final screenSize = MediaQuery.of(context).size;
    final width = screenSize.width;
    final height = screenSize.height;

    // Get camera preview aspect ratio if available
    double previewAspectRatio = _fourThreeRatio;

    // Create a rectangular frame matching camera preview aspect ratio
    // Using 70% of screen width for the frame width
    final frameWidth = width * 0.6;
    final frameHeight = frameWidth / previewAspectRatio;

    final centerX = width / 2;
    final centerY = height / 2 - height * 0.04;

    final frameLeft = centerX - (width * 0.3);
    final frameTop = centerY - (frameHeight * 3 / 5);

    return Rect.fromLTWH(frameLeft, frameTop, frameWidth, frameHeight);
  }

  img.Image _decodeAndNormalizeImage(Uint8List imageBytes) {
    final decodedImage = img.decodeImage(imageBytes);
    if (decodedImage == null) {
      throw Exception('Failed to decode image');
    }
    return img.bakeOrientation(decodedImage);
  }

  /// Calculate crop rect that is 5% smaller than frame and maintains 4:3 aspect ratio
  /// The crop rect is centered within the frame
  Rect _calculateCropRect(Rect frameRect) {
    // Calculate 95% of frame dimensions (5% smaller)
    final scaledWidth = frameRect.width * _cropScaleFactor;
    final scaledHeight = frameRect.height * _cropScaleFactor;

    // Calculate dimensions that maintain 4:3 aspect ratio
    double cropWidth, cropHeight;

    // Try to fit 4:3 within the scaled dimensions
    final widthForHeight = scaledHeight * _targetAspectRatio;
    final heightForWidth = scaledWidth / _targetAspectRatio;

    if (widthForHeight <= scaledWidth) {
      // Height is the limiting factor
      cropHeight = scaledHeight;
      cropWidth = widthForHeight;
    } else {
      // Width is the limiting factor
      cropWidth = scaledWidth;
      cropHeight = heightForWidth;
    }

    // Center the crop rect within the frame
    final frameCenter = frameRect.center;
    final cropLeft = frameCenter.dx - (cropWidth / 2);
    final cropTop = frameCenter.dy - (cropHeight / 2);

    return Rect.fromLTWH(cropLeft, cropTop, cropWidth, cropHeight);
  }

  Rect _convertScreenToImageCoordinates(
    Rect screenRect,
    Size screenSize,
    Size imageSize,
    CameraController controller,
  ) {
    Size previewSize = controller.value.previewSize ?? imageSize;
    final screenIsPortrait = screenSize.height >= screenSize.width;
    final previewIsPortrait = previewSize.height >= previewSize.width;

    if (screenIsPortrait != previewIsPortrait) {
      previewSize = Size(previewSize.height, previewSize.width);
    }

    final previewAspectRatio = previewSize.height / previewSize.width;
    final screenAspectRatio = screenSize.height / screenSize.width;

    double scaleX, scaleY;
    double offsetX = 0, offsetY = 0;

    if (previewAspectRatio > screenAspectRatio) {
      final scaledPreviewWidth = screenSize.height / previewAspectRatio;
      offsetX = (screenSize.width - scaledPreviewWidth) / 2;
      scaleX = imageSize.width / scaledPreviewWidth;
      scaleY = imageSize.height / screenSize.height;
    } else {
      final scaledPreviewHeight = screenSize.width * previewAspectRatio;
      offsetY = (screenSize.height - scaledPreviewHeight) / 2;
      scaleX = imageSize.width / screenSize.width;
      scaleY = imageSize.height / scaledPreviewHeight;
    }

    final imageLeft =
        ((screenRect.left - offsetX) * scaleX).clamp(0.0, imageSize.width);
    final imageTop =
        ((screenRect.top - offsetY) * scaleY).clamp(0.0, imageSize.height);
    final imageWidth =
        (screenRect.width * scaleX).clamp(0.0, imageSize.width - imageLeft);
    final imageHeight =
        (screenRect.height * scaleY).clamp(0.0, imageSize.height - imageTop);

    final finalWidth =
        imageWidth > 0 ? imageWidth : imageSize.width - imageLeft;
    final finalHeight =
        imageHeight > 0 ? imageHeight : imageSize.height - imageTop;

    return Rect.fromLTWH(
      imageLeft,
      imageTop,
      finalWidth.clamp(0.0, imageSize.width - imageLeft),
      finalHeight.clamp(0.0, imageSize.height - imageTop),
    );
  }

  Future<({Uint8List bytes, double aspectRatio})> _cropImageToFrame(
    String imagePath,
    Rect frameRect,
    Size screenSize,
  ) async {
    final imageBytes = await File(imagePath).readAsBytes();
    final originalImage = _decodeAndNormalizeImage(imageBytes);
    final cameraHeight = _cameraKey.currentContext!.size!.height;
    final screenHeight = screenSize.height;
    // Crop to the calculated rect with 4:3 aspect ratio
    final croppedImage = img.copyCrop(
      originalImage,
      x: (frameRect.left * originalImage.width / screenSize.width).toInt(),
      y: ((frameRect.top + cameraHeight / 2 - screenHeight / 2) *
              originalImage.height /
              cameraHeight)
          .toInt(),
      width: (frameRect.width * originalImage.width / screenSize.width).toInt(),
      height: (frameRect.height * originalImage.height / cameraHeight).toInt(),
    );

    // Encode as JPG
    final bytes = Uint8List.fromList(img.encodeJpg(croppedImage, quality: 90));

    return (bytes: bytes, aspectRatio: _targetAspectRatio);
  }

  Future<({Uint8List bytes, double aspectRatio})> _cropImageToFrameWeb(
    Uint8List imageBytes,
    Rect frameRect,
    Size screenSize,
  ) async {
    final originalImage = _decodeAndNormalizeImage(imageBytes);

    final imageSize =
        Size(originalImage.width.toDouble(), originalImage.height.toDouble());

    // Calculate crop rect that is 5% smaller than frame and maintains 4:3 aspect ratio
    final cropRect = _calculateCropRect(frameRect);

    // Convert crop rect from screen to image coordinates
    final imageCropRect = _convertScreenToImageCoordinates(
      cropRect,
      screenSize,
      imageSize,
      _controller!,
    );

    // Crop to the calculated rect with 4:3 aspect ratio
    final croppedImage = img.copyCrop(
      originalImage,
      x: imageCropRect.left.toInt().clamp(0, originalImage.width),
      y: imageCropRect.top.toInt().clamp(0, originalImage.height),
      width: imageCropRect.width
          .toInt()
          .clamp(1, originalImage.width - imageCropRect.left.toInt()),
      height: imageCropRect.height
          .toInt()
          .clamp(1, originalImage.height - imageCropRect.top.toInt()),
    );

    // Use 4:3 aspect ratio
    const aspectRatio = _targetAspectRatio;

    // Encode as JPG
    final bytes = Uint8List.fromList(img.encodeJpg(croppedImage, quality: 90));

    return (bytes: bytes, aspectRatio: aspectRatio);
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    // Show loading screen immediately when capture button is clicked
    _showUploadLoadingScreen();

    final analysisState = Provider.of<AnalysisState>(context, listen: false);
    final screenSize = MediaQuery.of(context).size;
    final frameRect = _getFrameRect();

    try {
      final XFile image = await _controller!.takePicture();
      if (kIsWeb) {
        final uncroppedBytes = await image.readAsBytes();
        // Store uncropped image for display purposes only
        analysisState.setUncroppedImage(bytes: uncroppedBytes);
        // Crop the image - this returns the cropped bytes
        final croppedResult =
            await _cropImageToFrameWeb(uncroppedBytes, frameRect, screenSize);
        // Upload ONLY the cropped image
        await _processImageWeb(
            analysisState, croppedResult.bytes, croppedResult.aspectRatio);
      } else {
        // Store uncropped image path for display purposes only
        analysisState.setUncroppedImage(path: image.path);
        // Crop the image - this returns the cropped bytes
        final croppedResult =
            await _cropImageToFrame(image.path, frameRect, screenSize);
        print('Cropped image aspectRatio: ${croppedResult.aspectRatio}');
        print('Cropped image bytes: ${croppedResult.bytes.length}');
        // Create temporary file with cropped image
        final tempFile = File('${image.path}_cropped.jpg');
        await tempFile.writeAsBytes(croppedResult.bytes);
        // Upload ONLY the cropped image
        await _processImage(
            analysisState, tempFile.path, croppedResult.aspectRatio);
      }
    } catch (e) {
      if (mounted) {
        _hideUploadLoadingScreen();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao capturar foto: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showUploadLoadingScreen() {
    if (!mounted || _isUploadDialogVisible) return;

    _isUploadDialogVisible = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (context) => const TaskProcessingLoadingScreen(
        message: 'Enviando imagem...',
        subtitle: 'Aguarde enquanto processamos',
      ),
    ).whenComplete(() => _isUploadDialogVisible = false);
  }

  void _hideUploadLoadingScreen() {
    if (!mounted || !_isUploadDialogVisible) return;

    Navigator.of(context, rootNavigator: true).pop();
  }

  Future<void> _processImageWeb(
      AnalysisState analysisState, Uint8List bytes, double aspectRatio) async {
    _showUploadLoadingScreen();

    try {
      // Upload ONLY the cropped image bytes - this will throw an exception if status code is not 200/201
      await analysisState.uploadFile(bytes,
          filename: 'image.jpg', aspectRatio: aspectRatio);

      // If we reach here, upload was successful (200/201 status code)
      // Ensure state is fully updated before navigating
      await Future.delayed(const Duration(milliseconds: 100));

      // Close loading screen first
      _hideUploadLoadingScreen();

      // Then navigate to analysis selection screen
      if (mounted) {
        // Verify fileUrl is set before navigation
        final fileUrl = analysisState.fileUrl;
        if (fileUrl != null && fileUrl.isNotEmpty) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
                builder: (context) => const AnalysisSelectionScreen()),
          );
        } else {
          // If fileUrl is not set, wait a bit more and retry
          await Future.delayed(const Duration(milliseconds: 200));
          if (mounted &&
              analysisState.fileUrl != null &&
              analysisState.fileUrl!.isNotEmpty) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                  builder: (context) => const AnalysisSelectionScreen()),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Erro: URL da imagem não foi configurada. Tente novamente.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      // Upload failed - close loading screen and show error
      if (mounted) {
        _hideUploadLoadingScreen();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao processar imagem: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> pickImageFromGallery() async {
    final analysisState = Provider.of<AnalysisState>(context, listen: false);
    final ImagePicker picker = ImagePicker();
    // Use the rectangular frame boundary for cropping

    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );

      if (image != null) {
        // if (kIsWeb) {
        //   final uncroppedBytes = await image.readAsBytes();
        //   // Store uncropped image for display purposes only
        //   analysisState.setUncroppedImage(bytes: uncroppedBytes);
        //   // Crop the image - this returns the cropped bytes
        //   final croppedResult = await _cropImageUsingNormalizedRect(
        //       uncroppedBytes, normalizedRect);
        //   // Upload ONLY the cropped image
        //   await _processImageWeb(
        //       analysisState, croppedResult.bytes, croppedResult.aspectRatio);
        // } else {
        // Store uncropped image path for display purposes only
        analysisState.setUncroppedImage(path: image.path);
        final uncroppedBytes = await File(image.path).readAsBytes();
        // Create temporary file with cropped image
        final tempFile = File('${image.path}_cropped.jpg');
        await tempFile.writeAsBytes(uncroppedBytes);
        // Upload ONLY the cropped image
        await _processImage(analysisState, tempFile.path, 1.0);
        // }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao selecionar imagem: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _processImage(
      AnalysisState analysisState, String imagePath, double aspectRatio) async {
    _showUploadLoadingScreen();

    try {
      // Upload ONLY the cropped image file
      await analysisState.uploadFile(imagePath, aspectRatio: aspectRatio);

      // Ensure state is fully updated before navigating
      await Future.delayed(const Duration(milliseconds: 100));

      // Close loading screen
      _hideUploadLoadingScreen();

      // Navigate to analysis selection screen
      if (mounted) {
        // Verify fileUrl is set before navigation
        final fileUrl = analysisState.fileUrl;
        if (fileUrl != null && fileUrl.isNotEmpty) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
                builder: (context) => const AnalysisSelectionScreen()),
          );
        } else {
          // If fileUrl is not set, wait a bit more and retry
          await Future.delayed(const Duration(milliseconds: 200));
          if (mounted &&
              analysisState.fileUrl != null &&
              analysisState.fileUrl!.isNotEmpty) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                  builder: (context) => const AnalysisSelectionScreen()),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Erro: URL da imagem não foi configurada. Tente novamente.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      // Close loading screen if still open
      if (mounted) {
        _hideUploadLoadingScreen();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao processar imagem: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final analysisState = context.watch<AnalysisState>();
    final isLoading = analysisState.isUploading ||
        analysisState.isProcessingSkin ||
        analysisState.isProcessingRatio;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_isCameraInitialized && _controller != null)
            // AspectRatio(
            //   aspectRatio: 9 / 16, // override display ratio
            //   child: CameraPreview(_controller!),
            // )
            Container(
              alignment: Alignment.center,
              height: double.infinity,
              width: double.infinity,
              child: CameraPreview(key: _cameraKey, _controller!),
            )
          else
            const Center(
              child: DotSpinner(
                activeColor: Colors.white,
                inactiveColor: Color(0xFF6B6B6B),
                dotCount: 12,
                dotSize: 8.0,
                radius: 40.0,
              ),
            ),
          // Face outline overlay for face alignment
          if (_isCameraInitialized)
            Positioned.fill(
              child: CustomPaint(
                painter: _FaceFrameOverlayPainter(
                  frameRect: _getFrameRect(),
                  overlayImage: _overlayImage,
                  useImageOverlay: _isOverlayImageLoaded,
                ),
              ),
            ),
          // Top smiley and instruction
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                const Icon(Icons.emoji_emotions_outlined,
                    color: Colors.white, size: 36),
                const SizedBox(height: 12),
                Text(
                  'Tire sua foto de vista frontal',
                  style: Theme.of(context).textTheme.labelLarge,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          // Info button (top left)
          Positioned(
            top: 60,
            left: 24,
            child: IconButton(
              icon:
                  const Icon(Icons.info_outline, color: Colors.white, size: 28),
              onPressed: () => setState(() => _showInstructions = true),
            ),
          ),
          // Gallery button (top right)
          Positioned(
            top: 60,
            right: 24,
            child: IconButton(
              icon: const Icon(Icons.photo_library,
                  color: Colors.white, size: 32),
              onPressed: isLoading ? null : pickImageFromGallery,
            ),
          ),
          // Tip box below frame
          if (_isCameraInitialized)
            Positioned(
              top: (MediaQuery.of(context).size.height / 2) +
                  (MediaQuery.of(context).size.width * 0.70 / 2) +
                  20,
              left: 24,
              right: 24,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Dica: enquadre a face na moldura para garantir uma distância adequada e padronizar suas fotos.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Instruction sheet
          if (_showInstructions)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => _showInstructions = false),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.5),
                  child: DraggableScrollableSheet(
                    initialChildSize: 0.75,
                    minChildSize: 0.5,
                    maxChildSize: 0.95,
                    builder: (sheetContext, scrollController) {
                      return _buildInstructionSheet(
                          sheetContext, scrollController);
                    },
                  ),
                ),
              ),
            ),
          // Camera button and progress bar
          Positioned(
            bottom: 4,
            left: 0,
            right: 0,
            child: Column(
              children: [
                GestureDetector(
                  onTap: isLoading ? null : _takePicture,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isLoading ? Colors.grey : Colors.white,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Center(
                      child: isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.camera_alt,
                              color: Colors.black, size: 40),
                    ),
                  ),
                ),
                // Progress bar
                Container(
                  margin: const EdgeInsets.only(top: 24),
                  width: 120,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: isLoading ? 0.7 : 1.0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(3),
                      ),
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

  Widget _buildInstructionSheet(
      BuildContext sheetContext, ScrollController scrollController) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Como tirar a foto perfeita',
                style: Theme.of(sheetContext).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _showInstructions = false),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Critical warning
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange[700]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Importante: O rosto deve ocupar mais de 60% da largura da imagem',
                    style: TextStyle(
                      color: Colors.orange[900],
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Recommendations
                  _buildInstructionItem(
                    Icons.check_circle,
                    Colors.green,
                    'Recomendações',
                    [
                      'Rosto claro e virado para frente',
                      'Cabelo preso ou puxado para trás',
                      'Ambiente bem iluminado',
                      'Olhe diretamente para a câmera',
                      'Mantenha o rosto centralizado',
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Avoid
                  _buildInstructionItem(
                    Icons.cancel,
                    Colors.red,
                    'Evite',
                    [
                      'Foto de perfil (lado)',
                      'Cabelo cobrindo ombros ou rosto',
                      'Mãos cobrindo o rosto',
                      'Óculos (se possível)',
                      'Maquiagem (para resultados mais precisos)',
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Action button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => setState(() => _showInstructions = false),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Entendi, vamos começar'),
            ),
          ),
          SizedBox(height: MediaQuery.of(sheetContext).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(
      IconData icon, Color color, String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(left: 28, bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: TextStyle(color: color, fontSize: 18)),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(fontSize: 14, height: 1.5),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}

// Face frame overlay painter with image support
class _FaceFrameOverlayPainter extends CustomPainter {
  final Rect frameRect;
  final ui.Image? overlayImage;
  final bool useImageOverlay;

  _FaceFrameOverlayPainter({
    required this.frameRect,
    this.overlayImage,
    this.useImageOverlay = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Draw dark overlay outside rectangular frame
    final overlayPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    // Draw four rectangles around the frame
    // Top
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width, frameRect.top),
      overlayPaint,
    );
    // Bottom
    canvas.drawRect(
      Rect.fromLTWH(0, frameRect.bottom, width, height - frameRect.bottom),
      overlayPaint,
    );
    // Left
    canvas.drawRect(
      Rect.fromLTWH(0, frameRect.top, frameRect.left, frameRect.height),
      overlayPaint,
    );
    // Right
    canvas.drawRect(
      Rect.fromLTWH(frameRect.right, frameRect.top, width - frameRect.right,
          frameRect.height),
      overlayPaint,
    );

    // If we have an image overlay, draw it
    if (useImageOverlay && overlayImage != null) {
      // Save canvas state
      canvas.save();

      // Clip to rectangular frame to ensure image doesn't overflow
      canvas.clipRect(frameRect);

      // Draw the image overlay with opacity for better visibility
      final imagePaint = Paint()
        ..colorFilter = ColorFilter.mode(
          Colors.white.withValues(alpha: 0.9),
          BlendMode.srcIn,
        )
        ..filterQuality = FilterQuality.high;

      // Scale the image to appear larger within the frame
      const scaleFactor = 1.15; // Increased to 115% of frame size
      // Center the image within the shadow boundary (frameRect)
      final frameCenterX = frameRect.left + (frameRect.width / 2);
      final frameCenterY = frameRect.top + (frameRect.height / 2);
      final scaledWidth = frameRect.width * scaleFactor;
      final scaledHeight = frameRect.height * scaleFactor;
      final scaledLeft = frameCenterX - (scaledWidth / 2);
      final scaledTop = frameCenterY - (scaledHeight / 2);
      final scaledRect =
          Rect.fromLTWH(scaledLeft, scaledTop, scaledWidth, scaledHeight);

      // Draw the image scaled larger than the rectangular frame
      canvas.drawImageRect(
        overlayImage!,
        Rect.fromLTWH(
          0,
          0,
          overlayImage!.width.toDouble(),
          overlayImage!.height.toDouble(),
        ),
        scaledRect,
        imagePaint,
      );

      // Restore canvas state
      canvas.restore();
    } else {
      // Draw white rectangular frame border
      final framePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;

      canvas.drawRect(frameRect, framePaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
