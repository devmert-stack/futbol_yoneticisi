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
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                email,
                style: const TextStyle(color: Colors.black54, fontSize: 13),
              ),
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
/// 2. OYUNCU PAZARI SEKMESİ
/// ========================================================
class _OyuncuPazariSekmesi extends StatelessWidget {
  final String ligId;
  final Map<String, dynamic> ligData;

  const _OyuncuPazariSekmesi({required this.ligId, required this.ligData});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: LigServisi.benimTakim(ligId),
      builder: (context, takimSnap) {
        final butce = (takimSnap.data?.data()?['butce'] as num?)?.toDouble() ?? 0.0;

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Kalan Bütçe: ${butce.toStringAsFixed(1)} M €',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text('Kod: ${ligData['davetKodu']}',
                      style: const TextStyle(color: Colors.black54)),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: LigServisi.oyuncular(ligId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                  final docs = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final d = doc.data();
                      final takimId = d['takimId'];
                      final fiyat = (d['fiyat'] as num?)?.toDouble() ?? 0.0;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.grey.shade300,
                          child: Text(d['mevki'] ?? 'OS', style: const TextStyle(fontSize: 12)),
                        ),
                        title: Text('${d['ad']} ${d['soyad']}'),
                        subtitle: Text('${fiyat.toStringAsFixed(1)} M €'),
                        trailing: takimId == null
                            ? ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                onPressed: () async {
                                  try {
                                    await LigServisi.oyuncuAl(ligId: ligId, oyuncuId: doc.id);
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(e.toString())),
                                    );
                                  }
                                },
                                child: const Text('Al'),
                              )
                            : Text(
                                takimId == uid ? 'Takımında' : 'Satıldı',
                                style: TextStyle(
                                  color: takimId == uid ? Colors.green : Colors.grey,
                                  fontWeight: FontWeight.bold,
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