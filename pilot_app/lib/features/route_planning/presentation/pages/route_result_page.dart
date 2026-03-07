import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Tela de resultado após "Calcular rota". Exibe id e status da route_request. APP-2002.
class RouteResultPage extends StatelessWidget {
  const RouteResultPage({super.key, required this.requestId, required this.status});

  final String requestId;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitação de rota'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_outline, size: 64, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 24),
              Text(
                'Rota enviada',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Text('ID: $requestId', style: Theme.of(context).textTheme.bodyLarge),
              if (status.isNotEmpty) Text('Status: $status', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () => context.go('/'),
                child: const Text('Voltar'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.go('/routes/new'),
                child: const Text('Nova rota'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
