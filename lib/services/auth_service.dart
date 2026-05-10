import 'dart:math' as dart_math;
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sign Up
  Future<UserModel?> signUp({
    required String branchName,
    required String location,
    required String email,
    required String password,
  }) async {
    try {
      // 1. Generate unique Branch Code
      String branchCode = '';
      bool isUnique = false;
      while (!isUnique) {
        branchCode = List.generate(6, (_) => "abcdefghijklmnopqrstuvwxyz0123456789"[dart_math.Random().nextInt(36)]).join();
        final checkSnapshot = await _firestore
            .collection(AppConstants.usersCollection)
            .where('branchCode', isEqualTo: branchCode)
            .get();
        if (checkSnapshot.docs.isEmpty) {
          isUnique = true;
        }
      }
      // 2. Create user in Firebase Auth

      // 2. Create user in Firebase Auth
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // 3. Send email verification
        await credential.user!.sendEmailVerification();

        // 4. Save user info in Firestore
        UserModel newUser = UserModel(
          uid: credential.user!.uid,
          branchCode: branchCode,
          branchName: branchName,
          email: email,
          location: location,
        );

        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(credential.user!.uid)
            .set(newUser.toMap());

        return newUser;
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw Exception('كلمة المرور ضعيفة جداً.');
      } else if (e.code == 'email-already-in-use') {
        throw Exception('البريد الإلكتروني مسجل مسبقاً.');
      } else if (e.code == 'operation-not-allowed') {
        throw Exception('يرجى تفعيل خيار تسجيل الدخول بالبريد الإلكتروني (Email/Password) في إعدادات Firebase Auth.');
      } else {
        throw Exception('خطأ في المصادقة: ${e.message} (${e.code})');
      }
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception('صلاحيات Firebase مرفوضة. يرجى التحقق من Rules.');
      }
      throw Exception('خطأ في قاعدة البيانات: ${e.message} (${e.code})');
    } catch (e, stacktrace) {
      debugPrint('SignUp Error: $e\n$stacktrace');
      throw Exception('حدث خطأ غير متوقع: $e');
    }
    return null;
  }

  // Login
  Future<User?> login({
    required String branchCode,
    required String password,
  }) async {
    try {
      // 1. Fetch email associated with branchCode
      final querySnapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .where('branchCode', isEqualTo: branchCode)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception("Invalid Branch Code");
      }

      String email = querySnapshot.docs.first.data()['email'];

      // 2. Sign in with email and password
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return credential.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw Exception('Invalid Credentials');
      }
      throw Exception(e.message ?? 'Login failed');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Password Reset
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception("Failed to send reset link: ${e.toString()}");
    }
  }

  // Get current user info
  Future<UserModel?> getCurrentUser() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
    }
    return null;
  }
}
