// lib/modeller/kus_filtre_tipi.dart

enum KusFiltreTipi {
  aktif,        // Aktif kuşlar
  erkek,        // Erkek kuşlar
  disi,         // Dişi kuşlar
  yavru,        // 0-12 ay arası yavrular
  yarismis,     // Yarışmış kuşlar
  satildi,      // Satılmış kuşlar
  kayip,        // Kayıp kuşlar
  olen,         // Ölen kuşlar
  tumu,         // Tüm kuşlar (en sona taşındı)
  pasif,        // Pasif kuşlar (aktif değil, ama spesifik olarak pasif durumu için)
}

extension KusFiltreTipiExtension on KusFiltreTipi {
  String toTurkishString() {
    switch (this) {
      case KusFiltreTipi.aktif:
        return 'Aktif';
      case KusFiltreTipi.erkek:
        return 'Erkek';
      case KusFiltreTipi.disi:
        return 'Dişi';
      case KusFiltreTipi.yavru:
        return 'Yavru (0-12 Ay)';
      case KusFiltreTipi.yarismis:
        return 'Yarışmış';
      case KusFiltreTipi.satildi:
        return 'Satıldı';
      case KusFiltreTipi.kayip:
        return 'Kayıp';
      case KusFiltreTipi.olen:
        return 'Ölen';
      case KusFiltreTipi.tumu:
        return 'Tümü';
      case KusFiltreTipi.pasif:
        return 'Pasif';
    }
  }
}
