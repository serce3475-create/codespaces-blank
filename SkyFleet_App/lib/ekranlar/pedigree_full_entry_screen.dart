import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pedigree_entry_provider.dart';
import '../modeller/kus.dart'; // PedigreeNodeData'da kullanılabilir
import 'package:intl/intl.dart'; // Tarih formatlama için
import 'package:collection/collection.dart'; // firstWhereOrNull için

// Bu ekran, ana kuşun ebeveynlerinden başlayarak 4 kuşağa kadar tüm ebeveynleri gireceğimiz yer olacak.
class PedigreeFullEntryScreen extends StatefulWidget {
  final String rootBirdHalkaNo; // Pedigri zincirinin ana kuşunun halka numarası

  const PedigreeFullEntryScreen({
    Key? key,
    required this.rootBirdHalkaNo,
  }) : super(key: key);

  @override
  State<PedigreeFullEntryScreen> createState() => _PedigreeFullEntryScreenState();
}

class _PedigreeFullEntryScreenState extends State<PedigreeFullEntryScreen> {
  final _formKey = GlobalKey<FormState>();

  // Kuşak 2 (Ebeveynler)
  final TextEditingController _fatherHalkaNoController = TextEditingController();
  final TextEditingController _fatherIsimController = TextEditingController();
  String? _fatherStatus;
  final TextEditingController _motherHalkaNoController = TextEditingController();
  final TextEditingController _motherIsimController = TextEditingController();
  String? _motherStatus;

  // Kuşak 3 (Büyük Ebeveynler)
  // Babanın Babası (BB) ve Babanın Annesi (BA)
  final TextEditingController _bbFatherHalkaNoController = TextEditingController();
  final TextEditingController _bbFatherIsimController = TextEditingController();
  String? _bbFatherStatus;
  final TextEditingController _bbMotherHalkaNoController = TextEditingController();
  final TextEditingController _bbMotherIsimController = TextEditingController();
  String? _bbMotherStatus;
  // Annenin Babası (AB) ve Annenin Annesi (AA)
  final TextEditingController _abFatherHalkaNoController = TextEditingController();
  final TextEditingController _abFatherIsimController = TextEditingController();
  String? _abFatherStatus;
  final TextEditingController _abMotherHalkaNoController = TextEditingController();
  final TextEditingController _abMotherIsimController = TextEditingController();
  String? _abMotherStatus;

  // Kuşak 4 (Büyük Büyük Ebeveynler)
  // BB'nin Babası (BBB) ve BB'nin Annesi (BBA)
  final TextEditingController _bbBFatherHalkaNoController = TextEditingController();
  final TextEditingController _bbBFatherIsimController = TextEditingController();
  String? _bbBFatherStatus;
  final TextEditingController _bbBMotherHalkaNoController = TextEditingController();
  final TextEditingController _bbBMotherIsimController = TextEditingController();
  String? _bbBMotherStatus;
  // BA'nın Babası (BAB) ve BA'nın Annesi (BAA)
  final TextEditingController _baBFatherHalkaNoController = TextEditingController();
  final TextEditingController _baBFatherIsimController = TextEditingController();
  String? _baBFatherStatus;
  final TextEditingController _baBMotherHalkaNoController = TextEditingController();
  final TextEditingController _baBMotherIsimController = TextEditingController();
  String? _baBMotherStatus;
  // AB'nin Babası (ABB) ve AB'nin Annesi (ABA)
  final TextEditingController _abBFatherHalkaNoController = TextEditingController();
  final TextEditingController _abBFatherIsimController = TextEditingController();
  String? _abBFatherStatus;
  final TextEditingController _abBMotherHalkaNoController = TextEditingController();
  final TextEditingController _abBMotherIsimController = TextEditingController();
  String? _abBMotherStatus;
  // AA'nın Babası (AAB) ve AA'nın Annesi (AAA)
  final TextEditingController _aaBFatherHalkaNoController = TextEditingController();
  final TextEditingController _aaBFatherIsimController = TextEditingController();
  String? _aaBFatherStatus;
  final TextEditingController _aaBMotherHalkaNoController = TextEditingController();
  final TextEditingController _aaBMotherIsimController = TextEditingController();
  String? _aaBMotherStatus;


  late PedigreeEntryProvider _pedigreeEntryProvider;

  @override
  void initState() {
    super.initState();
    _pedigreeEntryProvider = Provider.of<PedigreeEntryProvider>(context, listen: false);

    // Mevcut geçici zincirdeki verileri yükle (eğer daha önce girilmişse)
    _loadExistingPedigreeData();
  }

