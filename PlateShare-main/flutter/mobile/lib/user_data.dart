class UserData {
  final String uid;
  final String email;
  final String firstName;
  final String lastName;
  final String username;
  final String role;
  final String status;
  final bool admin;

  final String? organizationID;
  final String? orgName;
  final String? organizationStatus;

  UserData({
    required this.uid,
    required this.email,
    this.firstName = '',
    this.lastName = '',
    this.username = '',
    this.role = 'student',
    this.status = 'active',
    this.admin = false,
    this.organizationID,
    this.orgName,
    this.organizationStatus,
  });

  bool get isOrganization => role == 'organization';

  bool get isApprovedOrg => isOrganization && organizationStatus == 'active';

  bool get isAdmin => admin;

  factory UserData.fromMap(
    String uid,
    Map<String, dynamic> data, {
      String? organizationID,
      String? orgName,
      String? organizationStatus,
    }) {
      return UserData(
        uid: uid,
        email: data['email'] ?? '',
        firstName: data['firstName'] ?? '',
        lastName: data['lastName'] ?? '',
        username: data['username'] ?? '',
        role: data['role'] ?? 'student',
        status: data['status'] ?? 'active',
        admin: data['admin'] == true,
        organizationID: organizationID,
        orgName: orgName,
        organizationStatus: organizationStatus,
        );


    }
}