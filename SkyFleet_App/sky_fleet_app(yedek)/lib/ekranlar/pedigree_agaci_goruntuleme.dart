// lib/ekranlar/pedigree_agaci_goruntuleme.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pedigree_provider.dart';
import '../modeller/pedigree_node.dart';
import 'kus_detay_ekrani.dart'; // Detay ekranına geçiş için

// Sabitler
const double NODE_WIDTH = 120.0;
const double NODE_HEIGHT = 80.0;
const double NODE_MARGIN_VERTICAL = 8.0;

class PedigreeAgaciGoruntuleme extends StatelessWidget {
  final String halkaNo;
  
  const PedigreeAgaciGoruntuleme({super.key, required this.halkaNo});

  @override
  Widget build(BuildContext context) {
    final pedigreeProvider = Provider.of<PedigreeProvider>(context);
    final liste = pedigreeProvider.pedigreeListesi;

    // Veri yükleniyor veya başlangıçta Pedigree Provider henüz hesaplama yapmadıysa
    if (pedigreeProvider.veriYukleniyor && liste.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (liste.isEmpty) {
      return const Center(child: Text('Soy ağacı verisi oluşturulamadı.'));
    }

    // Listeyi seviyelerine göre gruplandır
    final Map<int, List<PedigreeNode>> seviyeyeGoreGruplar = {};
    for (var node in liste) {
      seviyeyeGoreGruplar.putIfAbsent(node.level, () => []).add(node);
    }

    // Yatay kaydırılabilir görünüm için SingleChildScrollView kullanıyoruz
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          // Her seviye (nesil) bir sütun (Column) olarak temsil edilir
          children: seviyeyeGoreGruplar.entries.map((entry) {
            final level = entry.key;
            final nodes = entry.value;

            return _buildPedigreeColumn(context, level, nodes);
          }).toList(),
        ),
      ),
    );
  }

  // Belirli bir seviyedeki (nesildeki) düğümleri oluşturan sütun
  Widget _buildPedigreeColumn(BuildContext context, int level, List<PedigreeNode> nodes) {
    return Container(
      width: NODE_WIDTH + 16, // Düğüm genişliği + biraz boşluk
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        // Düğüm sayısına göre dikey düzenleme (Ortalama)
        mainAxisAlignment: level == 0 ? MainAxisAlignment.center : MainAxisAlignment.spaceEvenly,
        children: nodes.map((node) => _buildPedigreeNode(context, node)).toList(),
      ),
    );
  }

  // Tek bir Pedigree Düğümü (Node) oluşturan bileşen
  Widget _buildPedigreeNode(BuildContext context, PedigreeNode node) {
    final isGecisYapilabilir = !node.isBos;

    return GestureDetector(
      onTap: isGecisYapilabilir
          ? () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => KusDetayEkrani(kusHalkaNo: node.halkaNo),
                ),
              );
            }
          : null,
      child: Container(
        width: NODE_WIDTH,
        height: NODE_HEIGHT,
        margin: const EdgeInsets.symmetric(vertical: NODE_MARGIN_VERTICAL),
        decoration: BoxDecoration(
          color: node.isBos
              ? Colors.grey.shade200
              : node.cinsiyet == 'Erkek'
                  ? Colors.blue.shade100 // Erkek için mavi
                  : node.cinsiyet == 'Dişi'
                      ? Colors.pink.shade100 // Dişi için pembe
                      : Colors.orange.shade100, // Bilinmiyor için turuncu
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: node.isBos ? Colors.grey.shade400 : Theme.of(context).primaryColor,
            width: 2,
          ),
          boxShadow: [
            if (!node.isBos)
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 3,
                offset: const Offset(1, 2),
              ),
          ],
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: node.isBos
                ? const Text(
                    'Bilinmiyor',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        node.isim ?? 'İsimsiz',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Halka: ${node.halkaNo}',
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (node.cinsiyet != null)
                        Text(
                          node.cinsiyet!,
                          style: TextStyle(
                            fontSize: 11,
                            color: node.cinsiyet == 'Erkek' ? Colors.blue.shade800 : Colors.pink.shade800,
                          ),
                        ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}