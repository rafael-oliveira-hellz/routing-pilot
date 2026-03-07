import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pilot_app/core/di/injection.dart';
import 'package:pilot_app/core/domain/dto/auth_dto.dart';
import 'package:pilot_app/core/error/pilot_exception.dart';
import 'package:pilot_app/features/admin/domain/admin_repository.dart';
import 'package:pilot_app/features/auth/domain/auth_repository.dart';

/// Tela Admin — Lista de usuários. Visível só para role == ADMIN. GET /users, DELETE /users/{id}.
class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  List<UserListItemDto> _users = [];
  bool _loading = true;
  String? _errorMessage;
  UserResponse? _currentUser;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final authRepo = serviceLocator<AuthRepository>();
    final user = await authRepo.getCurrentUser();
    if (!mounted) return;
    if (user == null || !user.isAdmin) {
      setState(() {
        _loading = false;
        _errorMessage = 'Sem permissão';
      });
      return;
    }
    setState(() {
      _currentUser = user;
      _errorMessage = null;
    });
    try {
      final list = await serviceLocator<AdminRepository>().getUsers();
      if (!mounted) return;
      setState(() {
        _users = list;
        _loading = false;
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = 'Falha ao carregar usuários.';
      });
    }
  }

  Future<void> _deleteUser(UserListItemDto user) async {
    if (_currentUser?.id == user.id) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover usuário'),
        content: Text(
          'Remover ${user.name} (${user.email})? O backend pode impedir remover o último admin.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _errorMessage = null);
    try {
      await serviceLocator<AdminRepository>().deleteUser(user.id);
      if (!mounted) return;
      _load();
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
    } on ValidationException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Não foi possível remover. Pode ser o último admin?');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Usuários')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_errorMessage == 'Sem permissão') {
      return Scaffold(
        appBar: AppBar(title: const Text('Usuários')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.block, size: 64, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              Text(
                'Sem permissão',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go('/'),
                child: const Text('Voltar'),
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuários'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Theme.of(context).colorScheme.errorContainer,
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
              ),
            ),
          Expanded(
            child: _users.isEmpty
                ? Center(
                    child: Text(
                      'Nenhum usuário.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      final u = _users[index];
                      final isSelf = _currentUser?.id == u.id;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(u.name),
                          subtitle: Text(
                            '${u.email} · ${u.role}${u.active ? '' : ' (inativo)'}',
                          ),
                          trailing: isSelf
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => _deleteUser(u),
                                  tooltip: 'Remover',
                                ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
