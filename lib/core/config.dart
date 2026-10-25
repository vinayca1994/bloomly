class AppConfig {
  const AppConfig({
    required this.endpoint,
    required this.projectId,
    required this.upiId,
    required this.upiName,
    required this.mapTileUrl,
  });

  final String endpoint;
  final String projectId;
  final String upiId;
  final String upiName;

  /// Public OSM tiles are fine for light use. Set `BLOOMLY_MAP_TILES` to a
  /// host whose terms allow production traffic. `{z}`, `{x}`, and `{y}` are
  /// replaced by the map.
  final String mapTileUrl;

  static const defaultMapTiles = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  bool get hasAppwrite => endpoint.isNotEmpty && projectId.isNotEmpty;

  factory AppConfig.fromEnvironment() {
    final tiles = const String.fromEnvironment('BLOOMLY_MAP_TILES');
    return AppConfig(
      endpoint: const String.fromEnvironment('APPWRITE_ENDPOINT'),
      projectId: const String.fromEnvironment('APPWRITE_PROJECT_ID'),
      upiId: const String.fromEnvironment('BLOOMLY_UPI_ID'),
      upiName: const String.fromEnvironment('BLOOMLY_UPI_NAME', defaultValue: 'Bloom'),
      mapTileUrl: tiles.trim().isEmpty ? defaultMapTiles : tiles.trim(),
    );
  }
}
