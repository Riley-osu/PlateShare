import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'main.dart'; // Gives access to globalPostsList and FoodPost model

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  // Tracks the currently tapped food post object to show its popup card
  dynamic _selectedPost; 

  @override
  Widget build(BuildContext context) {
    // Edmon Low Library Coordinates set as the default map center
    final LatLng edmonLowLibrary = const LatLng(36.1231, -97.0654);

    return Scaffold(
      body: Stack(
        children: [
          // OpenStreetMap Layer
          FlutterMap(
            options: MapOptions(
              initialCenter: edmonLowLibrary,
              initialZoom: 16.0,
              onTap: (_, __) {
                // Dismiss popup card when tapping empty map area
                if (_selectedPost != null) {
                  setState(() => _selectedPost = null);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.mobile',
              ),
              
              MarkerLayer(
                markers: globalPostsList.map((post) {
                  return Marker(
                    // TODO [Backend]: Replace with actual post coordinates from database
                    point: LatLng(post.latitude ?? 36.1231, post.longitude ?? -97.0654), 
                    width: 40,
                    height: 40,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedPost = post;
                        });
                      },
                      child: const Icon(
                        Icons.location_on,
                        size: 40,
                        color: Colors.orange,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // OpenStreetMap Attribution notice
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                "© OpenStreetMap contributors",
                style: TextStyle(fontSize: 10, color: Colors.black54),
              ),
            ),
          ),

          // Interactive Pop-up Reservation & Image Widget Card
          if (_selectedPost != null)
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: Card(
                elevation: 8.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedPost.orgName, // Backend field: Organization Name
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.deepOrange,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () => setState(() => _selectedPost = null),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // ---------------------------------------------------------
                      // Handle image display via `_selectedPost.imageUrl` (Firebase Storage URL)
                      // ---------------------------------------------------------
                      Container(
                        height: 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _selectedPost.imageUrl != null
                            ? Image.network(_selectedPost.imageUrl!, fit: BoxFit.cover)
                            : const Center(
                                child: Icon(Icons.fastfood, size: 40, color: Colors.orange),
                              ),
                      ),
                      const SizedBox(height: 12),

                      Text(
                        _selectedPost.foodType, // Backend field: Food type / title
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedPost.description, // Backend field: Description details
                        style: const TextStyle(color: Colors.black87, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Remaining Slots: ${_selectedPost.remainingSlots}", // Backend field: Real-time slot count
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                      ),
                      const SizedBox(height: 16),

                      // Reservation / Claim Widget Button
                      SizedBox(
                        width: double.infinity,
                        height: 40,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade800,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            // -----------------------------------------------------
                            // Call backend API / Firestore transaction to decrement 
                            // -----------------------------------------------------
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Slot reserved successfully!")),
                            );
                            setState(() => _selectedPost = null);
                          },
                          child: const Text("Reserve / Claim Food"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}