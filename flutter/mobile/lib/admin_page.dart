import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'user_data.dart';

class AdminPage extends StatefulWidget {
  final bool adminFlag;
  final ValueChanged<bool> onAdminFlagChanged;
  final TextEditingController searchController;
  final List<UserData> registeredUsersList;

  const AdminPage({
    super.key,
    required this.adminFlag,
    required this.onAdminFlagChanged,
    required this.searchController,
    required this.registeredUsersList,
  });

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  bool isUpdating = false;

  // Get organizations waiting for admin approval.
  Stream<QuerySnapshot<Map<String, dynamic>>> getPendingOrgs() {
    return firestore
        .collection('organizations')
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  // Get All Registered Users From Firestore
  Stream<QuerySnapshot<Map<String, dynamic>>> getMembers() {
    return firestore.collection('users').snapshots();
  }

  // Approve or reject an organization.
  Future<void> updateOrganizationStatus(
    String organizationID,
    String newStatus,
  ) async {
    if (isUpdating) return;

    setState(() {
      isUpdating = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        throw Exception('You must be logged in.');
      }

      final adminDocument = await firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (adminDocument.data()?['admin'] != true) {
        throw Exception('You do not have admin permission.');
      }

      if (newStatus != 'active' && newStatus != 'rejected') {
        throw Exception('Invalid organization status.');
      }

      await firestore
          .collection('organizations')
          .doc(organizationID)
          .update({
        'status': newStatus,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus == 'active'
                ? 'Organization approved successfully.'
                : 'Organization rejected.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isUpdating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.adminFlag) {
      return const Center(child: Text('Admin Access Required'),
      );
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
              subtitle: Text(widget.adminFlag
                  ? "Status: Granted (Access Enabled)"
                  : "Status: Restricted (Access Disabled)"),
              value: widget.adminFlag,
              onChanged: null,
            ),
          ),
          const Divider(height: 30),
          Expanded(
            child: widget.adminFlag
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
                              StreamBuilder<
                                  QuerySnapshot<Map<String, dynamic>>>(
                                stream: getPendingOrgs(),
                                builder: (context, snapshot) {
                                  if (snapshot.hasError) {
                                    return Center(
                                      child: Text(
                                        'Error loading organizations: ${snapshot.error}',
                                      ),
                                    );
                                  }

                                  if (!snapshot.hasData) {
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }

                                  final unapprovedOrgs = snapshot.data!.docs;

                                  if (unapprovedOrgs.isEmpty) {
                                    return const Center(
                                      child: Text(
                                        "No organizations pending approval.",
                                      ),
                                    );
                                  }

                                  return ListView.builder(
                                    itemCount: unapprovedOrgs.length,
                                    itemBuilder: (context, index) {
                                      final orgDoc = unapprovedOrgs[index];
                                      final orgData = orgDoc.data();

                                      return Card(
                                        margin: const EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                        child: ListTile(
                                          leading: const Icon(
                                            Icons.business,
                                            color: Colors.orange,
                                          ),
                                          title: Text(
                                            orgData['organizationName']
                                                    as String? ??
                                                "Unknown Org",
                                          ),
                                          subtitle: Text(
                                            orgData['ownerID']
                                                    as String? ??
                                                '',
                                          ),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.check_circle,
                                                  color: Colors.green,
                                                ),
                                                onPressed: isUpdating
                                                    ? null
                                                    : () {
                                                        updateOrganizationStatus(
                                                          orgDoc.id,
                                                          'active',
                                                        );
                                                      },
                                              ),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.cancel,
                                                  color: Colors.red,
                                                ),
                                                onPressed: isUpdating
                                                    ? null
                                                    : () {
                                                        updateOrganizationStatus(
                                                          orgDoc.id,
                                                          'rejected',
                                                        );
                                                      },
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                              // Tab 2: Member List
                              Column(
                                children: [
                                  const SizedBox(height: 10),
                                  TextField(
                                    controller: widget.searchController,
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
                                    child: StreamBuilder<
                                        QuerySnapshot<Map<String, dynamic>>>(
                                      stream: getMembers(),
                                      builder: (context, snapshot) {
                                        if (snapshot.hasError) {
                                          return Center(
                                            child: Text(
                                              'Error loading members: ${snapshot.error}',
                                            ),
                                          );
                                        }

                                        if (!snapshot.hasData) {
                                          return const Center(
                                            child:
                                                CircularProgressIndicator(),
                                                );
                                        }

                                        final search = widget
                                            .searchController.text
                                            .trim()
                                            .toLowerCase();

                                        final filteredMembers =
                                            snapshot.data!.docs.where((doc) {
                                          final data = doc.data();
                                          final email =
                                              (data['email'] as String? ?? '')
                                                  .toLowerCase();
                                          final username =
                                              (data['username'] as String? ?? '')
                                                  .toLowerCase();
                                          final firstName =
                                              (data['firstName'] as String? ?? '')
                                                  .toLowerCase();
                                          final lastName =
                                              (data['lastName'] as String? ?? '')
                                                  .toLowerCase();

                                          return email.contains(search) ||
                                              username.contains(search) ||
                                              firstName.contains(search) ||
                                              lastName.contains(search);
                                            }).toList();

                                            return ListView.builder(
                                              itemCount: filteredMembers.length,
                                              itemBuilder: (context, index) {
                                                final memberDoc =
                                                    filteredMembers[index];
                                                final member =
                                                    UserData.fromMap(
                                                  memberDoc.id,
                                                  memberDoc.data(),
                                                );
                                                
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
}