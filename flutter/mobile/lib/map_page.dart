import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapPage extends StatefulWidget {
  final ValueChanged<String> onListingSelected;

  const MapPage({super.key, required this.onListingSelected});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _listingsStream;

  @override
  void initState() {
    super.initState();
    _listingsStream = FirebaseFirestore.instance
        .collection('listings')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _listingsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Unable to load map listings: ${snapshot.error}'),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final markers = <Marker>[];
        for (final listing in snapshot.data!.docs) {
          final data = listing.data();
          final latitude = (data['lat'] as num?)?.toDouble();
          final longitude = (data['lng'] as num?)?.toDouble();
          if (latitude == null ||
              longitude == null ||
              !latitude.isFinite ||
              !longitude.isFinite ||
              latitude < -90 ||
              latitude > 90 ||
              longitude < -180 ||
              longitude > 180) {
            continue;
          }

          final foodName = (data['foodName'] ?? 'Food listing').toString();
          markers.add(
            Marker(
              point: LatLng(latitude, longitude),
              width: 160,
              height: 64,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => widget.onListingSelected(listing.id),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      constraints: const BoxConstraints(maxWidth: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 4),
                        ],
                      ),
                      child: Text(
                        foodName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.location_on,
                      size: 32,
                      color: Colors.deepOrange,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Stack(
          children: [
            FlutterMap(
              options: const MapOptions(
                initialCenter: LatLng(36.1231, -97.0654),
                initialZoom: 14,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.mobile',
                ),
                MarkerLayer(markers: markers),
              ],
            ),
            if (markers.isEmpty)
              const Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'No listings with location data are available yet.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            Positioned(
              bottom: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '© OpenStreetMap contributors',
                  style: TextStyle(fontSize: 10, color: Colors.black54),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
