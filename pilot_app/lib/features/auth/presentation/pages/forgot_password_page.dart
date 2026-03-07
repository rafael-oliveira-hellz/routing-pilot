import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pilot_app/core/di/injection.dart';
import 'package:pilot_app/features/auth/domain/auth_repository.dart';

/// Tela "Esqueci a senha": email; POST /api/v1/auth/forgot-password; mensagem genérica.
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _loading = false;
  bool _success = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    _errorMessage = null;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await serviceLocator<AuthRepository>().forgotPassword(_emailController.text.trim());
      if (!mounted) return;
      setState(() {
        _loading = false;
        _success = true;
      });
    } catch (_) {
      setState(() {
        _loading = false;
        _success = true;
        // Mensagem genérica mesmo em erro (não revelar se email existe)
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Esqueci a senha'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _success
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    Icon(
                      Icons.mark_email_read_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Se o e-mail existir em nossa base, você receberá instruções para redefinir sua senha.',
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Voltar ao login'),
                    ),
                  ],
                )
              : Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        decoration: const InputDecoration(
                          labelText: 'E-mail',
                          hintText: 'seu@email.com',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Informe o e-mail';
                          }
                          if (!RegExp(r'^[\w.-]+@[\w.-]+\.\w+$')
                              .hasMatch(v.trim())) {
                            return 'E-mail inválido';
                          }
                          return null;
                        },
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage!,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error),
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
                            : const Text('Enviar instruções'),
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
