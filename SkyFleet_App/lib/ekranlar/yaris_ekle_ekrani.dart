// lib/ekranlar/yaris_ekle_ekrani.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../modeller/yaris.dart'; // Yeni Yaris modeli
import '../providers/yaris_provider.dart'; // Yeni YarisProvider

class YarisEkleEkrani extends StatefulWidget {
  final String kusHalkaNo;

  const YarisEkleEkrani({Key? key, required this.kusHalkaNo}) : super(key: key);

  @override
  State<YarisEkleEkrani> createState() => _YarisEkleEkraniState();
}

class _YarisEkleEkraniState extends State<YarisEkleEkrani> {
  final _formKey = GlobalKey<FormState>();

  // Form alanları için controller'lar
  final TextEditingController _yarisAdiController = TextEditingController();
  final TextEditingController _baslangicYeriController = TextEditingController();
  final TextEditingController _varisYeriController = TextEditingController();
  final TextEditingController _mesafeController = TextEditingController(); // Bu alan artık 'mesafeKm' için
  final TextEditingController _dereceController = TextEditingController();
  final TextEditingController _notlarController = TextEditingController();

  // Seçim alanları
  DateTime? _yarisTarihi;
  TimeOfDay? _ucusSuresi; // TimeOfDay ile saat ve dakika tutulur

  // Yaris modelindeki 'mesafe' alanı için ayrı bir controller/değer
  // Eğer bu 'mesafe' alanı, Yaris modelindeki genel 'mesafe' ise, ona uygun bir controller eklemelisiniz.
  // Varsayılan olarak şu anki _mesafeController'ı 'mesafeKm' için kullanıyorum.
  // Genel 'mesafe' değeri için bir TextFormField eklemediyseniz, varsayılan bir değer sağlamanız gerekir.
  // Şimdilik 0.0 olarak varsayalım.
  final TextEditingController _genelMesafeController = TextEditingController();


  @override
  void dispose() {
    _yarisAdiController.dispose();
    _baslangicYeriController.dispose();
    _varisYeriController.dispose();
    _mesafeController.dispose(); // mesafeKm
    _dereceController.dispose();
    _notlarController.dispose();
    _genelMesafeController.dispose(); // Yeni eklenen
    super.dispose();
  }

  // Tarih seçiciyi açar
  Future<void> _tarihSec() async {
    final DateTime? alinanTarih = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (alinanTarih != null) {
      setState(() {
        _yarisTarihi = alinanTarih;
      });
    }
  }

