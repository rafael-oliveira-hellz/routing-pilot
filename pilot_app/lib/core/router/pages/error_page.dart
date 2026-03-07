import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:pilot_app/core/error/pilot_exception.dart';

/// Tela de erro genérica com traceId para suporte. APP-8001, APP-8002.
class ErrorPage extends StatelessWidget {
  const ErrorPage({
    super.key,
    this.message = 'Algo deu errado.',
    this.traceId,
    this.onRetry,
  });

  final String message;
  final String? traceId;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Erro')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 24),
              Text(
                message,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              if (traceId != null && traceId!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Semantics(
                  label: 'Código de rastreio para suporte',
                  child: SelectableText(
                    'Código: $traceId',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontFamily: 'monospace',
                        ),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    final t = traceId ?? '';
                    Clipboard.setData(ClipboardData(text: t));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Código copiado')),
                    );
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('Copiar código'),
                ),
              ],
              if (onRetry != null) ...[
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: onRetry,
                  child: const Text('Tentar novamente'),
                ),
              ],
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go('/'),
                child: const Text('Voltar ao início'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Extrai traceId de uma exceção (PilotException ou DioException com response).
String? traceIdFromException(Object error, [String? fallbackTraceId]) {
  if (error is PilotException && error.traceId != null) return error.traceId;
  return fallbackTraceId;
}
