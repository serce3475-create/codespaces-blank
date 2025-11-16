// lib/ekranlar/istatistik_ekrani.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/kus_provider.dart';
import '../providers/yaris_provider.dart';
import '../modeller/kus.dart'; // Kus modelini kullanıyor

class IstatistikEkrani extends StatelessWidget {
  const IstatistikEkrani({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Providers
    final kusProvider = Provider.of<KusProvider>(context);
    final yarisProvider = Provider.of<YarisProvider>(context);

    // Kuş İstatistikleri (YENİ GETTER'LAR KULLANILDI)
    // KusProvider'dan gelen tumKuslarIstatistik getter'ını kullanıyoruz
    final toplamKus = kusProvider.tumKuslarIstatistik.length;
    final erkekKusSayisi = kusProvider.erkekKuslarIstatistik.length;
    final disiKusSayisi = kusProvider.disiKuslarIstatistik.length;
    final yavruSayisi = kusProvider.yavrularIstatistik.length;

    // Yarış İstatistikleri
    final toplamYarisSayisi = yarisProvider.tumYarisKayitlari.length;
    // Derecesi 0'dan büyük olan kayıtlar.
    // Ancak Yarış modelinizde 'derece' alanı varsa bu şekilde kullanılabilir.
    // Yoksa YarisProvider'daki 'tumYarisKayitlari' içindeki Yaris objelerinin
    // hangi özelliğine bakacağınızı belirtmeniz gerekir.
    // Şimdilik varsayımsal olarak 'derece' alanı olduğunu kabul ediyoruz.
    final toplamKazanilanDerece = yarisProvider.tumYarisKayitlari
        .where((kayit) => kayit.derece > 0)
        .length;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // --- KUŞ ENVANTER İSTATİSTİKLERİ ---
            const Text(
              'Envanter Durumu',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueGrey),
            ),
            const Divider(thickness: 2, color: Colors.blueGrey),

            _buildStatisticCard(
              icon: Icons.group_work,
              title: 'Toplam Güvercin Sayısı',
              value: toplamKus.toString(),
              color: Colors.indigo,
            ),
            _buildStatisticCard(
              icon: Icons.male,
              title: 'Erkek',
              value: erkekKusSayisi.toString(),
              color: Colors.lightBlue,
            ),
            _buildStatisticCard(
              icon: Icons.female,
              title: 'Dişi',
              value: disiKusSayisi.toString(),
              color: Colors.pink,
            ),
            _buildStatisticCard(
              icon: Icons.child_friendly,
              title: 'Yavru', // Yavru tanımı KusProvider'daki yavrularIstatistik getter'ına bağlı
              value: yavruSayisi.toString(),
              color: Colors.green,
            ),

            // --- YARIŞ PERFORMANS İSTATİSTİKLERİ ---
            const SizedBox(height: 30),
            const Text(
              'Yarış Performansı',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueGrey),
            ),
            const Divider(thickness: 2, color: Colors.blueGrey),

            _buildStatisticCard(
              icon: Icons.flag,
              title: 'Tamamlanan Yarış Sayısı',
              value: toplamYarisSayisi.toString(),
              color: Colors.deepOrange,
            ),
            _buildStatisticCard(
              icon: Icons.emoji_events,
              title: 'Derece Kazanan Yarış Sayısı', // Metin güncellendi
              value: toplamKazanilanDerece.toString(),
              color: Colors.amber.shade700,
            ),

            // --- DETAYLI DURUM DAĞILIMI ---
            const SizedBox(height: 30),
            const Text(
              'Detaylı Durum Dağılımı',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueGrey),
            ),
            const Divider(thickness: 2, color: Colors.blueGrey),

            // tumKuslarIstatistik getter'ını kullanarak doğru veriyi gönderiyoruz
            ..._buildStatusStats(kusProvider.tumKuslarIstatistik),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: color.withOpacity(0.4), width: 1),
      ),
      margin: const EdgeInsets.only(bottom: 15),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
        child: Row(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.black87)
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildStatusStats(List<Kus> kuslar) {
    final statusMap = <String, int>{};
    for (var kus in kuslar) {
      final durum = kus.kusDurumu ?? 'Bilinmeyen';
      statusMap[durum] = (statusMap[durum] ?? 0) + 1;
    }

    return statusMap.entries.map((entry) {
      Color renk;
      IconData durumIkon;
      switch (entry.key) {
        case 'Aktif':
          renk = Colors.lightGreen.shade700;
          durumIkon = Icons.check_circle_outline;
          break;
        case 'Pasif':
          renk = Colors.orange.shade700;
          durumIkon = Icons.pause_circle_outline;
          break;
        case 'Öldü': // "Ölen" durumu yerine "Öldü" kullanılmış gibi görünüyor, Kus modelinizle tutarlı hale getirin.
          renk = Colors.red.shade700;
          durumIkon = Icons.dangerous_outlined;
          break;
        case 'Kayıp':
          renk = Colors.grey.shade600;
          durumIkon = Icons.help_outline;
          break;
        case 'Satıldı':
          renk = Colors.brown;
          durumIkon = Icons.sell_outlined;
          break;
        case 'Vefat': // "Ölen" ile aynı olabilir, Kus modelinizle tutarlı hale getirin.
          renk = Colors.black;
          durumIkon = Icons.hourglass_disabled_outlined;
          break;
        default:
          renk = Colors.blueGrey;
          durumIkon = Icons.circle_outlined;
      }

      return Card(
        elevation: 1,
        margin: const EdgeInsets.symmetric(vertical: 6.0),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(durumIkon, color: renk, size: 18),
                  const SizedBox(width: 10),
                  Text(entry.key, style: TextStyle(fontSize: 16, color: renk, fontWeight: FontWeight.w500)),
                ],
              ),
              Text(entry.value.toString(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: renk)),
            ],
          ),
        ),
      );
    }).toList();
  }
}
