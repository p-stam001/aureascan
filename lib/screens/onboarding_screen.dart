import 'package:aureascan_app/screens/camera_screen.dart';
import 'package:aureascan_app/state/analysis_state.dart';
import 'package:aureascan_app/widgets/gradient_button.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _hasReset = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize all variables in analysis state when onboarding screen is displayed
    // Only reset once when the widget is first built
    if (!_hasReset) {
      _hasReset = true;
      final analysisState = Provider.of<AnalysisState>(context, listen: false);
      analysisState.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final analysisState = Provider.of<AnalysisState>(context, listen: false);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              Text(
                'Aurea\nScanAI',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: 32),
              Text(
                'ÁureaScan AI usa mapeamento facial avançado e análise de pele para revelar seu potencial de beleza, sugerir tratamentos e orientá-lo para melhorias não invasivas.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const Spacer(flex: 3),
              GradientButton(
                text: 'Continuar',
                onPressed: () {
                  analysisState.reset();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (context) => const CameraScreen()),
                  );
                },
              ),
              const SizedBox(height: 16),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: Theme.of(context).textTheme.bodyMedium,
                  children: [
                    const TextSpan(
                        text: 'Ao continuar, você concorda com nossa '),
                    TextSpan(
                      text: 'Política de Privacidade',
                      style:
                          const TextStyle(decoration: TextDecoration.underline),
                      recognizer: TapGestureRecognizer()..onTap = () {},
                    ),
                    const TextSpan(text: ' e '),
                    TextSpan(
                      text: 'Termos e Condições',
                      style:
                          const TextStyle(decoration: TextDecoration.underline),
                      recognizer: TapGestureRecognizer()..onTap = () {},
                    ),
                    const TextSpan(text: '.'),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
