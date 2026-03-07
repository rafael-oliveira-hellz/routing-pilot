import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:pilot_app/core/config/app_config.dart';

/// Certificate pinning: valida SHA-256 do certificado do servidor.
/// Ativo quando AppConfig.enableCertificatePinning e CERT_PIN_SHA256 no .env.
/// APP-8002.
bool validateCertificatePinning(X509Certificate cert, String host, int port) {
  if (!AppConfig.enableCertificatePinning) return true;
  final expected = AppConfig.certificatePinSha256;
  if (expected == null || expected.isEmpty) return false;
  final digest = sha256.convert(cert.der);
  final hex = digest.toString();
  final normalized = expected.replaceAll(':', '').replaceAll(' ', '').toLowerCase();
  return hex == normalized;
}
