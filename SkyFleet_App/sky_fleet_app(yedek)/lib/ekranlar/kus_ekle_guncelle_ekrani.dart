// lib/ekranlar/kus_ekle_guncelle_ekrani.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../modeller/kus.dart';
import '../providers/kus_provider.dart';
import 'package:intl/intl.dart'; // Tarih formatlama için

class KusEkleGuncelleEkrani extends StatefulWidget {
  final Kus? kus; // Eğer bir kuş nesnesi gelirse güncelleme modunda demektir.

  const KusEkleGuncelleEkrani({super.key, this.kus});

  @override
  State<KusEkleGuncelleEkrani> createState() => _KusEkleGuncelleEkraniState();
}

class _KusEkleGuncelleEkraniState extends State<KusEkleGuncelleEkrani> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _halkaNoController = TextEditingController();
  final TextEditingController _isimController = TextEditingController();
  final TextEditingController _dogumTarihiController = TextEditingController();
  final TextEditingController _anneHalkaNoController = TextEditingController();
  final TextEditingController _babaHalkaNoController = TextEditingController();
  final TextEditingController _renkController = TextEditingController();
  final TextEditingController _genetikHatController = TextEditingController();
  final TextEditingController _notlarController = TextEditingController();

  // Form durumları
  String? _seciliCinsiyet;
  String? _seciliDurum;
  DateTime? _secilenDogumTarihi;
  bool _isGuncelleme = false;

  @override
  void initState() {
    super.initState();
    // Eğer düzenleme modundaysa, var olan verileri yükle
    if (widget.kus != null) {
      _isGuncelleme = true;
      _halkaNoController.text = widget.kus!.halkaNo;
      _isimController.text = widget.kus!.isim ?? '';
      _anneHalkaNoController.text = widget.kus!.anneHalkaNo ?? '';
      _babaHalkaNoController.text = widget.kus!.babaHalkaNo ?? '';
      _renkController.text = widget.kus!.renk ?? '';
      _genetikHatController.text = widget.kus!.genetikHat ?? '';
      _notlarController.text = widget.kus!.notlar ?? '';

      _seciliCinsiyet = widget.kus!.cinsiyet;
      _seciliDurum = widget.kus!.kusDurumu;

      if (widget.kus!.dogumTarihi != null) {
        _secilenDogumTarihi = widget.kus!.dogumTarihi;
        _dogumTarihiController.text = DateFormat('dd/MM/yyyy').format(_secilenDogumTarihi!);
      }
    } else {
        // Yeni kayıt ise varsayılan durum "Aktif"
      _seciliDurum = 'Aktif';
    }
  }

  @override
  void dispose() {
    _halkaNoController.dispose();
    _isimController.dispose();
    _dogumTarihiController.dispose();
    _anneHalkaNoController.dispose();
    _babaHalkaNoController.dispose();
    _renkController.dispose();
    _genetikHatController.dispose();
    _notlarController.dispose();
    super.dispose();
  }

  // Tarih seçici açar
  Future<void> _tarihSeciciyiGoster() async {
    final DateTime? seciliTarih = await showDatePicker(
      context: context,
      initialDate: _secilenDogumTarihi ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (seciliTarih != null && seciliTarih != _secilenDogumTarihi) {
      setState(() {
        _secilenDogumTarihi = seciliTarih;
        _dogumTarihiController.text = DateFormat('dd/MM/yyyy').format(seciliTarih);
      });
    }
  }

  void _kaydet() async {
    if (_formKey.currentState!.validate() && _seciliCinsiyet != null && _seciliCinsiyet!.isNotEmpty) {

      final provider = Provider.of<KusProvider>(context, listen: false);

      final String halkaNo = _halkaNoController.text.toUpperCase();
      final String? isim = _isimController.text.isEmpty ? null : _isimController.text;
      final String cinsiyet = _seciliCinsiyet!;
      final String? notlar = _notlarController.text.isEmpty ? null : _notlarController.text;

      final String? anneHalkaNo = _anneHalkaNoController.text.isEmpty ? null : _anneHalkaNoController.text.toUpperCase();
      final String? babaHalkaNo = _babaHalkaNoController.text.isEmpty ? null : _babaHalkaNoController.text.toUpperCase();
      final String? renk = _renkController.text.isEmpty ? null : _renkController.text;
      final String? genetikHat = _genetikHatController.text.isEmpty ? null : _genetikHatController.text;

      // Kuş nesnesinin oluşturulması
      final yeniKus = Kus(
        kusId: widget.kus?.kusId,
        halkaNo: halkaNo,
        isim: isim,
        cinsiyet: cinsiyet,
        dogumTarihi: _secilenDogumTarihi,
        kusDurumu: _seciliDurum ?? 'Aktif',
        notlar: notlar,
        anneHalkaNo: anneHalkaNo,
        babaHalkaNo: babaHalkaNo,
        renk: renk,
        genetikHat: genetikHat,
      );

      try {
        if (!_isGuncelleme) {
          // DÜZELTME: kusHalkaNoVarMi yerine halkaNoIleKusVarMi kullanıldı
          bool halkaNoZatenVar = provider.halkaNoIleKusVarMi(halkaNo);
          if (halkaNoZatenVar) {
            _gosterSnackBar('Hata: Bu halka numarasına sahip bir kuş zaten mevcut!');
            return; // Kayıt işlemini durdur
          }
          // Kuş Ekleme
          await provider.kusEkle(yeniKus);
          _gosterSnackBar('Kuş başarıyla eklendi!');
        } else {
          // Kuş Güncelleme
          await provider.kusGuncelle(yeniKus);
          _gosterSnackBar('Kuş başarıyla güncellendi!');
        }
        if (!mounted) return;
        Navigator.of(context).pop();
      } catch (e) {
        _gosterSnackBar('Kaydetme hatası: ${e.toString()}');
      }
    } else if (_seciliCinsiyet == null || _seciliCinsiyet!.isEmpty) {
       _gosterSnackBar('Lütfen kuşun cinsiyetini seçiniz.');
    } else {
      _gosterSnackBar('Lütfen tüm zorunlu alanları doğru şekilde doldurunuz.');
    }
  }


  void _gosterSnackBar(String mesaj) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mesaj)),
      );
    }
  }

  void _kusSilmeOnayiGoster(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Kuşu Sil"),
          content: Text("Bu kuşu (${widget.kus!.halkaNo}) tamamen silmek istediğinizden emin misiniz? Bu işlem geri alınamaz."),
          actions: <Widget>[
            TextButton(
              child: const Text("İptal"),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text("Sil"),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                try {
                  // DÜZELTME: kusTamamenSil metodu zaten KusProvider'da tanımlı
                  await Provider.of<KusProvider>(context, listen: false).kusTamamenSil(widget.kus!.kusId!);
                  _gosterSnackBar('Kuş (${widget.kus!.halkaNo}) başarıyla silindi.');
                  Navigator.pop(context);
                } catch (e) {
                   _gosterSnackBar('Silme sırasında hata oluştu: ${e.toString()}');
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isGuncelleme ? 'Kuşu Güncelle' : 'Yeni Kuş Ekle'),
        actions: [
            if (_isGuncelleme)
              IconButton(
              icon: const Icon(Icons.delete_forever),
              onPressed: () => _kusSilmeOnayiGoster(context),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: <Widget>[
              // Halka No (Sadece Ekleme modunda düzenlenebilir)
              TextFormField(
                controller: _halkaNoController,
                decoration: const InputDecoration(
                  labelText: 'Halka No (Zorunlu)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.numbers),
                ),
                enabled: !_isGuncelleme,
                textCapitalization: TextCapitalization.characters,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Halka Numarası boş bırakılamaz.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // İsim
              TextFormField(
                controller: _isimController,
                decoration: const InputDecoration(
                  labelText: 'İsim (Opsiyonel)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),

              // Cinsiyet Seçimi (Zorunlu Alan)
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Cinsiyet (Zorunlu)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.transgender),
                ),
                value: _seciliCinsiyet,
                items: ['Erkek', 'Dişi', 'Bilinmiyor']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _seciliCinsiyet = newValue;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen bir cinsiyet seçiniz.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Kuş Durumu Seçimi (Sadece Güncelleme Modunda)
              if (_isGuncelleme) ...[
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Kuş Durumu',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.info_outline),
                    ),
                    value: _seciliDurum,
                    items: ['Aktif', 'Pasif', 'Satıldı', 'Vefat'] // TODO: KusFiltreTipi'ne göre veya Kus modeline göre düzenle
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _seciliDurum = newValue;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
              ],


              // Doğum Tarihi
              TextFormField(
                controller: _dogumTarihiController,
                decoration: const InputDecoration(
                  labelText: 'Doğum Tarihi (Opsiyonel)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: _tarihSeciciyiGoster,
              ),
              const SizedBox(height: 16),

              // Anne Halka No
              TextFormField(
                controller: _anneHalkaNoController,
                decoration: const InputDecoration(
                  labelText: 'Anne Halka No (Opsiyonel)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.female),
                ),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 16),

              // Baba Halka No
              TextFormField(
                controller: _babaHalkaNoController,
                decoration: const InputDecoration(
                  labelText: 'Baba Halka No (Opsiyonel)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.male),
                ),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 16),

              // Renk
              TextFormField(
                controller: _renkController,
                decoration: const InputDecoration(
                  labelText: 'Renk (Opsiyonel)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.color_lens),
                ),
              ),
              const SizedBox(height: 16),

              // Genetik Hat
              TextFormField(
                controller: _genetikHatController,
                decoration: const InputDecoration(
                  labelText: 'Genetik Hat (Örn: Janssen, De Klak) (Opsiyonel)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
              ),
              const SizedBox(height: 16),

              // Notlar
              TextFormField(
                controller: _notlarController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notlar (Opsiyonel)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                ),
              ),
              const SizedBox(height: 24),

              // Kaydetme Butonu
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _kaydet,
                  icon: Icon(_isGuncelleme ? Icons.save : Icons.add),
                  label: Text(_isGuncelleme ? 'Değişiklikleri Kaydet' : 'Kuşu Ekle'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
