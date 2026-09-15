import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme.dart';
import '../../widgets/onboarding_illustrations.dart';
import '../auth/auth_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      illustration: const OnboardingIllustration1(),
      title: 'Trouvez des services près de chez vous',
      description: 'ServiceFinder vous aide à découvrir les prestataires de services dans votre quartier en quelques clics.',
    ),
    OnboardingPage(
      illustration: const OnboardingIllustration2(),
      title: 'Géolocalisation intelligente',
      description: 'Utilisez votre position pour trouver les prestataires les plus proches de vous, ou recherchez par ville.',
    ),
    OnboardingPage(
      illustration: const OnboardingIllustration3(),
      title: 'Contactez directement',
      description: 'Appelez ou envoyez un SMS aux prestataires sans quitter l\'application. Simple et rapide.',
    ),
    OnboardingPage(
      illustration: const OnboardingIllustration4(),
      title: 'Vous êtes prestataire ?',
      description: 'Créez votre profil et faites-vous connaître par les clients de votre région.',
    ),
  ];

  Future<void> _completeOnboarding () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),
            _buildBottomSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Page number watermark
          Align(
            alignment: Alignment.topRight,
            child: Text(
              '0${_currentPage + 1}',
              style: TextStyle(
                fontSize: 52,
                fontWeight: FontWeight.w500,
                color: AppTheme.accentColor.withValues(alpha: 0.2),
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Illustration
          page.illustration,
          const SizedBox(height: 32),
          // Accent line
          Container(
            width: 34,
            height: 3,
            color: AppTheme.accentColor,
          ),
          const SizedBox(height: 18),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
              height: 1.55,
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 0, 26, 26),
      child: Column(
        children: [
          Row(
            children: List.generate(
              _pages.length,
                  (index) => Expanded(
                child: Container(
                  height: 2,
                  margin: EdgeInsets.only(right: index < _pages.length - 1 ? 6 : 0),
                  color: index == _currentPage
                      ? AppTheme.accentColor
                      : AppTheme.borderSubtle,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _currentPage == _pages.length - 1
                  ? _completeOnboarding
                  : () {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: Text(
                _currentPage == _pages.length - 1 ? 'COMMENCER' : 'SUIVANT',
              ),
            ),
          ),
        ],
      ),
    );
  }

}

class OnboardingPage {
  final Widget illustration;
  final String title;
  final String description;

  OnboardingPage({
    required this.illustration,
    required this.title,
    required this.description,
  });
}
