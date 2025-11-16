import 'package:cloud_firestore/cloud_firestore.dart';
// KuluçkaDonemi modelini doğrudan burada import etmeye gerek yok,
// çünkü alt koleksiyon olarak yönetilecek.

// Eşleşmenin genel durumunu belirten enum
enum EslesmeDurumu {
  aktif,        // Eşleşme aktif, yeni kuluçka dönemleri başlatılabilir
  tamamlandi,   // Eşleşme tamamlandı, artık yeni kuluçka beklenmiyor
  ayrildi,      // Eşleşen kuşlar ayrıldı
  pasif,        // Eşleşme bir süreliğine pasife alındı
}

class Eslesme {
  final String? eslesmeId;
  final String erkekHalkaNo;
  final String disiHalkaNo;
  final DateTime eslesmeTarihi; // Eşleşmenin başlangıç tarihi (eslesmeBaslangicTarihi yerine)
  final EslesmeDurumu durumu; // Eşleşmenin genel durumu (aktif mi, ayrıldı mı vb.)
  final String? ozelNot; // Özel notlar

  // Kuluçka Dönemleri artık bu Eslesme belgesinin altında bir alt koleksiyon olarak yönetileceği için,
  // bu alanlar Eslesme modelinden kaldırılmıştır.
  // final DateTime? eslesmeBitisTarihi;
  // final int? yavruSayisi;

  Eslesme({
    this.eslesmeId,
    required this.erkekHalkaNo,
    required this.disiHalkaNo,
    required this.eslesmeTarihi,
    this.durumu = EslesmeDurumu.aktif, // Varsayılan durum
    this.ozelNot,
  });

  // Firestore'a göndermek için Map'e dönüştürme
  Map<String, dynamic> toMap() {
    return {
      'erkekHalkaNo': erkekHalkaNo,
      'disiHalkaNo': disiHalkaNo,
      'eslesmeTarihi': Timestamp.fromDate(eslesmeTarihi),
      'durumu': durumu.toString().split('.').last, // Enum'ı string'e çevir
      'ozelNot': ozelNot,
    };
  }

  // Firestore'dan okumak için Map'ten oluşturma
  factory Eslesme.fromMap(String id, Map<String, dynamic> map) {
    return Eslesme(
      eslesmeId: id,
      erkekHalkaNo: map['erkekHalkaNo'] as String,
      disiHalkaNo: map['disiHalkaNo'] as String,
      eslesmeTarihi: (map['eslesmeTarihi'] as Timestamp).toDate(),
      durumu: EslesmeDurumu.values.firstWhere(
        (e) => e.toString().split('.').last == map['durumu'],
        orElse: () => EslesmeDurumu.aktif, // Eğer durum bulunamazsa varsayılan
      ),
      ozelNot: map['ozelNot'] as String?,
    );
  }

  // Kopya oluşturma metodu
  Eslesme copyWith({
    String? eslesmeId,
    String? erkekHalkaNo,
    String? disiHalkaNo,
    DateTime? eslesmeTarihi,
    EslesmeDurumu? durumu,
    String? ozelNot,
  }) {
    return Eslesme(
      eslesmeId: eslesmeId ?? this.eslesmeId,
      erkekHalkaNo: erkekHalkaNo ?? this.erkekHalkaNo,
      disiHalkaNo: disiHalkaNo ?? this.disiHalkaNo,
      eslesmeTarihi: eslesmeTarihi ?? this.eslesmeTarihi,
      durumu: durumu ?? this.durumu,
      ozelNot: ozelNot ?? this.ozelNot,
    );
  }
}
