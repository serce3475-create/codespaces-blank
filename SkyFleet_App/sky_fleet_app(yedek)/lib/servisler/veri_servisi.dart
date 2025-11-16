// lib/servisler/veri_servisi.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../modeller/kus.dart';
import '../modeller/eslesme.dart';
import '../modeller/yaris.dart';
import '../modeller/kulucka_donemi.dart';

class VeriServisi {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _appId = String.fromEnvironment('__app_id', defaultValue: 'default-app-id');

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception("Kullanıcı oturumu bulunamadı! Lütfen giriş yapın.");
    }
    return user.uid;
  }

  // --- Koleksiyon Referansları ---
  CollectionReference<Kus> get _kuslarRef =>
      _firestore.collection('artifacts').doc(_appId).collection('users').doc(_uid).collection('Kuslar').withConverter<Kus>(
            fromFirestore: (snapshot, _) => Kus.fromMap(snapshot.id, snapshot.data()!),
            toFirestore: (kus, _) => kus.toMap(),
          );

  CollectionReference<Eslesme> get _eslesmelerRef =>
      _firestore.collection('artifacts').doc(_appId).collection('users').doc(_uid).collection('Eslesmeler').withConverter<Eslesme>(
            fromFirestore: (snapshot, _) => Eslesme.fromMap(snapshot.id, snapshot.data()!),
            toFirestore: (eslesme, _) => eslesme.toMap(),
          );

  CollectionReference<Yaris> get _yarislarRef =>
      _firestore.collection('artifacts').doc(_appId).collection('users').doc(_uid).collection('Yarislar').withConverter<Yaris>(
            fromFirestore: (snapshot, _) => Yaris.fromMap(snapshot.data()!, snapshot.id),
            toFirestore: (yaris, _) => yaris.toMap(),
          );

  // Kulucka Dönemi Koleksiyon Referansı Oluşturma Metodu
  CollectionReference<KuluckaDonemi> _getKuluckaDonemleriRef(String eslesmeId) {
    return _eslesmelerRef.doc(eslesmeId).collection('KuluckaDonemleri').withConverter<KuluckaDonemi>(
            fromFirestore: (snapshot, _) => KuluckaDonemi.fromMap(snapshot.id, snapshot.data()!),
            toFirestore: (kuluckaDonemi, _) => kuluckaDonemi.toMap(),
          );
  }

  // ----------------------------------------------------------------------
  // 🕊️ KUŞ İŞLEMLERİ
  // ----------------------------------------------------------------------

  Stream<List<Kus>> tumKuslariGetir() {
    return _kuslarRef.snapshots().map(
          (snapshot) => snapshot.docs.map((doc) => doc.data()).toList(),
        );
  }

  // YENİ Metot: Belirli bir kullanıcıya ait kuşları getirir (Stream olarak)
  // KusProvider'ın beklediği metot. Aslında tumKuslariGetir ile aynı görevi görüyor
  // çünkü _kuslarRef zaten o kullanıcıya özel. Ancak hata çıktısında istendiği için ekledik.
  Stream<List<Kus>> kullaniciKuslariniGetirStream(String userId) {
    // userId zaten _kuslarRef içinde kullanılıyor, dolayısıyla bu metot tumKuslariGetir() ile aynıdır.
    // Eğer farklı bir filtreleme veya erişim mantığı olacaksa, burada özelleştirilmelidir.
    return _kuslarRef.snapshots().map(
          (snapshot) => snapshot.docs.map((doc) => doc.data()).toList(),
        );
  }

  Future<List<Kus>> tumKuslariGetirBirDefa() async {
    final snapshot = await _kuslarRef.get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  // Güncellendi: Future<String> döndürüyor (eklenen kuşun ID'si)
  Future<String> kusEkle(Kus kus) async {
    try {
      final docRef = await _kuslarRef.add(kus);
      print("✅ Kuş başarıyla eklendi, ID: ${docRef.id}");
      return docRef.id;
    } catch (e) {
      print("❌ Kuş eklenirken hata oluştu: $e");
      rethrow;
    }
  }

  Future<void> kusSil(String kusId) async {
    try {
      await _kuslarRef.doc(kusId).delete();
    } catch (e) {
      print("❌ Kuş silinirken hata oluştu: $e");
      rethrow;
    }
  }

  Future<void> kusDurumuGuncelle(String kusId, String yeniDurum) async {
    try {
      await _kuslarRef.doc(kusId).update({'kusDurumu': yeniDurum});
    } catch (e) {
      print("❌ Kuş durumu güncellenirken hata oluştu: $e");
      rethrow;
    }
  }

  Future<void> kusGuncelle(Kus kus) async {
    if (kus.kusId == null) {
      throw Exception("Kuş ID'si eksik, güncelleme yapılamaz.");
    }
    try {
      await _kuslarRef.doc(kus.kusId).update(kus.toMap());
    } catch (e) {
      print("❌ Kuş güncellenirken hata oluştu: $e");
      rethrow;
    }
  }

  // ----------------------------------------------------------------------
  // 🥚 EŞLEŞME İŞLEMLERİ
  // ----------------------------------------------------------------------

  Stream<List<Eslesme>> tumEslesmeleriGetir() {
    return _eslesmelerRef.snapshots().map(
          (snapshot) => snapshot.docs.map((doc) => doc.data()).toList(),
        );
  }

  Future<List<Eslesme>> tumEslesmeleriGetirBirDefa() async {
    final snapshot = await _eslesmelerRef.get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<String> eslesmeEkle(Eslesme eslesme) async {
    try {
      final docRef = await _eslesmelerRef.add(eslesme);
      print("✅ Eşleşme başarıyla eklendi, ID: ${docRef.id}");
      return docRef.id;
    } catch (e) {
      print("❌ Eşleşme eklenirken hata oluştu: $e");
      rethrow;
    }
  }
  
  Future<void> eslesmeGuncelle(Eslesme eslesme) async {
    if (eslesme.eslesmeId == null) {
      throw Exception("Eşleşme ID'si eksik, güncelleme yapılamaz.");
    }
    try {
      await _eslesmelerRef.doc(eslesme.eslesmeId).update(eslesme.toMap());
      print("✅ Eşleşme başarıyla güncellendi, ID: ${eslesme.eslesmeId}");
    } catch (e) {
      print("❌ Eşleşme güncellenirken hata oluştu: $e");
      rethrow;
    }
  }

  Future<void> eslesmeSil(String eslesmeId) async {
    try {
      // Eşleşme silinirken, altındaki tüm kulucka dönemlerini de silmek isteyebiliriz.
      final kuluckaDonemleriSnapshot = await _getKuluckaDonemleriRef(eslesmeId).get();
      for (final doc in kuluckaDonemleriSnapshot.docs) {
        await doc.reference.delete();
      }

      await _eslesmelerRef.doc(eslesmeId).delete();
      print("✅ Eşleşme ve ilişkili tüm kulucka dönemleri başarıyla silindi, ID: $eslesmeId");
    } catch (e) {
      print("❌ Eşleşme silinirken hata oluştu: $e");
      rethrow;
    }
  }

  // ----------------------------------------------------------------------
  // KULUCKA DÖNEMİ İŞLEMLERİ
  // ----------------------------------------------------------------------

  // Belirli bir eşleşmeye ait tüm kulucka dönemlerini gerçek zamanlı dinler
  Stream<List<KuluckaDonemi>> getKuluckaDonemleri(String eslesmeId) {
    return _getKuluckaDonemleriRef(eslesmeId).orderBy('yumurtlamaTarihi', descending: true).snapshots().map(
          (snapshot) => snapshot.docs.map((doc) => doc.data()).toList(),
        );
  }

  // Belirli bir eşleşmeye yeni bir kulucka dönemi ekler
  Future<String> kuluckaDonemiEkle(String eslesmeId, KuluckaDonemi kuluckaDonemi) async {
    try {
      final docRef = await _getKuluckaDonemleriRef(eslesmeId).add(kuluckaDonemi);
      print("✅ Kulucka dönemi başarıyla eklendi, ID: ${docRef.id}");
      return docRef.id;
    } catch (e) {
      print("❌ Kulucka dönemi eklenirken hata oluştu: $e");
      rethrow;
    }
  }

  // Belirli bir kulucka dönemini günceller
  Future<void> kuluckaDonemiGuncelle(String eslesmeId, KuluckaDonemi kuluckaDonemi) async {
    if (kuluckaDonemi.kuluckaId == null) {
      throw Exception("Kulucka Dönemi ID'si eksik, güncelleme yapılamaz.");
    }
    try {
      await _getKuluckaDonemleriRef(eslesmeId).doc(kuluckaDonemi.kuluckaId).update(kuluckaDonemi.toMap());
      print("✅ Kulucka dönemi başarıyla güncellendi, ID: ${kuluckaDonemi.kuluckaId}");
    } catch (e) {
      print("❌ Kulucka dönemi güncellenirken hata oluştu: $e");
      rethrow;
    }
  }

  // ----------------------------------------------------------------------
  // 🏆 YARIŞ İŞLEMLERİ
  // ----------------------------------------------------------------------

  Future<Yaris?> yarisKaydiGetir(String yarisId) async {
    final docSnapshot = await _yarislarRef.doc(yarisId).get();
    if (docSnapshot.exists) {
      return docSnapshot.data();
    }
    return null;
  }

  Stream<List<Yaris>> tumYarisKayitlariniGetir() {
    return _yarislarRef.snapshots().map(
          (snapshot) => snapshot.docs.map((doc) => doc.data()).toList(),
        );
  }

  Future<List<Yaris>> tumYarisKayitlariniGetirBirDefa() async {
    final snapshot = await _yarislarRef.get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<String> yarisEkle(Yaris yaris) async {
    try {
      final docRef = await _yarislarRef.add(yaris);
      return docRef.id;
    } catch (e) {
      print("❌ Yarış eklenirken hata oluştu: $e");
      rethrow;
    }
  }

  Future<void> yarisGuncelle(Yaris yaris) async {
    if (yaris.id.isEmpty) {
      throw Exception("Yarış ID'si eksik veya geçersiz, güncelleme yapılamaz.");
    }
    try {
      await _yarislarRef.doc(yaris.id).update(yaris.toMap());
    } catch (e) {
      print("❌ Yarış güncellenirken hata oluştu: $e");
      rethrow;
    }
  }

  Future<void> yarisSil(String yarisId) async {
    try {
      await _yarislarRef.doc(yarisId).delete();
    } catch (e) {
      print("❌ Yarış silinirken hata oluştu: $e");
      rethrow;
    }
  }
}
