// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart'; // Gerekli olmadığı için kaldırıldı

import 'firebase_options.dart';

import 'servisler/auth_service.dart';
import 'providers/kus_provider.dart';
import 'providers/pedigree_provider.dart';
import 'providers/eslesme_provider.dart';
import 'providers/yaris_provider.dart';
import 'providers/kullanici_provider.dart';
import 'package:sky_fleet_app/providers/pedigree_entry_provider.dart';

import 'ekranlar/ana_sayfa.dart';
import 'ekranlar/giris_ekrani.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Temel servisler ve veri sağlayıcıları
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => KullaniciProvider()),
        ChangeNotifierProvider(create: (_) => YarisProvider()),
        ChangeNotifierProvider(create: (_) => KusProvider()), // KusProvider önce oluşturulmalı
        
        // YENİ: PedigreeEntryProvider'ı oluştururken KusProvider'ı bağımlılık olarak sağlıyoruz.
        ChangeNotifierProvider(
          create: (context) {
            final kusProvider = Provider.of<KusProvider>(context, listen: false);
            return PedigreeEntryProvider(kusProvider: kusProvider);
          },
        ),


        // EslesmeProvider: Kuş stream'ine ihtiyacı olduğu için KusProvider'dan sonra oluşturulmalı
        ChangeNotifierProvider(
          create: (context) {
            final eslesmeProvider = EslesmeProvider();
            // EslesmeProvider'ın Kuşları dinlemesi için KusProvider'ın stream'ini veriyoruz.
            // KusProvider zaten kendi içinde _veriServisi.tumKuslariGetir()'i dinlediği için,
            // EslesmeProvider'a o stream'i dışarıya açan kuslarStream getter'ını veriyoruz.
            eslesmeProvider.updateKuslariDinle(Provider.of<KusProvider>(context, listen: false).kuslarStream);
            return eslesmeProvider;
          },
        ),

        // PedigreeProvider: Tüm bağımlılıkları tamamlandıktan sonra oluşturulmalı
        ChangeNotifierProvider(
          create: (context) {
            final kusProvider = Provider.of<KusProvider>(context, listen: false);
            final kullaniciProvider = Provider.of<KullaniciProvider>(context, listen: false);
            final yarisProvider = Provider.of<YarisProvider>(context, listen: false);

            final pedigreeProvider = PedigreeProvider(
              kusProvider: kusProvider,
              kullaniciProvider: kullaniciProvider,
              yarisProvider: yarisProvider,
            );
            return pedigreeProvider;
          },
        ),
      ],
      child: MaterialApp(
        title: 'SkyFleet Güvercin Yönetimi',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blueGrey,
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: false,
            backgroundColor: Colors.blueGrey,
            foregroundColor: Colors.white,
          ),
          colorScheme: ColorScheme.fromSwatch(
            primarySwatch: Colors.blueGrey,
          ).copyWith(secondary: Colors.blueGrey.shade700),
        ),
        home: const WidgetTree(),
      ),
    );
  }
}

class WidgetTree extends StatelessWidget {
  const WidgetTree({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return StreamBuilder<User?>(
      stream: authService.user,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final user = snapshot.data;

        if (user == null) {
          return const GirisEkrani();
        } else {
          // YENİ: Kullanıcı oturum açtığında, PedigreeEntryProvider'a KusProvider'ı update et.
          // Bu, PedigreeEntryProvider'ın KusProvider'a her zaman erişebilmesini sağlar.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Provider.of<PedigreeEntryProvider>(context, listen: false)
                .updateKusProvider(Provider.of<KusProvider>(context, listen: false));
          });
          return const AnaSayfa();
        }
      },
    );
  }
}
