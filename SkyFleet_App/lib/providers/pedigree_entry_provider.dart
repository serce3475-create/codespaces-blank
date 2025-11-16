import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:collection/collection.dart'; // firstWhereOrNull için

import '../modeller/kus.dart';
import 'kus_provider.dart';

class PedigreeNodeData {
  final String halkaNo;
  final String? isim;
  final String? cinsiyet;
  final DateTime? dogumTarihi;
  final String? renk;
  final String? genetikHat;
  final String? notlar;
  final String status;

  final String? childHalkaNo; 
  final bool isRootBird; 
  final bool? isFather; 

  PedigreeNodeData({
    required this.halkaNo,
    this.isim,
    this.cinsiyet,
    this.dogumTarihi,
    this.renk,
    this.genetikHat,
    this.notlar,
    required this.status,
    this.childHalkaNo,
    this.isRootBird = false,
    this.isFather,
  });
}

class PedigreeEntryProvider with ChangeNotifier {
  final List<PedigreeNodeData> _pendingPedigreeChain = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  KusProvider? _kusProvider; 

  static const String _appId = String.fromEnvironment('__app_id', defaultValue: 'default-app-id');

  List<PedigreeNodeData> get pendingPedigreeChain => [..._pendingPedigreeChain];

  PedigreeEntryProvider({KusProvider? kusProvider}) : _kusProvider = kusProvider;

  void updateKusProvider(KusProvider kusProvider) {
    _kusProvider = kusProvider;
  }

  void addEntry(PedigreeNodeData entry) {
    final existingIndex = _pendingPedigreeChain.indexWhere(
      (e) => e.halkaNo == entry.halkaNo && e.childHalkaNo == entry.childHalkaNo && e.isFather == entry.isFather,
    );
    if (existingIndex != -1) {
      _pendingPedigreeChain[existingIndex] = entry;
      debugPrint("PedigreeEntryProvider: Girdi güncellendi (Halka No: ${entry.halkaNo})");
    } else {
      _pendingPedigreeChain.add(entry);
      debugPrint("PedigreeEntryProvider: Yeni girdi eklendi (Halka No: ${entry.halkaNo}), Zincir uzunluğu: ${_pendingPedigreeChain.length}");
    }
    notifyListeners();
  }

  void removeLastEntry() {
    if (_pendingPedigreeChain.isNotEmpty) {
      final removed = _pendingPedigreeChain.removeLast();
      debugPrint("PedigreeEntryProvider: Son girdi çıkarıldı: ${removed.halkaNo}, Zincir uzunluğu: ${_pendingPedigreeChain.length}");
      notifyListeners();
    }
  }

  void clearChain() {
    _pendingPedigreeChain.clear();
    debugPrint("PedigreeEntryProvider: Zincir temizlendi.");
    notifyListeners();
  }

  void updateEntry(String targetHalkaNo, PedigreeNodeData updatedEntry) {
    final index = _pendingPedigreeChain.indexWhere(
      (element) => element.halkaNo == targetHalkaNo &&
                   element.childHalkaNo == updatedEntry.childHalkaNo &&
                   element.isFather == updatedEntry.isFather
    );
    if (index != -1) {
      _pendingPedigreeChain[index] = updatedEntry;
      debugPrint("PedigreeEntryProvider: Girdi güncellendi: $targetHalkaNo");
      notifyListeners();
    }
  }

  String? getCurrentBirdHalkaNo() {
    if (_pendingPedigreeChain.isEmpty) return null;
    return _pendingPedigreeChain.last.halkaNo;
  }

  String? getCurrentChildHalkaNoForNewParents() {
    if (_pendingPedigreeChain.isEmpty) return null;
    return _pendingPedigreeChain.last.halkaNo; 
  }

  PedigreeNodeData? get rootBird => _pendingPedigreeChain.firstWhereOrNull((node) => node.isRootBird);

