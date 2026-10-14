import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

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
  }) async {
    return await firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  //Sign out function
  Future<void> signOut() async {
    await firebaseAuth.signOut();
  }

}