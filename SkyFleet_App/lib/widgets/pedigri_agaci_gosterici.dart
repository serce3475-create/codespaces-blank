// lib/widgets/pedigri_agaci_gosterici.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../modeller/kus.dart';
import '../providers/pedigree_provider.dart';

class PedigriAgaciGosterici extends StatelessWidget {
  final Kus anaKus;

  const PedigriAgaciGosterici({Key? key, required this.anaKus}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final pedigreeProvider = Provider.of<PedigreeProvider>(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton.icon(
            onPressed: pedigreeProvider.veriYukleniyor
                ? null // PDF oluşturulurken butonu devre dışı bırak
                : () async {
                    if (anaKus.halkaNo != null) {
                      await pedigreeProvider.generateAndSharePedigreePdf(context, anaKus.halkaNo);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(pedigreeProvider.veriYukleniyor ? 'Pedigri oluşturuluyor...' : 'Pedigri PDF oluşturuldu ve paylaşmaya hazır!'),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Hata: Ana kuşun halka numarası bulunamadı.')),
                      );
                    }
                  },
            icon: pedigreeProvider.veriYukleniyor
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.share),
            label: Text(pedigreeProvider.veriYukleniyor ? 'Oluşturuluyor...' : 'Pedigri PDF Oluştur ve Paylaş'),
          ),
        ),
        // PedigriProvider'dan gelen pedigreeListesi'ni görselleştirmek için
        // buraya bir widget ekleyebiliriz. Şimdilik sadece mesaj gösterelim.
        if (pedigreeProvider.veriYukleniyor)
          const Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 10),
                  Text('Pedigri verileri hazırlanıyor ve PDF oluşturuluyor...'),
                ],
              ),
            ),
          )
        else if (pedigreeProvider.pedigreeListesi.isEmpty)
          const Expanded(
            child: Center(
              child: Text('Pedigri oluşturmak için "Pedigri PDF Oluştur ve Paylaş" butonuna tıklayın.'),
            ),
          )
        else
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                // Buraya Pedigri listesini gösterecek başka bir widget gelebilir
                // Şimdilik sadece ilk kuşu ve ebeveynlerini listelemek için basit bir örnek
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Oluşturulan Pedigri Özeti:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ...pedigreeProvider.pedigreeListesi.map((node) {
                      return Text('Seviye ${node.level}: ${node.halkaNo} (${node.isim ?? ''}) - Yarış: ${node.hasRaceEntry ?? false ? "Evet" : "Hayır"}');
                    }).toList(),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
