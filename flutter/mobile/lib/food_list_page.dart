import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'main.dart';
import 'api_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FoodListPage extends StatefulWidget {
  final List<FoodPost> posts;
  final UserData currentUser;

  const FoodListPage({
    super.key,
    required this.posts,
    required this.currentUser,
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

  // Allows the user to reserve a listing
  Future<void> reserveSlot(
    String listingID,
    int currentQuantity,
  ) async {

    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar (
          content: Text('You must be logged in to reserve food.'),
        ),
      );

      return;
    }


    //if (currentQuantity <= 0) return;

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

        final reservedBy = List<String>.from (
          data?['reservedBy'] ?? [],
        );

        if (reservedBy.contains(user.uid)) {
          throw Exception('You have already reserved this food listing.');
        }

        if (quantity <= 0) {
          throw Exception('No slots are available.');
        }

        reservedBy.add(user.uid);

        transaction.update(listingRef, {
          'quantity': quantity - 1,
          'reservedBy': reservedBy,
        });
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar (
        const SnackBar (
          content: Text ('Food slot reserved successfully!'),
        ),
      );

    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to reserve slot: $e'),
        ),
      );
    }
  }
  // Function to delete a food listing
  Future<void> deleteFoodListing(String listingID) async {
    
    final bool? confirmDelete = await showDialog<bool> (
      context: context,
      builder: (dialogContext) => AlertDialog (
        title: const Text('Confirm Deletion'),
        content: const Text (
          'Are you sure you want to delete this food listing? This action cannot be undone',
        ),

        actions: [
          TextButton (
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),

          TextButton (
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (!mounted ||confirmDelete != true) return;
    
    // Buffering animation while deleting
    showDialog<void> (
      context: context,
      barrierDismissible: false,
      builder: (loadingContext) => const PopScope (
        canPop: false,
        child: AlertDialog (
          content: Row (
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Expanded (
                child: Text ('Deleting...'),
              ),
            ],
          ),
        ),
      ),
    );



    try {
      await ApiService.deleteListing(
        listingId: listingID,
      );

      if (!mounted) return;

      Navigator.of(context, rootNavigator: true).pop();

      ScaffoldMessenger.of(context).showSnackBar (
        const SnackBar (
          content: Text('Food listing deleted successfully.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      Navigator.of(context, rootNavigator: true).pop();

      ScaffoldMessenger.of(context).showSnackBar (
        SnackBar (
          content: Text ('Failed to delete food listing: $e'),
        ),
      );
    }
  }
  // Function to edit a food listing
  Future<void> editFoodListing(
    String listingID,
    String currentFoodName,
    String currentDescription,
    int currentQuantity,
  ) async {

    final foodNameController =
      TextEditingController(text: currentFoodName);

    final descriptionController =
      TextEditingController(text: currentDescription);

    final quantityController =
      TextEditingController(text: currentQuantity.toString());

    bool isSaving = false;

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return PopScope(
                canPop: !isSaving,
                child: AlertDialog(
                  title: const Text('Edit Food Listing'),

                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: foodNameController,
                          enabled: !isSaving,
                          decoration: const InputDecoration(
                            labelText: 'Food Name',
                          ),
                        ),

                        TextField(
                          controller: descriptionController,
                          enabled: !isSaving,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                          ),
                          maxLines: 3,
                        ),

                        TextField(
                          controller: quantityController,
                          enabled: !isSaving,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Available Slots',
                          ),
                        ),
                      ],
                    ),
                  ),

                  actions: [
                    TextButton(
                      onPressed: isSaving
                          ? null
                          : () {
                              Navigator.pop(dialogContext);
                            },
                      child: const Text('Cancel'),
                    ),

                    ElevatedButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              final foodName =
                                  foodNameController.text.trim();

                              final description =
                                  descriptionController.text.trim();

                              final quantity = int.tryParse(
                                quantityController.text.trim(),
                              );

                              if (foodName.isEmpty ||
                                  description.isEmpty ||
                                  quantity == null ||
                                  quantity < 0) {
                                ScaffoldMessenger.of(dialogContext)
                                    .showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Enter a food name, description, and valid quantity.',
                                    ),
                                  ),
                                );
                                return;
                              }

                            // Disable Save and show loading animation
                              setDialogState(() {
                                isSaving = true;
                              });

                              try {
                                await ApiService.updateListing(
                                  listingId: listingID,
                                  foodName: foodName,
                                  description: description,
                                  quantity: quantity,
                                );

                                if (!mounted) return;

                                if (dialogContext.mounted) {
                                  Navigator.of(dialogContext).pop();
                                }

                                ScaffoldMessenger.of(this.context)
                                    .showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Food listing updated successfully.',
                                    ),
                                  ),
                                );
                              } catch (e) {
                                if (!mounted) return;

                                ScaffoldMessenger.of(this.context)
                                    .showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Failed to update food listing: $e',
                                    ),
                                  ),
                                );
                              } finally {
                                if (dialogContext.mounted) {
                                  setDialogState(() {
                                    isSaving = false;
                                  });
                                }
                              }
                            },

                      child: isSaving
                          ? const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Text('Saving Changes...'),
                              ],
                            )
                          : const Text('Save'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    } finally {
      await Future<void>.delayed(
        const Duration(milliseconds: 300),
      );

      foodNameController.dispose();
      descriptionController.dispose();
      quantityController.dispose();
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

            final canManagePost = 
                widget.currentUser.isApprovedOrg && 
                widget.currentUser.organizationID != null &&
                widget.currentUser.organizationID!.isNotEmpty &&
                organizationID == widget.currentUser.organizationID;

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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FutureBuilder<String>(
                                future: getOrganizationName(organizationID),
                                builder: (context, orgSnapshot) {
                                  return Text(
                                    orgSnapshot.data ?? "Loading organization...",
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

                      // Only the organization can see this menu
                      if (canManagePost)
                      PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.more_vert,
                          color: Colors.white,
                        ),
        
                        onSelected: (value) {
                          if (value == 'edit') {
                            editFoodListing(
                              listingDoc.id,
                              foodType,
                              description,
                              remainingSlots,
                            );
                            
                          } else if (value == 'delete') {
                            deleteFoodListing(listingDoc.id);
                          }
                        },
        
                        itemBuilder: (context) => const [
                          PopupMenuItem<String>(
                            value: 'edit',
                            child: Text('Edit'),
                          ),
          
                          PopupMenuItem<String>(
                            value: 'delete',
                            child: Text('Delete'),
                          ),
                        ],
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