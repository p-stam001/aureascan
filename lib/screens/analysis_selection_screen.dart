import 'package:aureascan_app/screens/facial_structure_screen.dart';
import 'package:aureascan_app/screens/skin_analysis_screen.dart';
import 'package:aureascan_app/screens/face_retouch_screen.dart';
import 'package:aureascan_app/state/analysis_state.dart';
import 'package:aureascan_app/utils/app_colors.dart';
import 'package:aureascan_app/widgets/processing_image_overlay.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum _AnalysisCardStatus { pending, processing, ready }

class AnalysisSelectionScreen extends StatelessWidget {
  const AnalysisSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final analysisState = Provider.of<AnalysisState>(context);
    final fileUrl = analysisState.fileUrl;
    final isProcessingAny = analysisState.isProcessingRatio ||
        analysisState.isProcessingSkin ||
        analysisState.isProcessingRetouch;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_left,
                        color: Colors.black),
                    onPressed: () => Navigator.of(context).pop(),
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
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Escolha qual análise deseja realizar',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Preview image
            if (fileUrl != null)
              Expanded(
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final height = constraints.maxHeight;
                      return Container(
                        width: height * (3 / 4),
                        height: height,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          color: Colors.red,
                        ),
                        child: ProcessingImageOverlay(
                          imageUrl: fileUrl,
                          height: height,
                          fit: BoxFit.fitWidth,
                          showOverlay: isProcessingAny,
                          overlayMessage: 'Processando suas análises...',
                          borderRadius:
                              const BorderRadius.all(Radius.circular(18)),
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
                          builder: (context) => const FacialStructureScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
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
                          builder: (context) => const SkinAnalysisScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
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
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
            ),
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
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
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
}
