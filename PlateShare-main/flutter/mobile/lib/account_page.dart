import 'package:flutter/material.dart';
import 'main.dart';

class AccountPage extends StatelessWidget {
  final UserData currentUser;

  const AccountPage({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.account_circle, size: 80, color: Colors.grey),
          const SizedBox(height: 10),
          const Text("Account Page",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),

          Text('Role: ${currentUser.role}'),

          if (currentUser.isOrganization)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Chip(
                label: Text("Org: ${currentUser.orgName ?? 'Unspecified'}"),
                avatar: const Icon(Icons.business, size: 18),
              ),
            ),
          if (currentUser.isOrganization)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Organization Status: '
              '${currentUser.organizationStatus ?? 'Unspecified'}',
              style: TextStyle(color: currentUser.isApprovedOrg ? Colors.green : Colors.orange,
              ),
            ),
          ),  
        ],
      ),
    );
  }
}