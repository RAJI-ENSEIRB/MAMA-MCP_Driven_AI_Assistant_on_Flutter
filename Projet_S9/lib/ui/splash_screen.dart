import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/identity_profile.dart';

import '../onboarding/onboarding_flow.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _rotation = 0;

  @override
  void initState() {
    super.initState();
    _startRotationAnimation();
  }

  void _startRotationAnimation() {
    // 36 étapes de 10° chacune (360° / 10° = 36)
    // Chaque étape dure 60ms
    int stepIndex = 0;

    Future.doWhile(() async {
      if (!mounted) return false;

      await Future.delayed(const Duration(milliseconds: 60));

      if (mounted) {
        setState(() {
          _rotation = (stepIndex % 36) * 10;
        });
      }

      stepIndex++;

      // S'arrêter après 3 rotations complètes (36 * 3 = 108 étapes)
      if (stepIndex >= 108) {
        if (mounted) {
          await Future.delayed(const Duration(milliseconds: 1000));
          _navigateToNextScreen();
        }
        return false;
      }

      return true;
    });
  }

  void _navigateToNextScreen() {
    if (!mounted) return;

    final identityBox = Hive.box<IdentityProfile>('identity_box');
    final hasIdentity = identityBox.isNotEmpty;

    if (hasIdentity) {
      Navigator.of(context).pushReplacementNamed('/auth');
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingFlow()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Transform.rotate(
          angle: _rotation * 3.14159 / 180,
          child: Image.asset(
            'lib/assets/robot.png',
            width: 200,
            height: 200,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
