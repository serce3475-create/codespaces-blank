import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/kullanici_provider.dart';
import '../modeller/kullanici.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Mevcut kullanıcının email'i için

class KullaniciProfilEkrani extends StatefulWidget {
  const KullaniciProfilEkrani({super.key});

  @override
  State<KullaniciProfilEkrani> createState() => _KullaniciProfilEkraniState();
}

class _KullaniciProfilEkraniState extends State<KullaniciProfilEkrani> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _isimController;
  late TextEditingController _soyisimController;
  late TextEditingController _telefonController;
  late TextEditingController _ulkeController;
  late TextEditingController _ilController;
  late TextEditingController _ilceController;

  @override
  void initState() {
    super.initState();
    final kullaniciProvider = Provider.of<KullaniciProvider>(context, listen: false);
    final mevcutProfil = kullaniciProvider.kullaniciProfil;

    _isimController = TextEditingController(text: mevcutProfil?.isim);
    _soyisimController = TextEditingController(text: mevcutProfil?.soyisim);
    _telefonController = TextEditingController(text: mevcutProfil?.telefonNumarasi);
    _ulkeController = TextEditingController(text: mevcutProfil?.adres?['ulke']);
    _ilController = TextEditingController(text: mevcutProfil?.adres?['il']);
    _ilceController = TextEditingController(text: mevcutProfil?.adres?['ilce']);
  }

  @override
  void dispose() {
    _isimController.dispose();
    _soyisimController.dispose();
    _telefonController.dispose();
    _ulkeController.dispose();
    _ilController.dispose();
    _ilceController.dispose();
    super.dispose();
  }

  Future<void> _profilGuncelle() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save(); // Form alanlarını kaydet
      final kullaniciProvider = Provider.of<KullaniciProvider>(context, listen: false);
      final User? firebaseUser = FirebaseAuth.instance.currentUser;

      if (firebaseUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil güncellenemedi: Kullanıcı oturumu açık değil.')),
        );
        return;
      }

      final guncelKullanici = Kullanici(
        uid: firebaseUser.uid,
        isim: _isimController.text.trim().isNotEmpty ? _isimController.text.trim() : null,
        soyisim: _soyisimController.text.trim().isNotEmpty ? _soyisimController.text.trim() : null,
        telefonNumarasi: _telefonController.text.trim().isNotEmpty ? _telefonController.text.trim() : null,
        email: firebaseUser.email, // Email Firebase Auth'dan alınır
        adres: {
          'ulke': _ulkeController.text.trim().isNotEmpty ? _ulkeController.text.trim() : '',
          'il': _ilController.text.trim().isNotEmpty ? _ilController.text.trim() : '',
          'ilce': _ilceController.text.trim().isNotEmpty ? _ilceController.text.trim() : '',
        },
      );

      try {
        await kullaniciProvider.profilBilgileriniKaydet(guncelKullanici);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil başarıyla güncellendi!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profil güncellenirken hata oluştu: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Consumer kullanarak kullaniciProfil'deki değişikliklere tepki verebiliriz
    // ancak TextEditingController'lar initState'te bir kez ayarlandığı için
    // profil güncellense bile UI'daki text field'lar otomatik güncellenmez.
    // Bu ekran genellikle kullanıcının kendi profilini düzenlemesi için
    // olduğu için, anlık güncellemeler yerine kaydet butonuna basıldığında
    // verinin alınması yeterlidir.
    final kullaniciProvider = Provider.of<KullaniciProvider>(context);
    final firebaseUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Bilgileri'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // E-posta adresi (salt okunur)
              ListTile(
                leading: const Icon(Icons.email),
                title: const Text('E-posta Adresi'),
                subtitle: Text(firebaseUser?.email ?? 'Yok (Anonim Kullanıcı)'),
              ),
              const Divider(),
              _buildTextFormField(
                controller: _isimController,
                labelText: 'İsim',
                icon: Icons.person,
              ),
              _buildTextFormField(
                controller: _soyisimController,
                labelText: 'Soyisim',
                icon: Icons.person_outline,
              ),
              _buildTextFormField(
                controller: _telefonController,
                labelText: 'Telefon Numarası',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
              ),
              const Divider(height: 30, thickness: 1),
              Text(
                'Adres Bilgileri',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              _buildTextFormField(
                controller: _ulkeController,
                labelText: 'Ülke',
                icon: Icons.public,
              ),
              _buildTextFormField(
                controller: _ilController,
                labelText: 'İl',
                icon: Icons.location_city,
              ),
              _buildTextFormField(
                controller: _ilceController,
                labelText: 'İlçe',
                icon: Icons.location_on,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _profilGuncelle,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50), // Butonu genişletir
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Bilgileri Güncelle', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          filled: true,
          fillColor: Colors.grey[100],
        ),
        keyboardType: keyboardType,
        validator: validator,
      ),
    );
  }
}
