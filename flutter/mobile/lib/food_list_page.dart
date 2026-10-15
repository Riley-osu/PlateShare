import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'main.dart';

class FoodListPage extends StatefulWidget {
  final List<FoodPost> posts;

  const FoodListPage({
    super.key,
    required this.posts,
  });

  @override
  State<FoodListPage> createState() => _FoodListPageState();
}

class _FoodListPageState extends State<FoodListPage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  late final Stream<QuerySnapshot<Map<String, dynamic>>> listingsStream;

  @override
  void initState() {
    super.initState();
    listingsStream = firestore.collection('listings').snapshots();
  }

  Future<String> getOrganizationName(String organizationID) async {
    if (organizationID.isEmpty) {
      return "Unknown Organization";
    }

    try {
      final orgDoc = await firestore
          .collection('organizations')
          .doc(organizationID)
          .get();

      if (!orgDoc.exists) {
        return "Unknown Organization";
      }

      return orgDoc.data()?['organizationName'] as String? ??
          "Unknown Organization";
    } catch (e) {
      return "Unknown Organization";
    }
  }

  Future<void> reserveSlot(
    String listingID,
    int currentQuantity,
  ) async {
    if (currentQuantity <= 0) return;

    try {
      await firestore.runTransaction((transaction) async {
        final listingRef = firestore
            .collection('listings')
            .doc(listingID);

        final snapshot = await transaction.get(listingRef);

        if (!snapshot.exists) {
          throw Exception('This food post no longer exists.');
        }

        final data = snapshot.data();

        final quantity = data?['quantity'] as int? ?? 0;

        if (quantity <= 0) {
          throw Exception('No slots are available.');
        }

        transaction.update(listingRef, {
          'quantity': quantity - 1,
        });
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to reserve slot: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: listingsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading food posts: ${snapshot.error}',
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final listings = snapshot.data!.docs;

        if (listings.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                "No food posts available yet.\nOrganizations can create posts in the Post tab.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: listings.length,
          itemBuilder: (context, index) {
            final listingDoc = listings[index];
            final listing = listingDoc.data();

            final foodType =
                (listing['foodName'] ?? '').toString();

            final description =
                (listing['description'] ?? '').toString();

            final imageUrl =
                (listing['imageURL'] ?? '').toString();

            final remainingSlots =
                (listing['quantity'] as num?)?.toInt() ?? 0;

            final isDepleted = remainingSlots <= 0;

            final organizationID =
                (listing['organizationID'] ?? '').toString();

            final pickupStart =
                (listing['pickupStart'] as Timestamp?)?.toDate() ??
                    DateTime.now();

            final pickupEnd =
                (listing['pickupEnd'] as Timestamp?)?.toDate() ??
                    DateTime.now();

            final date = pickupStart;

            final startTime = TimeOfDay.fromDateTime(pickupStart);
            final endTime = TimeOfDay.fromDateTime(pickupEnd);

            DecorationImage? bgImage;

            if (imageUrl.isNotEmpty) {
              bgImage = DecorationImage(
                image: NetworkImage(imageUrl),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withValues(alpha: 0.65),
                  BlendMode.darken,
                ),
              );
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 20),
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 4,
              child: Container(
                height: 280,
                decoration: BoxDecoration(
                  color: bgImage == null
                      ? Colors.grey.shade900
                      : null,
                  image: bgImage,
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- ORGANIZATION & FOOD TYPE ---
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              FutureBuilder<String>(
                                future: getOrganizationName(
                                  organizationID,
                                ),
                                builder: (context, orgSnapshot) {
                                  return Text(
                                    orgSnapshot.data ??
                                        "Loading organization...",
                                    style: const TextStyle(
                                      color: Colors.orangeAccent,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  );
                                },
                              ),
                              const SizedBox(height: 2),
                              Text(
                                foodType,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // --- DATE & TIME SCHEDULE ROW ---
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          color: Colors.orange,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "${date.month}/${date.day}/${date.year}",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.access_time,
                          color: Colors.orange,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "${startTime.format(context)} - ${endTime.format(context)}",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // --- DESCRIPTION ---
                    Expanded(
                      child: Text(
                        description,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // --- SLOTS & RESERVE BUTTON ---
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isDepleted
                              ? "FULL / NO SLOTS LEFT"
                              : "Slots Left: $remainingSlots",
                          style: TextStyle(
                            color: isDepleted
                                ? Colors.redAccent
                                : Colors.lightGreenAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDepleted
                                ? Colors.grey
                                : Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          onPressed: isDepleted
                              ? null
                              : () {
                                  reserveSlot(
                                    listingDoc.id,
                                    remainingSlots,
                                  );
                                },
                          icon: const Icon(
                            Icons.bookmark_add,
                            size: 16,
                          ),
                          label: Text(
                            isDepleted
                                ? "Claimed"
                                : "Reserve Slot",
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}