import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'main.dart';

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
  var foodTypeController = TextEditingController();
  var descController = TextEditingController();
  var slotsController = TextEditingController();

  DateTime selectedDate = DateTime.now();
  TimeOfDay startTime = const TimeOfDay(hour: 12, minute: 0);
  TimeOfDay endTime = const TimeOfDay(hour: 13, minute: 0);
  File? pickedImage;

  var postFormKey = GlobalKey<FormState>();

  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  bool isPublishing = false;

  DateTime _combineDateAndTime(DateTime date, TimeOfDay time) {
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  // NEW: Save the food listing to Firestore
  Future<String> _savePostToFirebase({
    required String foodName,
    required String description,
    required int quantity,
    required DateTime pickupStart,
    required DateTime pickupEnd,
  }) async {
    final user = firebaseAuth.currentUser;

    if (user == null) {
      throw Exception('You must be logged in to create a post.');
    }

    // Find the organization belonging to this user.
    final orgQuery = await firestore
        .collection('organizations')
        .where('ownerID', isEqualTo: user.uid)
        .limit(1)
        .get();

    if (orgQuery.docs.isEmpty) {
      throw Exception('Organization not found in Firebase.');
    }

    final organization = orgQuery.docs.first;
    final orgData = organization.data();

    // Only approved organizations can publish food posts.
    if (orgData['status'] != 'active') {
      throw Exception(
        'Your organization must be approved before posting.',
      );
    }

    // Use the organization's saved address if available, if not leave it empty.
    final location =
        (orgData['address'] ?? '').toString();

    // Firestore stores the image URL
    const String imageURL = '';

    final document = await firestore
        .collection('listings')
        .add({
      'createdAt': FieldValue.serverTimestamp(),
      'description': description,
      'foodName': foodName,
      'imageURL': imageURL,
      'location': location,
      'organizationID': organization.id,
      'pickupEnd': Timestamp.fromDate(pickupEnd),
      'pickupStart': Timestamp.fromDate(pickupStart),
      'quantity': quantity,
      'status': 'available',
    });

    // Return the real Firestore document ID.
    return document.id;
  }

  // Publish to Firebase and update the existing local list
  Future<void> _publishPost() async {
    if (isPublishing) return;

    if (!postFormKey.currentState!.validate()) {
      return;
    }

    final quantity = int.parse(slotsController.text);

    if (quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Available Slots must be greater than zero.'),
        ),
      );
      return;
    }

    final pickupStart =
        _combineDateAndTime(selectedDate, startTime);

    final pickupEnd =
        _combineDateAndTime(selectedDate, endTime);

    if (!pickupEnd.isAfter(pickupStart)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End time must be after start time.'),
        ),
      );
      return;
    }

    setState(() {
      isPublishing = true;
    });

    try {
      final postID = await _savePostToFirebase(
        foodName: foodTypeController.text.trim(),
        description: descController.text.trim(),
        quantity: quantity,
        pickupStart: pickupStart,
        pickupEnd: pickupEnd,
      );

      if (!mounted) return;

      // Keep your original FoodPost functionality.
      var newPost = FoodPost(
        id: postID,
        orgName: widget.currentUser.orgName!,
        foodType: foodTypeController.text,
        description: descController.text,
        imageFile: pickedImage,
        date: selectedDate,
        startTime: startTime,
        endTime: endTime,
        remainingSlots: quantity,
      );

      widget.onPostCreated(newPost);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to publish post: $e'),
        ),
      );
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
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
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
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
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
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),

            // --- PUBLISH BUTTON ---
            ElevatedButton(
              onPressed: isPublishing ? null : _publishPost,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
             child: const Text(
               "Publish Post",
               style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}