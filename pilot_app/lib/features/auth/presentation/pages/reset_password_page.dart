import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pilot_app/core/di/injection.dart';
import 'package:pilot_app/core/error/pilot_exception.dart';
import 'package:pilot_app/features/auth/domain/auth_repository.dart';

/// Tela "Redefinir senha": token (query), nova senha + confirmação; POST reset-password.
class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key, required this.token});

  final String token;

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _loading = false;
  String? _errorMessage;

  static bool _isStrongPassword(String s) {
    if (s.length < 8) return false;
    if (!RegExp(r'[A-Z]').hasMatch(s)) return false;
    if (!RegExp(r'[a-z]').hasMatch(s)) return false;
    if (!RegExp(r'[0-9]').hasMatch(s)) return false;
    return true;
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    _errorMessage = null;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await serviceLocator<AuthRepository>().resetPassword(
        widget.token,
        _passwordController.text,
      );
      if (!mounted) return;
      context.go('/login?message=reset_ok');
    } on ValidationException catch (e) {
      setState(() {
        _loading = false;
        _errorMessage = e.message;
      });
    } catch (_) {
      setState(() {
        _loading = false;
        _errorMessage = 'Não foi possível redefinir. Link pode ter expirado.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.token.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Redefinir senha')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Link inválido ou expirado.'),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go('/login'),
                child: const Text('Ir para login'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova senha'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Nova senha',
                    helperText:
                        'Mín. 8 caracteres, maiúscula, minúscula e número',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Informe a nova senha';
                    if (!_isStrongPassword(v)) {
                      return 'Senha fraca: use 8+ caracteres, maiúscula, minúscula e número';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirmar nova senha',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v != _passwordController.text) {
                      return 'Senhas não conferem';
                    }
                    return null;
                  },
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Redefinir senha'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Voltar ao login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
