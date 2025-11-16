// lib/modeller/eslesme_kaydi.dart
class EslesmeKaydi {
  final String? eslesmeId;
  final String erkekHalkaNo;
  final String disiHalkaNo;
  final DateTime eslesmeBaslangicTarihi;
  final DateTime? eslesmeBitisTarihi;
  final String? notlar;

  EslesmeKaydi({
    this.eslesmeId,
    required this.erkekHalkaNo,
    required this.disiHalkaNo,
    required this.eslesmeBaslangicTarihi,
    this.eslesmeBitisTarihi,
    this.notlar,
  });

  // Firestore'dan EslesmeKaydi nesnesine dönüştürme
  factory EslesmeKaydi.fromMap(Map<String, dynamic> data, String id) {
    return EslesmeKaydi(
      eslesmeId: id,
      erkekHalkaNo: data['erkekHalkaNo'] ?? '',
      disiHalkaNo: data['disiHalkaNo'] ?? '',
      eslesmeBaslangicTarihi: data['eslesmeBaslangicTarihi']?.toDate() ?? DateTime.now(),
      eslesmeBitisTarihi: data['eslesmeBitisTarihi']?.toDate(),
      notlar: data['notlar'],
    );
  }

  // Firestore'a göndermek için Map'e dönüştürme
  Map<String, dynamic> toMap() {
    return {
      'erkekHalkaNo': erkekHalkaNo,
      'disiHalkaNo': disiHalkaNo,
      'eslesmeBaslangicTarihi': eslesmeBaslangicTarihi,
      'eslesmeBitisTarihi': eslesmeBitisTarihi,
      'notlar': notlar,
    };
  }
}