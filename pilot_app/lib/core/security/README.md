# core/security

- **SecureTokenStorage**: `flutter_secure_storage` para access e refresh token; não logar valores.
- **JwtParser**: leitura de claims (exp, sub, vehicleId, role); refresh antes de expirar (ex.: 1 h); não logar token.
- **HTTPS**: obrigatório em staging/prod; certificate pinning opcional e configurável por env (doc 14).
- Em builds release, obfuscar e não logar tokens nem dados sensíveis.