  void _loadExistingPedigreeData() {
    // Kök kuş zaten PedigreeEntryProvider'ın zincirinde olmalı, bu ekran için childHalkaNo'su widget.rootBirdHalkaNo'dur.

    // Kuşak 2: Ebeveynler
    _loadParentNode(
      childHalkaNo: widget.rootBirdHalkaNo,
      isFather: true,
      halkaNoController: _fatherHalkaNoController,
      isimController: _fatherIsimController,
      statusSetter: (status) => _fatherStatus = status,
    );
    _loadParentNode(
      childHalkaNo: widget.rootBirdHalkaNo,
      isFather: false,
      halkaNoController: _motherHalkaNoController,
      isimController: _motherIsimController,
      statusSetter: (status) => _motherStatus = status,
    );

    // Kuşak 3: Büyük Ebeveynler
    // Babanın Babası (BB)
    _loadParentNode(
      childHalkaNo: _fatherHalkaNoController.text.toUpperCase(),
      isFather: true,
      halkaNoController: _bbFatherHalkaNoController,
      isimController: _bbFatherIsimController,
      statusSetter: (status) => _bbFatherStatus = status,
    );
    // Babanın Annesi (BA)
    _loadParentNode(
      childHalkaNo: _fatherHalkaNoController.text.toUpperCase(),
      isFather: false,
      halkaNoController: _bbMotherHalkaNoController,
      isimController: _bbMotherIsimController,
      statusSetter: (status) => _bbMotherStatus = status,
    );
    // Annenin Babası (AB)
    _loadParentNode(
      childHalkaNo: _motherHalkaNoController.text.toUpperCase(),
      isFather: true,
      halkaNoController: _abFatherHalkaNoController,
      isimController: _abFatherIsimController,
      statusSetter: (status) => _abFatherStatus = status,
    );
    // Annenin Annesi (AA)
    _loadParentNode(
      childHalkaNo: _motherHalkaNoController.text.toUpperCase(),
      isFather: false,
      halkaNoController: _abMotherHalkaNoController,
      isimController: _abMotherIsimController,
      statusSetter: (status) => _abMotherStatus = status,
    );

    // Kuşak 4: Büyük Büyük Ebeveynler
    // BB'nin Babası (BBB)
    _loadParentNode(
      childHalkaNo: _bbFatherHalkaNoController.text.toUpperCase(),
      isFather: true,
      halkaNoController: _bbBFatherHalkaNoController,
      isimController: _bbBFatherIsimController,
      statusSetter: (status) => _bbBFatherStatus = status,
    );
    // BB'nin Annesi (BBA)
    _loadParentNode(
      childHalkaNo: _bbFatherHalkaNoController.text.toUpperCase(),
      isFather: false,
      halkaNoController: _bbBMotherHalkaNoController,
      isimController: _bbBMotherIsimController,
      statusSetter: (status) => _bbBMotherStatus = status,
    );
    // BA'nın Babası (BAB)
    _loadParentNode(
      childHalkaNo: _bbMotherHalkaNoController.text.toUpperCase(),
      isFather: true,
      halkaNoController: _baBFatherHalkaNoController,
      isimController: _baBFatherIsimController,
      statusSetter: (status) => _baBFatherStatus = status,
    );
    // BA'nın Annesi (BAA)
    _loadParentNode(
      childHalkaNo: _bbMotherHalkaNoController.text.toUpperCase(),
      isFather: false,
      halkaNoController: _baBMotherHalkaNoController,
      isimController: _baBMotherIsimController,
      statusSetter: (status) => _baBMotherStatus = status,
    );
    // AB'nin Babası (ABB)
    _loadParentNode(
      childHalkaNo: _abFatherHalkaNoController.text.toUpperCase(),
      isFather: true,
      halkaNoController: _abBFatherHalkaNoController,
      isimController: _abBFatherIsimController,
      statusSetter: (status) => _abBFatherStatus = status,
    );
    // AB'nin Annesi (ABA)
    _loadParentNode(
      childHalkaNo: _abFatherHalkaNoController.text.toUpperCase(),
      isFather: false,
      halkaNoController: _abBMotherHalkaNoController,
      isimController: _abBMotherIsimController,
      statusSetter: (status) => _abBMotherStatus = status,
    );
    // AA'nın Babası (AAB)
    _loadParentNode(
      childHalkaNo: _abMotherHalkaNoController.text.toUpperCase(),
      isFather: true,
      halkaNoController: _aaBFatherHalkaNoController,
      isimController: _aaBFatherIsimController,
      statusSetter: (status) => _aaBFatherStatus = status,
    );
    // AA'nın Annesi (AAA)
    _loadParentNode(
      childHalkaNo: _abMotherHalkaNoController.text.toUpperCase(),
      isFather: false,
      halkaNoController: _aaBMotherHalkaNoController,
      isimController: _aaBMotherIsimController,
      statusSetter: (status) => _aaBMotherStatus = status,
    );
  }

