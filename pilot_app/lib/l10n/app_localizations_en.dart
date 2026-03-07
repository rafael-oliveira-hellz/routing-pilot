// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Pilot';

  @override
  String get loginTitle => 'Log in';

  @override
  String get registerTitle => 'Create account';

  @override
  String get forgotPassword => 'Forgot password';

  @override
  String get resetPassword => 'Reset password';

  @override
  String get changePassword => 'Change password';

  @override
  String get logout => 'Log out';

  @override
  String get newRoute => 'New route';

  @override
  String get incidentsNearby => 'Nearby incidents';

  @override
  String get reportIncident => 'Report incident';

  @override
  String get adminUsers => 'Administration — Users';

  @override
  String get security => 'Security and sessions';

  @override
  String get themeToggle => 'Theme (light/dark/system)';

  @override
  String get back => 'Back';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get remove => 'Remove';

  @override
  String get removeUser => 'Remove user';

  @override
  String get noPermission => 'No permission';

  @override
  String get errorPageTitle => 'Error';

  @override
  String get errorGeneric => 'Something went wrong.';

  @override
  String supportCode(String traceId) {
    return 'Code: $traceId';
  }

  @override
  String get calculateRoute => 'Calculate route';

  @override
  String get calculating => 'Calculating...';

  @override
  String get recalculateRoute => 'Recalculate route';

  @override
  String get viewOnMap => 'View on map';

  @override
  String get startRoute => 'Start route (live ETA)';

  @override
  String get fillLastRoute => 'Fill with last route';

  @override
  String get origin => 'Origin';

  @override
  String get destination => 'Destination';

  @override
  String get stops => 'Stops (max. 1000)';

  @override
  String get add => 'Add';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get system => 'System';
}
