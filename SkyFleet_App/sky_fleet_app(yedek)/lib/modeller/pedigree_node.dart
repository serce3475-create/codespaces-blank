// lib/modeller/pedigree_node.dart

class PedigreeNode {
  final String halkaNo;
  final String? isim;
  final String? cinsiyet;
  final String? notlar;
  final int level;
  final bool isBos;

  final String? yetistiriciAdSoyad;
  final String? yarisBilgileri; // Özet string
  final int? yarisDerecesiAraligi; // YENİ: Yarış derecesine göre 1 (1-20), 2 (21+), null (yarışmamış)

  final String? renk;

  // YENİ EKLENDİ: PDF ağaç çizimi için ebeveyn halka numaraları
  final String? fatherHalkaNo;
  final String? motherHalkaNo;


  PedigreeNode({
    required this.halkaNo,
    this.isim,
    this.cinsiyet,
    this.notlar,
    required this.level,
    this.isBos = false,
    this.yetistiriciAdSoyad,
    this.yarisBilgileri,
    this.yarisDerecesiAraligi, // YENİ
    this.renk,
    // YENİ: Constructor'a eklendi
    this.fatherHalkaNo,
    this.motherHalkaNo,
  });

  factory PedigreeNode.bosNode(int level) {
    return PedigreeNode(
      halkaNo: 'Bilinmiyor',
      isim: 'Bilinmiyor',
      cinsiyet: null,
      notlar: null,
      level: level,
      isBos: true,
      yetistiriciAdSoyad: null,
      yarisBilgileri: null,
      yarisDerecesiAraligi: null, // YENİ
      renk: null,
      // Boş düğümler için de null
      fatherHalkaNo: null,
      motherHalkaNo: null,
    );
  }
}
