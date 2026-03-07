import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pilot_app/core/di/injection.dart';
import 'package:pilot_app/core/error/pilot_exception.dart';
import 'package:pilot_app/features/auth/domain/auth_repository.dart';

/// Tela "Alterar senha": senha atual, nova, confirmar; POST /api/v1/auth/change-password com Bearer.
class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _loading = false;
  String? _errorMessage;
  bool _success = false;

  static bool _isStrongPassword(String s) {
    if (s.length < 8) return false;
    if (!RegExp(r'[A-Z]').hasMatch(s)) return false;
    if (!RegExp(r'[a-z]').hasMatch(s)) return false;
    if (!RegExp(r'[0-9]').hasMatch(s)) return false;
    return true;
  }

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    _errorMessage = null;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await serviceLocator<AuthRepository>().changePassword(
        _currentController.text,
        _newController.text,
      );
      if (!mounted) return;
      setState(() {
        _loading = false;
        _success = true;
      });
    } on AuthException catch (_) {
      setState(() {
        _loading = false;
        _errorMessage = 'Senha atual incorreta.';
      });
    } on ValidationException catch (e) {
      setState(() {
        _loading = false;
        _errorMessage = e.message;
      });
    } catch (_) {
      setState(() {
        _loading = false;
        _errorMessage = 'Não foi possível alterar a senha.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alterar senha'),
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
                      Icons.check_circle_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Senha alterada com sucesso.',
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () => context.go('/'),
                      child: const Text('Voltar'),
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
                        controller: _currentController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Senha atual',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Informe a senha atual';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _newController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Nova senha',
                          helperText:
                              'Mín. 8 caracteres, maiúscula, minúscula e número',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Informe a nova senha';
                          }
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
                          if (v != _newController.text) {
                            return 'Senhas não conferem';
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
                            : const Text('Alterar senha'),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => context.go('/'),
                        child: const Text('Cancelar'),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
