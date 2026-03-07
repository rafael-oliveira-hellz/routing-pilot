// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Pilot';

  @override
  String get loginTitle => 'Entrar';

  @override
  String get registerTitle => 'Criar conta';

  @override
  String get forgotPassword => 'Esqueci a senha';

  @override
  String get resetPassword => 'Redefinir senha';

  @override
  String get changePassword => 'Alterar senha';

  @override
  String get logout => 'Sair';

  @override
  String get newRoute => 'Nova rota';

  @override
  String get incidentsNearby => 'Incidentes próximos';

  @override
  String get reportIncident => 'Reportar incidente';

  @override
  String get adminUsers => 'Administração — Usuários';

  @override
  String get security => 'Segurança e sessões';

  @override
  String get themeToggle => 'Tema (claro/escuro/sistema)';

  @override
  String get back => 'Voltar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get confirm => 'Confirmar';

  @override
  String get remove => 'Remover';

  @override
  String get removeUser => 'Remover usuário';

  @override
  String get noPermission => 'Sem permissão';

  @override
  String get errorPageTitle => 'Erro';

  @override
  String get errorGeneric => 'Algo deu errado.';

  @override
  String supportCode(String traceId) {
    return 'Código: $traceId';
  }

  @override
  String get calculateRoute => 'Calcular rota';

  @override
  String get calculating => 'Calculando...';

  @override
  String get recalculateRoute => 'Recalcular rota';

  @override
  String get viewOnMap => 'Ver no mapa';

  @override
  String get startRoute => 'Iniciar rota (ETA ao vivo)';

  @override
  String get fillLastRoute => 'Preencher com última rota';

  @override
  String get origin => 'Origem';

  @override
  String get destination => 'Destino';

  @override
  String get stops => 'Paradas (máx. 1000)';

  @override
  String get add => 'Adicionar';

  @override
  String get light => 'Claro';

  @override
  String get dark => 'Escuro';

  @override
  String get system => 'Sistema';
}
