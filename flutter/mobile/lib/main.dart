import 'package:flutter/material.dart';
import 'dart:io';

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
                    // Navigate to auth screen in login mode
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
                    // Navigate to auth screen in signup mode
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
  // Text controllers
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
    String pageTitle = "";
    if (isSignUpPage == true) {
      pageTitle = "Sign Up";
    } else {
      pageTitle = "Log In";
    }

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
                    // Close keyboard
                    FocusScope.of(context).unfocus();

                    if (myFormKey.currentState!.validate()) {
                      String userEmail = e1.text.trim().toLowerCase();
                      String userPass = p1.text;

                      if (isSignUpPage == true) {
                        // Create user object
                        var tempUser = UserData(
                          email: userEmail,
                          password: userPass,
                          isOrganization: isOrgSwitch,
                          orgName: isOrgSwitch ? o1.text.trim() : null,
                          isApprovedOrg: false,
                        );
                        registeredUsersList.add(tempUser);

                        // Navigate to Dashboard
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
                        // Check if user exists
                        int foundIndex = -1;
                        for (int i = 0; i < registeredUsersList.length; i++) {
                          if (registeredUsersList[i].email == userEmail &&
                              registeredUsersList[i].password == userPass) {
                            foundIndex = i;
                            break;
                          }
                        }

                        if (foundIndex == -1) {
                          // Show popup
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text("Account Not Found"),
                              content: const Text(
                                "We couldn't find an account matching these credentials. Would you like to sign up instead?",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                  },
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

// MAIN DASHBOARD SCREEN
class MainDashboard extends StatefulWidget {
  final UserData currentUser;
  final bool initialIsAdmin;

  const MainDashboard({
    super.key,
    required this.currentUser,
    this.initialIsAdmin = false,
  });

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int _selectedIndex = 0;
  bool adminFlag = false;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    adminFlag = widget.initialIsAdmin;
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic title string
    String titleText = "Dashboard";
    if (_selectedIndex == 0) titleText = "Food List View";
    if (_selectedIndex == 1) titleText = "Map View";
    if (_selectedIndex == 2) titleText = "Create Post";
    if (_selectedIndex == 3) titleText = "Account Settings";
    if (_selectedIndex == 4) titleText = "Admin Portal";

    return Scaffold(
      appBar: AppBar(
        title: Text(titleText),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LandingScreen()),
                (route) => false,
              );
            },
          )
        ],
      ),
      body: Builder(
        builder: (context) {
          // Tab 0: List View
          if (_selectedIndex == 0) {
            if (globalPostsList.isEmpty) {
              return const Center(
                child: Text(
                  "No food posts available yet.\nOrganizations can create posts in the Post tab.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: globalPostsList.length,
              itemBuilder: (context, index) {
                var post = globalPostsList[index];
                bool isDepleted = post.remainingSlots <= 0;

                DecorationImage? bgImage;
                if (post.imageFile != null) {
                  bgImage = DecorationImage(
                    image: FileImage(post.imageFile!),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withValues(alpha: 0.60),
                      BlendMode.darken,
                    ),
                  );
                } else if (post.imageUrl != null && post.imageUrl!.isNotEmpty) {
                  bgImage = DecorationImage(
                    image: NetworkImage(post.imageUrl!),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withValues(alpha: 0.60),
                      BlendMode.darken,
                    ),
                  );
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 20),
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 4,
                  child: Container(
                    height: 260,
                    decoration: BoxDecoration(
                      color: bgImage == null ? Colors.grey.shade900 : null,
                      image: bgImage,
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                "${post.orgName} - ${post.foodType}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, color: Colors.orange, size: 16),
                            const SizedBox(width: 5),
                            Text(
                              "${post.date.month}/${post.date.day}/${post.date.year}",
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                            const SizedBox(width: 15),
                            const Icon(Icons.access_time, color: Colors.orange, size: 16),
                            const SizedBox(width: 5),
                            Text(
                              "${post.startTime.format(context)} - ${post.endTime.format(context)}",
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: Text(
                            post.description,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isDepleted
                                      ? "FULL / NO SLOTS LEFT"
                                      : "Slots Left: ${post.remainingSlots}",
                                  style: TextStyle(
                                    color: isDepleted ? Colors.redAccent : Colors.lightGreenAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDepleted ? Colors.grey : Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: isDepleted
                                  ? null
                                  : () {
                                      setState(() {
                                        if (post.remainingSlots > 0) {
                                          post.remainingSlots--;
                                        }
                                      });
                                    },
                              icon: const Icon(Icons.bookmark_add),
                              label: Text(isDepleted ? "Claimed" : "Reserve Slot"),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            );
          }

          // Tab 1: Map View
          if (_selectedIndex == 1) {
            return const Center(
              child: Text("Map Page", style: TextStyle(fontSize: 24)),
            );
          }

          // Tab 2: Create Post
          if (_selectedIndex == 2) {
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

            return _CreatePostForm(
              orgName: widget.currentUser.orgName!,
              onPostCreated: (newPost) {
                setState(() {
                  globalPostsList.add(newPost);
                  _selectedIndex = 0; // Go back to list
                });
              },
            );
          }

          // Tab 3: Account Page
          if (_selectedIndex == 3) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.account_circle, size: 80, color: Colors.grey),
                  const SizedBox(height: 10),
                  const Text("Account Page",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text("Logged in as:\n${widget.currentUser.email}",
                      textAlign: TextAlign.center),
                  if (widget.currentUser.isOrganization)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Chip(
                        label: Text("Org: ${widget.currentUser.orgName ?? 'Unspecified'}"),
                        avatar: const Icon(Icons.business, size: 18),
                      ),
                    ),
                ],
              ),
            );
          }

          // Tab 4: Admin Portal
          if (_selectedIndex == 4) {
            List<UserData> unapprovedOrgs = [];
            for (var u in registeredUsersList) {
              if (u.isOrganization && !u.isApprovedOrg) {
                unapprovedOrgs.add(u);
              }
            }

            String searchQuery = searchController.text.toLowerCase();
            List<UserData> filteredMembers = [];
            for (var u in registeredUsersList) {
              if (u.email.toLowerCase().contains(searchQuery)) {
                filteredMembers.add(u);
              }
            }

            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    color: Colors.grey.shade100,
                    child: SwitchListTile(
                      title: const Text(
                        "Admin Access Credentials",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(adminFlag
                          ? "Status: Granted (Access Enabled)"
                          : "Status: Restricted (Access Disabled)"),
                      value: adminFlag,
                      onChanged: (bool value) {
                        setState(() {
                          adminFlag = value;
                        });
                      },
                    ),
                  ),
                  const Divider(height: 30),
                  Expanded(
                    child: adminFlag
                        ? DefaultTabController(
                            length: 2,
                            child: Column(
                              children: [
                                const TabBar(
                                  tabs: [
                                    Tab(
                                      icon: Icon(Icons.how_to_reg),
                                      text: "Approve Orgs",
                                    ),
                                    Tab(
                                      icon: Icon(Icons.people),
                                      text: "Member List",
                                    ),
                                  ],
                                ),
                                Expanded(
                                  child: TabBarView(
                                    children: [
                                      // Tab 1: Approve Orgs
                                      unapprovedOrgs.isEmpty
                                          ? const Center(
                                              child: Text("No organizations pending approval."))
                                          : ListView.builder(
                                              itemCount: unapprovedOrgs.length,
                                              itemBuilder: (context, index) {
                                                var orgUser = unapprovedOrgs[index];
                                                return Card(
                                                  margin: const EdgeInsets.symmetric(vertical: 8),
                                                  child: ListTile(
                                                    leading: const Icon(Icons.business, color: Colors.orange),
                                                    title: Text(orgUser.orgName ?? "Unknown Org"),
                                                    subtitle: Text(orgUser.email),
                                                    trailing: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        IconButton(
                                                          icon: const Icon(Icons.check_circle, color: Colors.green),
                                                          onPressed: () {
                                                            setState(() {
                                                              orgUser.isApprovedOrg = true;
                                                            });
                                                          },
                                                        ),
                                                        IconButton(
                                                          icon: const Icon(Icons.cancel, color: Colors.red),
                                                          onPressed: () {
                                                            setState(() {
                                                              registeredUsersList.remove(orgUser);
                                                            });
                                                          },
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),

                                      // Tab 2: Member List
                                      Column(
                                        children: [
                                          const SizedBox(height: 10),
                                          TextField(
                                            controller: searchController,
                                            decoration: const InputDecoration(
                                              labelText: "Search Members",
                                              prefixIcon: Icon(Icons.search),
                                              border: OutlineInputBorder(),
                                            ),
                                            onChanged: (val) {
                                              setState(() {});
                                            },
                                          ),
                                          const SizedBox(height: 10),
                                          Expanded(
                                            child: ListView.builder(
                                              itemCount: filteredMembers.length,
                                              itemBuilder: (context, index) {
                                                var member = filteredMembers[index];
                                                return ListTile(
                                                  leading: Icon(
                                                    member.isOrganization ? Icons.business : Icons.person,
                                                    color: member.isOrganization ? Colors.orange : Colors.blue,
                                                  ),
                                                  title: Text(member.email),
                                                  subtitle: Text(
                                                    member.isOrganization
                                                        ? "Organization: ${member.orgName ?? 'N/A'}"
                                                        : "Student/Member",
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.lock, size: 70, color: Colors.red.shade400),
                                const SizedBox(height: 15),
                                const Text(
                                  "Access Denied",
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  "You do not have the required admin credentials to view this page.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            );
          }

          return Container(); // fallback
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: Colors.orange.shade800,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list), label: "List"),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: "Map"),
          BottomNavigationBarItem(icon: Icon(Icons.add_box), label: "Post"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Account"),
          BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: "Admin"),
        ],
      ),
    );
  }
}

// CREATE POST FORM WIDGET
class _CreatePostForm extends StatefulWidget {
  final String orgName;
  final Function(FoodPost) onPostCreated;

  const _CreatePostForm({
    required this.orgName,
    required this.onPostCreated,
  });

  @override
  State<_CreatePostForm> createState() => _CreatePostFormState();
}

class _CreatePostFormState extends State<_CreatePostForm> {
  var foodTypeController = TextEditingController();
  var descController = TextEditingController();
  var slotsController = TextEditingController();

  DateTime selectedDate = DateTime.now();
  TimeOfDay startTime = const TimeOfDay(hour: 12, minute: 0);
  TimeOfDay endTime = const TimeOfDay(hour: 13, minute: 0);
  File? pickedImage;

  var postFormKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: postFormKey,
        child: Column(
          children: [
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
            ElevatedButton(
              onPressed: () {
                // Submit logic
                if (postFormKey.currentState!.validate()) {
                  var newPost = FoodPost(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    orgName: widget.orgName,
                    foodType: foodTypeController.text,
                    description: descController.text,
                    imageFile: pickedImage,
                    date: selectedDate,
                    startTime: startTime,
                    endTime: endTime,
                    remainingSlots: int.parse(slotsController.text),
                  );
                  widget.onPostCreated(newPost);
                }
              },
              child: const Text("Publish Post"),
            ),
          ],
        ),
      ),
    );
  }
}