import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Tarih formatlama için
import '../modeller/eslesme.dart';
import '../modeller/kulucka_donemi.dart';
import '../modeller/kus.dart';
import '../providers/eslesme_provider.dart';
import '../providers/kus_provider.dart';

// Tarih Formatlayıcı
final DateFormat _dateFormat = DateFormat('dd MMM yyyy');

// Kulucka süresini hesaplamak için sabitler
const int KULUCKA_MIN_GUN = 18;
const int KULUCKA_MAX_GUN = 21;


class EslesmeDetayEkrani extends StatefulWidget {
  final Eslesme eslesme;

  const EslesmeDetayEkrani({super.key, required this.eslesme});

  @override
  State<EslesmeDetayEkrani> createState() => _EslesmeDetayEkraniState();
}

class _EslesmeDetayEkraniState extends State<EslesmeDetayEkrani> {

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

  String _kuluckaDurumuCevir(KuluckaDurumu durum) {
    switch (durum) {
      case KuluckaDurumu.devamEdiyor:
        return 'Devam Ediyor';
      case KuluckaDurumu.basarili:
        return 'Başarılı';
      case KuluckaDurumu.basarisiz:
        return 'Başarısız';
      case KuluckaDurumu.iptalEdildi:
        return 'İptal Edildi';
    }
  }

