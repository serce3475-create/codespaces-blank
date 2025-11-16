import 'package:cloud_firestore/cloud_firestore.dart';

// Kulucka sürecinin durumunu belirten enum
enum KuluckaDurumu { // 'KuluçkaDurumu' -> 'KuluckaDurumu'
  devamEdiyor, // Kulucka aktif olarak devam ediyor
  basarili,    // Kulucka başarıyla sonuçlandı, yavru alındı
  basarisiz,   // Kulucka başarısız oldu (yumurtalar çatlamadı, yavrular öldü vb.)
  iptalEdildi, // Kulucka döngüsü çeşitli nedenlerle iptal edildi (örneğin ebeveynler ayrıldı)
}

class KuluckaDonemi { // 'KuluçkaDonemi' -> 'KuluckaDonemi'
  final String? kuluckaId; // 'kuluçkaId' -> 'kuluckaId' // Firestore document ID for this incubation cycle
  final DateTime yumurtlamaTarihi;
  final DateTime? kuluckaBitisTarihi; // 'kuluçkaBitisTarihi' -> 'kuluckaBitisTarihi' // Kulucka sürecinin fiilen bittiği tarih
  final KuluckaDurumu durumu; // 'KuluçkaDurumu' -> 'KuluckaDurumu' // Mevcut kulucka durumu
  final int? gerceklesenYavruSayisi; // Kulucka sonucunda alınan toplam yavru sayısı
  final int? basariliYavruSayisi;    // Sağlıklı büyüyen yavru sayısı (kayıtlı)
  final int? basarisizYavruSayisi;   // Kaybedilen yavru sayısı (kayıtlı)
  final String? kuluckaNotlari;     // 'kuluçkaNotlari' -> 'kuluckaNotlari' // Bu kulucka dönemiyle ilgili özel notlar

  KuluckaDonemi({ // 'KuluçkaDonemi' -> 'KuluckaDonemi'
    this.kuluckaId, // 'kuluçkaId' -> 'kuluckaId'
    required this.yumurtlamaTarihi,
    this.kuluckaBitisTarihi, // 'kuluçkaBitisTarihi' -> 'kuluckaBitisTarihi'
    this.durumu = KuluckaDurumu.devamEdiyor, // 'KuluçkaDurumu' -> 'KuluckaDurumu' // Varsayılan durum
    this.gerceklesenYavruSayisi,
    this.basariliYavruSayisi,
    this.basarisizYavruSayisi,
    this.kuluckaNotlari, // 'kuluçkaNotlari' -> 'kuluckaNotlari'
  });

  // Firestore'a göndermek için Map'e dönüştürür
  Map<String, dynamic> toMap() {
    return {
      'yumurtlamaTarihi': Timestamp.fromDate(yumurtlamaTarihi),
      'kuluckaBitisTarihi': kuluckaBitisTarihi != null ? Timestamp.fromDate(kuluckaBitisTarihi!) : null, // 'kuluçkaBitisTarihi' -> 'kuluckaBitisTarihi'
      'durumu': durumu.toString().split('.').last, // Enum'ı string'e çevir (örn: "devamEdiyor")
      'gerceklesenYavruSayisi': gerceklesenYavruSayisi,
      'basariliYavruSayisi': basariliYavruSayisi,
      'basarisizYavruSayisi': basarisizYavruSayisi,
      'kuluckaNotlari': kuluckaNotlari, // 'kuluçkaNotlari' -> 'kuluckaNotlari'
    };
  }

  // Firestore'dan gelen Map'i KuluckaDonemi nesnesine dönüştürür
  factory KuluckaDonemi.fromMap(String id, Map<String, dynamic> map) { // 'KuluçkaDonemi' -> 'KuluckaDonemi'
    return KuluckaDonemi( // 'KuluçkaDonemi' -> 'KuluckaDonemi'
      kuluckaId: id, // 'kuluçkaId' -> 'kuluckaId'
      yumurtlamaTarihi: (map['yumurtlamaTarihi'] as Timestamp).toDate(),
      kuluckaBitisTarihi: map['kuluckaBitisTarihi'] != null ? (map['kuluckaBitisTarihi'] as Timestamp).toDate() : null, // 'kuluçkaBitisTarihi' -> 'kuluckaBitisTarihi'
      durumu: KuluckaDurumu.values.firstWhere( // 'KuluçkaDurumu' -> 'KuluckaDurumu'
        (e) => e.toString().split('.').last == map['durumu'],
        orElse: () => KuluckaDurumu.devamEdiyor, // 'KuluçkaDurumu' -> 'KuluckaDurumu' // Eğer durum bulunamazsa varsayılan
      ),
      gerceklesenYavruSayisi: map['gerceklesenYavruSayisi'] as int?,
      basariliYavruSayisi: map['basariliYavruSayisi'] as int?,
      basarisizYavruSayisi: map['basarisizYavruSayisi'] as int?,
      kuluckaNotlari: map['kuluckaNotlari'] as String?, // 'kuluçkaNotlari' -> 'kuluckaNotlari'
    );
  }

  // Kopya oluşturma metodu (immutable nesneleri güncellemek için kullanışlı)
  KuluckaDonemi copyWith({ // 'KuluçkaDonemi' -> 'KuluckaDonemi'
    String? kuluckaId, // 'kuluçkaId' -> 'kuluckaId'
    DateTime? yumurtlamaTarihi,
    DateTime? kuluckaBitisTarihi, // 'kuluçkaBitisTarihi' -> 'kuluckaBitisTarihi'
    KuluckaDurumu? durumu, // 'KuluçkaDurumu' -> 'KuluckaDurumu'
    int? gerceklesenYavruSayisi,
    int? basariliYavruSayisi,
    int? basarisizYavruSayisi,
    String? kuluckaNotlari, // 'kuluçkaNotlari' -> 'kuluckaNotlari'
  }) {
    return KuluckaDonemi( // 'KuluçkaDonemi' -> 'KuluckaDonemi'
      kuluckaId: kuluckaId ?? this.kuluckaId, // 'kuluçkaId' -> 'kuluckaId'
      yumurtlamaTarihi: yumurtlamaTarihi ?? this.yumurtlamaTarihi,
      kuluckaBitisTarihi: kuluckaBitisTarihi ?? this.kuluckaBitisTarihi, // 'kuluçkaBitisTarihi' -> 'kuluckaBitisTarihi'
      durumu: durumu ?? this.durumu,
      gerceklesenYavruSayisi: gerceklesenYavruSayisi ?? this.gerceklesenYavruSayisi,
      basariliYavruSayisi: basariliYavruSayisi ?? this.basariliYavruSayisi,
      basarisizYavruSayisi: basarisizYavruSayisi ?? this.basarisizYavruSayisi,
      kuluckaNotlari: kuluckaNotlari ?? this.kuluckaNotlari, // 'kuluçkaNotlari' -> 'kuluckaNotlari'
    );
  }
}
