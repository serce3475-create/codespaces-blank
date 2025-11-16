// lib/ekranlar/giris_ekrani.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../servisler/auth_service.dart';

class GirisEkrani extends StatefulWidget {
  const GirisEkrani({super.key});

  @override
  State<GirisEkrani> createState() => _GirisEkraniState();
}

class _GirisEkraniState extends State<GirisEkrani> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final authService = Provider.of<AuthService>(context, listen: false);
      String? hataMesaji;

      if (_isLogin) {
        hataMesaji = await authService.signIn(_emailController.text, _passwordController.text);
      } else {
        hataMesaji = await authService.register(_emailController.text, _passwordController.text);
      }

      setState(() {
        _isLoading = false;
      });

      if (hataMesaji != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(hataMesaji)),
          );
        }
      }
      // Başarılı giriş/kayıt durumunda Navigator otomatik olarak yönlendirilecektir (main.dart'ta göreceğiz).
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'Giriş Yap' : 'Kayıt Ol'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // Başlık düzeltildi: SkyFleet (tek L)
                const Text(
                  'SkyFleet Güvercin Yönetimi', 
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
                ),
                const SizedBox(height: 30),

                // E-posta Alanı
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'E-posta',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty || !value.contains('@')) {
                      return 'Geçerli bir e-posta adresi giriniz.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Şifre Alanı
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Şifre',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.length < 6) {
                      return 'Şifre en az 6 karakter olmalıdır.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Giriş/Kayıt Butonu
                _isLoading
                    ? const CircularProgressIndicator()
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submitForm,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(_isLogin ? 'Giriş Yap' : 'Kayıt Ol'),
                        ),
                      ),
                const SizedBox(height: 16),

                // Mod Değiştirme Butonu
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isLogin = !_isLogin;
                      _emailController.clear();
                      _passwordController.clear();
                    });
                  },
                  child: Text(_isLogin ? 'Yeni Hesap Oluştur' : 'Zaten hesabım var'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}