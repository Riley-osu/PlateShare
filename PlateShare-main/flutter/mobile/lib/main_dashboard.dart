import 'package:flutter/material.dart';
import 'main.dart';
import 'auth_service.dart';
import 'food_list_page.dart';
import 'map_page.dart';
import 'create_post_page.dart';
import 'account_page.dart';
import 'admin_page.dart';

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
  
  final TextEditingController searchController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> logout() async {
    await authService.value.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LandingScreen()),
      (route) => false,
    );

  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.currentUser.admin;
    
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
            onPressed: logout,
          )
        ],
      ),
      body: Builder(
        builder: (context) {
          if (_selectedIndex == 0) {
            return FoodListPage(posts: globalPostsList);
          }
          if (_selectedIndex == 1) {
            return const MapPage();
          }
          if (_selectedIndex == 2) {
            return CreatePostPage(
              currentUser: widget.currentUser,
              onPostCreated: (newPost) {
                setState(() {
                  globalPostsList.add(newPost);
                  _selectedIndex = 0;
                });
              },
            );
          }
          if (_selectedIndex == 3) {
            return AccountPage(currentUser: widget.currentUser);
          }
          if (_selectedIndex == 4 && isAdmin) {
            return AdminPage(
              adminFlag: isAdmin,
              onAdminFlagChanged: (_) {},
              searchController: searchController,
              registeredUsersList: registeredUsersList,
            );
          }
          return const Center(child: Text("Page not found"),
          );
        }            
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
          BottomNavigationBarItem(icon: Icon(Icons.list), label: "List",),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: "Map",),
          BottomNavigationBarItem(icon: Icon(Icons.add_box), label: "Post",),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Account",),
          BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: "Admin",
          ),
        ],
      ),
    );
  }
}