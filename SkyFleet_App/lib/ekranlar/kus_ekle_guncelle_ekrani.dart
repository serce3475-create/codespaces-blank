// lib/ekranlar/kus_ekle_guncelle_ekrani.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../modeller/kus.dart';
import '../providers/kus_provider.dart';
import 'package:intl/intl.dart'; // Tarih formatlama için
import '../providers/pedigree_entry_provider.dart';
// import 'pedigree_parent_entry_screen.dart'; // ARTIK KULLANILMIYOR VE SİLİNMELİ
import 'pedigree_full_entry_screen.dart'; // YENİ EKLENDİ VE KULLANILACAK

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

      final kusProvider = Provider.of<KusProvider>(context, listen: false);
      final pedigreeEntryProvider = Provider.of<PedigreeEntryProvider>(context, listen: false);

      // Sadece tek bir kuşu kaydet veya mevcut bir kuşu güncelle.
      // Eğer PedigreeEntryProvider'da bir zincir varsa, bu butondan sadece root kuşu kaydetmeliyiz
      // VEYA tüm zinciri kaydetmeliyiz. İş mantığına göre burada sadece tekli kayıt ve güncelleme kalacak.
      // Zincirleme kayıt için "Ebeveyn Ekle" butonu üzerinden ilerliyoruz.

      // Yeni kuş ekleme senaryosu (PedigreeEntryProvider'da henüz zincir yoksa)
      if (!_isGuncelleme && pedigreeEntryProvider.pendingPedigreeChain.isEmpty) {
        final String halkaNo = _halkaNoController.text.toUpperCase();
        bool halkaNoZatenVar = kusProvider.halkaNoIleKusVarMi(halkaNo);
        if (halkaNoZatenVar) {
          _gosterSnackBar('Hata: Bu halka numarasına sahip bir kuş zaten mevcut!');
          return;
        }
        final yeniKus = Kus(
          kusId: widget.kus?.kusId,
          halkaNo: halkaNo,
          isim: _isimController.text.isEmpty ? null : _isimController.text,
          cinsiyet: _seciliCinsiyet!,
          dogumTarihi: _secilenDogumTarihi,
          kusDurumu: _seciliDurum ?? 'Aktif',
          notlar: _notlarController.text.isEmpty ? null : _notlarController.text,
          renk: _renkController.text.isEmpty ? null : _renkController.text,
          genetikHat: _genetikHatController.text.isEmpty ? null : _genetikHatController.text,
          anneHalkaNo: null,
          babaHalkaNo: null,
        );
        try {
          await kusProvider.kusEkle(yeniKus);
          _gosterSnackBar('Kuş başarıyla eklendi!');
          if (!mounted) return;
          Navigator.of(context).pop();
        } catch (e) {
          _gosterSnackBar('Kuş eklenirken hata: ${e.toString()}');
        }
      }
      // Mevcut kuşu güncelleme senaryosu
      else if (_isGuncelleme) {
        final guncelKus = Kus(
          kusId: widget.kus?.kusId,
          halkaNo: _halkaNoController.text.toUpperCase(),
          isim: _isimController.text.isEmpty ? null : _isimController.text,
          cinsiyet: _seciliCinsiyet!,
          dogumTarihi: _secilenDogumTarihi,
          kusDurumu: _seciliDurum ?? 'Aktif',
          notlar: _notlarController.text.isEmpty ? null : _notlarController.text,
          renk: _renkController.text.isEmpty ? null : _renkController.text,
          genetikHat: _genetikHatController.text.isEmpty ? null : _genetikHatController.text,
          anneHalkaNo: widget.kus?.anneHalkaNo, // Güncellemede eski değerleri koru
          babaHalkaNo: widget.kus?.babaHalkaNo, // Güncellemede eski değerleri koru
        );
        try {
          await kusProvider.kusGuncelle(guncelKus);
          _gosterSnackBar('Kuş başarıyla güncellendi!');
          if (!mounted) return;
          Navigator.of(context).pop();
        } catch (e) {
          _gosterSnackBar('Kuş güncellenirken hata: ${e.toString()}');
        }
      }
      // Eğer pedigreeEntryProvider'da bir zincir varsa ve _isGuncelleme false ise,
      // bu butona basmak aslında tüm pedigri zincirini kaydetmek anlamına gelir.
      // Bu senaryoda _saveEntirePedigreeChainFromProvider() çağrılacak.
      else if (pedigreeEntryProvider.pendingPedigreeChain.isNotEmpty && !_isGuncelleme) {
        await _saveEntirePedigreeChainFromProvider(); // YENİ: Tüm zinciri kaydet
      }
    } else if (_seciliCinsiyet == null || _seciliCinsiyet!.isEmpty) {
       _gosterSnackBar('Lütfen kuşun cinsiyetini seçiniz.');
    } else {
      _gosterSnackBar('Lütfen tüm zorunlu alanları doğru şekilde doldurunuz.');
    }
  }

  // YENİ METOT: Pedigri zincirini PedigreeEntryProvider üzerinden kaydeder
  Future<void> _saveEntirePedigreeChainFromProvider() async {
    final pedigreeEntryProvider = Provider.of<PedigreeEntryProvider>(context, listen: false);
    if (pedigreeEntryProvider.pendingPedigreeChain.isEmpty) {
      _gosterSnackBar('Kaydedilecek bir pedigri zinciri bulunmuyor.');
      return;
    }
    try {
      await pedigreeEntryProvider.saveEntirePedigreeChain();
      _gosterSnackBar('Tüm pedigri zinciri başarıyla kaydedildi!');
      if (!mounted) return;
      // Zincir kaydedildikten sonra tüm ilgili ekranları kapatıp ana listeye dön.
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      _gosterSnackBar('Pedigri zinciri kaydedilirken hata: ${e.toString()}');
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
                    items: ['Aktif', 'Pasif', 'Satıldı', 'Kayıp', 'Ölen']
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
                  border: const OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                ),
              ),
              const SizedBox(height: 24),

              // Kaydet ve Ebeveyn Ekle butonları için bir satır
              Row(
                children: [
                  Expanded(
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
                  if (!_isGuncelleme) // Sadece yeni kuş eklerken 'Ebeveyn Ekle' butonu görünür
                    const SizedBox(width: 10),
                  if (!_isGuncelleme)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (_formKey.currentState!.validate() && _seciliCinsiyet != null && _seciliCinsiyet!.isNotEmpty) {
                            final pedigreeEntryProvider = Provider.of<PedigreeEntryProvider>(context, listen: false);
                            final String halkaNo = _halkaNoController.text.toUpperCase();
                            final String? isim = _isimController.text.isEmpty ? null : _isimController.text;
                            final String cinsiyet = _seciliCinsiyet!;
                            final String? notlar = _notlarController.text.isEmpty ? null : _notlarController.text;
                            final String? renk = _renkController.text.isEmpty ? null : _renkController.text;
                            final String? genetikHat = _genetikHatController.text.isEmpty ? null : _genetikHatController.text;

                            // Mevcut kuş bilgilerini geçici zincire ekle
                            pedigreeEntryProvider.addEntry(
                              PedigreeNodeData(
                                halkaNo: halkaNo,
                                isim: isim,
                                cinsiyet: cinsiyet,
                                dogumTarihi: _secilenDogumTarihi,
                                renk: renk,
                                genetikHat: genetikHat,
                                notlar: notlar,
                                status: _seciliDurum ?? 'Aktif',
                                isRootBird: true, // Bu, zincirin kökü olan kuş
                              ),
                            );

                            // YENİ: PedigreeFullEntryScreen'e geç
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (ctx) => PedigreeFullEntryScreen(
                                  rootBirdHalkaNo: halkaNo,
                                ),
                              ),
                            ).then((_) {
                              // Geri gelindiğinde zinciri kontrol et ve temizle (eğer kayıt tamamlandıysa)
                              // Eğer pedigreeEntryProvider.pendingPedigreeChain boşsa, tüm zincir kaydedilmiştir.
                              if (pedigreeEntryProvider.pendingPedigreeChain.isEmpty && mounted) {
                                Navigator.of(context).pop(); // Bu ekranı da kapat
                              }
                            });

                          } else {
                            _gosterSnackBar('Lütfen ebeveyn eklemek için kuşun zorunlu bilgilerini doldurunuz.');
                          }
                        },
                        icon: const Icon(Icons.family_restroom),
                        label: const Text('Ebeveyn Ekle'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          backgroundColor: Colors.blueGrey, // Farklı bir renk
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