  void _loadParentNode({
    required String childHalkaNo,
    required bool isFather,
    required TextEditingController halkaNoController,
    required TextEditingController isimController,
    required Function(String?) statusSetter,
  }) {
    if (childHalkaNo.isEmpty) return; // Eğer çocuk HalkaNo boşsa yükleme yapma

    final node = _pedigreeEntryProvider.pendingPedigreeChain.firstWhereOrNull(
      (n) => n.childHalkaNo == childHalkaNo && n.isFather == isFather,
    );
    if (node != null) {
      halkaNoController.text = node.halkaNo;
      isimController.text = node.isim ?? '';
      statusSetter(node.status);
    }
  }

  @override
  void dispose() {
    _fatherHalkaNoController.dispose();
    _fatherIsimController.dispose();
    _motherHalkaNoController.dispose();
    _motherIsimController.dispose();

    _bbFatherHalkaNoController.dispose();
    _bbFatherIsimController.dispose();
    _bbMotherHalkaNoController.dispose();
    _bbMotherIsimController.dispose();
    _abFatherHalkaNoController.dispose();
    _abFatherIsimController.dispose();
    _abMotherHalkaNoController.dispose();
    _abMotherIsimController.dispose();

    _bbBFatherHalkaNoController.dispose();
    _bbBFatherIsimController.dispose();
    _bbBMotherHalkaNoController.dispose();
    _bbBMotherIsimController.dispose();
    _baBFatherHalkaNoController.dispose();
    _baBFatherIsimController.dispose();
    _baBMotherHalkaNoController.dispose();
    _baBMotherIsimController.dispose();
    _abBFatherHalkaNoController.dispose();
    _abBFatherIsimController.dispose();
    _abBMotherHalkaNoController.dispose();
    _abBMotherIsimController.dispose();
    _aaBFatherHalkaNoController.dispose();
    _aaBFatherIsimController.dispose();
    _aaBMotherHalkaNoController.dispose();
    _aaBMotherIsimController.dispose();
    super.dispose();
  }

