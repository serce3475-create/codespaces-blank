import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pedigree_entry_provider.dart'; // Yeni provider'ımız
import '../modeller/kus.dart'; // Kus sınıfını kullanıyoruz (PedigreeNodeData içinde kullanılıyor)
import 'package:intl/intl.dart'; // Tarih formatlama için
import 'package:collection/collection.dart'; // firstWhereOrNull için

class PedigreeParentEntryScreen extends StatefulWidget {
  // Bu ekrana geldiğimizde, hangi kuşun ebeveynlerini eklediğimizi bilmemiz gerekecek.
  // Bu, başlığı dinamik olarak ayarlamak ve doğru ebeveynleri PedigreeEntryProvider'a bağlamak için kullanılacak.
  final String childHalkaNo;
  final bool isRootBirdScreen; // Eğer bu ekran, ana kuşun ebeveynlerini ekliyorsak true olacak
  final bool isFatherEntry; // Eğer bu ekran bir babanın ebeveynleri için açıldıysa true (başlık için)

  const PedigreeParentEntryScreen({
    Key? key,
    required this.childHalkaNo,
    this.isRootBirdScreen = false,
    this.isFatherEntry = false,
  }) : super(key: key);

  @override
  State<PedigreeParentEntryScreen> createState() => _PedigreeParentEntryScreenState();
}

class _PedigreeParentEntryScreenState extends State<PedigreeParentEntryScreen> {
  final _formKey = GlobalKey<FormState>();

  // Baba için kontroller
  final TextEditingController _babaHalkaNoController = TextEditingController();
  final TextEditingController _babaIsimController = TextEditingController();
  final TextEditingController _babaNotlarController = TextEditingController();
  final TextEditingController _babaRenkController = TextEditingController();
  final TextEditingController _babaGenetikHatController = TextEditingController();
  String? _seciliBabaCinsiyet; // 'Erkek' olarak sabit kalmalı, ama yine de var
  String? _seciliBabaDurum;

  // Anne için kontroller
  final TextEditingController _anneHalkaNoController = TextEditingController();
  final TextEditingController _anneIsimController = TextEditingController();
  final TextEditingController _anneNotlarController = TextEditingController();
  final TextEditingController _anneRenkController = TextEditingController();
  final TextEditingController _anneGenetikHatController = TextEditingController();
  String? _seciliAnneCinsiyet; // 'Dişi' olarak sabit kalmalı, ama yine de var
  String? _seciliAnneDurum;

  late PedigreeEntryProvider _pedigreeEntryProvider;

  @override
  void initState() {
    super.initState();
    _seciliBabaCinsiyet = 'Erkek'; // Babanın cinsiyeti erkek olarak sabit
    _seciliAnneCinsiyet = 'Dişi';   // Annenin cinsiyeti dişi olarak sabit

    // Varsayılan durumlar
    _seciliBabaDurum = 'Aktif';
    _seciliAnneDurum = 'Aktif';

    // PedigreeEntryProvider'ı dinlemiyoruz, sadece çağırıyoruz
    _pedigreeEntryProvider = Provider.of<PedigreeEntryProvider>(context, listen: false);

    // Mevcut pendingPedigreeChain'den bu kuşun ebeveynlerini önceden doldur (varsa)
    _loadExistingParentData();
  }

  void _loadExistingParentData() {
    // childHalkaNo'su widget.childHalkaNo olan düğümün babasını ve annesini bul
    // Eğer root kuş ekranı ise, childHalkaNo ana kuşun halka nosu
    final childNodeHalkaNo = widget.childHalkaNo;

    // Babanın HalkaNo'su
    final fatherNode = _pedigreeEntryProvider.pendingPedigreeChain
        .firstWhereOrNull((node) => node.childHalkaNo == childNodeHalkaNo && node.isFather == true);
    if (fatherNode != null) {
      _babaHalkaNoController.text = fatherNode.halkaNo;
      _babaIsimController.text = fatherNode.isim ?? '';
      _babaNotlarController.text = fatherNode.notlar ?? '';
      _babaRenkController.text = fatherNode.renk ?? '';
      _babaGenetikHatController.text = fatherNode.genetikHat ?? '';
      _seciliBabaDurum = fatherNode.status;
    }

    // Annenin HalkaNo'su
    final motherNode = _pedigreeEntryProvider.pendingPedigreeChain
        .firstWhereOrNull((node) => node.childHalkaNo == childNodeHalkaNo && node.isFather == false);
    if (motherNode != null) {
      _anneHalkaNoController.text = motherNode.halkaNo;
      _anneIsimController.text = motherNode.isim ?? '';
      _anneNotlarController.text = motherNode.notlar ?? '';
      _anneRenkController.text = motherNode.renk ?? '';
      _anneGenetikHatController.text = motherNode.genetikHat ?? '';
      _seciliAnneDurum = motherNode.status;
    }
  }


