import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/config.dart';
import '../../core/theme.dart';
import '../../data/models.dart';

class DeliveryMap extends StatelessWidget {
  const DeliveryMap({
    required this.rider,
    required this.destLatitude,
    required this.destLongitude,
    super.key,
  });

  final RiderLocation? rider;
  final double? destLatitude;
  final double? destLongitude;

  @override
  Widget build(BuildContext context) {
    final dest = destLatitude == null || destLongitude == null
        ? null
        : LatLng(destLatitude!, destLongitude!);
    final pin = rider == null ? null : LatLng(rider!.latitude, rider!.longitude);
    if (dest == null && pin == null) {
      return const _WaitingMap(message: 'Waiting for the rider’s location.');
    }
    final center = pin != null && dest != null
        ? LatLng((pin.latitude + dest.latitude) / 2, (pin.longitude + dest.longitude) / 2)
        : (pin ?? dest)!;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 220,
        child: Stack(
          children: [
            FlutterMap(
              key: ValueKey('${pin?.latitude},${pin?.longitude},${dest?.latitude}'),
              options: MapOptions(initialCenter: center, initialZoom: pin != null && dest != null ? 13 : 15),
              children: [
                TileLayer(
                  urlTemplate: AppConfig.fromEnvironment().mapTileUrl,
                  userAgentPackageName: 'com.bloomly.bloomly',
                ),
                MarkerLayer(
                  markers: [
                    if (dest != null)
                      Marker(
                        point: dest,
                        width: 36,
                        height: 36,
                        child: const Icon(Icons.place, color: BloomlyColors.marigold, size: 32),
                      ),
                    if (pin != null)
                      Marker(
                        point: pin,
                        width: 40,
                        height: 40,
                        child: const Icon(Icons.delivery_dining, color: BloomlyColors.amber, size: 32),
                      ),
                  ],
                ),
              ],
            ),
            const Positioned(
              left: 8,
              bottom: 6,
              child: Text(
                '© OpenStreetMap',
                style: TextStyle(fontSize: 11, color: BloomlyColors.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WaitingMap extends StatelessWidget {
  const _WaitingMap({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: BloomlyColors.leafWash,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Text(message, textAlign: TextAlign.center),
    );
  }
}
