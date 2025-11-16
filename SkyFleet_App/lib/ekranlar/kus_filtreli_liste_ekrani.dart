// lib/ekranlar/kus_filtreli_liste_ekrani.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/kus_provider.dart';
import '../modeller/kus.dart';

// İstatistik ekranından hangi filtre tipinin gönderileceğini tanımlayan Enum
enum FiltreTipi {
  toplam,
  aktif,
  pasif,
  erkek,
  disi,
  yavru,
  yarisKuslari,
  oldu
}

class KusFiltreliListeEkrani extends StatelessWidget {
  final FiltreTipi filtreTipi;
  final String baslik;

  const KusFiltreliListeEkrani({
    super.key,
    required this.filtreTipi,
    required this.baslik,
  });

  // Filtreleme işlemini yapan merkezi fonksiyon
  List<Kus> _filtreleKuslari(List<Kus> tumKuslar, FiltreTipi filtre) {
    switch (filtre) {
      case FiltreTipi.toplam:
        return tumKuslar; // Tüm kuşları döndür
      case FiltreTipi.aktif:
        return tumKuslar.where((k) => k.kusDurumu == 'Aktif').toList();
      case FiltreTipi.pasif:
        return tumKuslar.where((k) => k.kusDurumu == 'Pasif').toList();
      case FiltreTipi.oldu:
        return tumKuslar.where((k) => k.kusDurumu == 'Öldü').toList();
      case FiltreTipi.erkek:
        return tumKuslar.where((k) => k.cinsiyet == 'Erkek').toList();
      case FiltreTipi.disi:
        return tumKuslar.where((k) => k.cinsiyet == 'Dişi').toList();
      case FiltreTipi.yavru:
        // Yavru mantığı: Doğum tarihi 6 aydan küçük olanlar (KusProvider'daki yavrular mantığı ile uyumlu)
        final altSinir = DateTime.now().subtract(const Duration(days: 30 * 6));
        return tumKuslar.where((k) => k.dogumTarihi.isAfter(altSinir)).toList();
      case FiltreTipi.yarisKuslari:
        // Yarış kaydı olan kuşları (YarisProvider'a gerek kalmadan)
        // Varsayım: Kuşun 'yarışmış' durumu bir şekilde modelde işaretleniyor
        // Eğer böyle bir alan yoksa, şimdilik 'Aktif' kuşları döndürelim ve bu kısmı daha sonra YarışProvider ile bağlayalım.
        // Kuş modelinde 'yarismisMi' alanı olsaydı: return tumKuslar.where((k) => k.yarismisMi == true).toList();
        return tumKuslar.where((k) => k.kusDurumu == 'Aktif').toList(); 
    }
  }

  @override
  Widget build(BuildContext context) {
    final kusProvider = Provider.of<KusProvider>(context);
    final filtrelenmisKuslar = _filtreleKuslari(kusProvider.tumKuslar, filtreTipi);

    return Scaffold(
      appBar: AppBar(
        title: Text(baslik),
      ),
      body: filtrelenmisKuslar.isEmpty
          ? Center(
              child: Text('$baslik kategorisinde kayıtlı kuş bulunmamaktadır.'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: filtrelenmisKuslar.length,
              itemBuilder: (context, index) {
                final kus = filtrelenmisKuslar[index];
                // Burada KusDetayEkrani'na yönlendirme veya basit bir kart gösterilebilir.
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: kus.cinsiyet == 'Erkek' ? Colors.blue.shade100 : Colors.pink.shade100,
                      child: Icon(
                        kus.cinsiyet == 'Erkek' ? Icons.male : Icons.female,
                        color: kus.cinsiyet == 'Erkek' ? Colors.blue : Colors.pink,
                      ),
                    ),
                    title: Text(kus.isimHalkaNo, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Cinsiyet: ${kus.cinsiyet ?? 'Belirsiz'} | Durum: ${kus.kusDurumu ?? 'N/A'}'),
                    // Kuş detay ekranına gitme işlevi eklenebilir.
                    onTap: () {
                       // TODO: KusDetayEkrani'na navigasyon eklenecek
                    },
                  ),
                );
              },
            ),
    );
  }
}