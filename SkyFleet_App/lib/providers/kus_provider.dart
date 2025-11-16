// lib/providers/kus_provider.dart

import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:collection/collection.dart'; // firstWhereOrNull için gerekli

import '../modeller/kus.dart';
import '../modeller/kus_filtre_tipi.dart'; // KusFiltreTipi enum'u için
import '../servisler/veri_servisi.dart';

class KusProvider with ChangeNotifier {
  final VeriServisi _veriServisi = VeriServisi();
  List<Kus> _tumKuslar = [];
  late StreamSubscription<List<Kus>> _kuslarSubscription;

  String _aramaSorgusu = '';
  KusFiltreTipi _aktifFiltre = KusFiltreTipi.tumu;

  List<Kus> get tumKuslar => _tumKuslar;
  String get aramaSorgusu => _aramaSorgusu;
  KusFiltreTipi get aktifFiltre => _aktifFiltre;

  // YENİ EKLENEN GETTER: EslesmeProvider'ın kuş stream'ini dinlemesi için
  Stream<List<Kus>> get kuslarStream => _veriServisi.tumKuslariGetir();


  KusProvider() {
    if (kDebugMode) { print("KusProvider: Constructor çağrıldı."); }
    _kuslarSubscription = kuslarStream.listen((kusListesi) {
      _tumKuslar = kusListesi;
      if (kDebugMode) { print("KusProvider: Kuş kayıtları güncellendi: ${_tumKuslar.length} kayıt."); }
      notifyListeners();
    }, onError: (error) {
      if (kDebugMode) { print("KusProvider HATA: Kuş kayıtları dinlenirken hata oluştu: $error"); }
    });
  }

  @override
  void dispose() {
    if (kDebugMode) { print("KusProvider: dispose() çağrıldı."); }
    _kuslarSubscription.cancel();
    super.dispose();
  }

  void aramaSorgusunuGuncelle(String query) {
    _aramaSorgusu = query;
    notifyListeners();
  }

  void filtreyiUygula(KusFiltreTipi filtreTipi) {
    _aktifFiltre = filtreTipi;
    notifyListeners();
  }

  List<Kus> get filtrelenmisVeAranmisKuslar {
    List<Kus> sonuc = _tumKuslar;

    // Filtreleme
    if (_aktifFiltre == KusFiltreTipi.aktif) {
      sonuc = sonuc.where((kus) => kus.kusDurumu == 'Aktif').toList();
    } else if (_aktifFiltre == KusFiltreTipi.pasif) {
      sonuc = sonuc.where((kus) => kus.kusDurumu == 'Pasif').toList();
    } else if (_aktifFiltre == KusFiltreTipi.satildi) {
      sonuc = sonuc.where((kus) => kus.kusDurumu == 'Satıldı').toList();
    } else if (_aktifFiltre == KusFiltreTipi.kayip) {
      sonuc = sonuc.where((kus) => kus.kusDurumu == 'Kayıp').toList();
    } else if (_aktifFiltre == KusFiltreTipi.olen) {
      sonuc = sonuc.where((kus) => kus.kusDurumu == 'Ölen').toList();
    } else if (_aktifFiltre == KusFiltreTipi.disi) {
      sonuc = sonuc.where((kus) => kus.cinsiyet == 'Dişi').toList();
    } else if (_aktifFiltre == KusFiltreTipi.erkek) {
      sonuc = sonuc.where((kus) => kus.cinsiyet == 'Erkek').toList();
    } else if (_aktifFiltre == KusFiltreTipi.yavru) { // YENİ: Yavru filtresi eklendi
      sonuc = sonuc.where((kus) => (kus.anneHalkaNo != null && kus.anneHalkaNo!.isNotEmpty) ||
                                   (kus.babaHalkaNo != null && kus.babaHalkaNo!.isNotEmpty)).toList();
    }

    // Arama Sorgusu
    if (_aramaSorgusu.isNotEmpty) {
      final aramaLower = _aramaSorgusu.toLowerCase();
      sonuc = sonuc.where((kus) {
        return kus.halkaNo.toLowerCase().contains(aramaLower) ||
               (kus.isim?.toLowerCase().contains(aramaLower) ?? false);
      }).toList();
    }

    return sonuc;
  }

  // İstatistikler için kullanılan getter'lar
  List<Kus> get tumKuslarIstatistik => _tumKuslar;
  List<Kus> get erkekKuslarIstatistik => _tumKuslar.where((kus) => kus.cinsiyet == 'Erkek').toList();
  List<Kus> get disiKuslarIstatistik => _tumKuslar.where((kus) => kus.cinsiyet == 'Dişi').toList();
  List<Kus> get yavrularIstatistik => _tumKuslar.where((kus) => (kus.anneHalkaNo != null && kus.anneHalkaNo!.isNotEmpty) || (kus.babaHalkaNo != null && kus.babaHalkaNo!.isNotEmpty)).toList();

  bool halkaNoIleKusVarMi(String halkaNo) {
    return _tumKuslar.any((kus) => kus.halkaNo.toUpperCase() == halkaNo.toUpperCase());
  }
  
  Kus? halkaNoIleKusBul(String halkaNo) {
    return _tumKuslar.firstWhereOrNull((kus) => kus.halkaNo.toUpperCase() == halkaNo.toUpperCase());
  }

  Kus? kusIdIleKusBul(String kusId) {
    return _tumKuslar.firstWhereOrNull((kus) => kus.kusId == kusId);
  }

  Future<String> kusEkle(Kus kus) async {
    if (kDebugMode) { print("KusProvider: kusEkle çağrıldı: ${kus.halkaNo}"); }
    return await _veriServisi.kusEkle(kus);
  }

  Future<void> kusGuncelle(Kus kus) async {
    if (kDebugMode) { print("KusProvider: kusGuncelle çağrıldı: ${kus.halkaNo}"); }
    await _veriServisi.kusGuncelle(kus);
  }

  Future<void> kusDurumuGuncelle(String kusId, String yeniDurum) async {
    if (kDebugMode) { print("KusProvider: kusDurumuGuncelle çağrıldı: ID:$kusId, Yeni Durum:$yeniDurum"); }
    final guncelKus = _tumKuslar.firstWhereOrNull((kus) => kus.kusId == kusId)?.copyWith(kusDurumu: yeniDurum);
    if (guncelKus != null) {
      await _veriServisi.kusGuncelle(guncelKus);
    }
  }

  Future<void> kusTamamenSil(String kusId) async {
    if (kDebugMode) { print("KusProvider: kusTamamenSil çağrıldı: $kusId"); }
    await _veriServisi.kusSil(kusId);
  }

  // Bu metod _veriServisi'ndeki kullaniciKuslariniGetirStream'i çağırır.
  Stream<List<Kus>> kullaniciKuslariniGetirStream(String userId) {
    return _veriServisi.kullaniciKuslariniGetirStream(userId);
  }
}
