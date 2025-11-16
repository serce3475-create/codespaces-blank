import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../modeller/eslesme.dart';
import '../providers/eslesme_provider.dart';
import '../providers/kus_provider.dart';
import '../modeller/kus.dart'; // Kus modelini doğrudan kullanmak için

class EslesmeEklemeEkrani extends StatefulWidget {
  final String? erkekHalkaNo;
  final String? disiHalkaNo;

  // Mevcut bir eşleşmeyi düzenlemek için veya yeni bir eşleşme oluşturmak için kullanılabilir.
  // Bu ekran şimdilik sadece yeni eşleşme eklemek için kullanılıyor gibi görünüyor.
  const EslesmeEklemeEkrani({
    Key? key,
    this.erkekHalkaNo,
    this.disiHalkaNo,
  }) : super(key: key);

  @override
  _EslesmeEklemeEkraniState createState() => _EslesmeEklemeEkraniState();
}

class _EslesmeEklemeEkraniState extends State<EslesmeEklemeEkrani> {
  final _formKey = GlobalKey<FormState>();

  Kus? _seciliErkekKus; // Seçilen erkek kuş nesnesi
  Kus? _seciliDisiKus; // Seçilen dişi kuş nesnesi

  final TextEditingController _ozelNotController = TextEditingController();

  DateTime? _eslesmeTarihi;

  @override
  void initState() {
    super.initState();
    final kusProvider = Provider.of<KusProvider>(context, listen: false);

    // Eğer başlangıçta erkek halka no varsa, kuşu bulup _seciliErkekKus'a ata
    if (widget.erkekHalkaNo != null) {
      _seciliErkekKus = kusProvider.halkaNoIleKusBul(widget.erkekHalkaNo!);
    }
    // Eğer başlangıçta dişi halka no varsa, kuşu bulup _seciliDisiKus'a ata
    if (widget.disiHalkaNo != null) {
      _seciliDisiKus = kusProvider.halkaNoIleKusBul(widget.disiHalkaNo!);
    }
  }

  @override
  void dispose() {
    _ozelNotController.dispose();
    super.dispose();
  }

  Future<void> _tarihSec() async {
    final DateTime? alinanTarih = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (alinanTarih != null) {
      setState(() {
        _eslesmeTarihi = alinanTarih;
      });
    }
  }

  void _kaydet() async { // async eklendi
    if (_formKey.currentState!.validate()) {
      if (_eslesmeTarihi == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lütfen eşleşme tarihini seçiniz.')),
        );
        return;
      }

      if (_seciliErkekKus == null || _seciliDisiKus == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lütfen hem erkek hem de dişi kuş seçiniz.')),
        );
        return;
      }

