import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:collection/collection.dart';
// rootBundle import'u kullanılıyor
import 'package:flutter/services.dart' show rootBundle; 


import '../modeller/kus.dart';
import '../modeller/kullanici.dart';
import 'kus_provider.dart';
import 'kullanici_provider.dart';
import 'yaris_provider.dart';

import '../modeller/pedigree_node.dart';

// Maximum gösterilecek kuşak sayısı (0, 1, 2, 3 -> Toplam 4 kuşak)
const int MAX_PEDIGREE_LEVEL = 3; 

// HATA GİDERİMİ İÇİN YENİDEN OPTİMİZE EDİLMİŞ KUTU YÜKSEKLİKLERİ
// (Dikey A4'e sığan en büyük boyutlar)
const Map<int, double> LEVEL_HEIGHTS = {
  0: 240.0, // Kök kuş
  1: 180.0, // Ebeveynler 
  2: 100.0, // Büyükanne/büyükbabalar 
  3: 75.0,  // Son kuşak 
};

// Her bir kuşak için kutu içeriği font büyüklükleri
const Map<int, double> LEVEL_FONT_SIZES = {
  0: 10.0, 
  1: 9.0, 
  2: 8.0,
  3: 7.0, 
};


class PedigreeProvider with ChangeNotifier {
  List<PedigreeNode> _pedigreeListesi = [];
  bool _veriYukleniyor = false;

  KusProvider? _kusProvider;
  KullaniciProvider? _kullaniciProvider;
  YarisProvider? _yarisProvider;

  List<PedigreeNode> get pedigreeListesi => _pedigreeListesi;
  bool get veriYukleniyor => _veriYukleniyor;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  PedigreeProvider({KusProvider? kusProvider, KullaniciProvider? kullaniciProvider, YarisProvider? yarisProvider}) {
    _kusProvider = kusProvider;
    _kullaniciProvider = kullaniciProvider;
    _yarisProvider = yarisProvider;
    debugPrint("PedigreeProvider: Constructor çağrıldı ve bağımlılıklar ayarlandı.");
  }

  void updateKusProvider(KusProvider kusProvider) {
    _kusProvider = kusProvider;
    debugPrint("PedigreeProvider: KusProvider bağımlılığı güncellendi.");
  }

  void updateKullaniciProvider(KullaniciProvider kullaniciProvider) {
    _kullaniciProvider = kullaniciProvider;
    debugPrint("PedigreeProvider: KullaniciProvider bağımlılığı güncellendi.");
  }

  void updateYarisProvider(YarisProvider yarisProvider) {
    _yarisProvider = yarisProvider;
    debugPrint("PedigreeProvider: YarisProvider bağımlılığı güncellendi.");
  }

  Future<void> pedigreeOlustur(String halkaNo) async {
    debugPrint("PedigreeProvider: pedigreeOlustur çağrıldı, halkaNo: $halkaNo");
    if (_kusProvider == null || _kullaniciProvider == null || _yarisProvider == null) {
      debugPrint("PedigreeProvider: HATA: pedigreeOlustur için bağımlılıklar tam olarak ayarlanmadı.");
      _pedigreeListesi = [];
      _veriYukleniyor = false;
      notifyListeners();
      return;
    }

    _pedigreeListesi = [];
    _veriYukleniyor = true;
    notifyListeners();
    debugPrint("PedigreeProvider: pedigreeOlustur - _veriYukleniyor true olarak ayarlandı.");

    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint("PedigreeProvider: HATA: pedigreeOlustur için kullanıcı oturumu açık değil.");
        throw Exception("Pedigri çekmek için kullanıcı oturum açmış olmalı.");
      }
      final userId = currentUser.uid;
      debugPrint("PedigreeProvider: pedigreeOlustur - Kullanıcı UID: $userId");

      debugPrint("PedigreeProvider: pedigreeOlustur - Kök kuş verisi çekiliyor: $halkaNo");
      final BirdDisplayData? rootBirdData = await _fetchBirdOrPassiveParent(halkaNo, userId);

