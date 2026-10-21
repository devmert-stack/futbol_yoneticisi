import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'kadro_ekrani.dart';
import 'lig_servisi.dart';
import 'mac_simulatoru.dart';

/// Giriş sonrası ana sayfa: Liglerim listesi, Lig Kurma ve Koda Katılma
class AnaSayfa extends StatelessWidget {
  const AnaSayfa({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'Kullanıcı';

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F5),
      appBar: AppBar(
        title: const Text('OnBirlik', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  email,
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
                IconButton(
                  tooltip: 'Çıkış Yap',
                  icon: const Icon(Icons.logout, color: Colors.redAccent, size: 20),
                  onPressed: () => _cikisYapOnayi(context),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            // ÜST BUTONLAR
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEBF1E8),
                      foregroundColor: Colors.black87,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('Lig Kur', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () => _ligKurDialog(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: Colors.grey.shade400),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.key, size: 20),
                    label: const Text('Koda Katıl', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () => _kodaKatilDialog(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Liglerim',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            // LİGLER LİSTESİ
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: LigServisi.benimLigler(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const Center(
                      child: Text('Henüz katıldığınız bir lig yok.'),
                    );
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data();
                      final ligAdi = data['ad'] ?? 'İsimsiz Lig';
                      final durum = data['durum'] ?? 'kurulum';
                      final aktifHafta = data['aktifHafta'] ?? 1;

                      String altYazi;
                      Color altYaziRenk = Colors.black54;
                      if (durum == 'bitti') {
                        altYazi = 'Sezon Sona Erdi (Tamamlandı)';
                        altYaziRenk = Colors.green.shade800;
                      } else if (durum == 'kurulum') {
                        altYazi = 'Kurulum Aşaması (Lobi)';
                        altYaziRenk = Colors.orange.shade800;
                      } else {
                        altYazi = 'Sezon Devam Ediyor ($aktifHafta. Hafta)';
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF3EB),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.green.shade200,
                            child: const Icon(Icons.sports_soccer, color: Colors.green),
                          ),
                          title: Text(
                            ligAdi,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Text(
                            altYazi,
                            style: TextStyle(
                              color: altYaziRenk,
                              fontWeight: durum == 'bitti' ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right, color: Colors.black54),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => LigDetaySayfasi(ligId: doc.id),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  void _cikisYapOnayi(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Çıkış Yap'),
        content: const Text('Hesabınızdan çıkış yapmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[800],
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseAuth.instance.signOut();
              // StreamBuilder (AuthStateChanges) kullanıyorsanız otomatik login ekranına döner,
              // veya stack'i temizleyip login ekranına atmak isterseniz:
              if (context.mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );
  }
  void _ligKurDialog(BuildContext context) {
    final ligAdCtrl = TextEditingController();
    final takimAdCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yeni Lig Kur'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ligAdCtrl,
              decoration: const InputDecoration(labelText: 'Lig Adı'),
            ),
            TextField(
              controller: takimAdCtrl,
              decoration: const InputDecoration(labelText: 'Takım Adınız'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () async {
              if (ligAdCtrl.text.isEmpty || takimAdCtrl.text.isEmpty) return;
              Navigator.pop(ctx);
              try {
                final id = await LigServisi.ligKur(
                  ligAdi: ligAdCtrl.text.trim(),
                  takimAdi: takimAdCtrl.text.trim(),
                );
                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => LigDetaySayfasi(ligId: id)),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Hata: $e')),
                );
              }
            },
            child: const Text('Kur'),
          ),
        ],
      ),
    );
  }

  void _kodaKatilDialog(BuildContext context) {
    final kodCtrl = TextEditingController();
    final takimAdCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Koda Göre Lige Katıl'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: kodCtrl,
              decoration: const InputDecoration(labelText: '6 Haneli Davet Kodu'),
              textCapitalization: TextCapitalization.characters,
            ),
            TextField(
              controller: takimAdCtrl,
              decoration: const InputDecoration(labelText: 'Takım Adınız'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () async {
              if (kodCtrl.text.isEmpty || takimAdCtrl.text.isEmpty) return;
              Navigator.pop(ctx);
              try {
                final id = await LigServisi.ligeKatil(
                  kod: kodCtrl.text.trim(),
                  takimAdi: takimAdCtrl.text.trim(),
                );
                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => LigDetaySayfasi(ligId: id)),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Hata: $e')),
                );
              }
            },
            child: const Text('Katıl'),
          ),
        ],
      ),
    );
  }
}

