import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';


/// Placeholder da tela de login. Tela real no card APP-1004.
class PlaceholderLoginPage extends StatelessWidget {
  const PlaceholderLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.login, size: 64),
              const SizedBox(height: 24),
              Text(
                'Tela de login (APP-1004)',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => GoRouter.of(context).go('/'),
                icon: const Icon(Icons.home),
                label: const Text('Voltar para Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
