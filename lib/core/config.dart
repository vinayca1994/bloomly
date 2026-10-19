class AppConfig {
  const AppConfig({
    required this.endpoint,
    required this.projectId,
    required this.upiId,
    required this.upiName,
  });

  final String endpoint;
  final String projectId;
  final String upiId;
  final String upiName;

  bool get hasAppwrite => endpoint.isNotEmpty && projectId.isNotEmpty;

  factory AppConfig.fromEnvironment() {
    return AppConfig(
      endpoint: const String.fromEnvironment('APPWRITE_ENDPOINT'),
      projectId: const String.fromEnvironment('APPWRITE_PROJECT_ID'),
      upiId: const String.fromEnvironment('BLOOMLY_UPI_ID'),
      upiName: const String.fromEnvironment('BLOOMLY_UPI_NAME', defaultValue: 'Bloomly'),
    );
  }
}
