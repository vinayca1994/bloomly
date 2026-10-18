class AppConfig {
  const AppConfig({required this.endpoint, required this.projectId});

  final String endpoint;
  final String projectId;

  bool get hasAppwrite => endpoint.isNotEmpty && projectId.isNotEmpty;

  factory AppConfig.fromEnvironment() {
    return AppConfig(
      endpoint: const String.fromEnvironment('APPWRITE_ENDPOINT'),
      projectId: const String.fromEnvironment('APPWRITE_PROJECT_ID'),
    );
  }
}
