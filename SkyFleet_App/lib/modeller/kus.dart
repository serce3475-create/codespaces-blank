// lib/modeller/kus.dart

import 'package:cloud_firestore/cloud_firestore.dart'; // Timestamp kullanımı için

class Kus {
  String? kusId; // Firestore ID'si
  final String halkaNo;
  final String? isim;
  final String? cinsiyet;
  final DateTime? dogumTarihi;
  final String? kusDurumu; // 'Aktif', 'Pasif', 'Satıldı', 'Ölen', 'Kayıp'
  final String? notlar;
  final String? anneHalkaNo;
  final String? babaHalkaNo;
  final String? renk;
  final String? genetikHat;

  Kus({
    this.kusId,
    required this.halkaNo,
    this.isim,
    this.cinsiyet,
    this.dogumTarihi,
    this.kusDurumu,
    this.notlar,
    this.anneHalkaNo,
    this.babaHalkaNo,
    this.renk,
    this.genetikHat,
  });

  // Firestore'dan gelen veriyi Kus nesnesine dönüştürme
  factory Kus.fromMap(String id, Map<String, dynamic> data) {
    return Kus(
      kusId: id,
      halkaNo: data['halkaNo'] ?? '',
      isim: data['isim'],
      cinsiyet: data['cinsiyet'],
      dogumTarihi: (data['dogumTarihi'] as Timestamp?)?.toDate(),
      kusDurumu: data['kusDurumu'],
      notlar: data['notlar'],
      anneHalkaNo: data['anneHalkaNo'],
      babaHalkaNo: data['babaHalkaNo'],
      renk: data['renk'],
      genetikHat: data['genetikHat'],
    );
  }

  // Kus nesnesini Firestore'a göndermek için Map'e dönüştürme
  Map<String, dynamic> toMap() {
    return {
      'halkaNo': halkaNo,
      'isim': isim,
      'cinsiyet': cinsiyet,
      'dogumTarihi': dogumTarihi != null ? Timestamp.fromDate(dogumTarihi!) : null,
      'kusDurumu': kusDurumu,
      'notlar': notlar,
      'anneHalkaNo': anneHalkaNo,
      'babaHalkaNo': babaHalkaNo,
      'renk': renk,
      'genetikHat': genetikHat,
    };
  }

  // YENİ EKLENEN METOT: copyWith
  Kus copyWith({
    String? kusId,
    String? halkaNo,
    String? isim,
    String? cinsiyet,
    DateTime? dogumTarihi,
    String? kusDurumu,
    String? notlar,
    String? anneHalkaNo,
    String? babaHalkaNo,
    String? renk,
    String? genetikHat,
  }) {
    return Kus(
      kusId: kusId ?? this.kusId,
      halkaNo: halkaNo ?? this.halkaNo,
      isim: isim ?? this.isim,
      cinsiyet: cinsiyet ?? this.cinsiyet,
      dogumTarihi: dogumTarihi ?? this.dogumTarihi,
      kusDurumu: kusDurumu ?? this.kusDurumu,
      notlar: notlar ?? this.notlar,
      anneHalkaNo: anneHalkaNo ?? this.anneHalkaNo,
      babaHalkaNo: babaHalkaNo ?? this.babaHalkaNo,
      renk: renk ?? this.renk,
      genetikHat: genetikHat ?? this.genetikHat,
    );
  }

  // Kuşun yaşını yıla göre hesaplama (Opsiyonel, eğer Kus modelinizde varsa)
  int? yasHesaplaYil() {
    if (dogumTarihi == null) {
      return null;
    }
    final now = DateTime.now();
    int yas = now.year - dogumTarihi!.year;
    if (now.month < dogumTarihi!.month ||
        (now.month == dogumTarihi!.month && now.day < dogumTarihi!.day)) {
      yas--;
    }
    return yas;
  }
}
