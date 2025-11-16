import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../modeller/kullanici.dart';
import 'dart:async';

class KullaniciProvider with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Kullanici? _kullaniciProfil;
  StreamSubscription<DocumentSnapshot<Kullanici>>? _profilStreamSubscription;

  static const String _appId = String.fromEnvironment('__app_id', defaultValue: 'default-app-id');

  Kullanici? get kullaniciProfil => _kullaniciProfil;

  KullaniciProvider() {
    print("KullaniciProvider: Constructor çağrıldı.");
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        print("KullaniciProvider: authStateChanges tetiklendi, user UID: ${user.uid}");
        _profilDinlemeyeBasla(user.uid);
      } else {
        print("KullaniciProvider: Kullanıcı oturumu kapalı veya yok.");
        _profilStreamSubscription?.cancel();
        _kullaniciProfil = null;
        notifyListeners();
      }
    });
    if (_auth.currentUser != null) {
      _profilDinlemeyeBasla(_auth.currentUser!.uid);
    }
  }

  DocumentReference<Kullanici> _getKullaniciProfilRef(String uid) {
    return _db
        .collection('artifacts')
        .doc(_appId)
        .collection('users')
        .doc(uid)
        .collection('profile')
        .doc(uid)
        .withConverter<Kullanici>(
          fromFirestore: (snapshot, _) => Kullanici.fromMap(snapshot.id, snapshot.data()!),
          toFirestore: (kullanici, _) => kullanici.toMap(),
        );
  }

  void _profilDinlemeyeBasla(String uid) {
    _profilStreamSubscription?.cancel();

    print("KullaniciProvider: Kullanıcı profili dinlenmeye başlanıyor (UID: $uid)...");
    _profilStreamSubscription = _getKullaniciProfilRef(uid).snapshots().listen((snapshot) {
      if (snapshot.exists) {
        _kullaniciProfil = snapshot.data();
        print("KullaniciProvider: Profil bilgileri güncellendi: ${_kullaniciProfil?.isim}");
      } else {
        _kullaniciProfil = null;
        print("KullaniciProvider: Kullanıcı profili bulunamadı.");
      }
      notifyListeners();
    }, onError: (error) {
      print("KullaniciProvider HATA: Kullanıcı profili dinlenirken hata oluştu: $error");
      _kullaniciProfil = null;
      notifyListeners();
    });
  }

  // YENİ METOT: Belirli bir UID'ye sahip kullanıcının profilini çeker (PedigreeProvider için)
  Future<Kullanici?> getKullaniciProfilById(String uid) async {
    try {
      final doc = await _getKullaniciProfilRef(uid).get();
      return doc.data();
    } catch (e) {
      print("KullaniciProvider HATA: UID ile kullanıcı profili çekilirken hata oluştu ($uid): $e");
      return null;
    }
  }

  Future<void> profilBilgileriniKaydet(Kullanici kullanici) async {
    final String? uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception("Kullanıcı oturumu açık değil, profil bilgileri kaydedilemez.");
    }
    if (kullanici.uid != uid) {
      throw Exception("Profil bilgileri farklı bir kullanıcıya ait olamaz.");
    }

    try {
      await _getKullaniciProfilRef(uid).set(kullanici);
      print("✅ Kullanıcı profil bilgileri başarıyla kaydedildi/güncellendi.");
    } catch (e) {
      print("❌ Kullanıcı profil bilgileri kaydedilirken/güncellenirken hata oluştu: $e");
      rethrow;
    }
  }

  @override
  void dispose() {
    _profilStreamSubscription?.cancel();
    super.dispose();
  }
}
