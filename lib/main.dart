import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'giris_sayfasi.dart';
import 'lig_sayfalari.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // options parametresini ekleyerek platform ayarlarını doğrudan bağlayın
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase başlatma hatası: $e");
  }

  runApp(const FutbolYoneticisiApp());
}

class FutbolYoneticisiApp extends StatelessWidget {
  const FutbolYoneticisiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Futbol Yöneticisi',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const AuthKapisi(),
    );
  }
}

/// Giriş yapılmışsa ana sayfayı, yapılmamışsa giriş ekranını gösterir.
class AuthKapisi extends StatelessWidget {
  const AuthKapisi({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) return const AnaSayfa();
        return const GirisSayfasi();
      },
    );
  }
}