      // Seçilen kuşların cinsiyet kontrolü
      if (_seciliErkekKus!.cinsiyet != 'Erkek') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seçilen erkek kuşun cinsiyeti "Erkek" olmalıdır.')),
        );
        return;
      }
      if (_seciliDisiKus!.cinsiyet != 'Dişi') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seçilen dişi kuşun cinsiyeti "Dişi" olmalıdır.')),
        );
        return;
      }

      // Yeni Eslesme modeline uygun olarak oluşturuyoruz
      final yeniEslesme = Eslesme(
        erkekHalkaNo: _seciliErkekKus!.halkaNo.toUpperCase(),
        disiHalkaNo: _seciliDisiKus!.halkaNo.toUpperCase(),
        eslesmeTarihi: _eslesmeTarihi!,
        ozelNot: _ozelNotController.text.isEmpty ? null : _ozelNotController.text,
        durumu: EslesmeDurumu.aktif, // Yeni eşleşme varsayılan olarak aktif başlar
      );

      try {
        final eslesmeId = await Provider.of<EslesmeProvider>(context, listen: false)
            .eslesmeEkle(yeniEslesme);

        // Eşleşme kaydedildikten sonra, kullanıcıyı genellikle detay ekranına yönlendiririz
        // veya eşleşme listesi ekranına geri döneriz.
        // Şimdilik listeye geri dönelim.
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Eşleşme başarıyla kaydedildi!')),
          );
        }
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Eşleşme kaydedilirken hata oluştu: $error')),
        );
      }
    }
  }

  // Akıllı Eş Seçimi için yardımcı metot
  Future<void> _kusSeciciGoster({required String cinsiyet, required Function(Kus) onSelect}) async {
    final selectedKus = await showModalBottomSheet<Kus>(
      context: context,
      isScrollControlled: true, // Tam ekran yapmak için
      builder: (BuildContext context) {
        return KusSeciciWidget(cinsiyet: cinsiyet);
      },
    );

    if (selectedKus != null) {
      onSelect(selectedKus);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni Eşleşme Kaydı'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Erkek Kuş Seçimi
              _buildKusSecici(
                cinsiyet: 'Erkek',
                seciliKus: _seciliErkekKus,
                onSeciliKusDegisti: (kus) {
                  setState(() {
                    _seciliErkekKus = kus;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Dişi Kuş Seçimi
              _buildKusSecici(
                cinsiyet: 'Dişi',
                seciliKus: _seciliDisiKus,
                onSeciliKusDegisti: (kus) {
                  setState(() {
                    _seciliDisiKus = kus;
                  });
                },
              ),
              const SizedBox(height: 24),

              ListTile(
                title: const Text('Eşleşme Tarihi Seç (Zorunlu)'),
                subtitle: Text(_eslesmeTarihi == null
                    ? 'Tarih seçilmedi'
                    : DateFormat('dd/MM/yyyy').format(_eslesmeTarihi!)
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _tarihSec,
              ),
              const Divider(height: 0),
              const SizedBox(height: 24),

              TextFormField(
                controller: _ozelNotController,
                decoration: const InputDecoration(
                  labelText: 'Eşleşme Özel Notları',
                  border: OutlineInputBorder()),
                maxLines: 3,
                keyboardType: TextInputType.multiline,
              ),
              const SizedBox(height: 32),

              ElevatedButton.icon(
                onPressed: _kaydet,
                icon: const Icon(Icons.favorite),
                label: const Text('Eşleşmeyi Kaydet', style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Akıllı Kuş Seçimi için yeniden kullanılabilir Widget
  Widget _buildKusSecici({
    required String cinsiyet,
    required Kus? seciliKus,
    required Function(Kus?) onSeciliKusDegisti,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                readOnly: true, // Sadece seçici üzerinden değiştirilsin
                controller: TextEditingController(text: seciliKus?.halkaNo ?? ''), // Halka Numarası göster
                decoration: InputDecoration(
                  labelText: '$cinsiyet Kuş Halka Numarası',
                  border: const OutlineInputBorder(),
                  prefixIcon: Icon(cinsiyet == 'Erkek' ? Icons.male : Icons.female),
                ),
                validator: (value) {
                  if (seciliKus == null) {
                    return 'Lütfen bir $cinsiyet kuş seçiniz.';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => _kusSeciciGoster(
                cinsiyet: cinsiyet,
                onSelect: (kus) => onSeciliKusDegisti(kus),
              ),
              child: const Text('Seç'),
            ),
          ],
        ),
        if (seciliKus != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0, left: 12.0),
            child: Text(
              'İsim: ${seciliKus.isim ?? 'Bilinmiyor'} (Cinsiyet: ${seciliKus.cinsiyet}, Durum: ${seciliKus.kusDurumu ?? 'Aktif'})',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
      ],
    );
  }
}


// Akıllı Kuş Seçimi için yeni widget
class KusSeciciWidget extends StatefulWidget {
  final String cinsiyet; // 'Erkek' veya 'Dişi'

  const KusSeciciWidget({Key? key, required this.cinsiyet}) : super(key: key);

  @override
  State<KusSeciciWidget> createState() => _KusSeciciWidgetState();
}

class _KusSeciciWidgetState extends State<KusSeciciWidget> {
  String _aramaMetni = '';
  final TextEditingController _aramaController = TextEditingController();

  @override
  void dispose() {
    _aramaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8, // Ekranın %80'ini kaplar
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            '${widget.cinsiyet} Kuş Seçin',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _aramaController,
            decoration: InputDecoration(
              labelText: 'Halka No veya İsim ile Ara',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _aramaMetni = value.toLowerCase();
              });
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            // BURADA DEĞİŞİKLİK: EslesmeProvider yerine KusProvider kullanıyoruz
            child: Consumer<KusProvider>(
              builder: (context, kusProvider, child) {
                // 1. Tüm kuşları alıyoruz (KusProvider'ın tumKuslar özelliğinden varsayarak)
                // NOT: KusProvider'ınızda 'List<Kus> tumKuslar;' gibi tüm kuşları tutan bir alan olmalı
                // veya getTumKuslarStream() gibi bir metotla tüm kuşları çekmelisiniz.
                // Eğer yoksa, KusProvider'a bu özelliği eklemeniz gerekecektir.
                List<Kus> tumKuslar = kusProvider.tumKuslar; // varsayılan olarak tumKuslar listesini kullanıyoruz

                // 2. Cinsiyete göre filtrele (Erkek veya Dişi)
                List<Kus> uygunCinsiyetKuslar = tumKuslar.where((kus) =>
                  kus.cinsiyet == widget.cinsiyet // Sadece doğru cinsiyetteki kuşları al
                ).toList();

                // 3. Arama metnine göre filtrele
                if (_aramaMetni.isNotEmpty) {
                  uygunCinsiyetKuslar = uygunCinsiyetKuslar.where((kus) =>
                      kus.halkaNo.toLowerCase().contains(_aramaMetni) ||
                      (kus.isim?.toLowerCase().contains(_aramaMetni) ?? false)
                  ).toList();
                }

                // 4. Kuşları halka numarasına göre sırala (isteğe bağlı, ama liste için iyi bir pratik)
                uygunCinsiyetKuslar.sort((a, b) => a.halkaNo.compareTo(b.halkaNo));


                if (uygunCinsiyetKuslar.isEmpty) {
                  return Center(
                    child: Text('Uygun ${widget.cinsiyet} kuş bulunamadı.'),
                  );
                }

                return ListView.builder(
                  itemCount: uygunCinsiyetKuslar.length,
                  itemBuilder: (context, index) {
                    final kus = uygunCinsiyetKuslar[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: Icon(widget.cinsiyet == 'Erkek' ? Icons.male : Icons.female),
                        title: Text('${kus.halkaNo} - ${kus.isim ?? 'Bilinmiyor'}'),
                        subtitle: Text('Cinsiyet: ${kus.cinsiyet}, Durum: ${kus.kusDurumu ?? 'Aktif'}'),
                        onTap: () {
                          Navigator.of(context).pop(kus); // Seçilen kuşu geri döndür
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Geri dön (bir kuş seçilmedi)
            },
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }
}
