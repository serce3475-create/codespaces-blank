// lib/modeller/yaris.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // 'required' keyword'ü için (Dart 2.12+ ise gerekmez)

class Yaris {
  final String id; // Firestore belge ID'sini tutmak için
  final String kusHalkaNo;
  final String yarisAdi;
  final DateTime yarisTarihi;
  final int derece;
  final double mesafe; // Genel mesafe (Örn: Uçuş mesafesi değil, yarışın uzunluğu)
  final String konum; // Yarışın genel konumu

  // Yeni eklenen ve diğer ekranlarda kullanılan alanlar:
  final String baslangicYeri;
  final String varisYeri;
  final Duration ucusSuresi; // Uçuş süresi için Duration kullanıyoruz
  final double mesafeKm; // Kuşun kat ettiği mesafe (Km cinsinden)
  final String? notlar; // <<<--- YENİ EKLENEN ALAN: Notlar (null olabilir)

  Yaris({
    required this.id,
    required this.kusHalkaNo,
    required this.yarisAdi,
    required this.yarisTarihi,
    required this.derece,
    required this.mesafe,
    required this.konum,
    // Diğer ekranlarda beklenen ve yeni eklenen alanlar:
    required this.baslangicYeri,
    required this.varisYeri,
    required this.ucusSuresi,
    required this.mesafeKm,
    this.notlar, // <<<--- KURUCUYA EKLENDİ (required değil, çünkü null olabilir)
  });

  // Firestore'dan gelen Map ve belge ID'sini alacak şekilde fromMap factory
  factory Yaris.fromMap(Map<String, dynamic> data, String documentId) {
    return Yaris(
      id: documentId,
      kusHalkaNo: data['kusHalkaNo'] as String,
      yarisAdi: data['yarisAdi'] as String,
      yarisTarihi: (data['yarisTarihi'] as Timestamp).toDate(),
      derece: data['derece'] as int,
      mesafe: (data['mesafe'] as num).toDouble(), // num'dan double'a çevirin
      konum: data['konum'] as String,
      // Yeni alanların okunması:
      baslangicYeri: data['baslangicYeri'] as String,
      varisYeri: data['varisYeri'] as String,
      ucusSuresi: Duration(milliseconds: data['ucusSuresiMillis'] as int), // Milisaniyeden Duration'a çevir
      mesafeKm: (data['mesafeKm'] as num).toDouble(), // num'dan double'a çevirin
      notlar: data['notlar'] as String?, // <<<--- fromMap metoduna eklendi
    );
  }

  // Firestore'a göndermek için Map'e dönüştüren toMap metodu
  Map<String, dynamic> toMap() {
    return {
      'kusHalkaNo': kusHalkaNo,
      'yarisAdi': yarisAdi,
      'yarisTarihi': Timestamp.fromDate(yarisTarihi), // DateTime'ı Timestamp'a çevirin
      'derece': derece,
      'mesafe': mesafe,
      'konum': konum,
      // Yeni alanların yazılması:
      'baslangicYeri': baslangicYeri,
      'varisYeri': varisYeri,
      'ucusSuresiMillis': ucusSuresi.inMilliseconds, // Duration'ı milisaniye olarak kaydet
      'mesafeKm': mesafeKm,
      'notlar': notlar, // <<<--- toMap metoduna eklendi
    };
  }
}