  void _gosterSnackBar(String mesaj) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mesaj)),
      );
    }
  }

  void _saveFullPedigree() async {
    if (!_formKey.currentState!.validate()) {
      _gosterSnackBar('Lütfen tüm zorunlu alanları doğru şekilde doldurunuz.');
      return;
    }

    // Mevcut ekrandaki tüm ebeveyn bilgilerini PedigreeEntryProvider'a ekle/güncelle
    _addPedigreeToChain();

    try {
      await _pedigreeEntryProvider.saveEntirePedigreeChain();
      _gosterSnackBar('Tüm pedigri zinciri başarıyla kaydedildi!');
      if (!mounted) return;
      // Pedigri önizlemesi yerine doğrudan ana kuşlar sayfasına dön
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      _gosterSnackBar('Pedigri zinciri kaydedilirken hata: ${e.toString()}');
    }
  }

  void _addPedigreeToChain() {
    // Kuşak 2 (Ebeveynler)
    _addParentNodeToChain(
      halkaNoController: _fatherHalkaNoController,
      isimController: _fatherIsimController,
      cinsiyet: 'Erkek',
      status: _fatherStatus,
      childHalkaNo: widget.rootBirdHalkaNo,
      isFather: true,
    );
    _addParentNodeToChain(
      halkaNoController: _motherHalkaNoController,
      isimController: _motherIsimController,
      cinsiyet: 'Dişi',
      status: _motherStatus,
      childHalkaNo: widget.rootBirdHalkaNo,
      isFather: false,
    );

    // Kuşak 3 (Büyük Ebeveynler)
    _addParentNodeToChain(
      halkaNoController: _bbFatherHalkaNoController,
      isimController: _bbFatherIsimController,
      cinsiyet: 'Erkek',
      status: _bbFatherStatus,
      childHalkaNo: _fatherHalkaNoController.text.toUpperCase(),
      isFather: true,
    );
    _addParentNodeToChain(
      halkaNoController: _bbMotherHalkaNoController,
      isimController: _bbMotherIsimController,
      cinsiyet: 'Dişi',
      status: _bbMotherStatus,
      childHalkaNo: _fatherHalkaNoController.text.toUpperCase(),
      isFather: false,
    );
    _addParentNodeToChain(
      halkaNoController: _abFatherHalkaNoController,
      isimController: _abFatherIsimController,
      cinsiyet: 'Erkek',
      status: _abFatherStatus,
      childHalkaNo: _motherHalkaNoController.text.toUpperCase(),
      isFather: true,
    );
    _addParentNodeToChain(
      halkaNoController: _abMotherHalkaNoController,
      isimController: _abMotherIsimController,
      cinsiyet: 'Dişi',
      status: _abMotherStatus,
      childHalkaNo: _motherHalkaNoController.text.toUpperCase(),
      isFather: false,
    );

    // Kuşak 4 (Büyük Büyük Ebeveynler)
    _addParentNodeToChain(
      halkaNoController: _bbBFatherHalkaNoController,
      isimController: _bbBFatherIsimController,
      cinsiyet: 'Erkek',
      status: _bbBFatherStatus,
      childHalkaNo: _bbFatherHalkaNoController.text.toUpperCase(),
      isFather: true,
    );
    _addParentNodeToChain(
      halkaNoController: _bbBMotherHalkaNoController,
      isimController: _bbBMotherIsimController,
      cinsiyet: 'Dişi',
      status: _bbBMotherStatus,
      childHalkaNo: _bbFatherHalkaNoController.text.toUpperCase(),
      isFather: false,
    );
    _addParentNodeToChain(
      halkaNoController: _baBFatherHalkaNoController,
      isimController: _baBFatherIsimController,
      cinsiyet: 'Erkek',
      status: _baBFatherStatus,
      childHalkaNo: _bbMotherHalkaNoController.text.toUpperCase(),
      isFather: true,
    );
    _addParentNodeToChain(
      halkaNoController: _baBMotherHalkaNoController,
      isimController: _baBMotherIsimController,
      cinsiyet: 'Dişi',
      status: _baBMotherStatus,
      childHalkaNo: _bbMotherHalkaNoController.text.toUpperCase(),
      isFather: false,
    );
    _addParentNodeToChain(
      halkaNoController: _abBFatherHalkaNoController,
      isimController: _abBFatherIsimController,
      cinsiyet: 'Erkek',
      status: _abBFatherStatus,
      childHalkaNo: _abFatherHalkaNoController.text.toUpperCase(),
      isFather: true,
    );
    _addParentNodeToChain(
      halkaNoController: _abBMotherHalkaNoController,
      isimController: _abBMotherIsimController,
      cinsiyet: 'Dişi',
      status: _abBMotherStatus,
      childHalkaNo: _abFatherHalkaNoController.text.toUpperCase(),
      isFather: false,
    );
    _addParentNodeToChain(
      halkaNoController: _aaBFatherHalkaNoController,
      isimController: _aaBFatherIsimController,
      cinsiyet: 'Erkek',
      status: _aaBFatherStatus,
      childHalkaNo: _abMotherHalkaNoController.text.toUpperCase(),
      isFather: true,
    );
    _addParentNodeToChain(
      halkaNoController: _aaBMotherHalkaNoController,
      isimController: _aaBMotherIsimController,
      cinsiyet: 'Dişi',
      status: _aaBMotherStatus,
      childHalkaNo: _abMotherHalkaNoController.text.toUpperCase(),
      isFather: false,
    );
  }

  void _addParentNodeToChain({
    required TextEditingController halkaNoController,
    required TextEditingController isimController,
    required String cinsiyet,
    required String? status,
    required String childHalkaNo,
    required bool isFather,
  }) {
    if (halkaNoController.text.isNotEmpty) {
      _pedigreeEntryProvider.addEntry(
        PedigreeNodeData(
          halkaNo: halkaNoController.text.toUpperCase(),
          isim: isimController.text.isEmpty ? null : isimController.text,
          cinsiyet: cinsiyet,
          status: status ?? 'Aktif',
          childHalkaNo: childHalkaNo,
          isFather: isFather,
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _addPedigreeToChain(); // Geri giderken de mevcut verileri zincire ekle
        Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('${widget.rootBirdHalkaNo} Pedigri Girişi'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Kuşak 2: Ebeveynler
                _buildSectionTitle(context, 'Kuşak 2: Ebeveynler'),
                _buildParentEntryFields(
                  halkaNoController: _fatherHalkaNoController,
                  isimController: _fatherIsimController,
                  status: _fatherStatus,
                  onStatusChanged: (value) => setState(() => _fatherStatus = value),
                  isFather: true,
                  parentOfHalkaNo: widget.rootBirdHalkaNo,
                  level: 2,
                ),
                _buildParentEntryFields(
                  halkaNoController: _motherHalkaNoController,
                  isimController: _motherIsimController,
                  status: _motherStatus,
                  onStatusChanged: (value) => setState(() => _motherStatus = value),
                  isFather: false,
                  parentOfHalkaNo: widget.rootBirdHalkaNo,
                  level: 2,
                ),
                const SizedBox(height: 24),

                // Kuşak 3: Büyük Ebeveynler
                _buildSectionTitle(context, 'Kuşak 3: Büyük Ebeveynler'),
                // Babanın Ebeveynleri (BB, BA)
                _buildParentEntryFields(
                  halkaNoController: _bbFatherHalkaNoController,
                  isimController: _bbFatherIsimController,
                  status: _bbFatherStatus,
                  onStatusChanged: (value) => setState(() => _bbFatherStatus = value),
                  isFather: true,
                  parentOfHalkaNo: _fatherHalkaNoController.text.toUpperCase(),
                  level: 3,
                ),
                _buildParentEntryFields(
                  halkaNoController: _bbMotherHalkaNoController,
                  isimController: _bbMotherIsimController,
                  status: _bbMotherStatus,
                  onStatusChanged: (value) => setState(() => _bbMotherStatus = value),
                  isFather: false,
                  parentOfHalkaNo: _fatherHalkaNoController.text.toUpperCase(),
                  level: 3,
                ),
                const SizedBox(height: 16),
                // Annenin Ebeveynleri (AB, AA)
                _buildParentEntryFields(
                  halkaNoController: _abFatherHalkaNoController,
                  isimController: _abFatherIsimController,
                  status: _abFatherStatus,
                  onStatusChanged: (value) => setState(() => _abFatherStatus = value),
                  isFather: true,
                  parentOfHalkaNo: _motherHalkaNoController.text.toUpperCase(),
                  level: 3,
                ),
                _buildParentEntryFields(
                  halkaNoController: _abMotherHalkaNoController,
                  isimController: _abMotherIsimController,
                  status: _abMotherStatus,
                  onStatusChanged: (value) => setState(() => _abMotherStatus = value),
                  isFather: false,
                  parentOfHalkaNo: _motherHalkaNoController.text.toUpperCase(),
                  level: 3,
                ),
                const SizedBox(height: 24),

                // Kuşak 4: Büyük Büyük Ebeveynler
                _buildSectionTitle(context, 'Kuşak 4: Büyük Büyük Ebeveynler'),
                // Babanın Babasının Ebeveynleri (BBB, BBA)
                _buildParentEntryFields(
                  halkaNoController: _bbBFatherHalkaNoController,
                  isimController: _bbBFatherIsimController,
                  status: _bbBFatherStatus,
                  onStatusChanged: (value) => setState(() => _bbBFatherStatus = value),
                  isFather: true,
                  parentOfHalkaNo: _bbFatherHalkaNoController.text.toUpperCase(),
                  level: 4,
                ),
                _buildParentEntryFields(
                  halkaNoController: _bbBMotherHalkaNoController,
                  isimController: _bbBMotherIsimController,
                  status: _bbBMotherStatus,
                  onStatusChanged: (value) => setState(() => _bbBMotherStatus = value),
                  isFather: false,
                  parentOfHalkaNo: _bbFatherHalkaNoController.text.toUpperCase(),
                  level: 4,
                ),
                const SizedBox(height: 16),
                // Babanın Annesinin Ebeveynleri (BAB, BAA)
                _buildParentEntryFields(
                  halkaNoController: _baBFatherHalkaNoController,
                  isimController: _baBFatherIsimController,
                  status: _baBFatherStatus,
                  onStatusChanged: (value) => setState(() => _baBFatherStatus = value),
                  isFather: true,
                  parentOfHalkaNo: _bbMotherHalkaNoController.text.toUpperCase(),
                  level: 4,
                ),
                _buildParentEntryFields(
                  halkaNoController: _baBMotherHalkaNoController,
                  isimController: _baBMotherIsimController,
                  status: _baBMotherStatus,
                  onStatusChanged: (value) => setState(() => _baBMotherStatus = value),
                  isFather: false,
                  parentOfHalkaNo: _bbMotherHalkaNoController.text.toUpperCase(),
                  level: 4,
                ),
                const SizedBox(height: 16),
                // Annenin Babasının Ebeveynleri (ABB, ABA)
                _buildParentEntryFields(
                  halkaNoController: _abBFatherHalkaNoController,
                  isimController: _abBFatherIsimController,
                  status: _abBFatherStatus,
                  onStatusChanged: (value) => setState(() => _abBFatherStatus = value),
                  isFather: true,
                  parentOfHalkaNo: _abFatherHalkaNoController.text.toUpperCase(),
                  level: 4,
                ),
                _buildParentEntryFields(
                  halkaNoController: _abBMotherHalkaNoController,
                  isimController: _abBMotherIsimController,
                  status: _abBMotherStatus,
                  onStatusChanged: (value) => setState(() => _abBMotherStatus = value),
                  isFather: false,
                  parentOfHalkaNo: _abFatherHalkaNoController.text.toUpperCase(),
                  level: 4,
                ),
                const SizedBox(height: 16),
                // Annenin Annesinin Ebeveynleri (AAB, AAA)
                _buildParentEntryFields(
                  halkaNoController: _aaBFatherHalkaNoController,
                  isimController: _aaBFatherIsimController,
                  status: _aaBFatherStatus,
                  onStatusChanged: (value) => setState(() => _aaBFatherStatus = value),
                  isFather: true,
                  parentOfHalkaNo: _abMotherHalkaNoController.text.toUpperCase(),
                  level: 4,
                ),
                _buildParentEntryFields(
                  halkaNoController: _aaBMotherHalkaNoController,
                  isimController: _aaBMotherIsimController,
                  status: _aaBMotherStatus,
                  onStatusChanged: (value) => setState(() => _aaBMotherStatus = value),
                  isFather: false,
                  parentOfHalkaNo: _abMotherHalkaNoController.text.toUpperCase(),
                  level: 4,
                ),
                const SizedBox(height: 24),

                // Kaydet Butonu
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saveFullPedigree,
                    icon: const Icon(Icons.save),
                    label: const Text('Tüm Pedigriyi Kaydet'),
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
      ),
    );
  }

  // Yardımcı widget: Ebeveyn giriş alanlarını oluşturur
  Widget _buildParentEntryFields({
    required TextEditingController halkaNoController,
    required TextEditingController isimController,
    required String? status,
    required ValueChanged<String?> onStatusChanged,
    required bool isFather,
    required String parentOfHalkaNo, // Hangi kuşun ebeveyni olduğunu belirtir
    required int level, // Hangi kuşakta olduğunu belirtir
    TextEditingController? renkController, // Opsiyonel
    TextEditingController? genetikHatController, // Opsiyonel
    TextEditingController? notlarController, // Opsiyonel
  }) {
    // Sadece parentOfHalkaNo boş DEĞİLSE bu alanı göster
    // Bu, formda gereksiz alanların görünmesini engeller
    if (parentOfHalkaNo.isEmpty) {
      return const SizedBox.shrink(); // Boş widget döndür
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${isFather ? 'Baba' : 'Anne'} Bilgileri (Ebeveyn: ${parentOfHalkaNo})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: halkaNoController,
              decoration: InputDecoration(
                labelText: 'Halka No (Opsiyonel)',
                border: const OutlineInputBorder(),
                prefixIcon: Icon(isFather ? Icons.male : Icons.female),
              ),
              textCapitalization: TextCapitalization.characters,
              validator: (value) {
                // Halka No girilmişse Durum seçimi zorunlu
                if (value != null && value.isNotEmpty && (status == null || status.isEmpty)) {
                  return 'Halka No girildiyse durum seçimi zorunludur.';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: isimController,
              decoration: const InputDecoration(
                labelText: 'İsim (Opsiyonel)',
                border: const OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Durum (Opsiyonel)',
                border: const OutlineInputBorder(),
                prefixIcon: Icon(Icons.info_outline),
              ),
              value: status,
              items: ['Aktif', 'Pasif', 'Satıldı', 'Kayıp', 'Ölen']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(value: value, child: Text(value));
              }).toList(),
              onChanged: onStatusChanged,
              validator: (value) {
                // Durum seçilmişse Halka No zorunlu
                if (value != null && value.isNotEmpty && (halkaNoController.text.isEmpty)) {
                  return 'Durum seçildiyse Halka No girilmesi zorunludur.';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }
}