      if (rootBirdData == null) {
        _pedigreeListesi.add(PedigreeNode.bosNode(0));
        debugPrint("PedigreeProvider: pedigreeOlustur - Kök kuş bulunamadı: $halkaNo. Boş düğüm eklendi.");
      } else {
        debugPrint("PedigreeProvider: pedigreeOlustur - Düz pedigri listesi yeniden oluşturuluyor.");
        await _rebuildFlatPedigreeList(rootBirdData, 0, userId);
        debugPrint("PedigreeProvider: pedigreeOlustur - Düz pedigri listesi oluşturuldu. Toplam düğüm: ${_pedigreeListesi.length}");
      }

    } catch (e) {
      debugPrint("PedigreeProvider: HATA: pedigreeOlustur sırasında hata oluştu: $e");
      _pedigreeListesi = [PedigreeNode.bosNode(0)];
    } finally {
      _veriYukleniyor = false;
      notifyListeners();
      debugPrint("PedigreeProvider: pedigreeOlustur tamamlandı. _veriYukleniyor false olarak ayarlandı.");
    }
  }

  Future<BirdDisplayData?> _fetchBirdOrPassiveParent(String id, String userId) async {
    Kus? activeBird = _kusProvider!.halkaNoIleKusBul(id);
    String? currentKusOwnerUid;

    if (activeBird != null) {
      currentKusOwnerUid = userId;
    }

    String? yetistiriciAdSoyad;
    if (currentKusOwnerUid != null) {
      final Kullanici? ownerProfile = await _kullaniciProvider!.getKullaniciProfilById(currentKusOwnerUid);
      if (ownerProfile != null) {
        yetistiriciAdSoyad = '${ownerProfile.isim ?? ''} ${ownerProfile.soyisim ?? ''}'.trim();
      }
    }

    String? yarisBilgileriOzet;
    int? yarisDerecesiAraligi;
    if (activeBird != null && _yarisProvider != null) {
      if (_yarisProvider!.kusYaristiMi(activeBird.halkaNo)) {
        yarisBilgileriOzet = _yarisProvider!.getKusunYarisBilgileriOzeti(activeBird.halkaNo);
        final enIyiDerece = _yarisProvider!.getKusunEnIyiYarisDerecesi(activeBird.halkaNo);
        if (enIyiDerece != null) {
          if (enIyiDerece >= 1 && enIyiDerece <= 20) {
            yarisDerecesiAraligi = 1; // Derece 1-20
          } else if (enIyiDerece >= 21) {
            yarisDerecesiAraligi = 2; // Derece 21+
          }
        }
      }
    }

    if (activeBird != null) {
      return BirdDisplayData(
        id: activeBird.halkaNo,
        halkaNumarasi: activeBird.halkaNo,
        isim: activeBird.isim,
        cinsiyet: activeBird.cinsiyet,
        notlar: activeBird.notlar,
        genetikHat: activeBird.genetikHat,
        renk: activeBird.renk,
        dogumTarihi: activeBird.dogumTarihi,
        fatherId: activeBird.babaHalkaNo,
        motherId: activeBird.anneHalkaNo,
        yetistiriciAdSoyad: yetistiriciAdSoyad,
        yarisBilgileri: yarisBilgileriOzet,
        yarisDerecesiAraligi: yarisDerecesiAraligi,
      );
    }

    try {
      final DocumentSnapshot passiveDoc = await _firestore.collection('PasifEbeveynler').doc(id).get();
      if (passiveDoc.exists) {
        final data = passiveDoc.data() as Map<String, dynamic>;
        return BirdDisplayData(
          id: passiveDoc.id,
          halkaNumarasi: data['halkaNumarasi'] ?? passiveDoc.id,
          cinsiyet: data['cinsiyet'],
          notlar: data['notlar'],
          fatherId: data['fatherId'],
          motherId: data['motherId'],
          renk: data['renk'],
          yetistiriciAdSoyad: null,
          yarisBilgileri: null,
          yarisDerecesiAraligi: null,
        );
      }
    } catch (e) {
      debugPrint("PedigreeProvider: HATA: Pasif ebeveyn çekilirken hata ($id): $e");
    }

    return null;
  }

  Future<void> _rebuildFlatPedigreeList(BirdDisplayData? birdData, int currentLevel, String userId) async {
    if (currentLevel > MAX_PEDIGREE_LEVEL) return;

    if (birdData == null) {
      _pedigreeListesi.add(PedigreeNode.bosNode(currentLevel));
      // Sadece 3. seviyeye kadar rekürsif olarak devam et
      if (currentLevel < MAX_PEDIGREE_LEVEL) {
        await _rebuildFlatPedigreeList(null, currentLevel + 1, userId);
        await _rebuildFlatPedigreeList(null, currentLevel + 1, userId);
      }
      return;
    }

    _pedigreeListesi.add(_birdDisplayDataToPedigreeNode(birdData, currentLevel));

    final BirdDisplayData? fatherBird = birdData.fatherId != null
        ? await _fetchBirdOrPassiveParent(birdData.fatherId!, userId)
        : null;
    await _rebuildFlatPedigreeList(fatherBird, currentLevel + 1, userId);

    final BirdDisplayData? motherBird = birdData.motherId != null
        ? await _fetchBirdOrPassiveParent(birdData.motherId!, userId)
        : null;
    await _rebuildFlatPedigreeList(motherBird, currentLevel + 1, userId);
  }

  PedigreeNode _birdDisplayDataToPedigreeNode(BirdDisplayData birdData, int level) {
    return PedigreeNode(
      halkaNo: birdData.halkaNumarasi,
      isim: birdData.isim ?? birdData.halkaNumarasi,
      cinsiyet: birdData.cinsiyet,
      notlar: birdData.notlar,
      level: level,
      yetistiriciAdSoyad: birdData.yetistiriciAdSoyad,
      yarisBilgileri: birdData.yarisBilgileri,
      yarisDerecesiAraligi: birdData.yarisDerecesiAraligi,
      renk: birdData.renk,
      fatherHalkaNo: birdData.fatherId,
      motherHalkaNo: birdData.motherId,
    );
  }

  // Yardımcı Metot: Tek bir kuşun PDF kutusunun içeriğini oluşturur
  pw.Widget _buildBirdInfoContent(PedigreeNode node, {required pw.Font baseFont}) {
    // Kuşağın seviyesine göre font büyüklüğünü al
    final double fontSize = LEVEL_FONT_SIZES[node.level] ?? 8.0;

    // Cinsiyete göre ikon ve renk
    String cinsiyetIcon = '';
    PdfColor textColor;
    if (node.cinsiyet == 'Erkek') {
      cinsiyetIcon = '♂'; // Erkek İkonu
      textColor = PdfColors.blue;
    } else if (node.cinsiyet == 'Dişi') {
      cinsiyetIcon = '♀'; // Dişi İkonu
      textColor = PdfColors.pink;
    } else {
      cinsiyetIcon = ''; // Bilinmiyor veya boş ise ikon yok
      textColor = PdfColors.black;
    }

    // İçerik sol ve üste yaslı kalmaya devam ediyor
    return pw.Column(
        mainAxisSize: pw.MainAxisSize.min, // İçeriği kadar yer kapla
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Halka No ve İsim
          pw.Row(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Text(
                '${node.halkaNo}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: fontSize, color: textColor, font: baseFont),
                maxLines: 1,
              ),
              if (node.isim != null && node.isim!.isNotEmpty)
                pw.Text(' - ${node.isim}', style: pw.TextStyle(fontSize: fontSize, color: textColor, font: baseFont), maxLines: 1),
              if (cinsiyetIcon.isNotEmpty)
                pw.Text(' $cinsiyetIcon', style: pw.TextStyle(fontSize: fontSize, color: textColor, font: baseFont)), // Cinsiyet ikonu
            ],
          ),
          // Yetiştirici
          if (node.yetistiriciAdSoyad != null && node.yetistiriciAdSoyad!.isNotEmpty)
            pw.Text(
              '${node.yetistiriciAdSoyad}',
              style: pw.TextStyle(fontSize: fontSize * 0.8, font: baseFont), // Biraz daha küçük font
              maxLines: 1,
            ),
          // Yarış Bilgisi
          if (node.yarisBilgileri != null && node.yarisBilgileri!.isNotEmpty)
            pw.Text(
              '${node.yarisBilgileri}',
              style: pw.TextStyle(fontSize: fontSize * 0.8, color: PdfColors.brown, font: baseFont), 
              maxLines: 1,
            ),
          // Notlar
          if (node.notlar != null && node.notlar!.isNotEmpty)
            pw.Text(
              '${node.notlar}',
              style: pw.TextStyle(fontSize: fontSize * 0.7, fontStyle: pw.FontStyle.italic, font: baseFont), // Daha da küçük font
              maxLines: 1,
            ),
        ],
      );
  }


  // Yardımcı Metot: Recursive olarak pedigri ağacını çizim için oluşturur
  // Yüksekliği LEVEL_HEIGHTS map'inden sabit olarak çeker.
  pw.Widget _buildPdfPedigreeTree(
    PedigreeNode? node, 
    Map<String, PedigreeNode> pedigreeMap, 
    int level,
    pw.Font baseFont, 
  ) {
    // 4 Kuşak (0, 1, 2, 3) gösterilecek.
    if (level > MAX_PEDIGREE_LEVEL) { 
      return pw.SizedBox.shrink();
    }

    // Mevcut seviyenin sabit yüksekliğini al
    final double currentHeight = LEVEL_HEIGHTS[level] ?? 240.0;
    
    // Alt seviyenin sabit yüksekliğini al 
    final double nextLevelHeight = LEVEL_HEIGHTS[level + 1] ?? 75.0; 

    // Eğer düğüm boşsa veya bulunamadıysa, boş bir kutu göster
    if (node == null || node.isBos) {
      // Boş kutular için de genişlik Level 1-3 genişliği olan 130.0 pt olarak bırakıldı
      return pw.Container(
        height: currentHeight, // Sabit yüksekliği kullan
        width: 130.0, 
        padding: pw.EdgeInsets.all(4), 
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300, width: 0.2), 
          borderRadius: pw.BorderRadius.circular(2),
          color: PdfColors.grey100, 
        ),
        child: pw.Align( // İçeriği sola ve üste yasla
          alignment: pw.Alignment.topLeft,
          child: pw.Padding(
            padding: pw.EdgeInsets.all(4),
            child: pw.Text(
              'Bilinmiyor',
              style: pw.TextStyle(fontStyle: pw.FontStyle.italic, color: PdfColors.grey600, fontSize: LEVEL_FONT_SIZES[level] ?? 8.0, font: baseFont),
            ),
          ),
        ),
      );
    }

    final PedigreeNode? fatherNode = node.fatherHalkaNo != null ? pedigreeMap[node.fatherHalkaNo!] : null;
    final PedigreeNode? motherNode = node.motherHalkaNo != null ? pedigreeMap[node.motherHalkaNo!] : null;

    // Rekürsif çağrılar: Alt seviye için level + 1 gönder
    pw.Widget fatherSubtree = _buildPdfPedigreeTree(fatherNode, pedigreeMap, level + 1, baseFont);
    pw.Widget motherSubtree = _buildPdfPedigreeTree(motherNode, pedigreeMap, level + 1, baseFont);

    // Kutu genişlikleri (Önceki büyük değerler korundu)
    double boxWidth = (level == 0) ? 150.0 : 130.0; 
    
    // Kuşun arka plan rengi
    PdfColor boxColor = PdfColors.white; 
    if (node.yarisDerecesiAraligi != null) {
      if (node.yarisDerecesiAraligi == 1) { // Derece 1-20
        boxColor = PdfColor.fromHex('FF6347'); // Kırmızımsı ton
      } else if (node.yarisDerecesiAraligi == 2) { // Derece 21+
        boxColor = PdfColor.fromHex('FFDEAD'); // Açık sarımsı ton
      }
    }

    // Mevcut kuşun kutusu
    pw.Widget currentBirdBox = pw.Container(
      height: currentHeight, // Sabit yüksekliği kullan
      width: boxWidth,
      padding: pw.EdgeInsets.all(4),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey500, width: 0.5),
        borderRadius: pw.BorderRadius.circular(4),
        color: boxColor,
      ),
      // İçeriği sola ve üste yasla
      child: pw.Align( 
        alignment: pw.Alignment.topLeft,
        child: _buildBirdInfoContent(node, baseFont: baseFont), 
      ),
    );

    // Eğer en sağdaki kuşaksa (Level 3), sadece kutuyu döndür.
    if (level == MAX_PEDIGREE_LEVEL) { 
      return currentBirdBox;
    }

    // Bağlantı Çizgisi Yüksekliği (Çizginin dikey uzunluğu, alt seviye kutusunun yarısı olmalı)
    final double verticalLineLength = nextLevelHeight / 2;

    // Ebeveynler varsa, çizgilerle bağlayarak yerleştir
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center, // Dikeyde ortala
      children: [
        currentBirdBox,
        // Düğümden ebeveynlere giden yatay çizgi
        pw.Container(
          width: 10, 
          height: 1, 
          color: PdfColors.black,
        ),
        // Ebeveynleri içeren Dikey Blok
        pw.Column(
          children: [
            // Baba kolu (üst)
            pw.Row(
              children: [
                pw.Container(
                  width: 1, // Dikey çizgi (üst yarısı)
                  height: verticalLineLength, 
                  color: PdfColors.black,
                ),
                pw.SizedBox(width: 5), // Çizgi ile kutu arası boşluk
                fatherSubtree,
              ],
            ),
            // Anne kolu (alt)
            pw.Row(
              children: [
                pw.Container(
                  width: 1, // Dikey çizgi (alt yarısı)
                  height: verticalLineLength, 
                  color: PdfColors.black,
                ),
                pw.SizedBox(width: 5), 
                motherSubtree,
              ],
            ),
          ],
        ),
      ],
    );
  }

  // Yardımcı Metot: PDF Altbilgisini oluşturur (Sabit Footer)
  pw.Widget _buildPdfFooter(Kullanici? currentUserProfile, pw.Font baseFont) {
    return pw.Container(
      height: 40, 
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, 
        crossAxisAlignment: pw.CrossAxisAlignment.end, 
        children: [
          // Sol Alan: Kullanıcı Bilgileri (Kaşe)
          pw.Column(
            mainAxisSize: pw.MainAxisSize.min, 
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (currentUserProfile != null) ...[
                pw.Text(
                  '${currentUserProfile.isim ?? ''} ${currentUserProfile.soyisim ?? ''}'.trim(),
                  style: pw.TextStyle(fontSize: 8, font: baseFont, fontWeight: pw.FontWeight.bold),
                ),
                if (currentUserProfile.telefonNumarasi != null && currentUserProfile.telefonNumarasi!.isNotEmpty)
                  pw.Text('Tel: ${currentUserProfile.telefonNumarasi}', style: pw.TextStyle(fontSize: 7, font: baseFont)),
                if (currentUserProfile.email != null && currentUserProfile.email!.isNotEmpty)
                  pw.Text('E-posta: ${currentUserProfile.email}', style: pw.TextStyle(fontSize: 7, font: baseFont)),
                if (currentUserProfile.adres != null && currentUserProfile.adres!.isNotEmpty)
                  pw.Text(
                    'Adres: ${currentUserProfile.adres!['il'] ?? ''}, ${currentUserProfile.adres!['ulke'] ?? ''}',
                    style: pw.TextStyle(fontSize: 7, font: baseFont),
                  ),
              ] else
                pw.Text('SkyFleet Kullanıcısı Bilgileri Yok', style: pw.TextStyle(fontSize: 8, font: baseFont)),
            ],
          ),

          // Sağ Alan: Uygulama Adı
          pw.Text(
            'SkyFleet Pigeons',
            style: pw.TextStyle(fontSize: 6, font: baseFont),
          ),
        ],
      ),
    );
  }


  Future<void> generateAndSharePedigreePdf(BuildContext context, String rootHalkaNo) async {
    debugPrint("PedigreeProvider: generateAndSharePedigreePdf çağrıldı, halkaNo: $rootHalkaNo");
    if (_pedigreeListesi.isEmpty) { 
      debugPrint("PedigreeProvider: generateAndSharePedigreePdf - _pedigreeListesi boş.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pedigri verileri henüz hazır değil. Lütfen bekleyin veya tekrar deneyin.')),
      );
      return;
    }

    _veriYukleniyor = true;
    notifyListeners();
    debugPrint("PedigreeProvider: generateAndSharePedigreePdf - _veriYukleniyor true olarak ayarlandı.");

    final pdf = pw.Document();

    final Map<String, PedigreeNode> pedigreeMap = {
      for (var node in _pedigreeListesi) node.halkaNo: node
    };

    final PedigreeNode? rootNode = _pedigreeListesi.firstWhereOrNull((node) => node.level == 0);

    if (rootNode == null) {
      debugPrint("PedigreeProvider: HATA: generateAndSharePedigreePdf - Kök kuş pedigri listesinde bulunamadı.");
      _veriYukleniyor = false;
      notifyListeners();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hata: Kök kuş bulunamadı.')),
      );
      return;
    }

    try {
      // TÜRKÇE KARAKTER DESTEKLİ TIMES FONTUNU YÜKLEME
      // NOT: "assets/fonts/times.ttf" dosyasının projenize eklendiğinden emin olun.
      final fontData = await rootBundle.load("assets/fonts/times.ttf"); 
      final pw.Font baseFont = pw.Font.ttf(fontData);

      final Kullanici? currentUserProfile = _kullaniciProvider?.kullaniciProfil;
      
      // DİKEY (PORTRAIT) FORMAT KULLANILIYOR
      final PdfPageFormat portraitFormat = PdfPageFormat.a4.portrait;

      const double generalMargin = 20.0; // Sayfa kenar marjini
      const double footerHeight = 40.0; 
      const double footerPadding = 5.0; 

      // Alt Marjin: Altbilgi Yüksekliği + Marjin + Padding (Altbilgiye yer açar)
      const double bottomMarginForFooter = generalMargin + footerHeight + footerPadding; 
      
      
      // Ağaç çizimi için rekürsif metodu çağırırken SADECE level=0'ı gönderiyoruz.
      pw.Widget pedigreeTreeWidget = _buildPdfPedigreeTree(
        rootNode, 
        pedigreeMap, 
        0, // Başlangıç level'ı 0
        baseFont
      );

      pdf.addPage(
        pw.MultiPage(
          pageFormat: portraitFormat, // DİKEY format
          // Sayfa marjinleri. Alt marjini footer'ı içerecek şekilde ayarladık.
          margin: pw.EdgeInsets.fromLTRB(generalMargin, generalMargin, generalMargin, bottomMarginForFooter), 
          
          footer: (pw.Context context) {
            return pw.Padding( 
              padding: pw.EdgeInsets.only(bottom: 0),
              child: _buildPdfFooter(currentUserProfile, baseFont),
            );
          },

          build: (pw.Context context) {
            return [
              // Ana içerik: Pedigri Ağacı (Dikeyde ve yatayda ortalanmış)
              pw.Center(
                child: pedigreeTreeWidget, 
              ),
            ];
          },
        ),
      );
      debugPrint("PedigreeProvider: generateAndSharePedigreePdf - PDF sayfası eklendi.");

      debugPrint("PedigreeProvider: generateAndSharePedigreePdf - PDF kaydediliyor.");
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/pedigri_agaci_$rootHalkaNo.pdf');
      await file.writeAsBytes(await pdf.save());
      debugPrint("PedigreeProvider: generateAndSharePedigreePdf - PDF kaydedildi: ${file.path}");

      await Printing.sharePdf(bytes: await pdf.save(), filename: 'pedigri_agaci_$rootHalkaNo.pdf');

    } catch (e) {
      debugPrint("PedigreeProvider: HATA: generateAndSharePedigreePdf sırasında font yükleme veya PDF oluşturma hatası oluştu: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF oluşturulurken bir hata oluştu. Font dosyasının (times.ttf) assets/fonts klasöründe ve pubspec.yaml dosyasında tanımlı olduğundan emin olun: ${e.toString()}')),
      );
    } finally {
      _veriYukleniyor = false;
      notifyListeners();
      debugPrint("PedigreeProvider: generateAndSharePedigreePdf tamamlandı. _veriYukleniyor false olarak ayarlandı.");
    }
  }
}

// BirdDisplayData sınıfı
class BirdDisplayData {
  final String id;
  final String halkaNumarasi;
  final String? isim;
  final String? cinsiyet;
  final String? notlar;
  final String? genetikHat;
  final String? renk;
  final DateTime? dogumTarihi;
  final String? fatherId;
  final String? motherId;
  
  final String? yetistiriciAdSoyad;
  final String? yarisBilgileri;
  final int? yarisDerecesiAraligi;

  BirdDisplayData({
    required this.id,
    required this.halkaNumarasi,
    this.isim,
    this.cinsiyet,
    this.notlar,
    this.genetikHat,
    this.renk,
    this.dogumTarihi,
    this.fatherId,
    this.motherId,
    this.yetistiriciAdSoyad,
    this.yarisBilgileri,
    this.yarisDerecesiAraligi,
  });
}