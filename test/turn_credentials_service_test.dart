import 'package:bemichat/services/turn_credential_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalizes worker URL to the TURN credentials endpoint', () {
    final service = TurnCredentialsService(
      workerUrl: 'https://bemichat-worker.syedhasnatali785.workers.dev',
    );
    expect(
      service.turnCredentialsUrl.toString(),
      'https://bemichat-worker.syedhasnatali785.workers.dev/turn-credentials',
    );

    final serviceWithTrailingSlash = TurnCredentialsService(
      workerUrl: 'https://bemichat-worker.syedhasnatali785.workers.dev/',
    );
    expect(
      serviceWithTrailingSlash.turnCredentialsUrl.toString(),
      'https://bemichat-worker.syedhasnatali785.workers.dev/turn-credentials',
    );
  });
}
