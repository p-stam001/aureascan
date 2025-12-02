import 'dart:io'
    if (dart.library.html) 'package:aureascan_app/utils/io_stub.dart' as io;
import 'package:aureascan_app/screens/facial_structure_screen.dart';
import 'package:aureascan_app/screens/skin_analysis_screen.dart';
import 'package:aureascan_app/screens/face_retouch_screen.dart';
import 'package:aureascan_app/state/analysis_state.dart';
import 'package:aureascan_app/utils/app_colors.dart';
import 'package:aureascan_app/widgets/processing_image_overlay.dart';
import 'package:aureascan_app/widgets/task_processing_loading_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

enum _AnalysisCardStatus { pending, processing, ready }

class AnalysisSelectionScreen extends StatefulWidget {
  const AnalysisSelectionScreen({super.key});

  @override
  State<AnalysisSelectionScreen> createState() =>
      _AnalysisSelectionScreenState();
}

class _AnalysisSelectionScreenState extends State<AnalysisSelectionScreen> {
  String? _precachedFileUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isLoading) {
      _loadData();
    } else {
      _precacheProcessingImage();
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    final analysisState = Provider.of<AnalysisState>(context, listen: false);

    // Wait for fileUrl to be available
    String? fileUrl = analysisState.fileUrl;
    int retryCount = 0;
    const maxRetries = 10;

    while ((fileUrl == null || fileUrl.isEmpty) && retryCount < maxRetries) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
      fileUrl = analysisState.fileUrl;
      retryCount++;
    }

    if (fileUrl == null || fileUrl.isEmpty) {
      // If fileUrl is still not available after retries, hide loading anyway
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    // Precache the image and wait for it to complete
    try {
      final imageProvider = CachedNetworkImageProvider(fileUrl);
      await precacheImage(imageProvider, context);
      _precachedFileUrl = fileUrl;
    } catch (e) {
      debugPrint('Error precaching image: $e');
      // Continue even if precaching fails
    }

    // Small delay to ensure everything is ready
    await Future.delayed(const Duration(milliseconds: 100));

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _precacheProcessingImage() {
    final analysisState = Provider.of<AnalysisState>(context, listen: false);
    final fileUrl = analysisState.fileUrl;
    if (fileUrl == null || fileUrl.isEmpty || fileUrl == _precachedFileUrl) {
      return;
    }
    _precachedFileUrl = fileUrl;
    precacheImage(CachedNetworkImageProvider(fileUrl), context);
  }

  @override
  Widget build(BuildContext context) {
    final analysisState = Provider.of<AnalysisState>(context);
    final fileUrl = analysisState.fileUrl;
    final uncroppedImagePath = analysisState.uncroppedImagePath;
    final isProcessingAny = analysisState.isProcessingRatio ||
        analysisState.isProcessingSkin ||
        analysisState.isProcessingRetouch;
    print('analysisState: ${analysisState.fileUrl}');
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          if (_isLoading)
            const TaskProcessingLoadingScreen(
              message: 'Carregando dados...',
              subtitle: 'Aguarde enquanto recuperamos suas informações',
            )
          else
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.keyboard_arrow_left,
                            color: Colors.black,
                          ),
                          onPressed: () {
                            analysisState.reset();
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selecione a Análise',
                          style: Theme.of(context)
                              .textTheme
                              .headlineLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Escolha qual análise deseja realizar',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Preview image
                  if (uncroppedImagePath != null || fileUrl != null)
                    Expanded(
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final height = constraints.maxHeight;
                            final width = constraints.maxWidth;
                            return Container(
                              width: width,
                              height: height,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                color: AppColors.background,
                              ),
                              child: _buildImageDisplay(
                                context: context,
                                uncroppedImagePath: uncroppedImagePath,
                                fileUrl: fileUrl,
                                width: width,
                                height: height,
                                isProcessingAny: isProcessingAny,
                              ),
                            );
                          },
                        ),
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  const SizedBox(height: 32),
                  // Analysis options
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        _buildAnalysisOption(
                          context,
                          icon: Icons.face,
                          title: 'Análise de Proporção Facial',
                          subtitle: analysisState.hasRatioResults
                              ? 'Resultado disponível'
                              : analysisState.isProcessingRatio
                                  ? 'Processando análise facial'
                                  : 'Mapeamento de estrutura facial e proporções',
                          status: _analysisStatus(
                            isProcessing: analysisState.isProcessingRatio,
                            hasResult: analysisState.hasRatioResults,
                          ),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const FacialStructureScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        _buildAnalysisOption(
                          context,
                          icon: Icons.spa,
                          title: 'Análise de Pele',
                          subtitle: analysisState.hasSkinResults
                              ? 'Resultado disponível'
                              : analysisState.isProcessingSkin
                                  ? 'Processando análise de pele'
                                  : 'Detecção de problemas de pele e pontuação',
                          status: _analysisStatus(
                            isProcessing: analysisState.isProcessingSkin,
                            hasResult: analysisState.hasSkinResults,
                          ),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const SkinAnalysisScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        _buildAnalysisOption(
                          context,
                          icon: Icons.auto_fix_high,
                          title: 'Retoque Facial',
                          subtitle: analysisState.hasRetouchResults
                              ? 'Resultado disponível'
                              : analysisState.isProcessingRetouch
                                  ? 'Processando retoque facial'
                                  : 'Visualização de potencial de beleza',
                          status: _analysisStatus(
                            isProcessing: analysisState.isProcessingRetouch,
                            hasResult: analysisState.hasRetouchResults,
                          ),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const FaceRetouchScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnalysisOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required _AnalysisCardStatus status,
    required VoidCallback onTap,
  }) {
    print('status_buildAnalysisOption: $status');
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.boderGray, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: AppColors.primary.withValues(alpha: 0.1),
          highlightColor: AppColors.primary.withValues(alpha: 0.05),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: AppColors.buttonGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          _buildStatusChip(status),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 18,
                  color: AppColors.textSecondary.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _AnalysisCardStatus _analysisStatus({
    required bool isProcessing,
    required bool hasResult,
  }) {
    if (isProcessing) return _AnalysisCardStatus.processing;
    if (hasResult) return _AnalysisCardStatus.ready;
    return _AnalysisCardStatus.pending;
  }

  Widget _buildStatusChip(_AnalysisCardStatus status) {
    late Color color;
    late String label;
    print('status: $status');

    switch (status) {
      case _AnalysisCardStatus.ready:
        color = Colors.green;
        label = 'Pronto';
        break;
      case _AnalysisCardStatus.processing:
        color = Colors.orange;
        label = 'Processando';
        break;
      case _AnalysisCardStatus.pending:
        color = Colors.grey;
        label = 'Pendente';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildImageDisplay({
    required BuildContext context,
    required String? uncroppedImagePath,
    required String? fileUrl,
    required double width,
    required double height,
    required bool isProcessingAny,
  }) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(18)),
          child: uncroppedImagePath != null && !kIsWeb
              ? Image.file(
                  io.File(uncroppedImagePath),
                  fit: BoxFit.fitWidth,
                  width: width,
                  height: height,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback to fileUrl if local image fails
                    if (fileUrl != null) {
                      return ProcessingImageOverlay(
                        imageUrl: fileUrl,
                        fit: BoxFit.contain,
                        showOverlay: false,
                        overlayMessage: '',
                        borderRadius: const BorderRadius.all(
                          Radius.circular(18),
                        ),
                        height: height,
                      );
                    }
                    return Container(
                      color: AppColors.boderGray,
                      child: const Center(
                        child: Icon(
                          Icons.error_outline,
                          color: AppColors.textSecondary,
                          size: 40,
                        ),
                      ),
                    );
                  },
                )
              : fileUrl != null
                  ? ProcessingImageOverlay(
                      imageUrl: fileUrl,
                      fit: BoxFit.contain,
                      showOverlay: false,
                      overlayMessage: '',
                      borderRadius: const BorderRadius.all(Radius.circular(18)),
                      height: height,
                    )
                  : Container(
                      color: AppColors.boderGray,
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: AppColors.textSecondary,
                          size: 48,
                        ),
                      ),
                    ),
        ),
        if (isProcessingAny)
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: Colors.black.withValues(alpha: 0.55),
            ),
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
                  'Processando suas análises...',
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
  }
}
