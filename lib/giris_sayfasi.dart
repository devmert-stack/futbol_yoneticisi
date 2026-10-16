import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// E-posta ve şifreyle giriş yapma ve kayıt olma ekranı.
/// Giriş başarılı olunca main.dart içindeki AuthKapisi ekranı kendiliğinden değiştirir.
class GirisSayfasi extends StatefulWidget {
  const GirisSayfasi({super.key});

  @override
  State<GirisSayfasi> createState() => _GirisSayfasiState();
}

class _GirisSayfasiState extends State<GirisSayfasi> {
  final _eposta = TextEditingController();
  final _sifre = TextEditingController();

  bool _kayitModu = false;
  bool _yukleniyor = false;
  String? _hata;

  @override
  void dispose() {
    _eposta.dispose();
    _sifre.dispose();
    super.dispose();
  }

  Future<void> _gonder() async {
    final eposta = _eposta.text.trim();
    final sifre = _sifre.text;

    if (eposta.isEmpty || sifre.isEmpty) {
      setState(() => _hata = 'E-posta ve şifre boş olamaz.');
      return;
    }

    setState(() {
      _yukleniyor = true;
      _hata = null;
    });

    try {
      final auth = FirebaseAuth.instance;
      if (_kayitModu) {
        await auth.createUserWithEmailAndPassword(email: eposta, password: sifre);
      } else {
        await auth.signInWithEmailAndPassword(email: eposta, password: sifre);
      }
      // Başarılıysa AuthKapisi bizi zaten başka ekrana taşıyacak.
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _hata = _hataMetni(e.code));
    } finally {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  String _hataMetni(String kod) => switch (kod) {
        'invalid-email' => 'E-posta adresi geçersiz.',
        'user-not-found' ||
        'wrong-password' ||
        'invalid-credential' =>
          'E-posta ya da şifre hatalı.',
        'email-already-in-use' => 'Bu e-posta ile zaten bir hesap var.',
        'weak-password' => 'Şifre en az 6 karakter olmalı.',
        'operation-not-allowed' =>
          'E-posta/şifre girişi Firebase konsolunda açık değil.',
        'network-request-failed' => 'İnternet bağlantısı yok.',
        _ => 'Bir hata oluştu ($kod).',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Futbol Yöneticisi',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  _kayitModu ? 'Yeni hesap oluştur' : 'Giriş yap',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _eposta,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'E-posta',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _sifre,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Şifre',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _yukleniyor ? null : _gonder(),
                ),
                if (_hata != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _hata!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _yukleniyor ? null : _gonder,
                  child: _yukleniyor
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_kayitModu ? 'Kayıt ol' : 'Giriş yap'),
                ),
                TextButton(
                  onPressed: _yukleniyor
                      ? null
                      : () => setState(() {
                            _kayitModu = !_kayitModu;
                            _hata = null;
                          }),
                  child: Text(_kayitModu
                      ? 'Zaten hesabım var, giriş yap'
                      : 'Hesabın yok mu? Kayıt ol'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
