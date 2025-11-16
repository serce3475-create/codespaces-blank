// lib/modeller/pasif_ebeveyn.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class PasifEbeveyn {
  String id; // Firestore belge ID'si, genellikle halkaNo ile aynı olacak (artık final değil)
  final String halkaNo;
  final String? isim;
  final String? cinsiyet; // 'Erkek', 'Dişi', 'Bilinmiyor'
  final String? renk;
  final String? genetikHat;
  final String? notlar;
  String? anneId; // Bu pasif ebeveynin annesinin Firestore ID'si
  String? babaId; // Bu pasif ebeveynin babasının Firestore ID'si
  String? creatorUserId; // YENİ EKLENDİ: Belgeyi oluşturan kullanıcının UID'si
  DateTime? createdAt; // Oluşturulma tarihi (önceden olusturulmaTarihi)
  DateTime? updatedAt; // Son güncellenme tarihi (yeni eklendi)

  PasifEbeveyn({
    required this.id,
    required this.halkaNo,
    this.isim,
    this.cinsiyet,
    this.renk,
    this.genetikHat,
    this.notlar,
    this.anneId,
    this.babaId,
    this.creatorUserId, // YENİ EKLENDİ
    this.createdAt,
    this.updatedAt,
  });

  // Firestore'dan gelen DocumentSnapshot'u PasifEbeveyn nesnesine dönüştürme
  factory PasifEbeveyn.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return PasifEbeveyn(
      id: doc.id, // Belge ID'sini doğrudan id alanına ata
      halkaNo: data['halkaNo'] as String? ?? '', // Halka no boş gelme ihtimaline karşı kontrol
      isim: data['isim'] as String?,
      cinsiyet: data['cinsiyet'] as String?,
      renk: data['renk'] as String?,
      genetikHat: data['genetikHat'] as String?,
      notlar: data['notlar'] as String?,
      anneId: data['anneId'] as String?,
      babaId: data['babaId'] as String?,
      creatorUserId: data['creatorUserId'] as String?, // YENİ EKLENDİ
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  // PasifEbeveyn nesnesini Firestore'a göndermek için Map'e dönüştürme
  // `id` alanı map'e dahil edilmez, çünkü belge ID'si olarak kullanılır.
  Map<String, dynamic> toFirestore() {
    return {
      'halkaNo': halkaNo,
      'isim': isim,
      'cinsiyet': cinsiyet,
      'renk': renk,
      'genetikHat': genetikHat,
      'notlar': notlar,
      'anneId': anneId,
      'babaId': babaId,
      'creatorUserId': creatorUserId, // YENİ EKLENDİ
      'createdAt': createdAt ?? FieldValue.serverTimestamp(), // Oluşturulmadıysa şimdi ayarla
      'updatedAt': FieldValue.serverTimestamp(), // Her zaman güncellendiğinde ayarla
    };
  }

  // copyWith metodu
  PasifEbeveyn copyWith({
    String? id,
    String? halkaNo,
    String? isim,
    String? cinsiyet,
    String? renk,
    String? genetikHat,
    String? notlar,
    String? anneId,
    String? babaId,
    String? creatorUserId, // YENİ EKLENDİ
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PasifEbeveyn(
      id: id ?? this.id,
      halkaNo: halkaNo ?? this.halkaNo,
      isim: isim ?? this.isim,
      cinsiyet: cinsiyet ?? this.cinsiyet,
      renk: renk ?? this.renk,
      genetikHat: genetikHat ?? this.genetikHat,
      notlar: notlar ?? this.notlar,
      anneId: anneId ?? this.anneId,
      babaId: babaId ?? this.babaId,
      creatorUserId: creatorUserId ?? this.creatorUserId, // YENİ EKLENDİ
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
