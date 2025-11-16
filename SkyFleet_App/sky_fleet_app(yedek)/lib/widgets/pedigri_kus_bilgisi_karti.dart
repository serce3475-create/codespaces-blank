// lib/widgets/pedigri_kus_bilgisi_karti.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Mevcut kullanıcı bilgisini almak için
import '../modeller/kus.dart';
import '../modeller/yaris.dart';
import '../providers/yaris_provider.dart';

class PedigriKusBilgisiKarti extends StatelessWidget {
  final Kus? kus; // Kuş null gelebilir (örneğin kayıtlı ebeveyn yoksa)
  final String? title; // Örneğin "Baba", "Anne". Ana kuş için boş veya null gelebilir.
  final String? prefix; // Ağaç yapısını oluşturmak için görsel önek (örn: "|   +--")
  final double indent; // Girinti miktarı

  const PedigriKusBilgisiKarti({
    super.key,
    required this.kus,
    this.title, // Artık null olabilir
    this.prefix,
    this.indent = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    if (kus == null) {
      // Kuş bilgisi yoksa hiçbir şey gösterme
      return const SizedBox.shrink(); // Boş bir widget döndürerek tamamen gizle
    }

    // Kus'un cinsiyeti bilinmiyorsa varsayılan değer atıyoruz
    final String cinsiyet = kus!.cinsiyet ?? 'Bilinmiyor';
    final IconData cinsiyetIcon = cinsiyet == 'Erkek' ? Icons.male : (cinsiyet == 'Dişi' ? Icons.female : Icons.question_mark);
    final Color cinsiyetColor = cinsiyet == 'Erkek' ? Colors.blue.shade700 : (cinsiyet == 'Dişi' ? Colors.pink.shade700 : Colors.grey);

    // Yarış performansını çekelim
    final yarisProvider = Provider.of<YarisProvider>(context, listen: false);
    final List<Yaris> kusYarislari = yarisProvider.kusunYarisKayitlari(kus!.halkaNo);

    // Yarış performans özetini oluştur
    String? yarisPerformansOzeti;
    if (kusYarislari.isNotEmpty) {
      final int toplamYaris = kusYarislari.length;
      final int dereceAlanYaris = kusYarislari.where((y) => y.derece > 0).length;
      final double toplamMesafe = kusYarislari.fold(0.0, (sum, y) => sum + y.mesafeKm);
      yarisPerformansOzeti = '$toplamYaris yarış, ${toplamMesafe.toStringAsFixed(1)} km, $dereceAlanYaris derece';
    }

    // Yetiştirici Adı (Genetik Hat)
    String? yetistiriciBilgisi;
    if (kus!.genetikHat != null && kus!.genetikHat!.isNotEmpty) {
      yetistiriciBilgisi = 'Genetik Hat: ${kus!.genetikHat!}';
      // TODO: Eğer Kus modelinde 'breederUid' gibi bir alan olursa,
      // bu alana mevcut kullanıcının UID'siyle eşleşip eşleşmediğini kontrol ederek
      // ' (Sizin Kuşunuz)' gibi bir metin eklenebilir.
      // Örneğin:
      // final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
      // if (kus!.breederUid == currentUserUid) {
      //   yetistiriciBilgisi += ' (Sizin Kuşunuz)';
      // }
    }

    // Notlar
    final String? notlar = kus!.notlar != null && kus!.notlar!.isNotEmpty ? kus!.notlar : null;


    return Padding(
      padding: EdgeInsets.only(left: indent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (prefix != null) Text(prefix!, style: const TextStyle(color: Colors.grey, height: 0.8)), // Prefix'in satır yüksekliğini ayarla
          Card(
            margin: EdgeInsets.zero, // Üstteki Padding ile boşluk sağlanacak
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: InkWell( // Kuş detayına gitmek için tıklanabilir yap
              onTap: () {
                // TODO: Kuşa tıklandığında detay ekranına yönlendirme
                // Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => KusDetayEkrani(kus: kus!)));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${kus!.halkaNo} detay ekranına gitme özelliği henüz aktif değil.')),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(cinsiyetIcon, color: cinsiyetColor, size: 18),
                        const SizedBox(width: 4),
                        // Ana kuş için başlık etiketi kaldırıldı
                        if (title != null && title!.isNotEmpty) // Başlık (örn: "Baba") varsa göster
                          Text(
                            '$title: ',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        Expanded(
                          child: Text(
                            '${kus!.halkaNo} - ${kus!.isim ?? 'Bilinmiyor'}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: cinsiyetColor,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 8, thickness: 0.5),

                    if (yetistiriciBilgisi != null) // Sadece bilgi varsa göster
                      Text(yetistiriciBilgisi, style: const TextStyle(fontSize: 12)),

                    if (yarisPerformansOzeti != null) // Sadece bilgi varsa göster
                      Text('Yarış Performansı: $yarisPerformansOzeti', style: const TextStyle(fontSize: 12)),

                    if (notlar != null) // Sadece bilgi varsa göster
                      Text('Notlar: $notlar', style: const TextStyle(fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 4), // Kartlar arası boşluk
        ],
      ),
    );
  }
}
