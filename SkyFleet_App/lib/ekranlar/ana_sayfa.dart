// lib/ekranlar/ana_sayfa.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart'; // FirebaseAuth'a doğrudan erişim için

// Yeni eklenen import'lar
import '../servisler/auth_service.dart'; // AuthService'i import etmeyi unutmayın!
import '../providers/kullanici_provider.dart';
// import '../providers/kus_provider.dart'; // KusProvider'a burada gerek yok, çağrılmıyor

import 'kullanici_profil_ekrani.dart';

// İhtiyaç duyacağımız diğer ekranlar
import 'kus_listesi_ekrani.dart';
import 'eslesme_listesi_ekrani.dart';
import 'istatistik_ekrani.dart';

class AnaSayfa extends StatefulWidget {
  const AnaSayfa({super.key});

  @override
  State<AnaSayfa> createState() => _AnaSayfaState();
}

class _AnaSayfaState extends State<AnaSayfa> {
  int _seciliIndex = 0;

  static final List<Widget> _sayfalar = <Widget>[
    const IstatistikEkrani(),
    const KusListesiEkrani(),
    const EslesmeListesiEkrani(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _seciliIndex = index;
    });
  }

  // Çıkış yapma mantığı
  Future<void> _cikisYap() async {
    try {
      // signOut işlemini AuthService üzerinden çağırıyoruz
      await Provider.of<AuthService>(context, listen: false).signOut();
      print("Kullanıcı başarıyla çıkış yaptı.");
    } catch (e) {
      print("Çıkış yaparken hata oluştu: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Çıkış yaparken bir hata oluştu: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Consumer<KullaniciProvider>(
          builder: (context, kullaniciProvider, child) {
            final User? currentUser = FirebaseAuth.instance.currentUser;

            final String kullaniciAdiHarfi = kullaniciProvider.kullaniciProfil?.isim?.isNotEmpty == true
                ? kullaniciProvider.kullaniciProfil!.isim![0].toUpperCase()
                : (currentUser?.email?.isNotEmpty == true
                    ? currentUser!.email![0].toUpperCase()
                    : '?');
            return IconButton(
              icon: CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.2), // Yarı saydam beyaz arka plan
                child: Text(
                  kullaniciAdiHarfi,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const KullaniciProfilEkrani(),
                  ),
                );
              },
              tooltip: 'Profil Bilgileri',
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _cikisYap,
            tooltip: 'Çıkış Yap',
          ),
        ],
      ),
      body: _sayfalar[_seciliIndex],

      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          const BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_sharp),
            label: 'İstatistikler',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/icons/guvercin_logo.png', // guvercin_logo.png dosyasının assets/icons klasöründe olduğundan emin olun
              width: 24,
              height: 24,
            ),
            label: 'Kuşlar',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Eşleşme',
          ),
        ],
        currentIndex: _seciliIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}
