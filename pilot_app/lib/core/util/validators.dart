// Validadores reutilizáveis (testáveis). APP-1008.

final RegExp _emailRegex = RegExp(r'^[\w.-]+@[\w.-]+\.[a-zA-Z]{2,}$');

bool isValidEmail(String? value) {
  if (value == null || value.trim().isEmpty) return false;
  return _emailRegex.hasMatch(value.trim());
}

/// Senha forte: mín. 8 caracteres, ao menos uma maiúscula, uma minúscula e um número.
bool isStrongPassword(String? value) {
  if (value == null || value.isEmpty) return false;
  if (value.length < 8) return false;
  if (!RegExp(r'[A-Z]').hasMatch(value)) return false;
  if (!RegExp(r'[a-z]').hasMatch(value)) return false;
  if (!RegExp(r'[0-9]').hasMatch(value)) return false;
  return true;
}
