import 'dart:io';
import 'package:flutter/material.dart';
import 'main_dashboard.dart';

void main() {
  runApp(const MyApp());
}

// Global list for database simulation
List<UserData> registeredUsersList = [
  UserData(
    email: 'admin@okstate.edu',
    password: 'password123',
    isOrganization: true,
    orgName: 'OSU Dining',
    isApprovedOrg: true,
  ),
  UserData(
    email: 'student@okstate.edu',
    password: 'password123',
    isOrganization: false,
  ),
];

// Global posts array
List<FoodPost> globalPostsList = [];

class UserData {
  String email;
  String password;
  bool isOrganization;
  String? orgName;
  bool isApprovedOrg;

  UserData({
    required this.email,
    required this.password,
    this.isOrganization = false,
    this.orgName,
    this.isApprovedOrg = false,
  });
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
  var e1 = TextEditingController();
  var p1 = TextEditingController();
  var o1 = TextEditingController();

  bool isOrgSwitch = false;
  bool isSignUpPage = false;
  var myFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    isSignUpPage = widget.isSignUp;
  }

  @override
  Widget build(BuildContext context) {
    String pageTitle = isSignUpPage == true ? "Sign Up" : "Log In";

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
                    if (value.length < 6) {
                      return "Password must be at least 6 characters";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                SwitchListTile(
                  title: const Text("Sign in as Organization"),
                  subtitle: const Text("Required if you plan to post items"),
                  value: isOrgSwitch,
                  onChanged: (bool val) {
                    setState(() {
                      isOrgSwitch = val;
                    });
                  },
                ),
                if (isOrgSwitch == true) ...[
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
                const SizedBox(height: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  onPressed: () {
                    FocusScope.of(context).unfocus();

                    if (myFormKey.currentState!.validate()) {
                      String userEmail = e1.text.trim().toLowerCase();
                      String userPass = p1.text;

                      if (isSignUpPage == true) {
                        var tempUser = UserData(
                          email: userEmail,
                          password: userPass,
                          isOrganization: isOrgSwitch,
                          orgName: isOrgSwitch ? o1.text.trim() : null,
                          isApprovedOrg: false,
                        );
                        registeredUsersList.add(tempUser);

                        bool checkAdmin = tempUser.email.startsWith('admin');
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MainDashboard(
                              currentUser: tempUser,
                              initialIsAdmin: checkAdmin,
                            ),
                          ),
                          (route) => false,
                        );
                      } else {
                        int foundIndex = -1;
                        for (int i = 0; i < registeredUsersList.length; i++) {
                          if (registeredUsersList[i].email == userEmail &&
                              registeredUsersList[i].password == userPass) {
                            foundIndex = i;
                            break;
                          }
                        }

                        if (foundIndex == -1) {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text("Account Not Found"),
                              content: const Text(
                                "We couldn't find an account matching these credentials. Would you like to sign up instead?",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text("Cancel"),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    setState(() {
                                      isSignUpPage = true;
                                    });
                                  },
                                  child: const Text("Sign Up"),
                                ),
                              ],
                            ),
                          );
                        } else {
                          var loggedUser = registeredUsersList[foundIndex];
                          if (isOrgSwitch) {
                            loggedUser.isOrganization = true;
                            loggedUser.orgName = o1.text.trim();
                          }
                          bool checkAdmin = loggedUser.email.startsWith('admin');
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MainDashboard(
                                currentUser: loggedUser,
                                initialIsAdmin: checkAdmin,
                              ),
                            ),
                            (route) => false,
                          );
                        }
                      }
                    }
                  },
                  child: Text(pageTitle, style: const TextStyle(fontSize: 18)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}