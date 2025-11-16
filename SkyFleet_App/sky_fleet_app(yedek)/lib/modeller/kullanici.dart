import 'package:cloud_firestore/cloud_firestore.dart';

class Kullanici {
  final String uid; // Firebase Authentication UID'si
  final String? isim;
  final String? soyisim;
  final String? telefonNumarasi;
  final String? email; // Firebase Auth'dan gelir, burada da tutulabilir
  final Map<String, String>? adres; // {'ulke': '...', 'il': '...', 'ilce': '...'}

  Kullanici({
    required this.uid,
    this.isim,
    this.soyisim,
    this.telefonNumarasi,
    this.email,
    this.adres,
  });

  // Firestore'a göndermek için Map'e dönüştürür
  Map<String, dynamic> toMap() {
    return {
      'isim': isim,
      'soyisim': soyisim,
      'telefonNumarasi': telefonNumarasi,
      'email': email,
      'adres': adres,
      // 'uid' Firestore doküman ID'si olarak kullanılacağı için burada saklanmaz.
    };
  }

  // Firestore'dan gelen Map'i Kullanici nesnesine dönüştürür
  factory Kullanici.fromMap(String uid, Map<String, dynamic> map) {
    return Kullanici(
      uid: uid,
      isim: map['isim'] as String?,
      soyisim: map['soyisim'] as String?,
      telefonNumarasi: map['telefonNumarasi'] as String?,
      email: map['email'] as String?,
      adres: (map['adres'] as Map<String, dynamic>?)?.map((key, value) => MapEntry(key, value.toString())),
    );
  }
}
