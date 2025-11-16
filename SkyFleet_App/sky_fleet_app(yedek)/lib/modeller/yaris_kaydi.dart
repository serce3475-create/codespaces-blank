// Bu dosya, belirli bir kuşun tek bir yarışta elde ettiği tüm detayları içerir.
import 'package:cloud_firestore/cloud_firestore.dart';

class YarisKaydi {
  final String? kayitId; // Firestore doküman ID'si
  final String kusHalkaNo;
  final DateTime yarisTarihi;
  final String yarisAdi;
  final String baslangicYeri;
  final String varisYeri;
  final double mesafeKm;
  final Duration ucusSuresi;
  final int derece; // Kuşun bu yarıştaki derecesi (0=derece alamadı)
  final String? notlar;

  YarisKaydi({
    this.kayitId,
    required this.kusHalkaNo,
    required this.yarisTarihi,
    required this.yarisAdi,
    required this.baslangicYeri,
    required this.varisYeri,
    required this.mesafeKm,
    required this.ucusSuresi,
    required this.derece,
    this.notlar,
  });

  // Duration nesnesini milisaniye cinsinden int'e çevir
  int _durationToMs(Duration duration) => duration.inMilliseconds;

  // Firestore'a veri yazmak için
  Map<String, dynamic> toMap() {
    return {
      'kusHalkaNo': kusHalkaNo,
      'yarisTarihi': Timestamp.fromDate(yarisTarihi), 
      'yarisAdi': yarisAdi,
      'baslangicYeri': baslangicYeri,
      'varisYeri': varisYeri,
      'mesafeKm': mesafeKm,
      'ucusSuresiMs': _durationToMs(ucusSuresi), 
      'derece': derece,
      'notlar': notlar,
    };
  }

  // Firestore'dan veri okumak için
  factory YarisKaydi.fromMap(Map<String, dynamic> map, String id) {
    // Güvenli tip dönüşü
    final int ucusSuresiMs = (map['ucusSuresiMs'] as int?) ?? 0;

    return YarisKaydi(
      kayitId: id,
      kusHalkaNo: map['kusHalkaNo'] as String? ?? '', // Kuş halka no her zaman olmalı
      yarisTarihi: (map['yarisTarihi'] as Timestamp?)?.toDate() ?? DateTime.now(),
      yarisAdi: map['yarisAdi'] as String? ?? 'Adsız Yarış',
      baslangicYeri: map['baslangicYeri'] as String? ?? '',
      varisYeri: map['varisYeri'] as String? ?? '',
      mesafeKm: (map['mesafeKm'] as num?)?.toDouble() ?? 0.0,
      ucusSuresi: Duration(milliseconds: ucusSuresiMs),
      derece: map['derece'] as int? ?? 0,
      notlar: map['notlar'] as String?,
    );
  }
}