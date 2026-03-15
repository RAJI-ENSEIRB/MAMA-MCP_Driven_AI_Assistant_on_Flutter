import 'package:flutter/material.dart';
import 'identity_page.dart';
import 'habitat_page.dart';
import 'family_page.dart';
import 'health_page.dart';
import 'profession_page.dart';
import 'mobility_page.dart';
import 'social_page.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 6) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Terminer l'onboarding et aller vers l'authentification
      Navigator.of(context).pushReplacementNamed('/auth');
    }
  }

  void _skipPage() {
    _nextPage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Indicateur de progression
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: LinearProgressIndicator(
                value: (_currentPage + 1) / 7,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                '${_currentPage + 1} / 7',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 8),

            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  // Catégorie 1 - Identité (obligatoire)
                  IdentityPage(onComplete: _nextPage),

                  // Catégorie 2 - Habitat
                  HabitatPage(onComplete: _nextPage, onSkip: _skipPage),

                  // Catégorie 3 - Famille
                  FamilyPage(onComplete: _nextPage, onSkip: _skipPage),

                  // Catégorie 4 - Santé
                  HealthPage(onComplete: _nextPage, onSkip: _skipPage),

                  // Catégorie 5 - Profession
                  ProfessionPage(onComplete: _nextPage, onSkip: _skipPage),

                  // Catégorie 6 - Mobilité
                  MobilityPage(onComplete: _nextPage, onSkip: _skipPage),

                  // Catégorie 7 - Social & Bien-être
                  SocialPage(onComplete: _nextPage, onSkip: _skipPage),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
