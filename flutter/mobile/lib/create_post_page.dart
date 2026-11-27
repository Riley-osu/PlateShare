import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import 'main.dart';
import 'api_service.dart';

class CreatePostPage extends StatefulWidget {
  final UserData currentUser;
  final Function(FoodPost) onPostCreated;

  const CreatePostPage({
    super.key,
    required this.currentUser,
    required this.onPostCreated,
  });

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  static const MethodChannel _nativeGeocoder = MethodChannel(
    'com.example.mobile/native_geocoder',
  );

  var foodTypeController = TextEditingController();
  var descController = TextEditingController();
  var slotsController = TextEditingController();
  var locationController = TextEditingController();
  final FocusNode locationFocusNode = FocusNode();

  DateTime selectedDate = DateTime.now();
  TimeOfDay startTime = const TimeOfDay(hour: 12, minute: 0);
  TimeOfDay endTime = const TimeOfDay(hour: 13, minute: 0);
  File? pickedImage;

  var postFormKey = GlobalKey<FormState>();

  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  bool isPublishing = false;
  bool isFindingLocation = false;
  int _addressSearchGeneration = 0;

  Future<Iterable<String>> _addressOptionsBuilder(
    TextEditingValue value,
  ) async {
    final query = value.text.trim();
    final requestGeneration = ++_addressSearchGeneration;
    if (query.length < 3) return const [];

    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted || requestGeneration != _addressSearchGeneration) {
      return const [];
    }

