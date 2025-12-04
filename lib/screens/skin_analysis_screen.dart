import 'package:aureascan_app/state/analysis_state.dart';
import 'package:aureascan_app/utils/app_colors.dart';
import 'package:aureascan_app/widgets/gradient_tab_indicator.dart';
import 'package:aureascan_app/widgets/analysis_processing_placeholder.dart';
import 'package:aureascan_app/widgets/task_processing_loading_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SkinAnalysisScreen extends StatefulWidget {
  const SkinAnalysisScreen({super.key});

  @override
  State<SkinAnalysisScreen> createState() => _SkinAnalysisScreenState();
}

class _SkinAnalysisScreenState extends State<SkinAnalysisScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  bool _hasTriggeredAnalysis = false;

  @override
  void initState() {
    super.initState();
    _triggerAnalysisIfNeeded();
  }

  void _triggerAnalysisIfNeeded() {
    final analysisState = Provider.of<AnalysisState>(context, listen: false);
    if (!analysisState.hasSkinResults &&
        !analysisState.isProcessingSkin &&
        analysisState.fileId != null &&
        !_hasTriggeredAnalysis) {
      _hasTriggeredAnalysis = true;
      analysisState.triggerSkinAnalysis().catchError((e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao iniciar análise: ${e.toString()}')),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  String _getLevel(double? score) {
    if (score == null) return 'N/A';
    if (score < 0.33) return 'Leve';
    if (score < 0.66) return 'Moderado';
    return 'Forte';
  }

  Color _getLevelColor(String level) {
    switch (level) {
      case 'Leve':
        return Colors.green;
      case 'Moderado':
        return Colors.orange;
      case 'Forte':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final analysisState = Provider.of<AnalysisState>(context);
    final skinResults = analysisState.skinResults;
    final isLoading = analysisState.isProcessingSkin;

    if (isLoading) {
      return AnalysisProcessingPlaceholder(
        title: 'Análise de Pele',
        overlayMessage: 'Processando análise de pele...',
        imageUrl: analysisState.uncroppedImagePath,
      );
    }

    if (skinResults == null) {
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

    // Prepare tab data
    final tabs = <_SkinTabData>[];

    // Overall score
    if (skinResults.all != null) {
      tabs.add(_SkinTabData(
        title: 'Geral',
        imageUrl: '',
        score: skinResults.all!.score,
        description: 'Pontuação geral da pele',
        featureType: 'all',
      ));
    }

    // Skin age
    if (skinResults.skinAge != null) {
      tabs.add(_SkinTabData(
        title: 'Idade da Pele',
        imageUrl: '',
        score: null,
        description: 'Idade estimada da pele',
        featureType: 'skinAge',
        skinAge: skinResults.skinAge,
      ));
    }

    // Redness
    if (skinResults.redness != null) {
      tabs.add(_SkinTabData(
        title: 'Vermelhidão',
        imageUrl: skinResults.redness!.url,
        score: skinResults.redness!.score,
        description: 'Nível de vermelhidão detectado',
        featureType: 'redness',
      ));
    }

    // Oiliness
    if (skinResults.oiliness != null) {
      tabs.add(_SkinTabData(
        title: 'Oleosidade',
        imageUrl: skinResults.oiliness!.url,
        score: skinResults.oiliness!.score,
        description: 'Nível de oleosidade da pele',
        featureType: 'oiliness',
      ));
    }

    // Age spots
    if (skinResults.ageSpot != null) {
      tabs.add(_SkinTabData(
        title: 'Manchas',
        imageUrl: skinResults.ageSpot!.url,
        score: skinResults.ageSpot!.score,
        description: 'Manchas de idade detectadas',
        featureType: 'ageSpot',
      ));
    }

    // Moisture
    if (skinResults.moisture != null) {
      tabs.add(_SkinTabData(
        title: 'Hidratação',
        imageUrl: skinResults.moisture!.url,
        score: skinResults.moisture!.score,
        description: 'Nível de hidratação da pele',
        featureType: 'moisture',
      ));
    }

    // Acne
    if (skinResults.acne != null) {
      tabs.add(_SkinTabData(
        title: 'Acne',
        imageUrl: skinResults.acne!.url,
        score: skinResults.acne!.score,
        description: 'Acne detectada',
        featureType: 'acne',
      ));
    }

    // Pores - Create separate tabs for each partial result
    if (skinResults.pore != null) {
      if (skinResults.pore!.forehead != null) {
        tabs.add(_SkinTabData(
          title: 'Poros - Testa',
          imageUrl: skinResults.pore!.forehead!.url,
          score: skinResults.pore!.forehead!.score,
          description: 'Análise de poros na região da testa',
          featureType: 'pore_forehead',
        ));
      }
      if (skinResults.pore!.nose != null) {
        tabs.add(_SkinTabData(
          title: 'Poros - Nariz',
          imageUrl: skinResults.pore!.nose!.url,
          score: skinResults.pore!.nose!.score,
          description: 'Análise de poros na região do nariz',
          featureType: 'pore_nose',
        ));
      }
      if (skinResults.pore!.cheek != null) {
        tabs.add(_SkinTabData(
          title: 'Poros - Bochecha',
          imageUrl: skinResults.pore!.cheek!.url,
          score: skinResults.pore!.cheek!.score,
          description: 'Análise de poros na região das bochechas',
          featureType: 'pore_cheek',
        ));
      }
      if (skinResults.pore!.whole != null) {
        tabs.add(_SkinTabData(
          title: 'Poros - Geral',
          imageUrl: skinResults.pore!.whole!.url,
          score: skinResults.pore!.whole!.score,
          description: 'Análise geral de poros',
          featureType: 'pore_whole',
        ));
      }
    }

    // Wrinkles - Create separate tabs for each partial result
    if (skinResults.wrinkle != null) {
      if (skinResults.wrinkle!.forehead != null) {
        tabs.add(_SkinTabData(
          title: 'Rugas - Testa',
          imageUrl: skinResults.wrinkle!.forehead!.url,
          score: skinResults.wrinkle!.forehead!.score,
          description: 'Análise de rugas na região da testa',
          featureType: 'wrinkle_forehead',
        ));
      }
      if (skinResults.wrinkle!.glabellar != null) {
        tabs.add(_SkinTabData(
          title: 'Rugas - Glabelar',
          imageUrl: skinResults.wrinkle!.glabellar!.url,
          score: skinResults.wrinkle!.glabellar!.score,
          description: 'Análise de rugas glabelares (entre as sobrancelhas)',
          featureType: 'wrinkle_glabellar',
        ));
      }
      if (skinResults.wrinkle!.crowfeet != null) {
        tabs.add(_SkinTabData(
          title: 'Rugas - Pé de galinha',
          imageUrl: skinResults.wrinkle!.crowfeet!.url,
          score: skinResults.wrinkle!.crowfeet!.score,
          description: 'Análise de rugas ao redor dos olhos (pé de galinha)',
          featureType: 'wrinkle_crowfeet',
        ));
      }
      if (skinResults.wrinkle!.periocular != null) {
        tabs.add(_SkinTabData(
          title: 'Rugas - Periocular',
          imageUrl: skinResults.wrinkle!.periocular!.url,
          score: skinResults.wrinkle!.periocular!.score,
          description: 'Análise de rugas na região periocular',
          featureType: 'wrinkle_periocular',
        ));
      }
      if (skinResults.wrinkle!.nasolabial != null) {
        tabs.add(_SkinTabData(
          title: 'Rugas - Nasolabial',
          imageUrl: skinResults.wrinkle!.nasolabial!.url,
          score: skinResults.wrinkle!.nasolabial!.score,
          description:
              'Análise de rugas nasolabiais (do nariz aos cantos da boca)',
          featureType: 'wrinkle_nasolabial',
        ));
      }
      if (skinResults.wrinkle!.marionette != null) {
        tabs.add(_SkinTabData(
          title: 'Rugas - Marionete',
          imageUrl: skinResults.wrinkle!.marionette!.url,
          score: skinResults.wrinkle!.marionette!.score,
          description:
              'Análise de rugas marionete (dos cantos da boca ao queixo)',
          featureType: 'wrinkle_marionette',
        ));
      }
      if (skinResults.wrinkle!.whole != null) {
        tabs.add(_SkinTabData(
          title: 'Rugas - Geral',
          imageUrl: skinResults.wrinkle!.whole!.url,
          score: skinResults.wrinkle!.whole!.score,
          description: 'Análise geral de rugas',
          featureType: 'wrinkle_whole',
        ));
      }
    }

    if (tabs.isEmpty) {
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
                      Icons.assessment_outlined,
                      size: 48,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Nenhum dado disponível',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Não há dados de análise disponíveis no momento.',
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

    // Initialize or update tab controller
    if (_tabController == null || _tabController!.length != tabs.length) {
      _tabController?.dispose();
      _tabController = TabController(length: tabs.length, vsync: this);
    }

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
                    'Análise de Pele',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Insights baseados em IA com base na sua foto',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                decoration: const BoxDecoration(
                  border: Border(
                      bottom: BorderSide(color: AppColors.boderGray, width: 1)),
                ),
                child: TabBar(
                  controller: _tabController!,
                  isScrollable: true,
                  labelColor: AppColors.textPrimary,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicator: const GradientTabIndicator(
                    gradient: AppColors.buttonGradient,
                    indicatorHeight: 2,
                  ),
                  labelStyle: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600),
                  unselectedLabelStyle: const TextStyle(fontSize: 12),
                  tabs: tabs.map((tab) => Tab(text: tab.title)).toList(),
                ),
              ),
            ),
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController!,
                children: tabs.map((tab) => _buildTabContent(tab)).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(_SkinTabData tab) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          if (tab.imageUrl.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  width: double.infinity,
                  height: 360,
                  child: CachedNetworkImage(
                    imageUrl: tab.imageUrl,
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
                            size: 48, color: AppColors.textSecondary),
                      ),
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            )
          else if (tab.featureType == 'all' || tab.featureType == 'skinAge')
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                gradient: AppColors.buttonGradient,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  tab.featureType == 'all'
                      ? Icons.assessment
                      : Icons.calendar_today,
                  size: 64,
                  color: Colors.white,
                ),
              ),
            ),
          const SizedBox(height: 24),
          // Description
          Text(
            tab.description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          // Score/Dimension cards
          if (tab.score != null)
            _buildScoreCard('Pontuação',
                '${(tab.score! * 100).toStringAsFixed(0)}%', tab.score!),
          if (tab.skinAge != null)
            _buildScoreCard('Idade da Pele', '${tab.skinAge} anos', null),
        ],
      ),
    );
  }

  Widget _buildScoreCard(String title, String value, double? score) {
    final level = score != null ? _getLevel(score) : '';
    final levelColor =
        score != null ? _getLevelColor(level) : Colors.transparent;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            Colors.white,
            AppColors.boderGray.withValues(alpha: 0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
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
              child:
                  const Icon(Icons.assessment, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
            if (level.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: levelColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: levelColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  level,
                  style: TextStyle(
                    color: levelColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SkinTabData {
  final String title;
  final String imageUrl;
  final double? score;
  final String description;
  final String featureType;
  final int? skinAge;

  _SkinTabData({
    required this.title,
    required this.imageUrl,
    this.score,
    required this.description,
    required this.featureType,
    this.skinAge,
  });
}
