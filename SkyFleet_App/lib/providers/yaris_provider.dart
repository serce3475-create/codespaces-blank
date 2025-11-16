// lib/providers/yaris_provider.dart
import 'package:flutter/material.dart';
import '../modeller/yaris.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'dart:convert'; // Bu import muhtemelen kullanılmıyor, kaldırabiliriz veya bırakabiliriz.

/// Yarış Kayıtlarının yönetimi ve Firebase ile senkronizasyonu için Provider sınıfı.
class YarisProvider with ChangeNotifier {
  List<Yaris> _tumYarisKayitlari = [];

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? _currentUser;
  bool _isInitialized = false;

  static const String _appId = String.fromEnvironment('__app_id', defaultValue: 'default-app-id');

  List<Yaris> get tumYarisKayitlari => _tumYarisKayitlari;

  bool kusYaristiMi(String kusHalkaNo) {
    return _tumYarisKayitlari.any((yaris) => yaris.kusHalkaNo == kusHalkaNo);
  }

  // YENİ METOT: Belirli bir kuşun en iyi (en düşük) yarış derecesini döner.
  // Yarışmamışsa null döner.
  int? getKusunEnIyiYarisDerecesi(String kusHalkaNo) {
    final kusunYarislari = _tumYarisKayitlari
        .where((yaris) => yaris.kusHalkaNo == kusHalkaNo)
        .toList();

    if (kusunYarislari.isEmpty) {
      return null; // Hiç yarışmamış
    }

    // En düşük derece (en iyi sonuç)
    int enIyiDerece = kusunYarislari.map((yaris) => yaris.derece).reduce((a, b) => a < b ? a : b);
    return enIyiDerece;
  }

  // YENİ METOT: Belirli bir kuşun tüm yarış bilgilerinin özetini string olarak döner.
  // Format: [Yarış Adı] - [Mesafe KM] - [Derece]
  String? getKusunYarisBilgileriOzeti(String kusHalkaNo) {
    final kusunYarislari = _tumYarisKayitlari
        .where((yaris) => yaris.kusHalkaNo == kusHalkaNo)
        .toList();

    if (kusunYarislari.isEmpty) {
      return null;
    }

    // En fazla 3 yarışın özetini alalım, çok uzun olmasın
    final yarisOzetleri = kusunYarislari.take(3).map((yaris) {
      return '${yaris.yarisAdi} - ${yaris.mesafeKm.toStringAsFixed(0)}km - ${yaris.derece}.';
    }).join('; '); // Yarışları noktalı virgülle ayır

    if (kusunYarislari.length > 3) {
      return '$yarisOzetleri (Daha fazla...)';
    }
    return yarisOzetleri;
  }


  YarisProvider() {
    print("YarisProvider: Constructor çağrıldı.");
    _auth.authStateChanges().listen((User? user) {
      _currentUser = user;
      print("YarisProvider: authStateChanges dinleyici tetiklendi. User UID: ${user?.uid}");
      if (user != null) {
        if (!_isInitialized) {
          _isInitialized = true;
          _yarisKayitlariniDinle();
        }
      } else {
        print("YarisProvider: Kullanıcı oturumu kapalı veya yok.");
        _isInitialized = false;
        _tumYarisKayitlari = [];
        notifyListeners();
        _attemptAuth();
      }
    });

    if (_auth.currentUser == null) {
      print("YarisProvider: Başlangıçta _auth.currentUser null. _attemptAuth çağrılıyor.");
      _attemptAuth();
    } else {
      _currentUser = _auth.currentUser;
      print("YarisProvider: Başlangıçta _auth.currentUser zaten var: ${_currentUser!.uid}. _yarisKayitlariniDinle çağrılıyor.");
      if (!_isInitialized) {
        _isInitialized = true;
        _yarisKayitlariniDinle();
      }
    }
  }