  Future<void> saveEntirePedigreeChain() async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception("Kullanıcı oturumu açık değil. Pedigri zinciri kaydedilemez.");
    }
    final String userId = currentUser.uid;

    if (_kusProvider == null) {
      throw Exception("KusProvider bağımlılığı PedigreeEntryProvider'a sağlanmadı.");
    }

    if (_pendingPedigreeChain.isEmpty) {
      debugPrint("PedigreeEntryProvider: Kaydedilecek Pedigri zinciri boş.");
      return;
    }

    final WriteBatch batch = _firestore.batch();
    
    final Map<String, DocumentReference> halkaNoToDocRefMap = {};

    // İlk döngü: Tüm kuşları/ebeveynleri batch'e set edin ve referanslarını saklayın.
    for (final nodeData in _pendingPedigreeChain) {
      final halkaNo = nodeData.halkaNo;

      if (nodeData.status == 'Aktif') {
        // Aktif kuşlar 'Kuslar' koleksiyonuna kaydedilecek (BÜYÜK K)
        final kusDocRef = _firestore.collection('artifacts').doc(_appId).collection('users').doc(userId).collection('Kuslar').doc(); 
        final newKus = Kus(
          kusId: kusDocRef.id,
          halkaNo: halkaNo,
          isim: nodeData.isim,
          cinsiyet: nodeData.cinsiyet,
          dogumTarihi: nodeData.dogumTarihi,
          kusDurumu: nodeData.status,
          notlar: nodeData.notlar,
          renk: nodeData.renk,
          genetikHat: nodeData.genetikHat,
          anneHalkaNo: null, 
          babaHalkaNo: null, 
        );
        batch.set(kusDocRef, newKus.toMap());
        halkaNoToDocRefMap[halkaNo] = kusDocRef; 
        debugPrint("PedigreeEntryProvider: Aktif kuş batch'e eklendi: $halkaNo, ID: ${kusDocRef.id}");

      } else { // status == 'Pasif'
        // Pasif ebeveynler kullanıcının kendi 'pasifEbeveynler' alt koleksiyonuna kaydedilecek
        final passiveParentDocRef = _firestore.collection('artifacts').doc(_appId).collection('users').doc(userId).collection('pasifEbeveynler').doc(halkaNo); 
        final passiveParentData = {
          'halkaNumarasi': halkaNo,
          'isim': nodeData.isim,
          'cinsiyet': nodeData.cinsiyet,
          'notlar': nodeData.notlar,
          'renk': nodeData.renk,
          'genetikHat': nodeData.genetikHat,
          'fatherId': null, 
          'motherId': null, 
          'creatorId': userId, 
        };
        batch.set(passiveParentDocRef, passiveParentData);
        halkaNoToDocRefMap[halkaNo] = passiveParentDocRef; 
        debugPrint("PedigreeEntryProvider: Pasif ebeveyn batch'e eklendi: $halkaNo (kullanıcıya özel)");
      }
    }

    // İkinci döngü: Anne/baba referanslarını güncelle.
    for (final nodeData in _pendingPedigreeChain) {
      String? childHalkaNo = nodeData.childHalkaNo; 

      if (childHalkaNo != null) { 
        final DocumentReference? childDocRef = halkaNoToDocRefMap[childHalkaNo]; 

        if (childDocRef == null) {
          debugPrint("PedigreeEntryProvider HATA: ChildDocRef (Halka No: $childHalkaNo) haritada bulunamadı.");
          continue; 
        }

        if (nodeData.isFather == true) { 
          // Çocuğun babasının halka nosunu güncelle
          batch.update(childDocRef, {'babaHalkaNo': nodeData.halkaNo}); 
          debugPrint("PedigreeEntryProvider: ${childHalkaNo} belgesinin babaHalkaNo'su ${nodeData.halkaNo} olarak güncellendi.");
        } else if (nodeData.isFather == false) { 
          // Çocuğun annesinin halka nosunu güncelle
          batch.update(childDocRef, {'anneHalkaNo': nodeData.halkaNo}); 
          debugPrint("PedigreeEntryProvider: ${childHalkaNo} belgesinin anneHalkaNo'su ${nodeData.halkaNo} olarak güncellendi.");
        }
      }
    }

    try {
      await batch.commit();
      debugPrint("PedigreeEntryProvider: Pedigri zinciri başarıyla kaydedildi.");
      clearChain(); 
    } catch (e) {
      debugPrint("PedigreeEntryProvider HATA: Pedigri zinciri kaydedilirken hata oluştu: $e");
      rethrow; 
    }
  }

  // Bu metot, saveEntirePedigreeChain içinde kullanılmayacak ancak KusProvider veya
  // başka bir yerde PedigreeEntryProvider dışından bir referans alınmak istenirse
  // aktif kalmasında fayda var. Burayı da güncelleyelim.
  Future<DocumentReference> _getDocRefForHalkaNo(String halkaNo, String userId) async {
    if (_kusProvider == null) {
      throw Exception("KusProvider sağlanmadığı için aktif kuş referansı alınamadı.");
    }

    // Önce kullanıcının kendi aktif kuşları arasında ara (BÜYÜK K ile arama)
    final activeBird = _kusProvider!.tumKuslar.firstWhereOrNull((kus) => kus.halkaNo == halkaNo);

    if (activeBird != null && activeBird.kusId != null) {
      return _firestore.collection('artifacts').doc(_appId).collection('users').doc(userId).collection('Kuslar').doc(activeBird.kusId!);
    }
    
    // Eğer aktif bir kuş değilse, kullanıcının kendi pasif ebeveynleri arasında ara
    final DocumentSnapshot pasifEbeveynDoc = await _firestore.collection('artifacts').doc(_appId).collection('users').doc(userId).collection('pasifEbeveynler').doc(halkaNo).get();
    if (pasifEbeveynDoc.exists) {
      return pasifEbeveynDoc.reference;
    }

    throw Exception("Halka No: $halkaNo için aktif veya pasif kuş referansı bulunamadı.");
  }
}