    try {
      final suggestions = await _nativeGeocoder.invokeListMethod<String>(
        'searchAddresses',
        {'query': query},
      );
      if (!mounted || requestGeneration != _addressSearchGeneration) {
        return const [];
      }
      return suggestions ?? const [];
    } catch (error) {
      if (mounted && requestGeneration == _addressSearchGeneration) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to search nearby addresses: $error')),
        );
      }
      return const [];
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      isFindingLocation = true;
    });

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('Turn on location services and try again.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        throw Exception('Location permission was denied.');
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Location permission is disabled. Enable it in your device settings.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final address = await _nativeGeocoder.invokeMethod<String>(
        'reverseGeocode',
        {'latitude': position.latitude, 'longitude': position.longitude},
      );
      if (address == null || address.trim().isEmpty) {
        throw Exception('Could not find a street address at this location.');
      }
      if (!mounted) return;
      locationController.text = address.trim();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to get your address: $e')));
    } finally {
      if (mounted) {
        setState(() {
          isFindingLocation = false;
        });
      }
    }
  }

  DateTime _combineDateAndTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  // NEW: Save the food listing to Firestore

  // Publish to Firebase and update the existing local list
  Future<void> _publishPost() async {
    if (isPublishing) return;

    if (!postFormKey.currentState!.validate()) {
      return;
    }

    if (int.parse(slotsController.text) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Available Slots must be greater than zero.'),
        ),
      );
      return;
    }

    final pickupStart = _combineDateAndTime(selectedDate, startTime);

    final pickupEnd = _combineDateAndTime(selectedDate, endTime);

    if (!pickupEnd.isAfter(pickupStart)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time.')),
      );
      return;
    }

    setState(() {
      isPublishing = true;
    });
    // Sends food post information to the API using the ApiService.createPost().
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception('You must be logged in to create a post.');
      }

      final orgQuery = await FirebaseFirestore.instance
          .collection('organizations')
          .where('ownerID', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (orgQuery.docs.isEmpty) {
        throw Exception('No organization found for the current user.');
      }

      if (orgQuery.docs.first.data()['status'] != 'active') {
        throw Exception(
          'Your organization has not beenapproved to create posts.',
        );
      }

      final organizationID = orgQuery.docs.first.id;

      // Temporarily disabled
      if (pickedImage == null) {
        throw Exception('Please select an image for the post.');
      }

      final response = await ApiService.createPost(
        foodName: foodTypeController.text.trim(),
        description: descController.text.trim(),
        quantity: int.parse(slotsController.text),
        pickupStart: pickupStart,
        pickupEnd: pickupEnd,
        organizationID: organizationID,
        location: locationController.text.trim(),
        imageFile: pickedImage!, // should be pickedImage! but temporarily allowing null for testing purposes
      );

      final postID =
          (response['listingID'] ?? response['listingId'] ?? response['id'])
              ?.toString();

      if (postID == null || postID.isEmpty) {
        throw Exception('API response did not contain a listing ID.');
      }
      final latitude = (response['lat'] as num?)?.toDouble();
      final longitude = (response['lng'] as num?)?.toDouble();
      if (latitude == null || longitude == null) {
        throw Exception('API response did not contain listing coordinates.');
      }

      if (!mounted) return;

      // Keep your original FoodPost functionality.
      var newPost = FoodPost(
        id: postID,
        orgName: widget.currentUser.orgName!,
        foodType: foodTypeController.text,
        description: descController.text,
        imageFile: pickedImage,
        location: locationController.text.trim(),
        latitude: latitude,
        longitude: longitude,
        date: selectedDate,
        startTime: startTime,
        endTime: endTime,
        remainingSlots: int.parse(slotsController.text),
      );

      widget.onPostCreated(newPost);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Unable to publish post: $e')));
    } finally {
      if (mounted) {
        setState(() {
          isPublishing = false;
        });
      }
    }
  }

  // Function to pick an image from gallery
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        pickedImage = File(pickedFile.path);
      });
    }
  }

  // Function to pick the post date
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  // Function to pick start time
  Future<void> _selectStartTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: startTime,
    );
    if (picked != null && picked != startTime) {
      setState(() {
        startTime = picked;
      });
    }
  }

  // Function to pick end time
  Future<void> _selectEndTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: endTime,
    );
    if (picked != null && picked != endTime) {
      setState(() {
        endTime = picked;
      });
    }
  }

  @override
  void dispose() {
    foodTypeController.dispose();
    descController.dispose();
    slotsController.dispose();
    locationController.dispose();
    locationFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.currentUser.isOrganization ||
        widget.currentUser.orgName == null ||
        widget.currentUser.orgName!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.block, size: 70, color: Colors.red),
              SizedBox(height: 15),
              Text(
                "Posting Access Restricted",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              SizedBox(height: 10),
              Text(
                "You must be signed in as an Organization with a valid Organization Name to create posts.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 15),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: postFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- IMAGE PICKER SECTION ---
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: pickedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          pickedImage!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                          SizedBox(height: 8),
                          Text(
                            "Tap to add food image",
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // --- TEXT FIELDS ---
            TextFormField(
              controller: foodTypeController,
              decoration: const InputDecoration(
                labelText: "Food Type",
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.isEmpty ? "Required" : null,
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: descController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Description",
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.isEmpty ? "Required" : null,
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: slotsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Available Slots",
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return "Required";
                if (int.tryParse(v) == null) return "Enter a valid number";
                return null;
              },
            ),

            const SizedBox(height: 15),
            RawAutocomplete<String>(
              textEditingController: locationController,
              focusNode: locationFocusNode,
              optionsBuilder: _addressOptionsBuilder,
              onSelected: (address) {
                locationController.text = address;
              },
              fieldViewBuilder:
                  (context, controller, focusNode, onFieldSubmitted) {
                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: "Pickup Location",
                        helperText: "Address suggestions are centered on Stillwater, OK",
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Pickup location is required";
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => onFieldSubmitted(),
                    );
                  },
              optionsViewBuilder: (context, onSelected, options) {
                final suggestions = options.toList();
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(8),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 240),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: suggestions.length,
                        itemBuilder: (context, index) {
                          final address = suggestions[index];
                          return ListTile(
                            leading: const Icon(Icons.location_on_outlined),
                            dense: true,
                            title: Text(address),
                            onTap: () => onSelected(address),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: isFindingLocation ? null : _useCurrentLocation,
                icon: isFindingLocation
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location),
                label: Text(
                  isFindingLocation
                      ? "Finding address..."
                      : "Use current location",
                ),
              ),
            ),

            const SizedBox(height: 20),

            // --- DAY & TIME SECTION ---
            const Text(
              "Date & Time Schedule",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Date Selection Button
            OutlinedButton.icon(
              onPressed: () => _selectDate(context),
              icon: const Icon(Icons.calendar_today),
              label: Text(
                "Date: ${selectedDate.toLocal().toString().split(' ')[0]}",
              ),
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Start & End Time Selection Row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selectStartTime(context),
                    icon: const Icon(Icons.access_time),
                    label: Text("Start: ${startTime.format(context)}"),
                    style: OutlinedButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selectEndTime(context),
                    icon: const Icon(Icons.access_time_filled),
                    label: Text("End: ${endTime.format(context)}"),
                    style: OutlinedButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),

            // --- PUBLISH BUTTON with Buffer ---
            ElevatedButton(
              onPressed: isPublishing ? null : _publishPost,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),

              child: isPublishing
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),

                        SizedBox(width: 10),
                        Text("Publishing...", style: TextStyle(fontSize: 16)),
                      ],
                    )
                  : const Text("Publish Post", style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
