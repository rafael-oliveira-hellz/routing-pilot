import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pilot_app/core/config/theme_mode_notifier.dart';
import 'package:pilot_app/core/di/injection.dart';
import 'package:pilot_app/features/auth/domain/auth_repository.dart';
import 'package:pilot_app/l10n/app_localizations.dart';

/// Placeholder da tela inicial até a implementação da home real (pós-login).
/// Menu Administração só visível para role == ADMIN. APP-1007. Tema claro/escuro. APP-1008.
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

  void _showThemeMenu(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final notifier = serviceLocator<ThemeModeNotifier>();
    showMenu<ThemeMode>(
      context: context,
      position: const RelativeRect.fromLTRB(1, 80, 0, 0),
      items: [
        PopupMenuItem(value: ThemeMode.light, child: Text(l10n.light)),
        PopupMenuItem(value: ThemeMode.dark, child: Text(l10n.dark)),
        PopupMenuItem(value: ThemeMode.system, child: Text(l10n.system)),
      ],
    ).then((mode) {
      if (mode != null) notifier.setThemeMode(mode);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      label: 'Tela inicial Pilot. Navegação para nova rota, incidentes, administração e configurações.',
      child: Scaffold(
        appBar: AppBar(
        title: Text(l10n.appTitle),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6),
            tooltip: l10n.themeToggle,
            onPressed: () => _showThemeMenu(context),
          ),
          IconButton(
            icon: const Icon(Icons.add_road),
            tooltip: l10n.newRoute,
            onPressed: () => GoRouter.of(context).go('/routes/new'),
          ),
          IconButton(
            icon: const Icon(Icons.warning_amber),
            tooltip: l10n.incidentsNearby,
            onPressed: () => GoRouter.of(context).go('/incidents'),
          ),
          IconButton(
            icon: const Icon(Icons.report),
            tooltip: l10n.reportIncident,
            onPressed: () => GoRouter.of(context).go('/incidents/report'),
          ),
          if (_isAdmin == true)
            IconButton(
              icon: const Icon(Icons.people),
              tooltip: l10n.adminUsers,
              onPressed: () => GoRouter.of(context).go('/admin/users'),
            ),
          IconButton(
            icon: const Icon(Icons.security),
            tooltip: l10n.security,
            onPressed: () => GoRouter.of(context).go('/security'),
          ),
          IconButton(
            icon: const Icon(Icons.lock_reset),
            tooltip: l10n.changePassword,
            onPressed: () => GoRouter.of(context).go('/change-password'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: l10n.logout,
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
      ),
    );
  }
}
