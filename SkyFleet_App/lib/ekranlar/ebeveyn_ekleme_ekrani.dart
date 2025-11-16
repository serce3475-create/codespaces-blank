// lib/ekranlar/ebeveyn_ekleme_ekrani.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../modeller/kus.dart';
import '../modeller/pasif_ebeveyn.dart';
import '../providers/kus_provider.dart';
import '../widgets/custom_text_form_field.dart'; // Varsayılan CustomTextFormField'ınız

// Her bir ebeveynin form verilerini tutmak için yardımcı sınıf
class ParentFormGroup {
  final TextEditingController halkaNoController = TextEditingController();
  final TextEditingController isimController = TextEditingController();
  final TextEditingController renkController = TextEditingController();
  final TextEditingController genetikHatController = TextEditingController();
  final TextEditingController notlarController = TextEditingController();
  bool isPasif = true; // Varsayılan: Pasif
  String? currentRecordId; // Mevcut kaydın ID'si (Firestore'dan yüklenirse)

  void dispose() {
    halkaNoController.dispose();
    isimController.dispose();
    renkController.dispose();
    genetikHatController.dispose();
    notlarController.dispose();
  }

  // Form grubunun boş olup olmadığını kontrol eder (sadece halka no değil tüm alanları kontrol eder)
  // Bu, bir ebeveyn için hiçbir bilgi girilmediyse null döndürmek için kullanılır.
  bool get isEmpty => halkaNoController.text.isEmpty &&
                       isimController.text.isEmpty &&
                       renkController.text.isEmpty &&
                       genetikHatController.text.isEmpty &&
                       notlarController.text.isEmpty;

  // Halka numarasının girilip girilmediğini kontrol eder
  bool get hasHalkaNo => halkaNoController.text.isNotEmpty;
}

class EbeveynEklemeEkrani extends StatefulWidget {
  final String anaKusId; // Ebeveynlerini eklediğimiz kuşun Firestore ID'si
  final String anaKusHalkaNo; // Ebeveynlerini eklediğimiz kuşun halka numarası

  const EbeveynEklemeEkrani({
    super.key,
    required this.anaKusId,
    required this.anaKusHalkaNo,
  });

  @override
  State<EbeveynEklemeEkrani> createState() => _EbeveynEklemeEkraniState();
}

class _EbeveynEklemeEkraniState extends State<EbeveynEklemeEkrani> {
  final _formKey = GlobalKey<FormState>();

  // Doğrudan ebeveynler (ana kuşun anne ve babası)
  late ParentFormGroup _anneGroup;
  late ParentFormGroup _babaGroup;

  // Büyükanne ve büyükbabalar
  late ParentFormGroup _anneAnneGroup; // Annenin annesi
  late ParentFormGroup _anneBabaGroup; // Annenin babası
  late ParentFormGroup _babaAnneGroup; // Babanın annesi
  late ParentFormGroup _babaBabaGroup; // Babanın babası

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Tüm ParentFormGroup'ları başlat
    _anneGroup = ParentFormGroup();
    _babaGroup = ParentFormGroup();
    _anneAnneGroup = ParentFormGroup();
    _anneBabaGroup = ParentFormGroup();
    _babaAnneGroup = ParentFormGroup();
    _babaBabaGroup = ParentFormGroup();

