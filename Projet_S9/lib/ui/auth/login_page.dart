// lib/ui/auth/login_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/auth_state.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthState>(context);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Connexion",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              // Bouton Google
              ElevatedButton.icon(
                icon: const Icon(Icons.login),
                label: const Text("Se connecter avec Google"),
                onPressed: auth.login,
              ),

              const SizedBox(height: 12),

              // Bouton "ne pas se connecter"
              TextButton(
                onPressed: auth.skipLogin,
                child: const Text("Ne pas se connecter maintenant"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
