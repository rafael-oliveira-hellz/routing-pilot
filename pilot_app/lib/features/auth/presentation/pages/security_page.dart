import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pilot_app/core/di/injection.dart';
import 'package:pilot_app/features/auth/domain/auth_repository.dart';

/// Tela Segurança/Sessões: encerrar sessões em outros dispositivos (revoke-all-other-sessions).
/// Caso de uso: usuário perdeu ou foi roubado o celular; a partir de outro dispositivo encerra o acesso no aparelho perdido.
class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key});

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  bool _loading = false;
  bool _success = false;
  String? _errorMessage;

  Future<void> _revokeAllOtherSessions() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
      _success = false;
    });
    try {
      await serviceLocator<AuthRepository>().revokeAllOtherSessions();
      if (!mounted) return;
      setState(() {
        _loading = false;
        _success = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = 'Não foi possível encerrar as outras sessões.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Segurança e sessões'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            ListTile(
              leading: const Icon(Icons.lock_reset),
              title: const Text('Alterar senha'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/change-password'),
            ),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Sessões em outros dispositivos',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Se você perdeu ou teve o celular roubado, use o botão abaixo para encerrar o acesso em todos os outros aparelhos. Apenas este dispositivo continuará logado.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            if (_success)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'As outras sessões foram encerradas. Este aparelho continua logado.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loading ? null : _revokeAllOtherSessions,
              icon: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.devices_other),
              label: Text(
                _loading
                    ? 'Encerrando...'
                    : 'Encerrar sessões em todos os outros dispositivos',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
