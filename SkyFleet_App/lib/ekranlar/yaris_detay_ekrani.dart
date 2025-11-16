// lib/ekranlar/yaris_detay_ekrani.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../modeller/yaris.dart';
import '../providers/yaris_provider.dart';
// Yaris ekle/düzenle ekranına yönlendirmek için import edebiliriz
import 'yaris_ekle_ekrani.dart'; 

class YarisDetayEkrani extends StatefulWidget {
  final Yaris yaris;

  const YarisDetayEkrani({super.key, required this.yaris});

  @override
  State<YarisDetayEkrani> createState() => _YarisDetayEkraniState();
}

class _YarisDetayEkraniState extends State<YarisDetayEkrani> {

  // Card içinde detay satırı oluşturan yardımcı widget
  Widget _buildDetailRow(String label, String value, {IconData? icon, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (icon != null) ...[Icon(icon, size: 18, color: Colors.blueGrey), const SizedBox(width: 8)],
              Text(
                '$label:',
                style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.blueGrey),
              ),
            ],
          ),
          Flexible( // Uzun metinler için taşmayı engelle
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: valueColor ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Yarış kaydını silmek için onay diyaloğu
  void _yarisKaydiSilOnay() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Silme Onayı'),
        content: Text('${widget.yaris.yarisAdi} isimli yarış kaydını silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.'),
        actions: <Widget>[
          TextButton(
            child: const Text('İptal'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          ),
          TextButton(
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
            onPressed: () async {
              Navigator.of(ctx).pop(); // Diyalogu kapat
              try {
                await Provider.of<YarisProvider>(context, listen: false).yarisSil(widget.yaris.id);
                if (mounted) {
                  Navigator.of(context).pop(); // Detay ekranını kapat ve önceki ekrana dön
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Yarış kaydı başarıyla silindi!')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Yarış kaydı silinirken hata oluştu: $e')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // KusDetayEkrani'nda olduğu gibi, güncel veriyi dinleyebiliriz,
    // ancak Yaris listesi YarisProvider tarafından tek seferde çekildiği için
    // burada doğrudan widget.yaris objesini kullanmak yeterli olabilir.
    // Eğer YarisProvider'da tek bir yarış kaydını gerçek zamanlı dinleyen bir metot olsaydı,
    // onu kullanırdık. Şimdilik widget.yaris ile devam ediyoruz.
    final yaris = widget.yaris; 

    // Dereceye göre renk belirleyelim
    Color dereceRengi = Colors.blueGrey;
    if (yaris.derece > 0 && yaris.derece < 4) {
      dereceRengi = Colors.green.shade700;
    } else if (yaris.derece == 0) { // Derece yoksa veya DNF (did not finish)
      dereceRengi = Colors.red.shade700;
    }

    // Uçuş süresini okunabilir bir stringe çevir
    String ucusSuresiText = '';
    if (yaris.ucusSuresi.inHours > 0) {
      ucusSuresiText += '${yaris.ucusSuresi.inHours} saat ';
    }
    ucusSuresiText += '${yaris.ucusSuresi.inMinutes.remainder(60)} dakika';
    if (yaris.ucusSuresi.inSeconds.remainder(60) > 0) {
      ucusSuresiText += ' ${yaris.ucusSuresi.inSeconds.remainder(60)} saniye';
    }


    return Scaffold(
      appBar: AppBar(
        title: Text('${yaris.yarisAdi} Detayları'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Yarışı düzenleme ekranına yönlendir
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Yarış düzenleme ekranı henüz implemente edilmedi.')),
              );
              // YarisEkleEkrani'nı düzenleme modunda açmak için
              // Navigator.of(context).push(
              //   MaterialPageRoute(
              //     builder: (ctx) => YarisEkleEkrani(kusHalkaNo: yaris.kusHalkaNo, yaris: yaris), // yaris objesini gönder
              //   ),
              // );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.red),
            onPressed: _yarisKaydiSilOnay,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      yaris.yarisAdi,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                    ),
                    const Divider(height: 20),
                    _buildDetailRow('Kuş Halka No', yaris.kusHalkaNo, icon: Icons.tag),
                    _buildDetailRow('Yarış Tarihi', DateFormat('dd MMMM yyyy').format(yaris.yarisTarihi), icon: Icons.calendar_today),
                    _buildDetailRow('Başlangıç Yeri', yaris.baslangicYeri, icon: Icons.flight_takeoff),
                    _buildDetailRow('Varış Yeri', yaris.varisYeri, icon: Icons.flight_land),
                    _buildDetailRow('Yarış Mesafesi', '${yaris.mesafe.toStringAsFixed(1)} km (Genel)', icon: Icons.route),
                    _buildDetailRow('Kat Edilen Mesafe', '${yaris.mesafeKm.toStringAsFixed(1)} km (Kuş)', icon: Icons.social_distance),
                    _buildDetailRow('Uçuş Süresi', ucusSuresiText, icon: Icons.timer),
                    _buildDetailRow('Konum', yaris.konum, icon: Icons.location_on),
                    _buildDetailRow(
                      'Derece',
                      yaris.derece > 0 ? '${yaris.derece}. Sıra' : 'Derece Yok',
                      icon: Icons.emoji_events,
                      valueColor: dereceRengi,
                    ),
                    if (yaris.notlar != null && yaris.notlar!.isNotEmpty)
                      _buildDetailRow('Notlar', yaris.notlar!, icon: Icons.notes),
                  ],
                ),
              ),
            ),
            // Buraya daha fazla aksiyon veya ilgili bilgi eklenebilir
          ],
        ),
      ),
    );
  }
}
