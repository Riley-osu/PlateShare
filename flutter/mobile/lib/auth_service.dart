import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'user_data.dart';


ValueNotifier<AuthService> authService = ValueNotifier(AuthService());


class AuthService {
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

//Access the currently signed-in user
  User? get currentUser => firebaseAuth.currentUser;

//Important for checking if the user is connected
  Stream<User?> get authStateChanges => firebaseAuth.authStateChanges();

  //Sign in function
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

//Create account function
Future<UserCredential> createAccount({
    required String email,
    required String password,
    bool isOrganization = false,
    String? orgName,
  }) async {
    final credential = await firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user!.uid;

    // Create the User Profile in Firestore
    await firestore.collection('users').doc(uid).set({
      'admin': false,
      'createdAt': FieldValue.serverTimestamp(),
      'email': email,
      'firstName': '',
      'lastName': '',
      'role': isOrganization ? 'organization' : 'student',
      'status': 'active',
      'username': '',
    });

    if (isOrganization) {
      await firestore.collection('organizations').add({
        'averageRating': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'description': '',
        'organizationName': orgName ?? '',
        'ownerID': uid,
        'status': 'pending',
        'totalRatings': 0,
      });
    }

    return credential;
  }
  
  // Get User Profile 
  Future<UserData?> getUserData() async {
    final user = firebaseAuth.currentUser;

    if (user == null) return null;

    final userDoc = await firestore.collection('users').doc(user.uid).get();

    if (!userDoc.exists || userDoc.data() == null) {
      return null;
    } 
    
    final userData = userDoc.data()!;

    String? organizationID;
    String? orgName;
    String? organizationStatus;

    if (userData['role'] == 'organization') {
      final orgQuery = await firestore
          .collection('organizations')
          .where('ownerID', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (orgQuery.docs.isNotEmpty) {
        final orgDoc = orgQuery.docs.first;
        final orgData = orgDoc.data();

        organizationID = orgDoc.id;
        orgName = orgData['organizationName'] as String?;
        organizationStatus = orgData['status'] as String?;
      }
    }

    return UserData.fromMap(
      user.uid, userData, organizationID: organizationID, orgName: orgName, organizationStatus: organizationStatus
    ); 
  }


  //Sign out function
  Future<void> signOut() async {
    await firebaseAuth.signOut();
  }
  // Reset Password function
  Future<void> resetPassword({
    required String email,
  }) async {
    await firebaseAuth.sendPasswordResetEmail(email: email);
  }
  
  // Update Username function
  Future<void> updateUsername({
    required String username,
  }) async {
    final user = currentUser;

    if (user == null) {
      throw Exception('No user is currently signed in.');
    }

    await firestore.collection('users').doc(user.uid).update({
      'username': username,
    });

    await user.updateDisplayName(username);
  }

  //Change Password
  Future<void> resetPasswordFromCurrentPassword({
    required String currentPassword,
    required String newPassword,
    required String email,
  }) async {

    final user = currentUser;

    if (user == null) {
      throw Exception('No user is currently signed in.');
    }

    final credential = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );
    await currentUser!.reauthenticateWithCredential(credential);

    await currentUser!.updatePassword(newPassword);
  }

  // Delete Account function
  Future<void> deleteAccount ({
    required String email,
    required String password,
  }) async {
    final user = currentUser;

    if (user == null) return;

    final credential = EmailAuthProvider.credential(
      email: email,
      password: password
    );
    await currentUser!.reauthenticateWithCredential(credential);
    await currentUser!.delete();
  }
}