  void _attemptAuth() async {
    print("YarisProvider: _attemptAuth çağrıldı.");
    const String initialAuthToken = (String.fromEnvironment('__initial_auth_token'));

    if (initialAuthToken.isNotEmpty) {
      try {
        await _auth.signInWithCustomToken(initialAuthToken);
        print("YarisProvider: Custom Token ile oturum açma başarılı.");
      } catch (e) {
        print("YarisProvider HATA: Custom Token ile oturum açma hatası: $e. Anonim oturum açılıyor.");
        await _auth.signInAnonymously();
        print("YarisProvider: Anonim oturum açma başarılı.");
      }
    } else {
      await _auth.signInAnonymously();
      print("YarisProvider: Anonim oturum açma başarılı (initialAuthToken yoktu).");
    }
  }

  CollectionReference<Yaris> _getYarisCollection() {
    if (_currentUser == null) {
      throw Exception("Kullanıcı oturumu açık değil. Yarış koleksiyonuna erişilemiyor.");
    }
    print("YarisProvider: _getYarisCollection çağrıldı. UID: ${_currentUser!.uid}, AppID: $_appId");
    return _db
        .collection('artifacts')
        .doc(_appId)
        .collection('users')
        .doc(_currentUser!.uid)
        .collection('Yarislar')
        .withConverter<Yaris>(
            fromFirestore: (snapshot, _) => Yaris.fromMap(snapshot.data()!, snapshot.id),
            toFirestore: (yaris, _) => yaris.toMap(),
        );
  }

  void _yarisKayitlariniDinle() {
    if (_currentUser == null) {
      print("YarisProvider: _yarisKayitlariniDinle çağrıldı ama _currentUser null. Erken çıkış.");
      return;
    }
    
    CollectionReference<Yaris> yarisCollection;
    try {
      yarisCollection = _getYarisCollection();
    } catch (e) {
      print("YarisProvider HATA: _yarisKayitlariniDinle içinde _getYarisCollection oluşturulurken hata: $e");
      return;
    }

    print("YarisProvider: Yarış kayıtları dinlenmeye başlanıyor (UID: ${_currentUser!.uid})...");
    yarisCollection
        .orderBy('yarisTarihi', descending: true)
        .snapshots()
        .listen((snapshot) {
      _tumYarisKayitlari = snapshot.docs.map((doc) => doc.data()).toList();
      notifyListeners();
      print("YarisProvider: Yarış kayıtları güncellendi: ${_tumYarisKayitlari.length} kayıt.");
      if (_tumYarisKayitlari.isEmpty) {
        print("YarisProvider: _tumYarisKayitlari listesi boş!");
      }
    }, onError: (error) {
      print("YarisProvider HATA: Yarış kayıtları dinlenirken hata oluştu: $error");
      _isInitialized = false;
    });
  }

  Future<void> yarisEkle(Yaris yaris) async {
    if (_currentUser == null) {
      print("YarisProvider HATA: yarisEkle çağrıldı ama _currentUser null!");
      throw Exception("Kullanıcı oturumu açık değil. Kayıt yapılamadı.");
    }
    try {
      await _getYarisCollection().add(yaris);
      print("✅ Yarış kaydı Firestore'a başarıyla eklendi.");
    } catch (e) {
      print("❌ Yarış kaydı eklenirken hata: $e");
      rethrow;
    }
  }

  Future<void> yarisSil(String yarisId) async {
    if (_currentUser == null) {
      print("YarisProvider HATA: yarisSil çağrıldı ama _currentUser null!");
      throw Exception("Kullanıcı oturumu açık değil. Silme yapılamadı.");
    }
    try {
      await _getYarisCollection().doc(yarisId).delete();
      print("✅ Yarış kaydı Firestore'dan başarıyla silindi: $yarisId");
    } catch (e) {
      print("❌ Yarış kaydı silinirken hata: $e");
      rethrow;
    }
  }

  List<Yaris> kusunYarisKayitlari(String halkaNo) {
    return _tumYarisKayitlari
        .where((yaris) => yaris.kusHalkaNo == halkaNo)
        .toList();
  }
}
