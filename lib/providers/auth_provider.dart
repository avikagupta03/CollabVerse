import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


// =============================================================
// AuthProvider
// =============================================================
class AuthProvider extends ChangeNotifier {
  final _auth = FirebaseAuth.instance;


  User? get user => _auth.currentUser;
  Stream<User?> get authState => _auth.authStateChanges();


  Future<void> login(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }


  Future<void> register(String email, String password) async {
    await _auth.createUserWithEmailAndPassword(email: email, password: password);
  }


  Future<void> logout() async => await _auth.signOut();
}