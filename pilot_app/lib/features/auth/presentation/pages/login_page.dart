import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pilot_app/core/di/injection.dart';
import 'package:pilot_app/core/domain/dto/auth_dto.dart';
import 'package:pilot_app/core/error/pilot_exception.dart';
import 'package:pilot_app/features/auth/domain/auth_repository.dart';

/// Tela de login: email, senha, Lembrar de mim; POST /api/v1/auth/login.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    _errorMessage = null;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final repo = serviceLocator<AuthRepository>();
      await repo.login(LoginRequest(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        rememberMe: _rememberMe,
      ));
      if (!mounted) return;
      context.go('/');
    } on AuthException catch (e) {
      setState(() {
        _loading = false;
        _errorMessage = e.message;
      });
    } on ValidationException catch (e) {
      setState(() {
        _loading = false;
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _errorMessage = 'Falha ao entrar. Tente novamente.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final message = GoRouterState.of(context).uri.queryParameters['message'];
    final showResetOk = message == 'reset_ok';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Entrar'),
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
                if (showResetOk) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Senha redefinida. Faça login com sua nova senha.',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
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
                    if (v == null || v.trim().isEmpty) return 'Informe o e-mail';
                    if (!RegExp(r'^[\w.-]+@[\w.-]+\.\w+$').hasMatch(v.trim())) {
                      return 'E-mail inválido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Senha',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Informe a senha';
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  value: _rememberMe,
                  onChanged: (v) => setState(() => _rememberMe = v ?? false),
                  title: const Text('Lembrar de mim'),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
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
                      : const Text('Entrar'),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.go('/forgot-password'),
                    child: const Text('Esqueci a senha'),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.go('/register'),
                  child: const Text('Criar conta'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