/// ========================================================
/// LİG DETAY SAYFASI (Dinamik Kayar Sekmeli Yapı)
/// ========================================================
class LigDetaySayfasi extends StatelessWidget {
  final String ligId;

  const LigDetaySayfasi({super.key, required this.ligId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: LigServisi.lig(ligId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final ligDoc = snapshot.data;
        // Lig silindiyse ekranda takılmadan otomatik ana ekrana dön
        if (ligDoc == null || !ligDoc.exists || ligDoc.data() == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted && Navigator.canPop(context)) {
              Navigator.of(context).pop();
            }
          });
          return const Scaffold(body: Center(child: Text('Lig bulunamadı.')));
        }

        final ligData = ligDoc.data()!;
        final String ligAdi = ligData['ad'] ?? 'Lig';
        final String durum = ligData['durum'] ?? 'kurulum';
        final String davetKodu = ligData['davetKodu'] ?? '';
        final int aktifHafta = ligData['aktifHafta'] ?? 1;
        final int toplamHafta = ligData['toplamHafta'] ?? 1;

        final bool isKurulum = (durum == 'kurulum');
        final int tabSayisi = isKurulum ? 3 : 5;

        return DefaultTabController(
          key: ValueKey(durum), // Sekme sayısı dinamik değiştiğinde index hatasını önler
          length: tabSayisi,
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              elevation: 0,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ligAdi, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(
                    isKurulum ? 'Lobi (Kod: $davetKodu)' : 'Hafta: $aktifHafta / $toplamHafta',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
              bottom: TabBar(
                isScrollable: true,
                labelColor: const Color(0xFF2E6930),
                unselectedLabelColor: Colors.black54,
                indicatorColor: const Color(0xFF2E6930),
                tabs: [
                  const Tab(icon: Icon(Icons.people), text: 'Lobi'),
                  const Tab(icon: Icon(Icons.storefront), text: 'Oyuncu Pazarı'),
                  const Tab(icon: Icon(Icons.shield), text: 'Kadrom'),
                  if (!isKurulum) ...[
                    const Tab(icon: Icon(Icons.calendar_month), text: 'Fikstür & Maç'),
                    const Tab(icon: Icon(Icons.leaderboard), text: 'Puan Tablosu'),
                  ],
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _LobiSekmesi(ligId: ligId, ligData: ligData),
                _OyuncuPazariSekmesi(ligId: ligId, ligData: ligData),
                _KadromSekmesi(ligId: ligId),
                if (!isKurulum) ...[
                  _FiksturSekmesi(ligId: ligId, ligData: ligData),
                  _PuanTablosuSekmesi(ligId: ligId, ligData: ligData),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// ========================================================
/// 1. LOBİ SEKMESİ (Birebir Ekran Görüntüsü Tasarımı)
/// ========================================================
class _LobiSekmesi extends StatelessWidget {
  final String ligId;
  final Map<String, dynamic> ligData;

  const _LobiSekmesi({required this.ligId, required this.ligData});

  @override
  Widget build(BuildContext context) {
    final davetKodu = ligData['davetKodu'] ?? '';
    final maxUye = ligData['maxUye'] ?? 5;
    final kurucuId = ligData['kurucuId'] ?? '';
    final durum = ligData['durum'] ?? 'kurulum';
    final suankiUid = FirebaseAuth.instance.currentUser?.uid;
    final bool benKurucuyum = (suankiUid == kurucuId);

    final uyeler = Map<String, dynamic>.from((ligData['uyeler'] as Map?) ?? {});
    final List<MapEntry<String, dynamic>> uyeListesi = uyeler.entries.toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // MAVİ DAVET KARTI
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F2FD),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text(
                  'Davet Kodu',
                  style: TextStyle(color: Colors.black45, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: davetKodu));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Davet kodu kopyalandı!')),
                    );
                  },
                  child: Text(
                    davetKodu,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Arkadaşların bu kodla lige katılabilir\n(Maksimum $maxUye takım).',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // BAŞLIK
          Text(
            'Katılan Takımlar (${uyeler.length}/$maxUye)',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Divider(thickness: 1),
          const SizedBox(height: 8),

          // NUMARALANDIRILMIŞ TAKIM LİSTESİ
          Expanded(
            child: ListView.builder(
              itemCount: uyeListesi.length,
              itemBuilder: (context, index) {
                final entry = uyeListesi[index];
                final uid = entry.key;
                final takimAdi = entry.value.toString();
                final isKurucu = (uid == kurucuId);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    children: [
                      // Yeşil Daire İçinde Sıra Numarası
                      Container(
                        width: 38,
                        height: 38,
                        decoration: const BoxDecoration(
                          color: Color(0xFFC3ECC4),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          takimAdi,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      if (isKurucu)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade400),
                          ),
                          child: const Text(
                            'Kurucu',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),

          // KURUCU İÇİN SEZONU BAŞLAT BUTONU (Sadece Kurulumdaysa Çıkar)
          if (durum == 'kurulum' && benKurucuyum)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E6930),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    try {
                      await LigServisi.sezonuBaslat(ligId);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Hata: $e')),
                      );
                    }
                  },
                  child: const Text('Sezonu Başlat & Fikstürü Kur',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// ========================================================
/// 2. OYUNCU PAZARI SEKMESİ (Limitli, Sıralı ve Modern Tasarım)
/// ========================================================
class _OyuncuPazariSekmesi extends StatelessWidget {
  final String ligId;
  final Map<String, dynamic> ligData;

  const _OyuncuPazariSekmesi({required this.ligId, required this.ligData});

  // Mevkilerin sıralama önceliği: KL -> DEF -> OS -> FOR
  int _mevkiOncelik(String mevki) {
    final m = mevki.toLowerCase().trim();
    if (m.contains('kaleci') || m == 'kl') return 1;
    if (m.contains('defans') || m == 'def') return 2;
    if (m.contains('orta') || m == 'os') return 3;
    if (m.contains('forvet') || m == 'for' || m == 'fwt') return 4;
    return 5;
  }

  // Mevkiye göre renk paleti
  Color _mevkiRenk(String mevki) {
    final oncelik = _mevkiOncelik(mevki);
    switch (oncelik) {
      case 1:
        return Colors.amber.shade700; // Kaleci
      case 2:
        return Colors.blue.shade700;  // Defans
      case 3:
        return Colors.green.shade700; // Orta Saha
      case 4:
        return Colors.red.shade700;   // Forvet
      default:
        return Colors.grey.shade700;
    }
  }

  // Kısa mevki etiketi
  String _kisaMevki(String mevki) {
    final oncelik = _mevkiOncelik(mevki);
    switch (oncelik) {
      case 1:
        return 'KL';
      case 2:
        return 'DEF';
      case 3:
        return 'OS';
      case 4:
        return 'FOR';
      default:
        return mevki.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: LigServisi.benimTakim(ligId),
      builder: (context, takimSnap) {
        final butce = (takimSnap.data?.data()?['butce'] as num?)?.toDouble() ?? 0.0;

        // Kullanıcının mevcut kadrosundaki oyuncuları dinleyelim (Limit kontrolü için)
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: LigServisi.benimOyuncularim(ligId),
          builder: (context, benimKadroSnap) {
            final benimOyuncular = benimKadroSnap.data?.docs ?? [];

            // Mevki bazlı mevcut sayıları hesapla
            int klSayisi = 0;
            int defSayisi = 0;
            int osSayisi = 0;
            int forSayisi = 0;

            for (final doc in benimOyuncular) {
              final m = (doc.data()['mevki'] ?? '').toString();
              final oncelik = _mevkiOncelik(m);
              if (oncelik == 1) klSayisi++;
              if (oncelik == 2) defSayisi++;
              if (oncelik == 3) osSayisi++;
              if (oncelik == 4) forSayisi++;
            }

            // Mevki doluluk kuralları (Maksimumlar)
            final bool klDolu = klSayisi >= 3;
            final bool defDolu = defSayisi >= 5;
            final bool osDolu = osSayisi >= 5;
            final bool forDolu = forSayisi >= 3;

            return Column(
              children: [
                // 1. ÜST BİLGİ VE BÜTÇE KARTI
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: Colors.white,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.account_balance_wallet, color: Colors.green, size: 20),
                              const SizedBox(width: 6),
                              Text(
                                '${butce.toStringAsFixed(1)} M €',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                              ),
                            ],
                          ),
                          Text(
                            'Kod: ${ligData['davetKodu']}',
                            style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // MEVKİ KONTENJAN ROZETLERİ (1/3, 2/5 gibi)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _kontenjanRozeti('KL', klSayisi, 3, Colors.amber.shade700),
                          _kontenjanRozeti('DEF', defSayisi, 5, Colors.blue.shade700),
                          _kontenjanRozeti('OS', osSayisi, 5, Colors.green.shade700),
                          _kontenjanRozeti('FOR', forSayisi, 3, Colors.red.shade700),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, thickness: 1),

                // 2. PAZARDAKİ OYUNCULAR LİSTESİ
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: LigServisi.oyuncular(ligId),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      // Sadece henüz bir takıma ait olmayan (satılmamış) oyuncuları al
                      var tumOyuncular = snapshot.data!.docs.where((doc) {
                        final tId = doc.data()['takimId'];
                        return tId == null;
                      }).toList();

                      // Mevkisi dolanları bu kullanıcının pazarından gizle
                      tumOyuncular = tumOyuncular.where((doc) {
                        final m = (doc.data()['mevki'] ?? '').toString();
                        final oncelik = _mevkiOncelik(m);
                        if (oncelik == 1 && klDolu) return false;
                        if (oncelik == 2 && defDolu) return false;
                        if (oncelik == 3 && osDolu) return false;
                        if (oncelik == 4 && forDolu) return false;
                        return true;
                      }).toList();

                      // SIRALAMA: Önce Mevki (KL -> DEF -> OS -> FOR), sonra Fiyat (Yüksekten düşüğe)
                      tumOyuncular.sort((a, b) {
                        final ma = _mevkiOncelik((a.data()['mevki'] ?? '').toString());
                        final mb = _mevkiOncelik((b.data()['mevki'] ?? '').toString());
                        if (ma != mb) return ma.compareTo(mb);

                        final fa = (a.data()['fiyat'] as num?)?.toDouble() ?? 0.0;
                        final fb = (b.data()['fiyat'] as num?)?.toDouble() ?? 0.0;
                        return fb.compareTo(fa);
                      });

                      if (tumOyuncular.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Text(
                              (klDolu && defDolu && osDolu && forDolu)
                                  ? 'Tüm mevkileriniz tamamlandı (Kadro 16/16 dolu)!'
                                  : 'Bu kriterlerde uygun oyuncu kalmadı.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        itemCount: tumOyuncular.length,
                        itemBuilder: (context, index) {
                          final doc = tumOyuncular[index];
                          final d = doc.data();
                          final mevkiRaw = (d['mevki'] ?? 'OS').toString();
                          final mevkiLabel = _kisaMevki(mevkiRaw);
                          final mevkiColor = _mevkiRenk(mevkiRaw);
                          final fiyat = (d['fiyat'] as num?)?.toDouble() ?? 0.0;
                          final guc = d['guc'] ?? 70;
                          final adSoyad = '${d['ad']} ${d['soyad']}';
                          final parasiYetiyor = butce >= fiyat;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              child: Row(
                                children: [
                                  // MEVKİ ROZETİ
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: mevkiColor.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                      child: Text(
                                        mevkiLabel,
                                        style: TextStyle(
                                          color: mevkiColor,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // OYUNCU ADI VE GÜCÜ
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          adSoyad,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade100,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'GÜÇ $guc',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.grey.shade800,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '${fiyat.toStringAsFixed(1)} M €',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.green.shade800,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  // SATIN AL BUTONU
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: parasiYetiyor ? const Color(0xFF2E6930) : Colors.grey.shade400,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: parasiYetiyor
                                        ? () async {
                                            try {
                                              await LigServisi.oyuncuAl(ligId: ligId, oyuncuId: doc.id);
                                            } catch (e) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text(e.toString())),
                                              );
                                            }
                                          }
                                        : null,
                                    child: const Text(
                                      'Al',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Kontenjan gösterge etiketi
  Widget _kontenjanRozeti(String mevki, int aktif, int max, Color renk) {
    final bool doldu = aktif >= max;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: doldu ? Colors.grey.shade200 : renk.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: doldu ? Colors.grey.shade400 : renk.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$mevki: ',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: doldu ? Colors.black54 : renk,
            ),
          ),
          Text(
            '$aktif/$max',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: doldu ? Colors.red.shade700 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

/// ========================================================
/// 3. KADROM SEKMESİ (4-4-2 Sahaya Geçiş)
/// ========================================================
class _KadromSekmesi extends StatelessWidget {
  final String ligId;

  const _KadromSekmesi({required this.ligId});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade800,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.sports_soccer),
              label: const Text('Sahada Gör (4-4-2 Dizilişi)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => KadroEkrani(ligId: ligId),
                  ),
                );
              },
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: LigServisi.benimOyuncularim(ligId),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data!.docs;

              if (docs.isEmpty) {
                return const Center(child: Text('Takımınızda henüz oyuncu yok.'));
              }

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final d = doc.data();
                  final fiyat = (d['fiyat'] as num?)?.toDouble() ?? 0.0;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green.shade100,
                      child: Text(d['mevki'] ?? 'OS',
                          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    ),
                    title: Text('${d['ad']} ${d['soyad']}'),
                    subtitle: Text('${fiyat.toStringAsFixed(1)} M €'),
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                      onPressed: () => LigServisi.oyuncuSat(ligId: ligId, oyuncuId: doc.id),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

/// ========================================================
/// 4. FİKSTÜR & MAÇ SEKMESİ (Bittiğinde Sil Butonu)
/// ========================================================
class _FiksturSekmesi extends StatelessWidget {
  final String ligId;
  final Map<String, dynamic> ligData;

  const _FiksturSekmesi({required this.ligId, required this.ligData});

  @override
  Widget build(BuildContext context) {
    final String durum = ligData['durum'] ?? 'kurulum';
    final String kurucuId = ligData['kurucuId'] ?? '';
    final String uid = FirebaseAuth.instance.currentUser!.uid;
    final bool benKurucuyum = (uid == kurucuId);
    final int aktifHafta = ligData['aktifHafta'] ?? 1;

    return StreamBuilder<List<Mac>>(
      stream: LigServisi.maclar(ligId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final maclar = snapshot.data!;

        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            // DEVAM EDİYORSA SİMÜLASYON BUTONU
            if (durum == 'devam_ediyor' && benKurucuyum) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B5998),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.flash_on),
                    label: Text('$aktifHafta. Haftayı Oynat / Simüle Et',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () async {
                      try {
                        await LigServisi.haftayiOyna(ligId);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString())),
                        );
                      }
                    },
                  ),
                ),
              ),
            ],

            // SEZON BİTTİYSE KUPA MESAJI VE KURUCUYA SİL BUTONU
            if (durum == 'bitti') ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade700, width: 1.5),
                ),
                child: Row(
                  children: [
                    Icon(Icons.emoji_events, color: Colors.amber.shade900, size: 32),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        '🏆 Sezon Sona Erdi!\nPuan Tablosundan şampiyonu görebilirsiniz.',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              if (benKurucuyum)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[800],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.delete_forever),
                      label: const Text('Ligi Sonlandır ve Sil',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      onPressed: () => _ligiSilOnayi(context, ligId),
                    ),
                  ),
                ),
            ],

            // MAÇ LİSTESİ
            ...maclar.map((mac) {
              final buHaftaMi = (mac.hafta == aktifHafta && durum == 'devam_ediyor');

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: buHaftaMi ? const Color(0xFFE8EEF8) : const Color(0xFFF1F4F0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: buHaftaMi ? const Color(0xFF3B5998) : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${mac.hafta}. Hafta',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          if (buHaftaMi)
                            const Text('Oynanacak Hafta',
                                style: TextStyle(
                                    color: Color(0xFF3B5998),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12))
                          else if (mac.oynandi)
                            const Text('Tamamlandı',
                                style: TextStyle(color: Colors.green, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Expanded(
                            child: Text(
                              mac.evAd,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2B2B2B),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              mac.oynandi ? '${mac.evGol} - ${mac.depGol}' : 'VS',
                              style: const TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              mac.depAd,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  void _ligiSilOnayi(BuildContext context, String ligId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Ligi Silmek İstiyor musunuz?'),
        content: const Text(
          'Sezon bittiği için bu lig ve altındaki tüm takımlar, oyuncular ve maç kayıtları veritabanından kalıcı olarak silinecektir.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Vazgeç')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[800]),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await LigServisi.ligiSil(ligId);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Hata: $e')),
                  );
                }
              }
            },
            child: const Text('Evet, Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

/// ========================================================
/// 5. PUAN TABLOSU SEKMESİ
/// ========================================================
class _PuanTablosuSekmesi extends StatelessWidget {
  final String ligId;
  final Map<String, dynamic> ligData;

  const _PuanTablosuSekmesi({required this.ligId, required this.ligData});

  @override
  Widget build(BuildContext context) {
    final uyeler = Map<String, String>.from(
      (ligData['uyeler'] as Map?)?.map((k, v) => MapEntry(k.toString(), v.toString())) ?? {},
    );

    return StreamBuilder<List<Mac>>(
      stream: LigServisi.maclar(ligId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final maclar = snapshot.data!;
        final tablo = puanTablosuHesapla(uyeler, maclar);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: DataTable(
            columnSpacing: 16,
            headingRowColor: WidgetStateProperty.all(Colors.grey.shade200),
            columns: const [
              DataColumn(label: Text('Takım', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('O', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
              DataColumn(label: Text('G', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
              DataColumn(label: Text('B', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
              DataColumn(label: Text('M', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
              DataColumn(label: Text('AV', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
              DataColumn(label: Text('P', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
            ],
            rows: tablo.map((satir) {
              return DataRow(
                cells: [
                  DataCell(Text(satir.takimAdi, style: const TextStyle(fontWeight: FontWeight.w600))),
                  DataCell(Text('${satir.oynanan}')),
                  DataCell(Text('${satir.galibiyet}')),
                  DataCell(Text('${satir.beraberlik}')),
                  DataCell(Text('${satir.maglubiyet}')),
                  DataCell(Text('${satir.averaj}')),
                  DataCell(Text('${satir.puan}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
                ],
              );
            }).toList(),
          ),
        );
      },
    );
  }
}