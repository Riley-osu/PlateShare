import 'package:flutter/material.dart';
import 'main.dart';

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
  @override
  Widget build(BuildContext context) {
    List<UserData> unapprovedOrgs = [];
    for (var u in widget.registeredUsersList) {
      if (u.isOrganization && !u.isApprovedOrg) {
        unapprovedOrgs.add(u);
      }
    }

    String searchQuery = widget.searchController.text.toLowerCase();
    List<UserData> filteredMembers = [];
    for (var u in widget.registeredUsersList) {
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
              subtitle: Text(widget.adminFlag
                  ? "Status: Granted (Access Enabled)"
                  : "Status: Restricted (Access Disabled)"),
              value: widget.adminFlag,
              onChanged: widget.onAdminFlagChanged,
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
                                                      widget.registeredUsersList.remove(orgUser);
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
}