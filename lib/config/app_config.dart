class AppConfig {
  static const String defaultWorkerBaseUrl =
      'https://bemichat-worker.syedhasnatali785.workers.dev';

  static String get workerBaseUrl => defaultWorkerBaseUrl;

  static String normalizeWorkerBaseUrl(String rawUrl) {
    final value = rawUrl.trim();
    if (value.isEmpty) return defaultWorkerBaseUrl;
    final uri = Uri.parse(value);
    return uri.toString().replaceFirst(RegExp(r'/+$'), '');
  }

  static String turnCredentialsEndpoint([String? workerUrl]) =>
      '${normalizeWorkerBaseUrl(workerUrl ?? defaultWorkerBaseUrl)}/turn-credentials';

  static String notificationEndpoint([String? workerUrl]) =>
      '${normalizeWorkerBaseUrl(workerUrl ?? defaultWorkerBaseUrl)}/send-notification';
}
