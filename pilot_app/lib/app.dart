import 'package:flutter/material.dart';
import 'package:pilot_app/core/theme/app_theme.dart';

/// Root widget do Pilot App.
/// Navegação e rotas serão configurados nas sprints (go_router / auto_route).
class PilotApp extends StatelessWidget {
  const PilotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pilot',
      debugShowCheckedModeBanner: true,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const _HomePlaceholder(),
    );
  }
}

class _HomePlaceholder extends StatelessWidget {
  const _HomePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilot'),
        centerTitle: true,
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
                'Implemente as features conforme docs/TODO-SPRINTS.md',
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