  @override
  void dispose() {
    _babaHalkaNoController.dispose();
    _babaIsimController.dispose();
    _babaNotlarController.dispose();
    _babaRenkController.dispose();
    _babaGenetikHatController.dispose();
    _anneHalkaNoController.dispose();
    _anneIsimController.dispose();
    _anneNotlarController.dispose();
    _anneRenkController.dispose();
    _anneGenetikHatController.dispose();
    super.dispose();
  }

  // Ortak Snackbar gösterim metodu
  void _gosterSnackBar(String mesaj) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mesaj)),
      );
    }
  }

  // Pedigri zincirini PedigreeEntryProvider'a ekleme metodu
  void _addParentsToChain() {
    // Baba bilgilerini ekle/güncelle
    if (_babaHalkaNoController.text.isNotEmpty) {
      final babaNode = PedigreeNodeData(
        halkaNo: _babaHalkaNoController.text.toUpperCase(),
        isim: _babaIsimController.text.isEmpty ? null : _babaIsimController.text,
        cinsiyet: _seciliBabaCinsiyet,
        status: _seciliBabaDurum!,
        notlar: _babaNotlarController.text.isEmpty ? null : _babaNotlarController.text,
        renk: _babaRenkController.text.isEmpty ? null : _babaRenkController.text,
        genetikHat: _babaGenetikHatController.text.isEmpty ? null : _babaGenetikHatController.text,
        childHalkaNo: widget.childHalkaNo,
        isFather: true,
      );
      _pedigreeEntryProvider.addEntry(babaNode); // addEntry zaten güncelleme mantığını içeriyor
    }

    // Anne bilgilerini ekle/güncelle
    if (_anneHalkaNoController.text.isNotEmpty) {
      final anneNode = PedigreeNodeData(
        halkaNo: _anneHalkaNoController.text.toUpperCase(),
        isim: _anneIsimController.text.isEmpty ? null : _anneIsimController.text,
        cinsiyet: _seciliAnneCinsiyet,
        status: _seciliAnneDurum!,
        notlar: _anneNotlarController.text.isEmpty ? null : _anneNotlarController.text,
        renk: _anneRenkController.text.isEmpty ? null : _anneRenkController.text,
        genetikHat: _anneGenetikHatController.text.isEmpty ? null : _anneGenetikHatController.text,
        childHalkaNo: widget.childHalkaNo,
        isFather: false,
      );
      _pedigreeEntryProvider.addEntry(anneNode); // addEntry zaten güncelleme mantığını içeriyor
    }
  }


  // Tüm zinciri kaydetme işlemi
  Future<void> _saveEntirePedigreeChainAndExit() async {
    if (!_formKey.currentState!.validate()) {
      _gosterSnackBar('Lütfen tüm zorunlu alanları doğru şekilde doldurunuz.');
      return;
    }

    _addParentsToChain(); // Mevcut ekranın ebeveynlerini zincire ekle/güncelle

    try {
      await _pedigreeEntryProvider.saveEntirePedigreeChain();
      _gosterSnackBar('Tüm pedigri zinciri başarıyla kaydedildi!');
      if (!mounted) return;
      // Kayıt başarılı olduğunda tüm ekranları kapatıp ana listeye dön
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      _gosterSnackBar('Pedigri zinciri kaydedilirken hata: ${e.toString()}');
    }
  }

  // "Ebeveyn Ekle" butonuna basıldığında açılacak menü
  void _showAddParentMenu(BuildContext ctx) {
    if (!_formKey.currentState!.validate()) {
      _gosterSnackBar('Lütfen ebeveyn eklemek için zorunlu alanları doldurunuz.');
      return;
    }

    _addParentsToChain(); // Mevcut ekranın ebeveynlerini zincire ekle/güncelle

    // Pedigri derinliğini kontrol et
    // Root bird (Level 0), ebeveynleri (Level 1), büyük ebeveynler (Level 2), büyük-büyük ebeveynler (Level 3)
    // Şu anki childHalkaNo'nun zincirdeki yerini bulup level'ını hesaplayalım.
    int currentLevel = 0;
    final rootNode = _pedigreeEntryProvider.pendingPedigreeChain.firstWhereOrNull((node) => node.isRootBird);
    if(rootNode != null) {
      // Zincirdeki her düğümün kendi childHalkaNo'suna göre seviyesini takip etmek karmaşık olabilir.
      // Daha basit bir yaklaşım: pendingPedigreeChain'deki son eklenen düğümün seviyesini tahmin edelim.
      // Ya da widget.isRootBirdScreen'den başlayarak her yeni ekranda level'ı artırabiliriz.
      // Şimdilik sadece bu ekrana recursive olarak kaç kere geldiğimize bağlı olarak bir seviye tahmini yapalım.
      // Daha robust bir seviye kontrolü için PedigreeEntryProvider içinde seviye bilgisi tutulabilir.
    }
    // Örnek: Eğer ana kuşun ebeveynlerini giriyorsak currentLevel = 0'ın ebeveynleri (yani level 1)
    // Bir sonraki ekran açıldığında level 2 olacak, sonra level 3. MAX_PEDIGREE_LEVEL (3)
    // level 3'ün ebeveynleri level 4'tür. Bizim MAX_PEDIGREE_LEVEL constant'ımız 3'tü.
    // Yani level 3'e kadar izin veriyoruz (4. kuşak).
    // Eğer mevcut ekranın babası/annesi için ebeveyn ekleyeceksek, bu kuşların seviyesi 1 artar.
    // Şimdilik basitçe pendingPedigreeChain uzunluğuna göre bir tahmin yapalım:
    // Zincirde root, sonra baba/anne, sonra onların babası/annesi...
    // Mevcut ekrandan önceki zincirdeki en son kuşun halka nosu childHalkaNo.
    // Onun kendi ebeveynlerini eklediğimiz için onların seviyesi +1 olur.

    final String? currentChildNodeHalkaNo = widget.childHalkaNo;
    int depth = _pedigreeEntryProvider.pendingPedigreeChain.where((node) => node.childHalkaNo == currentChildNodeHalkaNo).length;
    // Eğer burası root kuşun ebeveyn ekranı ise depth 0. Bir sonraki ekrana geçerken depth'i artıracağız.
    // Daha güvenilir bir seviye hesaplaması için PedigreeNodeData'ya 'level' veya 'depth' eklenebilir.
    // Şimdilik sabit bir limit kullanalım.

    showModalBottomSheet(
      context: ctx,
      builder: (_) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_babaHalkaNoController.text.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.male),
                title: Text('${_babaHalkaNoController.text.toUpperCase()} (${widget.childHalkaNo} babasının) Ebeveynlerini Ekle'),
                onTap: () {
                  Navigator.of(ctx).pop(); // BottomSheet'i kapat
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => PedigreeParentEntryScreen(
                        childHalkaNo: _babaHalkaNoController.text.toUpperCase(),
                        isFatherEntry: true,
                      ),
                    ),
                  ).then((_) {
                    // Geri gelindiğinde zinciri kontrol et ve temizle (eğer kayıt tamamlandıysa)
                    if (_pedigreeEntryProvider.pendingPedigreeChain.isEmpty && mounted) {
                      Navigator.of(context).popUntil((route) => route.isFirst); // Ana ekrana dön
                    }
                  });
                },
              )
            else
              ListTile(
                leading: const Icon(Icons.male),
                title: const Text('Babanın halka numarasını girerek devam edin.'),
                enabled: false,
              ),
            if (_anneHalkaNoController.text.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.female),
                title: Text('${_anneHalkaNoController.text.toUpperCase()} (${widget.childHalkaNo} annesinin) Ebeveynlerini Ekle'),
                onTap: () {
                  Navigator.of(ctx).pop(); // BottomSheet'i kapat
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => PedigreeParentEntryScreen(
                        childHalkaNo: _anneHalkaNoController.text.toUpperCase(),
                        isFatherEntry: false,
                      ),
                    ),
                  ).then((_) {
                    // Geri gelindiğinde zinciri kontrol et ve temizle (eğer kayıt tamamlandıysa)
                    if (_pedigreeEntryProvider.pendingPedigreeChain.isEmpty && mounted) {
                      Navigator.of(context).popUntil((route) => route.isFirst); // Ana ekrana dön
                    }
                  });
                },
              )
            else
              ListTile(
                leading: const Icon(Icons.female),
                title: const Text('Annenin halka numarasını girerek devam edin.'),
                enabled: false,
              ),
          ],
        );
      },
    );
  }

  // Ekran başlığını dinamik olarak oluşturan getter
  String get _ekranBasligi {
    // pendingPedigreeChain'deki root kuşu bulalım
    final rootBirdHalkaNo = _pedigreeEntryProvider.rootBird?.halkaNo ?? 'Bilinmeyen Kuş';

    if (widget.isRootBirdScreen) {
      return '$rootBirdHalkaNo Ebeveynleri';
    } else {
      String parentType = widget.isFatherEntry ? 'Babasının' : 'Annesinin';
      // widget.childHalkaNo, bu ekranda ebeveynlerini eklediğimiz kuşu temsil eder.
      return '${widget.childHalkaNo} Ebeveynleri ($parentType)';
    }
  }


  @override
  Widget build(BuildContext context) {
    return PopScope( // Android geri tuşu veya iOS kaydırma hareketi için
      canPop: false, // Pop hareketini kontrol edeceğiz
      onPopInvoked: (didPop) {
        if (didPop) return;
        _addParentsToChain(); // Mevcut ekranın ebeveynlerini zincire eklemeden geri git
        Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_ekranBasligi),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              // Geri butonuna basıldığında da onPopInvoked çalışır, ekrana veri ekler.
              // Sonra da Navigator.of(context).pop() çağrılır.
              Navigator.of(context).pop();
            },
          ),
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: <Widget>[
                // *** BABA BİLGİLERİ ***
                const SizedBox(height: 16),
                _buildSectionTitle('Baba Bilgileri'),
                TextFormField(
                  controller: _babaHalkaNoController,
                  decoration: const InputDecoration(
                    labelText: 'Halka No (Zorunlu)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.male),
                  ),
                  textCapitalization: TextCapitalization.characters,
                  validator: (value) {
                    // Eğer anne veya baba boşsa, diğerinin de boş olması validasyon hatası vermemeli
                    // Sadece doldurulduysa zorunlu olmalı.
                    if (value == null || value.isEmpty) {
                      if (_anneHalkaNoController.text.isEmpty) { // Hem anne hem baba boşsa validasyon geçsin
                        return null;
                      } else { // Baba boş ama anne doluysa, baba zorunlu
                        return 'Babanın Halka Numarası boş bırakılamaz.';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _babaIsimController,
                  decoration: const InputDecoration(
                    labelText: 'İsim (Opsiyonel)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Durum (Zorunlu)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.info_outline),
                  ),
                  value: _seciliBabaDurum,
                  items: ['Aktif', 'Pasif', 'Satıldı', 'Kayıp', 'Ölen']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(value: value, child: Text(value));
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _seciliBabaDurum = newValue;
                    });
                  },
                  validator: (value) {
                    if (_babaHalkaNoController.text.isNotEmpty && (value == null || value.isEmpty)) {
                      return 'Lütfen babanın durumunu seçiniz.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _babaRenkController,
                  decoration: const InputDecoration(
                    labelText: 'Renk (Opsiyonel)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.color_lens),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _babaGenetikHatController,
                  decoration: const InputDecoration(
                    labelText: 'Genetik Hat (Opsiyonel)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _babaNotlarController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notlar (Opsiyonel)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.note),
                  ),
                ),
                const SizedBox(height: 32),

                // *** ANNE BİLGİLERİ ***
                _buildSectionTitle('Anne Bilgileri'),
                TextFormField(
                  controller: _anneHalkaNoController,
                  decoration: const InputDecoration(
                    labelText: 'Halka No (Zorunlu)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.female),
                  ),
                  textCapitalization: TextCapitalization.characters,
                  validator: (value) {
                    // Eğer anne veya baba boşsa, diğerinin de boş olması validasyon hatası vermemeli
                    if (value == null || value.isEmpty) {
                      if (_babaHalkaNoController.text.isEmpty) { // Hem anne hem baba boşsa validasyon geçsin
                        return null;
                      } else { // Anne boş ama baba doluysa, anne zorunlu
                        return 'Annenin Halka Numarası boş bırakılamaz.';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _anneIsimController,
                  decoration: const InputDecoration(
                    labelText: 'İsim (Opsiyonel)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Durum (Zorunlu)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.info_outline),
                  ),
                  value: _seciliAnneDurum,
                  items: ['Aktif', 'Pasif', 'Satıldı', 'Kayıp', 'Ölen']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(value: value, child: Text(value));
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _seciliAnneDurum = newValue;
                    });
                  },
                  validator: (value) {
                    if (_anneHalkaNoController.text.isNotEmpty && (value == null || value.isEmpty)) {
                      return 'Lütfen annenin durumunu seçiniz.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _anneRenkController,
                  decoration: const InputDecoration(
                    labelText: 'Renk (Opsiyonel)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.color_lens),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _anneGenetikHatController,
                  decoration: const InputDecoration(
                    labelText: 'Genetik Hat (Opsiyonel)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _anneNotlarController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notlar (Opsiyonel)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.note),
                  ),
                ),
                const SizedBox(height: 24),

                // Butonlar
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _saveEntirePedigreeChainAndExit, // Tüm zinciri kaydet ve çık
                        icon: const Icon(Icons.save),
                        label: const Text('Tüm Pedigriyi Kaydet'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showAddParentMenu(context), // Ebeveyn ekleme menüsünü aç
                        icon: const Icon(Icons.add),
                        label: const Text('Ebeveyn Ekle'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          backgroundColor: Colors.orange, // Farklı bir renk
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Geri Butonu
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // PopScope onPopInvoked'ı çağıracak
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Geri Git'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      side: BorderSide(color: Theme.of(context).primaryColor),
                      foregroundColor: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }
}