    _loadExistingPedigree();
  }

  // Mevcut soyağacı bilgilerini yükle (Ana kuşun ebeveynleri ve onların ebeveynleri)
  Future<void> _loadExistingPedigree() async {
    setState(() { _isLoading = true; });
    final provider = Provider.of<KusProvider>(context, listen: false);

    Kus? childBird = provider.kusIdIleKusBul(widget.anaKusId);

    if (childBird != null) {
      // ANNE BİLGİLERİ
      if (childBird.anneId != null && childBird.anneId!.isNotEmpty) {
        await _populateParentGroup(provider, childBird.anneId!, _anneGroup);

        // Annenin ebeveynlerini yükle (Büyükanne/Büyükbaba)
        if (_anneGroup.currentRecordId != null) {
          // Yüklenen annenin kaydını çekerek onun ebeveyn ID'lerini al
          dynamic motherRecord = await provider.getRecordById(_anneGroup.currentRecordId!);
          if (motherRecord != null) {
            final String? motherMotherId = (motherRecord is Kus) ? motherRecord.anneId : (motherRecord is PasifEbeveyn ? motherRecord.anneId : null);
            if (motherMotherId != null && motherMotherId.isNotEmpty) {
              await _populateParentGroup(provider, motherMotherId, _anneAnneGroup);
            }
            final String? motherFatherId = (motherRecord is Kus) ? motherRecord.babaId : (motherRecord is PasifEbeveyn ? motherRecord.babaId : null);
            if (motherFatherId != null && motherFatherId.isNotEmpty) {
              await _populateParentGroup(provider, motherFatherId, _anneBabaGroup);
            }
          }
        }
      }

      // BABA BİLGİLERİ
      if (childBird.babaId != null && childBird.babaId!.isNotEmpty) {
        await _populateParentGroup(provider, childBird.babaId!, _babaGroup);

        // Babanın ebeveynlerini yükle (Büyükanne/Büyükbaba)
        if (_babaGroup.currentRecordId != null) {
          // Yüklenen babanın kaydını çekerek onun ebeveyn ID'lerini al
          dynamic fatherRecord = await provider.getRecordById(_babaGroup.currentRecordId!);
          if (fatherRecord != null) {
            final String? fatherMotherId = (fatherRecord is Kus) ? fatherRecord.anneId : (fatherRecord is PasifEbeveyn ? fatherRecord.anneId : null);
            if (fatherMotherId != null && fatherMotherId.isNotEmpty) {
              await _populateParentGroup(provider, fatherMotherId, _babaAnneGroup);
            }
            final String? fatherFatherId = (fatherRecord is Kus) ? fatherRecord.babaId : (fatherRecord is PasifEbeveyn ? fatherRecord.babaId : null);
            if (fatherFatherId != null && fatherFatherId.isNotEmpty) {
              await _populateParentGroup(provider, fatherFatherId, _babaBabaGroup);
            }
          }
        }
      }
    }
    setState(() { _isLoading = false; });
  }

  // Belirli bir ParentFormGroup'u Firestore'dan gelen verilerle doldurur
  Future<void> _populateParentGroup(KusProvider provider, String recordId, ParentFormGroup group) async {
    final record = await provider.getRecordById(recordId);
    if (record != null) {
      if (record is Kus) {
        group.currentRecordId = record.id; // Record ID'sini kaydet
        group.halkaNoController.text = record.halkaNo;
        group.isimController.text = record.isim ?? '';
        group.renkController.text = record.renk ?? '';
        group.genetikHatController.text = record.genetikHat ?? '';
        group.notlarController.text = record.notlar ?? '';
        group.isPasif = false;
      } else if (record is PasifEbeveyn) {
        group.currentRecordId = record.id; // Record ID'sini kaydet
        group.halkaNoController.text = record.halkaNo;
        group.isimController.text = record.isim ?? '';
        group.renkController.text = record.renk ?? '';
        group.genetikHatController.text = record.genetikHat ?? '';
        group.notlarController.text = record.notlar ?? '';
        group.isPasif = true;
      }
    }
  }


  @override
  void dispose() {
    _anneGroup.dispose();
    _babaGroup.dispose();
    _anneAnneGroup.dispose();
    _anneBabaGroup.dispose();
    _babaAnneGroup.dispose();
    _babaBabaGroup.dispose();
    super.dispose();
  }

  String _getAppBarTitle() {
    return 'Soyağacı Oluştur: ${widget.anaKusHalkaNo}';
  }

  // Tek bir ebeveyni (veya büyükanne/büyükbabanın) kaydeden yardımcı metot
  // `KusProvider.saveOrUpdateSingleParent` metodunu çağırır.
  Future<String?> _saveSingleParentGroup({
    required KusProvider provider,
    required ParentFormGroup parentGroup,
    String? parentMotherId, // Bu ebeveynin annesinin ID'si (örn: annenin annesi için)
    String? parentFatherId, // Bu ebeveynin babasının ID'si (örn: annenin babası için)
    String? cinsiyet, // Kaydedilen kaydın cinsiyeti (örn: 'Dişi', 'Erkek')
  }) async {
    if (parentGroup.isEmpty) {
      return null; // Form grubu boşsa bir şey kaydetme
    }
    if (!parentGroup.hasHalkaNo) {
      // Halka no zorunlu olduğu için hata verilebilir
      throw Exception('Halka Numarası boş bırakılamaz.');
    }

    // provider.saveOrUpdateSingleParent metodu, 'id' verilirse mevcut kaydı günceller,
    // verilmezse veya mevcut ID bulunamazsa 'halkaNo' üzerinden kayıt bulmaya çalışır veya yeni oluşturur.
    return await provider.saveOrUpdateSingleParent(
      id: parentGroup.currentRecordId, // Mevcut ID varsa güncelleme için kullanılır
      halkaNo: parentGroup.halkaNoController.text,
      isPasif: parentGroup.isPasif,
      isim: parentGroup.isimController.text.isNotEmpty ? parentGroup.isimController.text : null,
      renk: parentGroup.renkController.text.isNotEmpty ? parentGroup.renkController.text : null,
      genetikHat: parentGroup.genetikHatController.text.isNotEmpty ? parentGroup.genetikHatController.text : null,
      notlar: parentGroup.notlarController.text.isNotEmpty ? parentGroup.notlarController.text : null,
      anneId: parentMotherId,
      babaId: parentFatherId,
      cinsiyet: cinsiyet, // Cinsiyeti pass et
    );
  }

  Future<void> _saveFullPedigree() async {
    if (!_formKey.currentState!.validate()) {
      _gosterSnackBar('Lütfen tüm zorunlu alanları doldurunuz.');
      return;
    }

    setState(() { _isLoading = true; });

    try {
      final provider = Provider.of<KusProvider>(context, listen: false);

      // 1. En derindeki nesilleri (büyükanne/büyükbaba) kaydet
      String? anneAnneId;
      if (!_anneAnneGroup.isEmpty) {
        anneAnneId = await _saveSingleParentGroup(
            provider: provider,
            parentGroup: _anneAnneGroup,
            cinsiyet: 'Dişi' // Büyükanne için cinsiyet
        );
      }

      String? anneBabaId;
      if (!_anneBabaGroup.isEmpty) {
        anneBabaId = await _saveSingleParentGroup(
            provider: provider,
            parentGroup: _anneBabaGroup,
            cinsiyet: 'Erkek' // Büyükbaba için cinsiyet
        );
      }

      String? babaAnneId;
      if (!_babaAnneGroup.isEmpty) {
        babaAnneId = await _saveSingleParentGroup(
            provider: provider,
            parentGroup: _babaAnneGroup,
            cinsiyet: 'Dişi' // Büyükanne için cinsiyet
        );
      }

      String? babaBabaId;
      if (!_babaBabaGroup.isEmpty) {
        babaBabaId = await _saveSingleParentGroup(
            provider: provider,
            parentGroup: _babaBabaGroup,
            cinsiyet: 'Erkek' // Büyükbaba için cinsiyet
        );
      }

      // 2. Bir önceki nesli (annenin annesi ve babası ID'leri ile anne) kaydet
      String? anneId;
      if (!_anneGroup.isEmpty) {
        anneId = await _saveSingleParentGroup(
          provider: provider,
          parentGroup: _anneGroup,
          parentMotherId: anneAnneId,
          parentFatherId: anneBabaId,
          cinsiyet: 'Dişi', // Anne için cinsiyet
        );
      }

      String? babaId;
      if (!_babaGroup.isEmpty) {
        babaId = await _saveSingleParentGroup(
          provider: provider,
          parentGroup: _babaGroup,
          parentMotherId: babaAnneId,
          parentFatherId: babaBabaId,
          cinsiyet: 'Erkek', // Baba için cinsiyet
        );
      }

      // 3. Ana kuşu (anaKusId) ebeveyn ID'leri ile güncelle
      await provider.updateKusParents(widget.anaKusId, anneId, babaId);

      _gosterSnackBar('Soyağacı bilgileri başarıyla kaydedildi!');
      if (mounted) {
        Navigator.of(context).pop(); // Bir önceki ekrana dön
      }
    } catch (e) {
      _gosterSnackBar('Soyağacı kaydetme hatası: ${e.toString()}');
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  void _gosterSnackBar(String mesaj) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mesaj)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '${widget.anaKusHalkaNo} numaralı kuşun ebeveyn bilgilerini giriniz.',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 24),

                    // ANNE BİLGİLERİ SECTION
                    _buildParentAndGrandparentSection(
                      context: context,
                      title: 'Anne Bilgileri',
                      parentGroup: _anneGroup,
                      genderIcon: Icons.female,
                      grandparentMotherGroup: _anneAnneGroup,
                      grandparentFatherGroup: _anneBabaGroup,
                      grandparentSectionTitle: 'Annenin Ebeveynleri (Büyükanne/Büyükbaba)',
                    ),
                    const SizedBox(height: 32),

                    // BABA BİLGİLERİ SECTION
                    _buildParentAndGrandparentSection(
                      context: context,
                      title: 'Baba Bilgileri',
                      parentGroup: _babaGroup,
                      genderIcon: Icons.male,
                      grandparentMotherGroup: _babaAnneGroup,
                      grandparentFatherGroup: _babaBabaGroup,
                      grandparentSectionTitle: 'Babanın Ebeveynleri (Büyükanne/Büyükbaba)',
                    ),
                    const SizedBox(height: 32),

                    // Aksiyon Butonu (Sadece tek bir kaydet butonu var)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _saveFullPedigree,
                        icon: const Icon(Icons.save),
                        label: const Text('Soyağacı Bilgilerini Kaydet'),
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

  // Ebeveyn ve büyükanne/büyükbaba bölümünü oluşturan yardımcı widget
  Widget _buildParentAndGrandparentSection({
    required BuildContext context,
    required String title,
    required ParentFormGroup parentGroup,
    required IconData genderIcon,
    required ParentFormGroup grandparentMotherGroup,
    required ParentFormGroup grandparentFatherGroup,
    required String grandparentSectionTitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const Divider(),
        const SizedBox(height: 16),
        _buildParentFormFields(
          context: context,
          parentGroup: parentGroup,
          genderIcon: genderIcon,
          isMainParent: true, // Halka no zorunlu
        ),
        const SizedBox(height: 16),
        // Ebeveynin halka numarası girildiğinde veya boş değilse büyükanne/büyükbaba bölümünü göster
        if (parentGroup.hasHalkaNo || !parentGroup.isEmpty)
          ExpansionTile(
            title: Text(grandparentSectionTitle),
            subtitle: const Text('Opsiyonel: Bu ebeveynin anne ve babasını girin.'),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Text('Annesi', style: Theme.of(context).textTheme.titleMedium),
                    const Divider(),
                    _buildParentFormFields(
                      context: context,
                      parentGroup: grandparentMotherGroup,
                      genderIcon: Icons.female,
                      isMainParent: false, // Büyükanne/büyükbaba halka no zorunlu değil
                    ),
                    const SizedBox(height: 24),
                    Text('Babası', style: Theme.of(context).textTheme.titleMedium),
                    const Divider(),
                    _buildParentFormFields(
                      context: context,
                      parentGroup: grandparentFatherGroup,
                      genderIcon: Icons.male,
                      isMainParent: false, // Büyükanne/büyükbaba halka no zorunlu değil
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  // Tek bir ebeveynin (veya büyükanne/büyükbabanın) form alanlarını oluşturan yardımcı widget
  Widget _buildParentFormFields({
    required BuildContext context,
    required ParentFormGroup parentGroup,
    required IconData genderIcon,
    bool isMainParent = false, // Doğrudan ebeveyn mi (halka no zorunlu)
  }) {
    return Column(
      children: [
        CustomTextFormField(
          controller: parentGroup.halkaNoController,
          labelText: isMainParent ? 'Halka No (Zorunlu)' : 'Halka No (Opsiyonel)',
          prefixIcon: genderIcon,
          textCapitalization: TextCapitalization.characters,
          validator: (value) {
            if (isMainParent && (value == null || value.isEmpty)) {
              return 'Halka Numarası boş bırakılamaz.';
            }
            return null;
          },
          onChanged: (value) {
            // Halka numarası değiştiğinde UI'ı yenile, özellikle ExpansionTile görünürlüğü ve detay alanları için
            setState(() {});
          },
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Pasif Kayıt'),
          subtitle: Text(parentGroup.isPasif
              ? 'Bu kayıt ana kuş listesinde görünmeyecek.'
              : 'Bu kayıt ana kuş listesine eklenecek.'),
          value: parentGroup.isPasif,
          onChanged: (value) {
            setState(() {
              parentGroup.isPasif = value;
            });
          },
          secondary: const Icon(Icons.archive),
          activeColor: Theme.of(context).primaryColor,
        ),
        const SizedBox(height: 16),
        // Halka numarası girildiğinde veya boş değilse (yani diğer alanlardan biri doldurulmuşsa) detayları göster
        if (parentGroup.hasHalkaNo || !parentGroup.isEmpty) ...[
          CustomTextFormField(
            controller: parentGroup.isimController,
            labelText: 'İsim (Opsiyonel)',
            prefixIcon: Icons.badge,
          ),
          const SizedBox(height: 16),
          CustomTextFormField(
            controller: parentGroup.renkController,
            labelText: 'Renk (Opsiyonel)',
            prefixIcon: Icons.color_lens,
          ),
          const SizedBox(height: 16),
          CustomTextFormField(
            controller: parentGroup.genetikHatController,
            labelText: 'Genetik Hat (Opsiyonel)',
            prefixIcon: Icons.category,
          ),
          const SizedBox(height: 16),
          CustomTextFormField(
            controller: parentGroup.notlarController,
            labelText: 'Notlar (Opsiyonel)',
            prefixIcon: Icons.notes,
            maxLines: 3,
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}
