// lib/ekranlar/eslesme_listesi_ekrani.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Tarih formatlama için

import '../modeller/eslesme.dart';
import '../providers/eslesme_provider.dart';
import '../providers/kus_provider.dart'; // Kuş isimlerini çekmek için
import 'eslesme_detay_ekrani.dart'; // Detay ekranına navigasyon için

class EslesmeListesiEkrani extends StatefulWidget {
  const EslesmeListesiEkrani({super.key});

  @override
  State<EslesmeListesiEkrani> createState() => _EslesmeListesiEkraniState();
}

class _EslesmeListesiEkraniState extends State<EslesmeListesiEkrani> {
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy');

  // Durum etiketlerini Türkçe'ye çevirir
  String _eslesmeDurumuCevir(EslesmeDurumu durum) {
    switch (durum) {
      case EslesmeDurumu.aktif:
        return 'Aktif';
      case EslesmeDurumu.tamamlandi:
        return 'Tamamlandı';
      case EslesmeDurumu.ayrildi:
        return 'Ayrıldı';
      case EslesmeDurumu.pasif:
        return 'Pasif';
    }
  }

  // Yeni Eşleşme Ekleme Formunu gösterir (Modal Dialog)
  void _showYeniEslesmeForm(BuildContext context, EslesmeProvider eslesmeProvider, KusProvider kusProvider) {
    final formKey = GlobalKey<FormState>();
    String? erkekHalkaNo;
    String? disiHalkaNo;
    DateTime eslesmeTarihi = DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Yeni Eşleşme Ekle'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Erkek Kuş Halka No'),
                      textCapitalization: TextCapitalization.characters,
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return 'Erkek kuş halka no giriniz.';
                        }
                        return null;
                      },
                      onSaved: (val) => erkekHalkaNo = val!.toUpperCase(),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Dişi Kuş Halka No'),
                      textCapitalization: TextCapitalization.characters,
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return 'Dişi kuş halka no giriniz.';
                        }
                        return null;
                      },
                      onSaved: (val) => disiHalkaNo = val!.toUpperCase(),
                    ),
                    const SizedBox(height: 10),
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: Text('Eşleşme Tarihi: ${_dateFormat.format(eslesmeTarihi)}'),
                      trailing: const Icon(Icons.edit),
                      onTap: () async {
                        final newDate = await showDatePicker(
                          context: context,
                          initialDate: eslesmeTarihi,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (newDate != null) {
                          setState(() {
                            eslesmeTarihi = newDate;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      formKey.currentState!.save();

                      // Kuşların varlığını kontrol et
                      final bool erkekVar = kusProvider.halkaNoIleKusVarMi(erkekHalkaNo!);
                      final bool disiVar = kusProvider.halkaNoIleKusVarMi(disiHalkaNo!);

                      if (!erkekVar) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Hata: Erkek kuş ($erkekHalkaNo) bulunamadı.')),
                        );
                        return;
                      }
                      if (!disiVar) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Hata: Dişi kuş ($disiHalkaNo) bulunamadı.')),
                        );
                        return;
                      }
                      if (erkekHalkaNo == disiHalkaNo) {
                         ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Hata: Erkek ve dişi kuş halka numaraları aynı olamaz.')),
                        );
                        return;
                      }


                      // Yeni eşleşmeyi oluştur
                      final yeniEslesme = Eslesme(
                        eslesmeId: null, // Firestore otomatik atayacak
                        erkekHalkaNo: erkekHalkaNo!,
                        disiHalkaNo: disiHalkaNo!,
                        eslesmeTarihi: eslesmeTarihi,
                        durumu: EslesmeDurumu.aktif,
                      );

                      await eslesmeProvider.eslesmeEkle(yeniEslesme);
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Yeni eşleşme başarıyla eklendi!')),
                      );
                    }
                  },
                  child: const Text('Ekle'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // EslesmeProvider ve KusProvider'a erişim
    final eslesmeProvider = Provider.of<EslesmeProvider>(context);
    final kusProvider = Provider.of<KusProvider>(context); // Kuş isimlerini almak için

    return Scaffold(
      appBar: AppBar(
        title: const Text('Eşleşmelerim'),
        actions: [
          // Filtreleme/Sıralama butonları (İsteğe bağlı, daha sonra eklenebilir)
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Eşleşmeleri filtreleme ve sıralama seçeneklerini göster
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Filtreleme/Sıralama özelliği henüz mevcut değil.')),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Eslesme>>(
        stream: eslesmeProvider.getEslesmelerStream(), // EslesmeProvider'dan tüm eşleşmeleri dinle
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Eşleşmeler yüklenirken hata oluştu: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'Henüz kayıtlı bir eşleşme bulunmamaktadır. Yeni bir eşleşme eklemek için "+" butonuna dokunun.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final eslesmeler = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: eslesmeler.length,
            itemBuilder: (context, index) {
              final eslesme = eslesmeler[index];

              // Erkek ve dişi kuş isimlerini KusProvider'dan al
              final erkekKus = kusProvider.halkaNoIleKusBul(eslesme.erkekHalkaNo);
              final disiKus = kusProvider.halkaNoIleKusBul(eslesme.disiHalkaNo);

              // Eşleşme durumuna göre renk ve ikon seçimi
              Color statusColor;
              IconData statusIcon;
              switch (eslesme.durumu) {
                case EslesmeDurumu.aktif:
                  statusColor = Colors.green.shade700;
                  statusIcon = Icons.favorite_border;
                  break;
                case EslesmeDurumu.tamamlandi:
                  statusColor = Colors.blueGrey.shade700;
                  statusIcon = Icons.check_circle_outline;
                  break;
                case EslesmeDurumu.ayrildi:
                  statusColor = Colors.red.shade700;
                  statusIcon = Icons.heart_broken;
                  break;
                case EslesmeDurumu.pasif:
                  statusColor = Colors.orange.shade700;
                  statusIcon = Icons.pause_circle_outline;
                  break;
              }

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6.0),
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: statusColor.withOpacity(0.2),
                    child: Icon(statusIcon, color: statusColor, size: 24),
                  ),
                  title: Text(
                    '${erkekKus?.isim ?? eslesme.erkekHalkaNo} & ${disiKus?.isim ?? eslesme.disiHalkaNo}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Durum: ${_eslesmeDurumuCevir(eslesme.durumu)}',
                        style: TextStyle(color: statusColor, fontWeight: FontWeight.w500),
                      ),
                      Text('Başlangıç: ${_dateFormat.format(eslesme.eslesmeTarihi)}'),
                      // Opsiyonel: Kuluçka özeti eklenebilir
                      // Text('Kuluçka Sayısı: ${eslesme.kuluckaDonemleri?.length ?? 0}'),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
                  onTap: () {
                    // Detay ekranına git
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (ctx) => EslesmeDetayEkrani(eslesme: eslesme),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showYeniEslesmeForm(context, eslesmeProvider, kusProvider),
        child: const Icon(Icons.add),
      ),
    );
  }
}
