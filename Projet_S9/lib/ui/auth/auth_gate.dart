// lib/ui/auth/auth_gate.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/auth_state.dart';
import '../home/home_page.dart';
import 'login_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthState>(context);

    // Tant que l'utilisateur n'a pas choisi (login ou skip) → écran de connexion
    if (!auth.hasChosen) {
      return const LoginPage();
    }

    // Une fois qu'il a choisi (avec ou sans Google) → on affiche l'app
    return const MyHomePage();
  }
}
