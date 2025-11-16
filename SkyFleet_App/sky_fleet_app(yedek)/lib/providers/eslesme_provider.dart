// lib/providers/eslesme_provider.dart

import 'package:flutter/foundation.dart'; // ChangeNotifier ve kDebugMode için
import 'dart:async'; // StreamSubscription için
import 'package:collection/collection.dart'; // firstWhereOrNull için

import '../modeller/eslesme.dart';
import '../modeller/kulucka_donemi.dart';
import '../modeller/kus.dart';
import '../servisler/veri_servisi.dart';

class EslesmeProvider with ChangeNotifier {
  final VeriServisi _veriServisi = VeriServisi();
  List<Eslesme> _tumEslesmeler = [];
  late StreamSubscription<List<Eslesme>> _eslesmelerSubscription;

  // Akıllı Eş Seçimi ve Kuş bilgilerine erişim için KusProvider'dan gelecek kuşları tutacak
  List<Kus> _tumKuslar = [];
  StreamSubscription<List<Kus>>? _kuslarSubscription; // Kuşlar için dinleyici aboneliği


  // UI'da kullanılacak tüm eşleşmelerin listesi
  List<Eslesme> get tumEslesmeler => _tumEslesmeler;

  EslesmeProvider() {
    if (kDebugMode) { print("EslesmeProvider: Constructor çağrıldı."); }
    // Gerçek zamanlı dinlemeyi başlat
    _eslesmelerSubscription = _veriServisi.tumEslesmeleriGetir().listen((eslesmeListesi) {
      _tumEslesmeler = eslesmeListesi;
      if (kDebugMode) {
        print("EslesmeProvider: Eşleşme kayıtları güncellendi: ${_tumEslesmeler.length} kayıt.");
      }
      notifyListeners(); // Dinleyen widget'ları güncelle
    }, onError: (error) {
      if (kDebugMode) {
        print("EslesmeProvider HATA: Eşleşme kayıtları dinlenirken hata oluştu: $error");
      }
    });
  }

  @override
  void dispose() {
    if (kDebugMode) { print("EslesmeProvider: dispose() çağrıldı."); }
    _eslesmelerSubscription.cancel();
    _kuslarSubscription?.cancel(); // Kuşlar aboneliğini de temizle
    super.dispose();
  }

  // YENİ Metot: EslesmeListesiEkrani tarafından kullanılacak Stream'i doğrudan döndürür
  Stream<List<Eslesme>> getEslesmelerStream() {
    return _veriServisi.tumEslesmeleriGetir();
  }

  // Kuş Provider'dan gelen kuşlar listesini günceller ve dinlemeyi başlatır
  void updateKuslariDinle(Stream<List<Kus>> kuslarStream) {
    if (kDebugMode) { print("EslesmeProvider: updateKuslariDinle çağrıldı."); }
    _kuslarSubscription?.cancel(); // Önceki dinleyiciyi iptal et
    _kuslarSubscription = kuslarStream.listen((kusListesi) {
      _tumKuslar = kusListesi;
      // Kuş listesi değiştiğinde bu provider'ın UI'ını update etmeye gerek yok
      // Sadece Akıllı Eş Seçimi gibi özellikler için iç listede tutuluyor.
    });
  }

  // Belirli bir ID'ye sahip eşleşmeyi tek seferlik bulur
  Eslesme? eslesmeIdIleBul(String eslesmeId) {
    return _tumEslesmeler.firstWhereOrNull(
      (e) => e.eslesmeId == eslesmeId,
    );
  }
  
  // Belirli bir kuşa ait tüm eşleşmeleri filtreler
  List<Eslesme> kusaAitEslesmeleriGetir(String kusHalkaNo) {
    return _tumEslesmeler.where((e) => e.erkekHalkaNo == kusHalkaNo || e.disiHalkaNo == kusHalkaNo).toList();
  }

  // ----------------------------------------------------------------------
  // 🥚 EŞLEŞME İŞLEMLERİ
  // ----------------------------------------------------------------------

  // Yeni eşleşme kaydı ekler
  Future<String> eslesmeEkle(Eslesme eslesme) async {
    if (kDebugMode) { print("EslesmeProvider: eslesmeEkle çağrıldı: ${eslesme.erkekHalkaNo} & ${eslesme.disiHalkaNo}"); }
    return await _veriServisi.eslesmeEkle(eslesme);
  }
  
  // Mevcut eşleşmeyi günceller
  Future<void> eslesmeGuncelle(Eslesme eslesme) async {
    if (kDebugMode) { print("EslesmeProvider: eslesmeGuncelle çağrıldı: ${eslesme.eslesmeId}"); }
    await _veriServisi.eslesmeGuncelle(eslesme);
  }

  // Belirli bir eşleşme kaydını siler
  Future<void> eslesmeSil(String eslesmeId) async {
    if (kDebugMode) { print("EslesmeProvider: eslesmeSil çağrıldı: $eslesmeId"); }
    await _veriServisi.eslesmeSil(eslesmeId);
  }

  // ----------------------------------------------------------------------
  // KULUCKA DÖNEMİ İŞLEMLERİ
  // ----------------------------------------------------------------------

  // Belirli bir eşleşmeye ait tüm kulucka dönemlerini gerçek zamanlı dinler
  Stream<List<KuluckaDonemi>> getKuluckaDonemleriStream(String eslesmeId) {
    return _veriServisi.getKuluckaDonemleri(eslesmeId);
  }

  // Belirli bir eşleşmeye yeni bir kulucka dönemi ekler
  Future<String> kuluckaDonemiEkle(String eslesmeId, KuluckaDonemi kuluckaDonemi) async {
    if (kDebugMode) { print("EslesmeProvider: kuluckaDonemiEkle çağrıldı: Eslesme:$eslesmeId, Yumurtlama:${kuluckaDonemi.yumurtlamaTarihi}"); }
    return await _veriServisi.kuluckaDonemiEkle(eslesmeId, kuluckaDonemi);
  }

  // Belirli bir kulucka dönemini günceller
  Future<void> kuluckaDonemiGuncelle(String eslesmeId, KuluckaDonemi kuluckaDonemi) async {
    if (kDebugMode) { print("EslesmeProvider: kuluckaDonemiGuncelle çağrıldı: Eslesme:$eslesmeId, Kulucka:${kuluckaDonemi.kuluckaId}"); }
    await _veriServisi.kuluckaDonemiGuncelle(eslesmeId, kuluckaDonemi);
  }

  // ----------------------------------------------------------------------
  // AKILLI EŞ SEÇİMİ İÇİN YARDIMCI METOTLAR (KusProvider'dan gelen _tumKuslar'ı kullanır)
  // ----------------------------------------------------------------------

  // Belirli bir cinsiyetteki (ve 'Aktif' durumdaki) kuşları döndürür
  List<Kus> getCinsiyeteGoreAktifKuslar(String cinsiyet) {
    return _tumKuslar
        .where((kus) => kus.cinsiyet == cinsiyet && kus.kusDurumu == 'Aktif')
        .toList();
  }

  // Halka numarasına göre kuş bulur
  Kus? halkaNoIleKusBul(String halkaNo) {
    return _tumKuslar.firstWhereOrNull((kus) => kus.halkaNo.toUpperCase() == halkaNo.toUpperCase());
  }
}
