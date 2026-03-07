import 'package:flutter/material.dart';

/// Strings da aplicação. pt-BR padrão; estrutura para en. APP-1008.
/// Para adicionar novos idiomas: estender _Strings e registrar em byLocale.
abstract class AppStrings {
  String get appTitle;
  String get loginTitle;
  String get registerTitle;
}

class _StringsPt extends AppStrings {
  @override
  String get appTitle => 'Pilot';
  @override
  String get loginTitle => 'Entrar';
  @override
  String get registerTitle => 'Criar conta';
}

class _StringsEn extends AppStrings {
  @override
  String get appTitle => 'Pilot';
  @override
  String get loginTitle => 'Log in';
  @override
  String get registerTitle => 'Create account';
}

/// Retorna strings para o locale. pt-BR padrão; en disponível.
AppStrings appStringsFor(Locale locale) {
  if (locale.languageCode == 'en') return _StringsEn();
  return _StringsPt();
}
