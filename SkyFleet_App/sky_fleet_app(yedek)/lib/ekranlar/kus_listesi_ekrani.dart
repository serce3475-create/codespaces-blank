// lib/ekranlar/kus_listesi_ekrani.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/kus_provider.dart';
import '../modeller/kus_filtre_tipi.dart';
import 'kus_ekle_guncelle_ekrani.dart';
import 'kus_detay_ekrani.dart';
// import '../modeller/kus.dart'; // Kus modeli zaten dolaylı olarak provider üzerinden kullanılıyor.

class KusListesiEkrani extends StatefulWidget {
  const KusListesiEkrani({super.key});

  @override
  State<KusListesiEkrani> createState() => _KusListesiEkraniState();
}

class _KusListesiEkraniState extends State<KusListesiEkrani> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Arama controller'ı için listener
    _searchController.addListener(_onSearchChanged);
    // Ekran ilk açıldığında, KusProvider'daki aktif filtreyi temizle veya varsayılanı ayarla
    // Bu, AnaSayfa'dan gelindiğinde önceki filtre durumunun kalmaması için iyi bir uygulamadır.
    // Provider.of<KusProvider>(context, listen: false).filtreyiUygula(KusFiltreTipi.tumu);
  }

  void _onSearchChanged() {
    // KusProvider'daki arama sorgusunu günceller
    Provider.of<KusProvider>(context, listen: false)
        .aramaSorgusunuGuncelle(_searchController.text);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const KusEkleGuncelleEkrani(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: Consumer<KusProvider>(
        builder: (context, kusProvider, child) {
          final filtrelenmisVeAranmisKuslar = kusProvider.filtrelenmisVeAranmisKuslar;

          return Column(
            children: [
              // Arama Çubuğu
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Halka No veya İsim ile Ara...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                  ),
                ),
              ),

              // FİLTRE BUTONLARI (Estetik Geliştirme Yapıldı)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: Row(
                  children: KusFiltreTipi.values.map((filtreTipi) {
                    String filtreAdi = filtreTipi.toTurkishString();
                    bool isSelected = kusProvider.aktifFiltre == filtreTipi;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ChoiceChip(
                        label: Text(filtreAdi),
                        selected: isSelected,
                        selectedColor: Theme.of(context).primaryColor,
                        // YENİ: Seçili olmayanlar için daha belirgin kenarlık
                        side: isSelected ? BorderSide.none : BorderSide(color: Colors.grey.shade400, width: 1),
                        // YENİ: Hafif gölgelendirme
                        elevation: isSelected ? 4 : 1,
                        shadowColor: Colors.black54, // Gölgelendirme rengi
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, // Seçili olana bold font
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            kusProvider.filtreyiUygula(filtreTipi);
                          }
                        },
                        // YENİ: Yuvarlatılmış köşeler
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              Expanded(
                child: filtrelenmisVeAranmisKuslar.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            kusProvider.aramaSorgusu.isNotEmpty
                                ? 'Aradığınız kritere uygun kuş bulunmamaktadır.'
                                : (kusProvider.aktifFiltre == KusFiltreTipi.tumu
                                    ? 'Henüz kayıtlı kuş bulunmamaktadır.'
                                    : 'Seçili filtreye uygun kuş bulunmamaktadır.'),
                            style: const TextStyle(fontSize: 16, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filtrelenmisVeAranmisKuslar.length,
                        itemBuilder: (context, index) {
                          final kus = filtrelenmisVeAranmisKuslar[index];

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            elevation: 3,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            child: ListTile(
                              leading: Icon(
                                kus.cinsiyet == 'Erkek' ? Icons.male : (kus.cinsiyet == 'Dişi' ? Icons.female : Icons.help_outline),
                                color: Theme.of(context).primaryColor,
                              ),
                              title: Text(
                                '${kus.halkaNo} - ${kus.isim ?? 'İsimsiz Kuş'}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                'Cinsiyet: ${kus.cinsiyet}, Durum: ${kus.kusDurumu ?? 'Aktif'}, Yaş: ${kus.yasHesaplaYil() ?? 'Bilinmiyor'}',
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => KusDetayEkrani(kus: kus),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