  Widget _buildDetailRow(String label, String? value, {Color? color, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (icon != null) ...[Icon(icon, size: 18, color: Colors.blueGrey), const SizedBox(width: 8)],
              Text(
                '$label:',
                style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.blueGrey),
              ),
            ],
          ),
          Text(
            value ?? 'Belirtilmemiş',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color ?? (value != null ? Colors.black87 : Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKuluckaAksiyonlari(BuildContext context, EslesmeProvider eslesmeProvider, KusProvider kusProvider, String eslesmeId, KuluckaDonemi kuluckaDonemi) {
    switch (kuluckaDonemi.durumu) {
      case KuluckaDurumu.devamEdiyor:
        return Row(
          children: [
            Expanded(
              child: _actionCard(
                title: 'Kuluçka Başarılı',
                subtitle: 'Yavru sayısı ve künye numaralarını girin.',
                color: Colors.green.shade600,
                icon: Icons.check_circle_outline,
                onTap: () => _showYavruEkleForm(context, eslesmeProvider, kusProvider, eslesmeId, kuluckaDonemi),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _actionCard(
                title: 'Kuluçka Başarısız',
                subtitle: 'Kuluçkayı sonlandır ve not ekle.',
                color: Colors.red.shade400,
                icon: Icons.cancel,
                onTap: () => _showKuluckaBitirForm(context, eslesmeProvider, eslesmeId, kuluckaDonemi, KuluckaDurumu.basarisiz),
              ),
            ),
          ],
        );
      case KuluckaDurumu.basarili:
      case KuluckaDurumu.basarisiz:
      case KuluckaDurumu.iptalEdildi:
        return const SizedBox.shrink();
    }
  }

  Widget _buildGenelEslesmeAksiyonlari(BuildContext context, EslesmeProvider eslesmeProvider, Eslesme currentEslesme) {
    if (currentEslesme.durumu == EslesmeDurumu.aktif) {
      return Row(
        children: [
          Expanded(
            child: _actionCard(
              title: 'Yeni Kuluçka Başlat',
              subtitle: 'Bu eşleşmeden yeni bir yumurtlama dönemi ekleyin.',
              color: Colors.blue.shade600,
              icon: Icons.egg_alt,
              onTap: () => _showKuluckaBaslatForm(context, eslesmeProvider, currentEslesme.eslesmeId!),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _actionCard(
              title: 'Eşleşmeyi Sonlandır',
              subtitle: 'Kuşları ayır veya eşleşmeyi tamamla.',
              color: Colors.deepOrange,
              icon: Icons.broken_image,
              onTap: () => _showEslesmeDurumuGuncelleForm(context, eslesmeProvider, currentEslesme, EslesmeDurumu.tamamlandi),
            ),
          ),
        ],
      );
    } else {
      return const SizedBox.shrink();
    }
  }


  Widget _actionCard({
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 24),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
        ),
      ),
    );
  }
  
  // --- MODAL FORMLAR ---

  void _showKuluckaBaslatForm(BuildContext context, EslesmeProvider eslesmeProvider, String eslesmeId) {
    final formKey = GlobalKey<FormState>();
    DateTime yumurtlamaTarihi = DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Yeni Kuluçka Başlat'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: Text('Yumurtlama Tarihi: ${_dateFormat.format(yumurtlamaTarihi)}'),
                      trailing: const Icon(Icons.edit),
                      onTap: () async {
                        final newDate = await showDatePicker(
                          context: context,
                          initialDate: yumurtlamaTarihi,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (newDate != null) {
                          setState(() {
                            yumurtlamaTarihi = newDate;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('İptal')),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      formKey.currentState!.save();
                      Navigator.of(context).pop();
                      final yeniKulucka = KuluckaDonemi(yumurtlamaTarihi: yumurtlamaTarihi);
                      await eslesmeProvider.kuluckaDonemiEkle(eslesmeId, yeniKulucka);
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Yeni kuluçka dönemi başlatıldı!')));
                    }
                  },
                  child: const Text('Başlat'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Yavru Ekleme Formu
  void _showYavruEkleForm(BuildContext context, EslesmeProvider eslesmeProvider, KusProvider kusProvider, String eslesmeId, KuluckaDonemi kuluckaDonemi) {
    final formKey = GlobalKey<FormState>();

    // Sabit 2 yavru için değişkenler
    TextEditingController _halkaNo1Controller = TextEditingController();
    TextEditingController _halkaNo2Controller = TextEditingController();
    bool _isYavru1Basarili = true; // Varsayılan olarak başarılı kabul edilebilir
    bool _isYavru2Basarili = true; // Varsayılan olarak başarılı kabul edilebilir

    String? kuluckaNotlari;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Yavru Kaydı & Kuluçka Sonlandırma'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // --- Yavru 1 Kontrolleri ---
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _halkaNo1Controller,
                              decoration: const InputDecoration(
                                labelText: 'Yavru 1 Halka No',
                                border: OutlineInputBorder(),
                              ),
                              textCapitalization: TextCapitalization.characters,
                              enabled: _isYavru1Basarili, // Sadece başarılıysa etkin
                              validator: (val) {
                                if (_isYavru1Basarili && (val == null || val.isEmpty)) {
                                  return 'Yavru 1 için halka no giriniz (Başarılı işaretli).';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            children: [
                              Checkbox(
                                value: _isYavru1Basarili,
                                onChanged: (bool? newValue) {
                                  setState(() {
                                    _isYavru1Basarili = newValue ?? false;
                                    if (!_isYavru1Basarili) {
                                      _halkaNo1Controller.clear(); // Başarısız ise halka noyu temizle
                                      formKey.currentState?.validate(); // Halka No'yu temizledikten sonra validator'ı yeniden çalıştır
                                    }
                                  });
                                },
                              ),
                              const Text('Başarılı'),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // --- Yavru 2 Kontrolleri ---
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _halkaNo2Controller,
                              decoration: const InputDecoration(
                                labelText: 'Yavru 2 Halka No',
                                border: OutlineInputBorder(),
                              ),
                              textCapitalization: TextCapitalization.characters,
                              enabled: _isYavru2Basarili, // Sadece başarılıysa etkin
                              validator: (val) {
                                if (_isYavru2Basarili && (val == null || val.isEmpty)) {
                                  return 'Yavru 2 için halka no giriniz (Başarılı işaretli).';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            children: [
                              Checkbox(
                                value: _isYavru2Basarili,
                                onChanged: (bool? newValue) {
                                  setState(() {
                                    _isYavru2Basarili = newValue ?? false;
                                    if (!_isYavru2Basarili) {
                                      _halkaNo2Controller.clear(); // Başarısız ise halka noyu temizle
                                      formKey.currentState?.validate(); // Halka No'yu temizledikten sonra validator'ı yeniden çalıştır
                                    }
                                  });
                                },
                              ),
                              const Text('Başarılı'),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // --- Kuluçka Notları ---
                      TextFormField(
                        initialValue: kuluckaDonemi.kuluckaNotlari,
                        decoration: const InputDecoration(labelText: 'Kuluçka Notları (İsteğe Bağlı)'),
                        maxLines: 3,
                        onSaved: (val) => kuluckaNotlari = val,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('İptal')),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      formKey.currentState!.save();

                      int totalSuccessfulCount = 0;
                      int totalUnsuccessfulCount = 0; // Manuel giriş alanı kaldırıldığı için başlangıç 0

                      // Yavru 1 kontrolü
                      if (_isYavru1Basarili && _halkaNo1Controller.text.isNotEmpty) {
                        final halkaNo = _halkaNo1Controller.text.toUpperCase();
                        // TODO: Halka No'nun benzersizliğini kontrol et (KusProvider'da kusHalkaNoVarMi metodu var)
                        final yeniYavru = Kus(
                          halkaNo: halkaNo,
                          cinsiyet: 'Bilinmiyor',
                          dogumTarihi: kuluckaDonemi.yumurtlamaTarihi,
                          kusDurumu: 'Aktif',
                          anneHalkaNo: widget.eslesme.disiHalkaNo,
                          babaHalkaNo: widget.eslesme.erkekHalkaNo,
                        );
                        await kusProvider.kusEkle(yeniYavru);
                        totalSuccessfulCount++;
                      } else {
                        // Başarılı değilse VEYA başarılı işaretli ama halka no boşsa başarısız sayılır
                        totalUnsuccessfulCount++;
                      }

                      // Yavru 2 kontrolü
                      if (_isYavru2Basarili && _halkaNo2Controller.text.isNotEmpty) {
                        final halkaNo = _halkaNo2Controller.text.toUpperCase();
                        // TODO: Halka No'nun benzersizliğini kontrol et
                        final yeniYavru = Kus(
                          halkaNo: halkaNo,
                          cinsiyet: 'Bilinmiyor',
                          dogumTarihi: kuluckaDonemi.yumurtlamaTarihi,
                          kusDurumu: 'Aktif',
                          anneHalkaNo: widget.eslesme.disiHalkaNo,
                          babaHalkaNo: widget.eslesme.erkekHalkaNo,
                        );
                        await kusProvider.kusEkle(yeniYavru);
                        totalSuccessfulCount++;
                      } else {
                        // Başarılı değilse VEYA başarılı işaretli ama halka no boşsa başarısız sayılır
                        totalUnsuccessfulCount++;
                      }
                      
                      // Kuluçka dönemini güncelle
                      final guncelKulucka = kuluckaDonemi.copyWith(
                        durumu: KuluckaDurumu.basarili,
                        gerceklesenYavruSayisi: totalSuccessfulCount + totalUnsuccessfulCount,
                        basariliYavruSayisi: totalSuccessfulCount,
                        basarisizYavruSayisi: totalUnsuccessfulCount,
                        kuluckaBitisTarihi: DateTime.now(),
                        kuluckaNotlari: kuluckaNotlari,
                      );
                      await eslesmeProvider.kuluckaDonemiGuncelle(eslesmeId, guncelKulucka);

                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Yavrular kaydedildi ve kuluçka başarılı olarak işaretlendi!')));
                    }
                  },
                  child: const Text('Kaydet'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      _halkaNo1Controller.dispose();
      _halkaNo2Controller.dispose();
      // _ekBasarisizYavruSayisiController kaldırıldı
    });
  }

  void _showKuluckaBitirForm(BuildContext context, EslesmeProvider eslesmeProvider, String eslesmeId, KuluckaDonemi kuluckaDonemi, KuluckaDurumu bitisDurumu) {
    final formKey = GlobalKey<FormState>();
    String? kuluckaNotlari;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(bitisDurumu == KuluckaDurumu.basarisiz ? 'Kuluçka Başarısız Olarak İşaretle' : 'Kuluçkayı İptal Et'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  bitisDurumu == KuluckaDurumu.basarisiz
                    ? 'Bu kuluçka dönemini başarısız olarak işaretleyecek. Bir not ekleyebilirsiniz.'
                    : 'Bu kuluçka dönemini iptal edecek. Bir not ekleyebilirsiniz.',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Notlar (İsteğe Bağlı)'),
                  initialValue: kuluckaDonemi.kuluckaNotlari,
                  maxLines: 3,
                  onSaved: (val) => kuluckaNotlari = val,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('İptal')),
            ElevatedButton(
              onPressed: () async {
                formKey.currentState!.save();
                Navigator.of(context).pop();
                final guncelKulucka = kuluckaDonemi.copyWith(
                  durumu: bitisDurumu,
                  kuluckaBitisTarihi: DateTime.now(),
                  kuluckaNotlari: kuluckaNotlari,
                );
                await eslesmeProvider.kuluckaDonemiGuncelle(eslesmeId, guncelKulucka);
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Kuluçka ${bitisDurumu == KuluckaDurumu.basarisiz ? "başarısız" : "iptal edildi"} olarak işaretlendi!')));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: bitisDurumu == KuluckaDurumu.basarisiz ? Colors.red.shade400 : Colors.orange.shade400,
                foregroundColor: Colors.white,
              ),
              child: Text(bitisDurumu == KuluckaDurumu.basarisiz ? 'Başarısız İşaretle' : 'İptal Et'),
            ),
          ],
        );
      },
    );
  }

  void _showEslesmeDurumuGuncelleForm(BuildContext context, EslesmeProvider eslesmeProvider, Eslesme eslesme, EslesmeDurumu hedefDurum) {
    final formKey = GlobalKey<FormState>();
    String? ozelNot;
    EslesmeDurumu secilenDurum = hedefDurum;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(_eslesmeDurumuCevir(hedefDurum) + ' Olarak İşaretle'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<EslesmeDurumu>(
                      value: secilenDurum,
                      decoration: const InputDecoration(labelText: 'Eşleşme Durumu'),
                      items: EslesmeDurumu.values.map((EslesmeDurumu durum) {
                        return DropdownMenuItem<EslesmeDurumu>(
                          value: durum,
                          child: Text(_eslesmeDurumuCevir(durum)),
                        );
                      }).toList(),
                      onChanged: (EslesmeDurumu? newValue) {
                        if (newValue != null) {
                          setState(() {
                            secilenDurum = newValue;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Özel Notlar (İsteğe Bağlı)'),
                      initialValue: eslesme.ozelNot,
                      maxLines: 3,
                      onSaved: (val) => ozelNot = val,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('İptal')),
                ElevatedButton(
                  onPressed: () async {
                    formKey.currentState!.save();
                    Navigator.of(context).pop();
                    final guncelEslesme = eslesme.copyWith(
                      durumu: secilenDurum,
                      ozelNot: ozelNot,
                    );
                    await eslesmeProvider.eslesmeGuncelle(guncelEslesme);
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Eşleşme durumu "${_eslesmeDurumuCevir(secilenDurum)}" olarak güncellendi!')));
                  },
                  child: const Text('Güncelle'),
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
    final eslesmeProvider = Provider.of<EslesmeProvider>(context);
    final kusProvider = Provider.of<KusProvider>(context);

    final currentEslesme = eslesmeProvider.tumEslesmeler.firstWhere(
      (e) => e.eslesmeId == widget.eslesme.eslesmeId,
      orElse: () => widget.eslesme,
    );

    final erkekKus = kusProvider.halkaNoIleKusBul(currentEslesme.erkekHalkaNo);
    final disiKus = kusProvider.halkaNoIleKusBul(currentEslesme.disiHalkaNo);


    return Scaffold(
      appBar: AppBar(
        title: Text('${currentEslesme.erkekHalkaNo} & ${currentEslesme.disiHalkaNo}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: _eslesmeDurumuCevir(currentEslesme.durumu) == 'Aktif'
                  ? Colors.green.shade100
                  : Colors.grey.shade100,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Eşleşme Bilgileri', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const Divider(),
                    _buildDetailRow(
                      'Durum',
                      _eslesmeDurumuCevir(currentEslesme.durumu),
                      color: currentEslesme.durumu == EslesmeDurumu.aktif ? Colors.green.shade700 : Colors.red.shade700,
                      icon: currentEslesme.durumu == EslesmeDurumu.aktif ? Icons.favorite_border : Icons.heart_broken,
                    ),
                    _buildDetailRow('Eşleşme Tarihi', _dateFormat.format(currentEslesme.eslesmeTarihi), icon: Icons.calendar_today),
                    _buildDetailRow(
                      'Erkek Kuş',
                      '${erkekKus?.halkaNo ?? currentEslesme.erkekHalkaNo} (${erkekKus?.isim ?? 'Bilinmiyor'})',
                      icon: Icons.male,
                      color: Colors.blue.shade700,
                    ),
                    _buildDetailRow(
                      'Dişi Kuş',
                      '${disiKus?.halkaNo ?? currentEslesme.disiHalkaNo} (${disiKus?.isim ?? 'Bilinmiyor'})',
                      icon: Icons.female,
                      color: Colors.pink.shade700,
                    ),
                    if (currentEslesme.ozelNot != null && currentEslesme.ozelNot!.isNotEmpty)
                      _buildDetailRow('Özel Not', currentEslesme.ozelNot, icon: Icons.notes),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            _buildGenelEslesmeAksiyonlari(context, eslesmeProvider, currentEslesme),

            const SizedBox(height: 16),

            const Text('Kuluçka Dönemleri', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            const Divider(thickness: 2, color: Colors.blueGrey),

            StreamBuilder<List<KuluckaDonemi>>(
              stream: eslesmeProvider.getKuluckaDonemleriStream(currentEslesme.eslesmeId!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Kuluçka dönemleri yüklenirken hata oluştu: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: currentEslesme.durumu == EslesmeDurumu.aktif
                        ? const Text('Bu eşleşmeye ait henüz kuluçka dönemi yok. Başlatabilirsiniz.')
                        : const Text('Bu eşleşmeye ait kuluçka dönemi bulunmamaktadır.'),
                  );
                }

                final kuluckaDonemleri = snapshot.data!;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: kuluckaDonemleri.length,
                  itemBuilder: (context, index) {
                    final kulucka = kuluckaDonemleri[index];
                    
                    final tahminiCikisTarihi = kulucka.yumurtlamaTarihi.add(const Duration(days: KULUCKA_MAX_GUN));
                    final kalanGun = tahminiCikisTarihi.difference(DateTime.now()).inDays;
                    
                    Color durumRengi;
                    String durumMetni = _kuluckaDurumuCevir(kulucka.durumu);
                    IconData durumIconu;

                    switch (kulucka.durumu) {
                      case KuluckaDurumu.devamEdiyor:
                        durumRengi = Colors.amber.shade700;
                        durumIconu = Icons.watch_later_outlined;
                        if (kalanGun >= 0 && kalanGun <= KULUCKA_MAX_GUN) {
                           durumMetni += ' (Kalan: $kalanGun gün)';
                        } else if (kalanGun < 0) {
                           durumMetni += ' (Gecikmiş)';
                        }
                        break;
                      case KuluckaDurumu.basarili:
                        durumRengi = Colors.green.shade700;
                        durumIconu = Icons.check_circle_outline;
                        break;
                      case KuluckaDurumu.basarisiz:
                        durumRengi = Colors.red.shade700;
                        durumIconu = Icons.error_outline;
                        break;
                      case KuluckaDurumu.iptalEdildi:
                        durumRengi = Colors.grey.shade700;
                        durumIconu = Icons.cancel_outlined;
                        break;
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: ExpansionTile(
                        leading: Icon(durumIconu, color: durumRengi),
                        title: Text(
                          'Yumurtlama: ${_dateFormat.format(kulucka.yumurtlamaTarihi)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('Durum: $durumMetni', style: TextStyle(color: durumRengi)),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDetailRow('Kuluçka ID', kulucka.kuluckaId, icon: Icons.tag),
                                _buildDetailRow('Yumurtlama Tarihi', _dateFormat.format(kulucka.yumurtlamaTarihi), icon: Icons.calendar_today),
                                if (kulucka.durumu == KuluckaDurumu.devamEdiyor)
                                  _buildDetailRow('Tahmini Çıkış Tarihi', _dateFormat.format(tahminiCikisTarihi), icon: Icons.calendar_month, color: Colors.orange.shade700),
                                if (kulucka.kuluckaBitisTarihi != null)
                                  _buildDetailRow('Kuluçka Bitiş Tarihi', _dateFormat.format(kulucka.kuluckaBitisTarihi!), icon: Icons.event_available),
                                if (kulucka.gerceklesenYavruSayisi != null)
                                  _buildDetailRow('Gerçekleşen Yavru Sayısı', kulucka.gerceklesenYavruSayisi.toString(), icon: Icons.pets),
                                if (kulucka.basariliYavruSayisi != null)
                                  _buildDetailRow('Başarılı Yavru Sayısı', kulucka.basariliYavruSayisi.toString(), icon: Icons.check_circle, color: Colors.green),
                                if (kulucka.basarisizYavruSayisi != null)
                                  _buildDetailRow('Başarısız Yavru Sayısı', kulucka.basarisizYavruSayisi.toString(), icon: Icons.dangerous, color: Colors.red),
                                if (kulucka.kuluckaNotlari != null && kulucka.kuluckaNotlari!.isNotEmpty)
                                  _buildDetailRow('Kuluçka Notları', kulucka.kuluckaNotlari, icon: Icons.notes),
                                const SizedBox(height: 16),
                                _buildKuluckaAksiyonlari(context, eslesmeProvider, kusProvider, currentEslesme.eslesmeId!, kulucka),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
