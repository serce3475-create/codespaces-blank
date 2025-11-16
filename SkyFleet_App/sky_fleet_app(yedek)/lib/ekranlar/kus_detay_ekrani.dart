// lib/ekranlar/kus_detay_ekrani.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart'; // firstWhereOrNull için

import '../providers/kus_provider.dart';
import '../providers/eslesme_provider.dart';
import '../providers/yaris_provider.dart';
import '../providers/pedigree_provider.dart';
import '../modeller/kus.dart';
import '../modeller/eslesme.dart';
import '../modeller/pedigree_node.dart';

import 'eslesme_ekle_ekrani.dart';
import 'yaris_ekle_ekrani.dart';
import 'kus_ekle_guncelle_ekrani.dart';
import 'eslesme_detay_ekrani.dart';
import 'yaris_detay_ekrani.dart';

class KusDetayEkrani extends StatefulWidget {
  final Kus kus;

  const KusDetayEkrani({Key? key, required this.kus}) : super(key: key);

  @override
  _KusDetayEkraniState createState() => _KusDetayEkraniState();
}

class _KusDetayEkraniState extends State<KusDetayEkrani> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Durum renkleri için yardımcı haritalar
  final Map<String, Color> _durumArkaPlanRenkleri = {
    'Aktif': Colors.green.shade100,
    'Pasif': Colors.orange.shade100,
    'Satıldı': Colors.blue.shade100,
    'Kayıp': Colors.purple.shade100,
    'Ölen': Colors.red.shade100,
  };

  final Map<String, Color> _durumMetinRenkleri = {
    'Aktif': Colors.green.shade800,
    'Pasif': Colors.orange.shade800,
    'Satıldı': Colors.blue.shade800,
    'Kayıp': Colors.purple.shade800,
    'Ölen': Colors.red.shade800,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _kusSilOnay() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Silme Onayı'),
        content: Text('${widget.kus.halkaNo} halka numaralı kuşu tamamen silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.'),
        actions: <Widget>[
          TextButton(
            child: const Text('İptal'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          ),
          TextButton(
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
            onPressed: () {
              Navigator.of(ctx).pop();
              if (widget.kus.kusId != null) {
                Provider.of<KusProvider>(context, listen: false)
                    .kusTamamenSil(widget.kus.kusId!)
                    .then((_) {
                      Navigator.of(context).pop(); // Kuş silindikten sonra bir önceki ekrana dön
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Kuş başarıyla silindi!')),
                      );
                    }).catchError((error) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Silme hatası: $error')),
                      );
                    });
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Hata: Kuş ID bulunamadı.')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDurumGuncelleme(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (String yeniDurum) {
        if (widget.kus.kusId != null) {
          Provider.of<KusProvider>(context, listen: false)
              .kusDurumuGuncelle(widget.kus.kusId!, yeniDurum)
              .then((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Durum "$yeniDurum" olarak güncellendi.')),
                );
              }).catchError((error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Durum güncelleme hatası: $error')),
                );
              });
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        // Kuşun alabileceği tüm durum seçeneklerini burada sunuyoruz
        const PopupMenuItem<String>(
          value: 'Aktif',
          child: Text('Aktif Yap'),
        ),
        const PopupMenuItem<String>(
          value: 'Pasif',
          child: Text('Pasif Yap'),
        ),
        const PopupMenuItem<String>(
          value: 'Satıldı',
          child: Text('Satıldı Olarak İşaretle'),
        ),
        const PopupMenuItem<String>(
          value: 'Kayıp',
          child: Text('Kayıp Olarak İşaretle'),
        ),
        const PopupMenuItem<String>(
          value: 'Ölen',
          child: Text('Ölen Olarak İşaretle'),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          // Duruma göre arka plan rengi
          color: _durumArkaPlanRenkleri[widget.kus.kusDurumu] ?? Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.kus.kusDurumu ?? 'Belirtilmemiş',
              style: TextStyle(
                // Duruma göre metin rengi
                color: _durumMetinRenkleri[widget.kus.kusDurumu] ?? Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.black54, size: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // KusProvider'dan güncel kuş detaylarını çekiyoruz
    // Bu sayede, Kuş Ekle/Güncelle ekranında yapılan değişiklikler buraya yansır.
    final guncelKus = Provider.of<KusProvider>(context).kusIdIleKusBul(widget.kus.kusId!); // kusId null olamaz, güvende çağırdık
    final kusDetayi = guncelKus ?? widget.kus;

    return Scaffold(
      appBar: AppBar(
        title: Text(kusDetayi.halkaNo),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => KusEkleGuncelleEkrani(kus: kusDetayi),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.red),
            onPressed: _kusSilOnay,
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          kusDetayi.isim ?? 'İsimsiz Kuş',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        if (kusDetayi.kusId != null) // KusId varsa durumu göster
                          _buildDurumGuncelleme(context),
                      ],
                    ),
                    const Divider(height: 15),
                    _buildDetaySatir('Cinsiyet', kusDetayi.cinsiyet ?? 'Belirtilmemiş'),
                    _buildDetaySatir('Doğum Tarihi',
                      kusDetayi.dogumTarihi != null
                        ? DateFormat('dd/MM/yyyy').format(kusDetayi.dogumTarihi!)
                        : 'Belirtilmemiş'
                    ),
                    if (kusDetayi.notlar != null && kusDetayi.notlar!.isNotEmpty)
                      _buildDetaySatir('Notlar', kusDetayi.notlar!),
                  ],
                ),
              ),
            ),
          ),

          TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: 'Pedigri', icon: Icon(Icons.family_restroom)),
              Tab(text: 'Eşleşmeler', icon: Icon(Icons.favorite_border)),
              Tab(text: 'Yarışlar', icon: Icon(Icons.military_tech_outlined)),
            ],
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPedigreeTab(context, kusDetayi),
                _buildEslesmeTab(context, kusDetayi),
                _buildYarisTab(context, kusDetayi.halkaNo),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetaySatir(String baslik, String icerik) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text('$baslik:', style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(child: Text(icerik)),
        ],
      ),
    );
  }

  Widget _buildEslesmeTab(BuildContext context, Kus kusDetayi) {
    return Consumer<EslesmeProvider>(
      builder: (context, eslesmeProvider, child) {
        final eslesmeler = eslesmeProvider.tumEslesmeler
       .where((e) => e.erkekHalkaNo == kusDetayi.halkaNo || e.disiHalkaNo == kusDetayi.halkaNo)
       .toList();

        return Stack(
          children: [
            if (eslesmeler.isEmpty)
              const Center(
                child: Text('Henüz eşleşme kaydı yok.', style: TextStyle(color: Colors.grey)),
              )
            else
              ListView.builder(
                padding: const EdgeInsets.only(bottom: 80.0),
                itemCount: eslesmeler.length,
                itemBuilder: (ctx, i) {
                  final eslesme = eslesmeler[i];
                  final partnerHalkaNo = (kusDetayi.cinsiyet == 'Erkek' && eslesme.disiHalkaNo != null)
                      ? eslesme.disiHalkaNo
                      : ((kusDetayi.cinsiyet == 'Dişi' && eslesme.erkekHalkaNo != null)
                          ? eslesme.erkekHalkaNo
                          : 'Bilinmiyor');

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: ListTile(
                      leading: const Icon(Icons.favorite, color: Colors.red),
                      title: Text('Partner: $partnerHalkaNo'),
                      subtitle: Text(
                          'Başlangıç: ${DateFormat('dd/MM/yyyy').format(eslesme.eslesmeTarihi)}'
                          '${eslesme.durumu != EslesmeDurumu.aktif ? ' - Durum: ${eslesme.durumu.toString().split('.').last}' : ''}'
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (ctx) => EslesmeDetayEkrani(eslesme: eslesme),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),

            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton.extended(
                heroTag: 'addEslesme',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (ctx) => EslesmeEklemeEkrani(
                        erkekHalkaNo: kusDetayi.cinsiyet == 'Erkek' ? kusDetayi.halkaNo : null,
                        disiHalkaNo: kusDetayi.cinsiyet == 'Dişi' ? kusDetayi.halkaNo : null,
                      ),
                    ),
                  ).then((_) {
                  });
                },
                label: const Text('Eşleşme Ekle'),
                icon: const Icon(Icons.add_circle),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildYarisTab(BuildContext context, String halkaNo) {
    return Consumer<YarisProvider>(
      builder: (context, yarisProvider, child) {
        final yarislar = yarisProvider.kusunYarisKayitlari(halkaNo);

        return Stack(
          children: [
            if (yarislar.isEmpty)
              const Center(
                child: Text('Henüz yarış kaydı yok.', style: TextStyle(color: Colors.grey)),
              )
            else
              ListView.builder(
                padding: const EdgeInsets.only(bottom: 80.0),
                itemCount: yarislar.length,
                itemBuilder: (ctx, i) {
                  final yaris = yarislar[i];
                  final yarisTarihi = DateFormat('dd/MM/yyyy').format(yaris.yarisTarihi);

                  final ucusSuresiText = yaris.ucusSuresi.inHours > 0
                      ? '${yaris.ucusSuresi.inHours}s ${yaris.ucusSuresi.inMinutes.remainder(60)}dk'
                      : '${yaris.ucusSuresi.inMinutes}dk';

                  Color dereceRengi = Colors.blueGrey;
                  if (yaris.derece > 0 && yaris.derece < 4) {
                    dereceRengi = Colors.green.shade700;
                  } else if (yaris.derece == 0) {
                    dereceRengi = Colors.red.shade700;
                  }

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: ListTile(
                      leading: Icon(Icons.emoji_events, color: dereceRengi),
                      title: Text('${yaris.yarisAdi} - ${yaris.baslangicYeri} > ${yaris.varisYeri}'),
                      subtitle: Text('$yarisTarihi | Mesafe: ${yaris.mesafeKm.toStringAsFixed(1)} km | Süre: $ucusSuresiText'),
                      trailing: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: dereceRengi.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          yaris.derece > 0 ? '${yaris.derece}. Sıra' : 'Derece Yok',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: dereceRengi,
                          ),
                        ),
                      ),
                      onTap: () {
                         Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (ctx) => YarisDetayEkrani(yaris: yaris),
                           ),
                         );
                      },
                    ),
                  );
                },
              ),

            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton.extended(
                heroTag: 'addYaris',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (ctx) => YarisEkleEkrani(kusHalkaNo: widget.kus.halkaNo),
                    ),
                  );
                },
                label: const Text('Yarış Ekle'),
                icon: const Icon(Icons.add_circle),
              ),
            ),
          ],
        );
      },
    );
  }

  // Pedigri Tab içeriği
  Widget _buildPedigreeTab(BuildContext context, Kus kusDetayi) {
    final pedigreeProvider = Provider.of<PedigreeProvider>(context);

    // Kuş Detay Ekranı'ndaki pedigri sekmesine her girildiğinde,
    // pedigri verisinin otomatik olarak yüklenmesini tetikliyoruz.
    // Bu, hem UI'da özet gösterimi hem de PDF oluşturma için verinin hazır olmasını sağlar.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!pedigreeProvider.veriYukleniyor &&
          (pedigreeProvider.pedigreeListesi.isEmpty ||
              (pedigreeProvider.pedigreeListesi.isNotEmpty && pedigreeProvider.pedigreeListesi.first.halkaNo != kusDetayi.halkaNo))) {
        pedigreeProvider.pedigreeOlustur(kusDetayi.halkaNo);
      }
    });

    // UI'da gösterilecek pedigri özetini filtrele
    // Sadece Ana Kuş (level 0) ve Kuşak 2 ebeveynleri (level 1)
    final rootBird = pedigreeProvider.pedigreeListesi.firstWhereOrNull((node) => node.level == 0);
    final fatherBird = pedigreeProvider.pedigreeListesi.firstWhereOrNull((node) => node.level == 1 && node.cinsiyet == 'Erkek');
    final motherBird = pedigreeProvider.pedigreeListesi.firstWhereOrNull((node) => node.level == 1 && node.cinsiyet == 'Dişi');


    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton.icon(
            onPressed: pedigreeProvider.veriYukleniyor
                ? null // Veri yükleniyor veya PDF oluşturuluyorsa butonu devre dışı bırak
                : () async {
                    if (kusDetayi.halkaNo != null) {
                      // Eğer pedigri verisi henüz oluşturulmadıysa (veya değiştiyse), oluştur
                      if (pedigreeProvider.pedigreeListesi.isEmpty ||
                          (pedigreeProvider.pedigreeListesi.isNotEmpty &&
                              pedigreeProvider.pedigreeListesi.first.halkaNo != kusDetayi.halkaNo)) {
                        await pedigreeProvider.pedigreeOlustur(kusDetayi.halkaNo);
                      }
                      // Pedigri verisi hazır olduğunda PDF'i oluştur ve paylaş
                      await pedigreeProvider.generateAndSharePedigreePdf(context, kusDetayi.halkaNo);
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Hata: Ana kuşun halka numarası bulunamadı.')),
                        );
                      }
                    }
                  },
            icon: pedigreeProvider.veriYukleniyor
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.share),
            label: Text(pedigreeProvider.veriYukleniyor ? 'Yükleniyor...' : 'Pedigri PDF Oluştur ve Paylaş'),
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(40)), // Butonu biraz büyüt
          ),
        ),
        
        // Pedigri yüklenirken gösterge
        if (pedigreeProvider.veriYukleniyor)
          const Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 10),
                  Text('Pedigri verileri yükleniyor...', textAlign: TextAlign.center),
                ],
              ),
            ),
          )
        else // Veri yüklendiyse özet bilgileri göster
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pedigri Özeti:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Divider(),
                  // Ana Kuş Bilgisi
                  if (rootBird != null && !rootBird.isBos)
                    _buildPedigreeOzetiSatir('Ana Kuş', rootBird),
                  
                  // Baba (Sire) Bilgisi
                  if (fatherBird != null && !fatherBird.isBos)
                    _buildPedigreeOzetiSatir('Baba (Sire)', fatherBird),
                  
                  // Anne (Dam) Bilgisi
                  if (motherBird != null && !motherBird.isBos)
                    _buildPedigreeOzetiSatir('Anne (Dam)', motherBird),
                  
                  // Hiçbir pedigri bilgisi yoksa
                  if (rootBird == null && fatherBird == null && motherBird == null)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'Bu kuş için pedigri bilgisi bulunamadı veya ebeveyn bilgileri eksik.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),
                  const Text(
                    'Detaylı, 5 kuşaklık pedigri ağacını PDF olarak almak için yukarıdaki butona tıklayınız.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // Pedigri özet satırlarını oluşturmak için yardımcı metot
  Widget _buildPedigreeOzetiSatir(String baslik, PedigreeNode node) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$baslik:',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                'Halka No: ${node.halkaNo}',
                style: const TextStyle(fontSize: 14),
              ),
              if (node.isim != null && node.isim!.isNotEmpty)
                Text(
                  ' - İsim: ${node.isim}',
                  style: const TextStyle(fontSize: 14),
                ),
              if (node.cinsiyet != null && node.cinsiyet!.isNotEmpty)
                Text(
                  ' (${node.cinsiyet == 'Erkek' ? '♂' : '♀'})', // Cinsiyet ikonu
                  style: TextStyle(fontSize: 14, color: node.cinsiyet == 'Erkek' ? Colors.blue : Colors.pink),
                ),
            ],
          ),
          if (node.yetistiriciAdSoyad != null && node.yetistiriciAdSoyad!.isNotEmpty)
            Text(
              'Yetiştirici: ${node.yetistiriciAdSoyad}',
              style: const TextStyle(fontSize: 14),
            ),
          if (node.yarisBilgileri != null && node.yarisBilgileri!.isNotEmpty)
            Text(
              'Yarış: ${node.yarisBilgileri}',
              style: const TextStyle(fontSize: 14),
            ),
          const SizedBox(height: 8), // Satırlar arasına boşluk
        ],
      ),
    );
  }
}
