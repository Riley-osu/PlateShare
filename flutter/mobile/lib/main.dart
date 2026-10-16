import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'auth_service.dart';
import 'user_data.dart';
import 'main_dashboard.dart';

export 'user_data.dart';

List<UserData> registeredUsersList = [];

List<FoodPost> globalPostsList = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,

  );

  runApp(const MyApp());
}

class FoodPost {
  String id;
  String orgName;
  String foodType;
  String description;
  File? imageFile;
  String? imageUrl;
  DateTime date;
  TimeOfDay startTime;
  TimeOfDay endTime;
  int remainingSlots;

  FoodPost({
    required this.id,
    required this.orgName,
    required this.foodType,
    required this.description,
    this.imageFile,
    this.imageUrl,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.remainingSlots,
  });
}

// Main Application
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Okstate Portal',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      home: const LandingScreen(),
    );
  }
}

// LANDING SCREEN
class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: 1000, // force huge width
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange.shade800, Colors.black87],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),

        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.school, size: 90, color: Colors.white),
              const SizedBox(height: 20),
              const Text(
                "Welcome to OSU App",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 10),
              const Text(
                "Please Log In or Sign Up using your @okstate.edu email to continue.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),

              const SizedBox(height: 50),

              // Login Button Container
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.orange.shade900,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AuthScreen(isSignUp: false),
                      ),
                    );
                  },
                  child: const Text("Log In",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 15),
              // Signup Button Container
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AuthScreen(isSignUp: true),
                      ),
                    );
                  },
                  child: const Text("Sign Up",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// AUTHENTICATION SCREEN
class AuthScreen extends StatefulWidget {
  final bool isSignUp;
  const AuthScreen({super.key, required this.isSignUp});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final e1 = TextEditingController();
  final p1 = TextEditingController();
  final o1 = TextEditingController();

  bool isOrgSwitch = false;
  bool isSignUpPage = false;
  bool isLoading = false;

  final myFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    isSignUpPage = widget.isSignUp;
  }

  @override
  void dispose() {
    e1.dispose();
    p1.dispose();
    o1.dispose();
    super.dispose();
  }
  
  Future<void> handleAuthentication() async {
    FocusScope.of(context).unfocus();

    if (!myFormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    final userEmail = e1.text.trim().toLowerCase();
    final userPass = p1.text;

    try {
      if (isSignUpPage) {
        await authService.value.createAccount(email: userEmail, password: userPass, isOrganization: isOrgSwitch, orgName: isOrgSwitch ? o1.text.trim() : null);
      } else {
        await authService.value.signIn(email: userEmail, password: userPass);

      }

      final loggedUser = await authService.value.getUserData();

      if (loggedUser == null) {
        throw Exception("User data not found after authentication.");
      }
      if (loggedUser.status != 'active') {
        await authService.value.signOut();

        throw Exception("Your account is not active.");
      }

      if (!mounted) return;

      // Open Dashboard
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
        builder: (context) => MainDashboard(
          currentUser: loggedUser, initialIsAdmin: loggedUser.isAdmin,
          ),
      ),
        (route) => false,
      );
  
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String message = "Authentication failed";

      if (e.code == 'email-already-in-use') {
        message = "This email is already in use.";
      } else if (e.code == 'weak-password') {
        message = "Password is too weak.";   
      } else if (e.code == 'invalid-email') {
        message = "Invalid email address.";
      } else if (e.code == 'invalid-credential' || e.code == 'wrong-password' || e.code == 'user-not-found') {
        message = "Incorrect email or password.";
      } else if (e.code == 'network-request-failed') {
        message = "Network error. Please check your internet connection.";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );

    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"),
        ),
      );

    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    } 
  }

  @override
  Widget build(BuildContext context) {
    final pageTitle = isSignUpPage == true? "Sign Up" : "Log In";

    return Scaffold(
      appBar: AppBar(title: Text(pageTitle)),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: myFormKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Text(
                  pageTitle,
                  style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),

                // Email Input Field
                TextFormField(
                  controller: e1,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    hintText: "yourname@okstate.edu",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Please enter an email";
                    }
                    if (!value.trim().toLowerCase().endsWith('@okstate.edu')) {
                      return "Email must end with @okstate.edu";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Password Input Field
                TextFormField(
                  controller: p1,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Password",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter a password";
                    }
                    if (isSignUpPage && value.length < 6) {
                      return "Password must be at least 6 characters";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Organization Sign-in
                if (isSignUpPage) ...[// 
                  SwitchListTile(
                    title: const Text("Sign in as Organization"),
                    subtitle: const Text("Required if you plan to post items"),
                    value: isOrgSwitch,
                    onChanged: (value) {
                      setState(() {
                      isOrgSwitch = value;
                    });
                  },
                ),
                if (isOrgSwitch) ...[
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: o1,
                    decoration: const InputDecoration(
                      labelText: "Organization Name",
                      hintText: "e.g., Student Government Association",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.business),
                    ),
                    validator: (value) {
                      if (isOrgSwitch && (value == null || value.trim().isEmpty)) {
                        return "Organization name is required to post";
                      }
                      return null;
                    },
                  ),
                ],
              ],  
                const SizedBox(height: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  onPressed: isLoading ? null : handleAuthentication,
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : Text(
                          pageTitle,
                          style: const TextStyle(fontSize: 18),
                        ),
                ),
              
              ]
            ),
          ),
        ),
      ),
    );
  }
}