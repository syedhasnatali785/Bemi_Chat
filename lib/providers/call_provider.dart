import 'package:bemichat/config/app_config.dart';
import 'package:bemichat/services/call_services/call_service.dart';
import 'package:bemichat/services/turn_credential_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final callServiceProvider = Provider<CallService>((ref) {
  return CallService(
    turnCredentials: TurnCredentialsService(workerUrl: AppConfig.workerBaseUrl),
  );
});
