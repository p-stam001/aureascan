import 'package:aureascan_app/state/analysis_state.dart';
import 'package:aureascan_app/utils/app_colors.dart';
import 'package:aureascan_app/utils/ideal_ratios.dart';
import 'package:aureascan_app/widgets/analysis_processing_placeholder.dart';
import 'package:aureascan_app/widgets/task_processing_loading_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FacialStructureScreen extends StatefulWidget {
  const FacialStructureScreen({super.key});

  @override
  State<FacialStructureScreen> createState() => _FacialStructureScreenState();
}

class _FacialStructureScreenState extends State<FacialStructureScreen> {
  bool _hasTriggeredAnalysis = false;
  int _selectedRatioIndex = 0; // Default to first ratio

  // Ratio options with icons and data
  List<_RatioOption> _ratioOptions = [];

  @override
  void initState() {
    super.initState();
    _triggerAnalysisIfNeeded();
  }

  void _triggerAnalysisIfNeeded() {
    final analysisState = Provider.of<AnalysisState>(context, listen: false);
    if (!analysisState.hasRatioResults &&
        !analysisState.isProcessingRatio &&
        analysisState.fileId != null &&
        !_hasTriggeredAnalysis) {
      _hasTriggeredAnalysis = true;
      analysisState.triggerRatioAnalysis().catchError((e) {
        if (mounted) {
          debugPrint('Error triggering ratio analysis: $e');
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

  void _initializeRatioOptions(ratioResults) {
    _ratioOptions = [
      _RatioOption(
        title: 'Terços Horizontais',
        iconType: RatioIconType.horizontalThirds,
        imageUrl: ratioResults.horizontalThird?.url ?? '',
        rates: ratioResults.horizontalThird?.rates ?? const <double>[],
        description: 'Divisão da face em três partes horizontais',
      ),
      _RatioOption(
        title: 'Quintas Verticais',
        iconType: RatioIconType.verticalFifths,
        imageUrl: ratioResults.verticalFifth?.url ?? '',
        rates: ratioResults.verticalFifth?.rates ?? const <double>[],
        description: 'Divisão da face em cinco partes verticais',
      ),
      _RatioOption(
        title: 'Proporção Facial',
        iconType: RatioIconType.facialProportion,
        imageUrl: ratioResults.faceAspectRatio?.url ?? '',
        rates: ratioResults.faceAspectRatio?.rates ?? const <double>[],
        description: 'Proporção geral do formato do rosto',
      ),
      _RatioOption(
        title: 'Proporção Áurea (LC-Sto-Me)',
        iconType: RatioIconType.goldenLcStoMe,
        imageUrl: ratioResults.horizontalGoldenRatioLcStoMe?.url ?? '',
        rates: ratioResults.horizontalGoldenRatioLcStoMe?.rates ??
            const <double>[],
        description: 'Proporção áurea horizontal',
      ),
      _RatioOption(
        title: 'Proporção Áurea (Tr-Ln-Me)',
        iconType: RatioIconType.goldenTrLnMe,
        imageUrl: ratioResults.horizontalGoldenRatioTrLnMe?.url ?? '',
        rates:
            ratioResults.horizontalGoldenRatioTrLnMe?.rates ?? const <double>[],
        description: 'Proporção áurea horizontal',
      ),
      _RatioOption(
        title: 'Proporção Olhos-Boca',
        iconType: RatioIconType.eyesToMouth,
        imageUrl: ratioResults.eyesToMouthWidthRatio?.url ?? '',
        rates: ratioResults.eyesToMouthWidthRatio?.rates ?? const <double>[],
        description: 'Relação entre largura dos olhos e boca',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final analysisState = Provider.of<AnalysisState>(context);
    final ratioResults = analysisState.ratioResults;
    final isLoading = analysisState.isProcessingRatio;

    if (isLoading) {
      return AnalysisProcessingPlaceholder(
        title: 'Análise facial',
        overlayMessage: 'Processando análise facial...',
        imageUrl: analysisState.uncroppedImagePath,
        backgroundColor: AppColors.background,
        headerColor: const Color(0xFF2A2A2A),
        titleColor: Colors.white,
      );
    }

    if (ratioResults == null) {
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

    // Initialize ratio options if not already done
    if (_ratioOptions.isEmpty) {
      _initializeRatioOptions(ratioResults);
    }

    if (_ratioOptions.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: Text(
              'Nenhum dado disponível',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
        ),
      );
    }

    final selectedRatio = _ratioOptions[_selectedRatioIndex];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: const Color(0xFF2A2A2A), // Dark grey header
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text(
                      'Análise facial',
                      textAlign: TextAlign.center,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                    ),
                  ),
                  const SizedBox(width: 48), // Balance the back button
                ],
              ),
            ),
            // Main content
            Expanded(
              child: Column(
                children: [
                  // Image display area (top section)
                  Expanded(
                    flex: 3,
                    child: Container(
                      width: double.infinity,
                      color: Colors.white,
                      child: Stack(
                        children: [
                          // Result image
                          if (selectedRatio.imageUrl.isNotEmpty)
                            Container(
                              width: double.infinity,
                              height: double.infinity,
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: CachedNetworkImageProvider(
                                      selectedRatio.imageUrl),
                                  fit: BoxFit.fitWidth,
                                ),
                              ),
                              child: CachedNetworkImage(
                                imageUrl: selectedRatio.imageUrl,
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
                                    child: Icon(Icons.error_outline,
                                        size: 48,
                                        color: AppColors.textSecondary),
                                  ),
                                ),
                                fit: BoxFit.fitWidth,
                              ),
                            )
                          else
                            Container(
                              color: AppColors.boderGray,
                              child: const Center(
                                child: Icon(Icons.image_not_supported,
                                    size: 64, color: AppColors.textSecondary),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  // Results section (bottom section)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      color: Color(0xFF2A2A2A), // Dark grey background
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedRatio.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (selectedRatio.displayRate != null) ...[
                          // User's ratio
                          // Row(
                          //   crossAxisAlignment: CrossAxisAlignment.baseline,
                          //   textBaseline: TextBaseline.alphabetic,
                          //   children: [
                          //     Text(
                          //       'Sua Proporção: ',
                          //       style: TextStyle(
                          //         color: Colors.white.withValues(alpha: 0.8),
                          //         fontSize: 16,
                          //       ),
                          //     ),
                          //     Text(
                          //       selectedRatio.displayRate!.toStringAsFixed(3),
                          //       style: const TextStyle(
                          //         color: Color(
                          //             0xFFFF6B9D), // Pink/red for user's ratio
                          //         fontSize: 32,
                          //         fontWeight: FontWeight.bold,
                          //       ),
                          //     ),
                          //   ],
                          // ),
                          if (selectedRatio.formattedRates.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children:
                                  selectedRatio.formattedRates.map((value) {
                                final parsedValue = double.tryParse(value);
                                final displayText = (selectedRatio.title
                                            .contains('Terços Horizontais') ||
                                        selectedRatio.title
                                            .contains('Quintas Verticais'))
                                    ? '${(parsedValue! * 100).toStringAsFixed(0)}%'
                                    : value;
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    displayText,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                          const SizedBox(height: 12),
                          // Ideal ratio
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                'Proporção Ouro: ',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                IdealRatios.getFormattedIdealRatio(
                                    selectedRatio.title),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          // const SizedBox(height: 16),
                          // Status indicator (Short/Balanced/Long)
                          // _buildStatusIndicator(
                          //   selectedRatio.displayRate!,
                          //   selectedRatio.title,
                          // ),
                        ] else
                          const Text(
                            'Dados não disponíveis',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Bottom navigation bar (ratio selector)
            Container(
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  _ratioOptions.length,
                  (index) => _buildRatioSelector(
                    _ratioOptions[index],
                    index,
                    index == _selectedRatioIndex,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatioSelector(
    _RatioOption option,
    int index,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRatioIndex = index;
        });
      },
      child: _RatioFaceIcon(
        iconType: option.iconType,
        isSelected: isSelected,
      ),
    );
  }
}

class _RatioOption {
  final String title;
  final RatioIconType iconType;
  final String imageUrl;
  final List<double> rates;
  final String description;

  double? get displayRate {
    if (rates.isEmpty) return null;
    return rates.reduce((a, b) => a + b) / rates.length;
  }

  List<String> get formattedRates =>
      rates.map((value) => value.toStringAsFixed(3)).toList();

  _RatioOption({
    required this.title,
    required this.iconType,
    required this.imageUrl,
    required this.rates,
    required this.description,
  });
}

enum RatioIconType {
  horizontalThirds,
  verticalFifths,
  facialProportion,
  goldenLcStoMe,
  goldenTrLnMe,
  eyesToMouth,
}

class _RatioFaceIcon extends StatelessWidget {
  final RatioIconType iconType;
  final bool isSelected;

  const _RatioFaceIcon({
    required this.iconType,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor =
        isSelected ? const Color(0xFF4A9EFF) : Colors.transparent;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 64,
      height: 64,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: CustomPaint(
        painter: _RatioIconPainter(
          type: iconType,
          strokeColor: isSelected ? Colors.white : AppColors.textSecondary,
          accentColor:
              isSelected ? const Color(0xFF8BD3FF) : const Color(0xFF4A9EFF),
          faceFill: isSelected
              ? const Color(0xFF4A9EFF).withValues(alpha: 0.15)
              : Colors.white,
          background: isSelected
              ? const Color(0xFF4A9EFF).withValues(alpha: 0.1)
              : AppColors.boderGray.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}

class _RatioIconPainter extends CustomPainter {
  final RatioIconType type;
  final Color strokeColor;
  final Color accentColor;
  final Color faceFill;
  final Color background;

  _RatioIconPainter({
    required this.type,
    required this.strokeColor,
    required this.accentColor,
    required this.faceFill,
    required this.background,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint bgPaint = Paint()
      ..color = background
      ..style = PaintingStyle.fill;
    final Rect bgRect = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, const Radius.circular(10)),
      bgPaint,
    );

    final Offset headCenter = Offset(size.width / 2, size.height / 2.1);
    final double faceRadius = size.width * 0.28;

    final Paint facePaint = Paint()
      ..color = faceFill
      ..style = PaintingStyle.fill;
    final Paint outlinePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(headCenter, faceRadius, facePaint);
    canvas.drawCircle(headCenter, faceRadius, outlinePaint);

    final Paint eyePaint = Paint()
      ..color = strokeColor
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2;
    final double eyeOffsetX = size.width * 0.08;
    final double eyeY = headCenter.dy - faceRadius * 0.2;
    canvas.drawLine(Offset(headCenter.dx - eyeOffsetX, eyeY),
        Offset(headCenter.dx - eyeOffsetX / 2, eyeY), eyePaint);
    canvas.drawLine(Offset(headCenter.dx + eyeOffsetX / 2, eyeY),
        Offset(headCenter.dx + eyeOffsetX, eyeY), eyePaint);

    final Paint mouthPaint = Paint()
      ..color = strokeColor
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2;
    final double mouthWidth = size.width * 0.2;
    final double mouthY = headCenter.dy + faceRadius * 0.3;
    canvas.drawLine(
      Offset(headCenter.dx - mouthWidth / 2, mouthY),
      Offset(headCenter.dx + mouthWidth / 2, mouthY),
      mouthPaint,
    );

    final Paint overlayPaint = Paint()
      ..color = strokeColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    switch (type) {
      case RatioIconType.horizontalThirds:
        _drawHorizontalGuides(canvas, size, overlayPaint, [0.25, 0.5, 0.75]);
        break;
      case RatioIconType.verticalFifths:
        _drawVerticalGuides(canvas, size, overlayPaint, 5);
        break;
      case RatioIconType.facialProportion:
        _drawScanFrame(canvas, size, overlayPaint);
        break;
      case RatioIconType.goldenLcStoMe:
        _drawGoldenHorizontal(canvas, size, overlayPaint, accentColor);
        break;
      case RatioIconType.goldenTrLnMe:
        _drawGoldenVertical(canvas, size, overlayPaint, accentColor);
        break;
      case RatioIconType.eyesToMouth:
        _drawEyesMouthFocus(canvas, size, overlayPaint, accentColor);
        break;
    }
  }

  void _drawHorizontalGuides(
      Canvas canvas, Size size, Paint paint, List<double> positions) {
    for (final position in positions) {
      final double y = size.height * position;
      canvas.drawLine(
        Offset(size.width * 0.18, y),
        Offset(size.width * 0.82, y),
        paint,
      );
    }
  }

  void _drawVerticalGuides(
      Canvas canvas, Size size, Paint paint, int divisions) {
    final double gap = (size.width * 0.64) / (divisions - 1);
    final double startX = size.width * 0.18;
    for (int i = 0; i < divisions; i++) {
      final double x = startX + gap * i;
      canvas.drawLine(
        Offset(x, size.height * 0.2),
        Offset(x, size.height * 0.8),
        paint,
      );
    }
  }

  void _drawScanFrame(Canvas canvas, Size size, Paint paint) {
    final RRect frame = RRect.fromLTRBR(
      size.width * 0.18,
      size.height * 0.2,
      size.width * 0.82,
      size.height * 0.8,
      const Radius.circular(10),
    );
    canvas.drawRRect(frame, paint);
  }

  void _drawGoldenHorizontal(
      Canvas canvas, Size size, Paint paint, Color accentColor) {
    _drawHorizontalGuides(canvas, size, paint, [0.35, 0.6]);
    final Paint accentPaint = Paint()
      ..color = accentColor
      ..strokeWidth = paint.strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final double centerX = size.width / 2;
    canvas.drawLine(
      Offset(centerX, size.height * 0.25),
      Offset(centerX, size.height * 0.75),
      accentPaint,
    );
  }

  void _drawGoldenVertical(
      Canvas canvas, Size size, Paint paint, Color accentColor) {
    _drawVerticalGuides(canvas, size, paint, 3);
    final Paint accentPaint = Paint()
      ..color = accentColor
      ..strokeWidth = paint.strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final double midY = size.height / 2;
    canvas.drawLine(
      Offset(size.width * 0.25, midY),
      Offset(size.width * 0.75, midY),
      accentPaint,
    );
  }

  void _drawEyesMouthFocus(
      Canvas canvas, Size size, Paint paint, Color accentColor) {
    final Paint accentPaint = Paint()
      ..color = accentColor
      ..strokeWidth = paint.strokeWidth + 0.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final double eyeY = size.height * 0.4;
    final double mouthY = size.height * 0.65;
    canvas.drawLine(
      Offset(size.width * 0.22, eyeY),
      Offset(size.width * 0.78, eyeY),
      accentPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.3, mouthY),
      Offset(size.width * 0.7, mouthY),
      paint,
    );
    final double centerX = size.width / 2;
    final Paint connectorPaint = Paint()
      ..color = paint.color
      ..strokeWidth = paint.strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(centerX, eyeY),
      Offset(centerX, mouthY),
      connectorPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RatioIconPainter oldDelegate) {
    return oldDelegate.type != type ||
        oldDelegate.strokeColor != strokeColor ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.faceFill != faceFill ||
        oldDelegate.background != background;
  }
}
