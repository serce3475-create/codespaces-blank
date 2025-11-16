// lib/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Anlık kullanıcı durumunu dinler (giriş yapmış mı?)
  Stream<User?> get user {
    return _auth.authStateChanges();
  }

  // E-posta ve şifre ile giriş yap
  Future<String?> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      notifyListeners();
      return null; // Başarılı
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Bilinmeyen bir hata oluştu.';
    }
  }

  // E-posta ve şifre ile yeni hesap oluştur
  Future<String?> register(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
      notifyListeners();
      return null; // Başarılı
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Bilinmeyen bir hata oluştu.';
    }
  }

  // Çıkış yap
  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
  }

  // Mevcut kullanıcı kimliğini (UID) döndürür
  String? getCurrentUserUID() {
    return _auth.currentUser?.uid;
  }
}