  // Süre seçiciyi açar (Hour/Minute)
  Future<void> _sureSec() async {
    final TimeOfDay? secilenSure = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 0, minute: 0),
    );
    if (secilenSure != null) {
      setState(() {
        _ucusSuresi = secilenSure;
      });
    }
  }

  // Kaydetme İşlemi
  void _kaydet() async {
    // Formun ve zorunlu alanların (Tarih/Süre) geçerliliğini kontrol et
    if (_formKey.currentState!.validate() && _yarisTarihi != null && _ucusSuresi != null) {
      final yarisProvider = Provider.of<YarisProvider>(context, listen: false);

      // TimeOfDay'i Duration'a çevir (Sadece saat ve dakikayı kullanıyoruz)
      final Duration ucusSuresiD = Duration(
        hours: _ucusSuresi!.hour,
        minutes: _ucusSuresi!.minute,
      );

      final yeniYarisKaydi = Yaris(
        id: '', // <<<--- HATA DÜZELTİLDİ: Yeni kayıt için boş string atandı. Firestore otomatik ID verecek.
        kusHalkaNo: widget.kusHalkaNo,
        yarisTarihi: _yarisTarihi!,
        yarisAdi: _yarisAdiController.text,
        baslangicYeri: _baslangicYeriController.text,
        varisYeri: _varisYeriController.text,
        mesafe: double.parse(_genelMesafeController.text), // Yaris modelindeki genel 'mesafe' için
        konum: '${_baslangicYeriController.text}-${_varisYeriController.text}', // Konum alanı için baslangic ve varis yeri birleştirildi
        mesafeKm: double.parse(_mesafeController.text), // Yaris modelindeki 'mesafeKm' için
        ucusSuresi: ucusSuresiD,
        derece: int.parse(_dereceController.text),
        notlar: _notlarController.text.isEmpty ? null : _notlarController.text,
      );

      try {
        await yarisProvider.yarisEkle(yeniYarisKaydi);

        if (!mounted) return;
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Yarış kaydı başarıyla eklendi!')),
        );
      } catch (e) {
        // Hata yakalama
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kaydetme hatası: ${e.toString()}')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tüm zorunlu alanları doldurunuz ve tarih/süre seçiniz.')),
      );
    }
  }

  // --- Build Metodu ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.kusHalkaNo} İçin Yarış Kaydı'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Yarış Adı
              TextFormField(
                controller: _yarisAdiController,
                decoration: const InputDecoration(
                  labelText: 'Yarış Adı (Örn: İstanbul Kupası)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.flag),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen yarış adını giriniz';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Başlangıç Yeri
              TextFormField(
                controller: _baslangicYeriController,
                decoration: const InputDecoration(
                  labelText: 'Başlangıç Yeri',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.flight_takeoff),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen başlangıç yerini giriniz';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Varış Yeri
              TextFormField(
                controller: _varisYeriController,
                decoration: const InputDecoration(
                  labelText: 'Varış Yeri',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.flight_land),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen varış yerini giriniz';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Mesafe (Yarışın genel mesafesi, örn: 500km parkur)
              TextFormField(
                controller: _genelMesafeController, // Yeni controller
                decoration: const InputDecoration(
                  labelText: 'Yarışın Genel Mesafesi (km)', // Label güncellendi
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.route), // Icon güncellendi
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                validator: (value) {
                  if (value == null || value.isEmpty || double.tryParse(value) == null) {
                    return 'Geçerli bir genel mesafe (sayı) giriniz';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Mesafe (km) - Kuşun kat ettiği mesafe (mesafeKm)
              TextFormField(
                controller: _mesafeController, // Bu şimdi 'mesafeKm' için
                decoration: const InputDecoration(
                  labelText: 'Kuşun Katettiği Mesafe (km)', // Label güncellendi
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.social_distance),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                validator: (value) {
                  if (value == null || value.isEmpty || double.tryParse(value) == null) {
                    return 'Geçerli bir kat edilen mesafe (sayı) giriniz';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Derece
              TextFormField(
                controller: _dereceController,
                decoration: const InputDecoration(
                  labelText: 'Alınan Derece (Sıra, Derece yoksa 0)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.emoji_events),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty || int.tryParse(value) == null) {
                    return 'Geçerli bir sıralama (tam sayı) giriniz';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Tarih Seçici
              ListTile(
                leading: const Icon(Icons.calendar_today, color: Colors.blueAccent),
                title: const Text('Yarış Tarihi Seç'),
                subtitle: Text(_yarisTarihi == null
                    ? 'Tarih seçilmedi (Zorunlu)'
                    : DateFormat('dd MMMM yyyy').format(_yarisTarihi!),
                    style: const TextStyle(fontWeight: FontWeight.bold)
                ),
                trailing: const Icon(Icons.edit),
                onTap: _tarihSec,
              ),
              const Divider(),

              // Süre Seçici
              ListTile(
                leading: const Icon(Icons.timer, color: Colors.blueAccent),
                title: const Text('Uçuş Süresi Seç (Saat:Dakika)'),
                subtitle: Text(_ucusSuresi == null
                    ? 'Süre seçilmedi (Zorunlu)'
                    : '${_ucusSuresi!.hour} saat ${_ucusSuresi!.minute} dakika',
                    style: const TextStyle(fontWeight: FontWeight.bold)
                ),
                trailing: const Icon(Icons.edit),
                onTap: _sureSec,
              ),
              const Divider(),

              // Notlar
              TextFormField(
                controller: _notlarController,
                decoration: const InputDecoration(
                  labelText: 'Notlar (Hava durumu, kuşun durumu vb. - Opsiyonel)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.notes),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 30),

              // Kaydet Butonu
              ElevatedButton.icon(
                onPressed: _kaydet,
                icon: const Icon(Icons.save),
                label: const Text('Yarış Kaydını Ekle'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
