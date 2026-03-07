import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pilot_app/core/di/injection.dart';
import 'package:pilot_app/features/auth/domain/auth_repository.dart';

/// Placeholder da tela inicial até a implementação da home real (pós-login).
/// Menu Administração só visível para role == ADMIN. APP-1007.
class HomePlaceholderPage extends StatefulWidget {
  const HomePlaceholderPage({super.key});

  @override
  State<HomePlaceholderPage> createState() => _HomePlaceholderPageState();
}

class _HomePlaceholderPageState extends State<HomePlaceholderPage> {
  bool? _isAdmin;

  @override
  void initState() {
    super.initState();
    serviceLocator<AuthRepository>().getCurrentUser().then((user) {
      if (mounted) setState(() => _isAdmin = user?.isAdmin ?? false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilot'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_road),
            tooltip: 'Nova rota',
            onPressed: () => GoRouter.of(context).go('/routes/new'),
          ),
          if (_isAdmin == true)
            IconButton(
              icon: const Icon(Icons.people),
              tooltip: 'Administração — Usuários',
              onPressed: () => GoRouter.of(context).go('/admin/users'),
            ),
          IconButton(
            icon: const Icon(Icons.security),
            tooltip: 'Segurança e sessões',
            onPressed: () => GoRouter.of(context).go('/security'),
          ),
          IconButton(
            icon: const Icon(Icons.lock_reset),
            tooltip: 'Alterar senha',
            onPressed: () => GoRouter.of(context).go('/change-password'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () async {
              await serviceLocator<AuthRepository>().logout();
              if (context.mounted) GoRouter.of(context).go('/login');
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.route,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Pilot App',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Roteamento · ETA · Incidentes',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Text(
                'Estrutura e config: APP-1001 · Auth: APP-1004',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
