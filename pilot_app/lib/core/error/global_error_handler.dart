import 'package:flutter/foundation.dart';
import 'package:pilot_app/core/error/pilot_exception.dart';

/// Captura erros não tratados. Não loga tokens, senhas nem posições. APP-8001, APP-8002.
void setupGlobalErrorHandler() {
  FlutterError.onError = (details) {
    if (kReleaseMode) {
      // Em produção: logar apenas mensagem e traceId, sem stack trace sensível
      final traceId = details.exception is PilotException
          ? (details.exception as PilotException).traceId
          : null;
      // ignore: avoid_print
      print('FlutterError: ${details.exceptionAsString().split('\n').first}'
          '${traceId != null ? ' traceId=$traceId' : ''}');
    } else {
      FlutterError.presentError(details);
    }
  };
}
