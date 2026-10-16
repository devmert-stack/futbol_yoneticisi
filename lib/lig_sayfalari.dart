import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'lig_servisi.dart';
import 'mac_simulatoru.dart';
//import 'oyuncu_uretici.dart' show Mevki, Oyuncu;

// ------------------------------------------------------------
// ANA SAYFA: Liglerim, Yeni Lig Kur, Koda Katıl
// ------------------------------------------------------------
class AnaSayfa extends StatelessWidget {
  const AnaSayfa({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('OnBirlik'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(
                user?.email ?? '',
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Çıkış Yap',
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: LigServisi.benimLigler(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final ligler = snapshot.data!.docs;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Lig Kur'),
                      onPressed: () => _ligKurDialog(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.vpn_key),
                      label: const Text('Koda Katıl'),
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
              if (ligler.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text('Henüz bir lige üye değilsin.'),
                  ),
                )
              else
                ...ligler.map((doc) {
                  final data = doc.data();
                  final ligAdi = data['ad'] ?? 'İsimsiz Lig';
                  final durum = data['durum'] ?? 'kurulum';
                  final uyeler = (data['uyeIdleri'] as List?)?.length ?? 0;
                  final maxUye = data['maxUye'] ?? LigServisi.maxUye;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Icon(durum == 'kurulum'
                            ? Icons.group
                            : Icons.sports_soccer),
                      ),
                      title: Text(ligAdi,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        durum == 'kurulum'
                            ? 'Lobi ($uyeler/$maxUye Takım) • Kod: ${data['davetKodu']}'
                            : 'Sezon Devam Ediyor (${data['aktifHafta']}. Hafta)',
                      ),
                      trailing: const Icon(Icons.chevron_right),
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
                }),
            ],
          );
        },
      ),
    );
  }

  static void _ligKurDialog(BuildContext context) {
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
              decoration: const InputDecoration(labelText: 'Takımının Adı'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final lAd = ligAdCtrl.text.trim();
              final tAd = takimAdCtrl.text.trim();
              if (lAd.isEmpty || tAd.isEmpty) return;

              Navigator.pop(ctx);
              try {
                final id = await LigServisi.ligKur(ligAdi: lAd, takimAdi: tAd);
                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LigDetaySayfasi(ligId: id),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Hata: $e')),
                  );
                }
              }
            },
            child: const Text('Kur'),
          ),
        ],
      ),
    );
  }

  static void _kodaKatilDialog(BuildContext context) {
    final kodCtrl = TextEditingController();
    final takimAdCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Davet Koduyla Katıl'),
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
              decoration: const InputDecoration(labelText: 'Takımının Adı'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final kod = kodCtrl.text.trim();
              final tAd = takimAdCtrl.text.trim();
              if (kod.isEmpty || tAd.isEmpty) return;

              Navigator.pop(ctx);
              try {
                final id = await LigServisi.ligeKatil(kod: kod, takimAdi: tAd);
                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LigDetaySayfasi(ligId: id),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              }
            },
            child: const Text('Katıl'),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------
// LİG DETAY / ANA PANEL SAYFASI
// ------------------------------------------------------------
class LigDetaySayfasi extends StatelessWidget {
  const LigDetaySayfasi({super.key, required this.ligId});
  final String ligId;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: LigServisi.lig(ligId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final ligData = snapshot.data!.data();
        if (ligData == null) {
          return const Scaffold(
            body: Center(child: Text('Lig bulunamadı.')),
          );
        }

        final ligAdi = ligData['ad'] ?? 'Lig';
        final kod = ligData['davetKodu'] ?? '';
        final durum = ligData['durum'] ?? 'kurulum';
        final kurucuId = ligData['kurucuId'];
        final benKurucuyum = kurucuId == uid;
        final aktifHafta = ligData['aktifHafta'] as int? ?? 1;
        final toplamHafta = ligData['toplamHafta'] as int? ?? 0;
        final uyeler = Map<String, dynamic>.from(ligData['uyeler'] ?? {});

        return DefaultTabController(
          length: durum == 'kurulum' ? 3 : 5,
          child: Scaffold(
            appBar: AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ligAdi, style: const TextStyle(fontSize: 16)),
                  Text(
                    durum == 'kurulum'
                        ? 'Lobi (Kod: $kod)'
                        : 'Hafta: $aktifHafta / $toplamHafta',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              bottom: TabBar(
                isScrollable: true,
                tabs: [
                  const Tab(icon: Icon(Icons.people), text: 'Lobi'),
                  const Tab(icon: Icon(Icons.store), text: 'Oyuncu Pazarı'),
                  const Tab(icon: Icon(Icons.shield), text: 'Kadrom'),
                  if (durum != 'kurulum') ...[
                    const Tab(
                        icon: Icon(Icons.calendar_month), text: 'Fikstür & Maç'),
                    const Tab(
                        icon: Icon(Icons.leaderboard), text: 'Puan Tablosu'),
                  ],
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _LobiSekmesi(
                  ligId: ligId,
                  ligData: ligData,
                  benKurucuyum: benKurucuyum,
                ),
                _OyuncuPazariSekmesi(ligId: ligId),
                _KadroSekmesi(ligId: ligId),
                if (durum != 'kurulum') ...[
                  _FiksturSekmesi(
                    ligId: ligId,
                    benKurucuyum: benKurucuyum,
                    aktifHafta: aktifHafta,
                    toplamHafta: toplamHafta,
                  ),
                  _PuanTablosuSekmesi(ligId: ligId, uyeler: uyeler),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

// ------------------------------------------------------------
// SEKME 1: LOBİ (Katılanlar ve Sezonu Başlat)
// ------------------------------------------------------------
class _LobiSekmesi extends StatelessWidget {
  const _LobiSekmesi({
    required this.ligId,
    required this.ligData,
    required this.benKurucuyum,
  });

  final String ligId;
  final Map<String, dynamic> ligData;
  final bool benKurucuyum;

  @override
  Widget build(BuildContext context) {
    final uyeler = Map<String, dynamic>.from(ligData['uyeler'] ?? {});
    final durum = ligData['durum'] ?? 'kurulum';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: Colors.blue.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text('Davet Kodu', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 4),
                SelectableText(
                  ligData['davetKodu'] ?? '',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Arkadaşların bu kodla lige katılabilir (Maksimum 5 takım).',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Katılan Takımlar (${uyeler.length}/${LigServisi.maxUye})',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const Divider(),
        ...uyeler.entries.map((e) {
          final isKurucu = e.key == ligData['kurucuId'];
          return ListTile(
            leading: CircleAvatar(
              child: Text(e.value.toString().characters.first.toUpperCase()),
            ),
            title: Text(e.value.toString()),
            trailing: isKurucu
                ? const Chip(label: Text('Kurucu', style: TextStyle(fontSize: 11)))
                : null,
          );
        }),
        const SizedBox(height: 24),
        if (durum == 'kurulum' && benKurucuyum)
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Sezonu Başlat / Fikstürü Oluştur'),
            onPressed: () async {
              try {
                await LigServisi.sezonuBaslat(ligId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Sezon başladı! Fikstür oluşturuldu.')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Sezon Başlatılamadı'),
                      content: Text(e.toString()),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Tamam'),
                        ),
                      ],
                    ),
                  );
                }
              }
            },
          ),
      ],
    );
  }
}

// ------------------------------------------------------------
// SEKME 2: OYUNCU PAZARI (Canlı Havuz ve Satın Alma)
// ------------------------------------------------------------
class _OyuncuPazariSekmesi extends StatefulWidget {
  const _OyuncuPazariSekmesi({required this.ligId});
  final String ligId;

  @override
  State<_OyuncuPazariSekmesi> createState() => _OyuncuPazariSekmesiState();
}

class _OyuncuPazariSekmesiState extends State<_OyuncuPazariSekmesi> {
  bool sadeceBosta = false;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Column(
      children: [
        // Canlı Bütçe ve Kadro Bilgi Çubuğu
        StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: LigServisi.benimTakim(widget.ligId),
          builder: (context, snap) {
            final tData = snap.data?.data();
            final butce = (tData?['butce'] as num?)?.toDouble() ?? 0.0;
            final kadroSayisi =
                (tData?['kadro'] as List<dynamic>?)?.length ?? 0;

            return Container(
              color: Colors.grey.shade200,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Kalan Bütçe: $butce M',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('Kadro: $kadroSayisi/${LigServisi.kadroSiniri}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            );
          },
        ),
        // Filtre Çubuğu
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              const Text('Sadece Boştakiler'),
              Switch(
                value: sadeceBosta,
                onChanged: (v) => setState(() => sadeceBosta = v),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Oyuncu Listesi
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: LigServisi.oyuncular(widget.ligId),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              var doclar = snapshot.data!.docs;
              if (sadeceBosta) {
                doclar =
                    doclar.where((d) => d.data()['takimId'] == null).toList();
              }

              return ListView.separated(
                itemCount: doclar.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final data = doclar[index].data();
                  final pId = doclar[index].id;
                  final ad = data['ad'] ?? '';
                  final mevki = data['mevki'] ?? '';
                  final genel = data['genel'] ?? 0;
                  final fiyat = data['fiyat'] ?? 0.0;
                  final takimId = data['takimId'];

                  final bool bende = takimId == uid;
                  final bool bosta = takimId == null;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _mevkiRengi(mevki),
                      child: Text(
                        genel.toString(),
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(ad,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('$mevki • Fiyat: $fiyat M'),
                    trailing: bende
                        ? const Chip(
                            label: Text('Senin'),
                            backgroundColor: Colors.greenAccent)
                        : bosta
                            ? ElevatedButton(
                                onPressed: () async {
                                  try {
                                    await LigServisi.oyuncuAl(
                                      ligId: widget.ligId,
                                      oyuncuId: pId,
                                    );
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(content: Text(e.toString())),
                                      );
                                    }
                                  }
                                },
                                child: const Text('Al'),
                              )
                            : const Text('Alındı',
                                style: TextStyle(color: Colors.grey)),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Color _mevkiRengi(String m) {
    if (m.contains('kaleci')) return Colors.orange;
    if (m.contains('defans')) return Colors.blue;
    if (m.contains('orta')) return Colors.purple;
    return Colors.red;
  }
}

// ------------------------------------------------------------
// SEKME 3: KADROM (Kendi Oyuncularım ve Satış)
// ------------------------------------------------------------
class _KadroSekmesi extends StatelessWidget {
  const _KadroSekmesi({required this.ligId});
  final String ligId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: LigServisi.benimOyuncularim(ligId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final doclar = snapshot.data!.docs;
        if (doclar.isEmpty) {
          return const Center(
            child: Text('Henüz kadrona oyuncu transfer etmedin.'),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: doclar.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final data = doclar[index].data();
            final pId = doclar[index].id;
            final ad = data['ad'] ?? '';
            final mevki = data['mevki'] ?? '';
            final genel = data['genel'] ?? 0;
            final fiyat = data['fiyat'] ?? 0.0;

            return ListTile(
              leading: CircleAvatar(
                child: Text(genel.toString()),
              ),
              title: Text(ad),
              subtitle: Text('$mevki • Değer: $fiyat M'),
              trailing: OutlinedButton(
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () async {
                  try {
                    await LigServisi.oyuncuSat(ligId: ligId, oyuncuId: pId);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString())),
                      );
                    }
                  }
                },
                child: const Text('Sat'),
              ),
            );
          },
        );
      },
    );
  }
}

// ------------------------------------------------------------
// SEKME 4: FİKSTÜR VE HAFTALIK MAÇLAR
// ------------------------------------------------------------
class _FiksturSekmesi extends StatelessWidget {
  const _FiksturSekmesi({
    required this.ligId,
    required this.benKurucuyum,
    required this.aktifHafta,
    required this.toplamHafta,
  });

  final String ligId;
  final bool benKurucuyum;
  final int aktifHafta;
  final int toplamHafta;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Mac>>(
      stream: LigServisi.maclar(ligId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final maclar = snapshot.data!;
        if (maclar.isEmpty) {
          return const Center(child: Text('Fikstür henüz oluşturulmadı.'));
        }

        // Maçları haftalarına göre gruplayalım
        final haftaGruplari = <int, List<Mac>>{};
        for (final m in maclar) {
          haftaGruplari.putIfAbsent(m.hafta, () => []).add(m);
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (benKurucuyum && aktifHafta <= toplamHafta)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.flash_on),
                  label: Text('$aktifHafta. Haftayı Oynat / Simüle Et'),
                  onPressed: () async {
                    try {
                      await LigServisi.haftayiOyna(ligId);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString())),
                        );
                      }
                    }
                  },
                ),
              ),
            ...haftaGruplari.entries.map((entry) {
              final hNo = entry.key;
              final hMaclar = entry.value;
              final isAktif = hNo == aktifHafta;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    color: isAktif ? Colors.indigo : Colors.grey.shade300,
                    width: isAktif ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isAktif
                            ? Colors.indigo.shade50
                            : Colors.grey.shade100,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(10)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('$hNo. Hafta',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          if (isAktif)
                            const Text(
                              'Oynanacak Hafta',
                              style: TextStyle(
                                  color: Colors.indigo,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12),
                            ),
                        ],
                      ),
                    ),
                    ...hMaclar.map((m) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                m.evAd,
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              margin: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: m.oynandi
                                    ? Colors.black87
                                    : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                m.oynandi
                                    ? '${m.evGol} - ${m.depGol}'
                                    : 'vs',
                                style: TextStyle(
                                  color: m.oynandi
                                      ? Colors.white
                                      : Colors.black87,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                m.depAd,
                                textAlign: TextAlign.left,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

// ------------------------------------------------------------
// SEKME 5: PUAN DURUMU TABLOSU
// ------------------------------------------------------------
class _PuanTablosuSekmesi extends StatelessWidget {
  const _PuanTablosuSekmesi({
    required this.ligId,
    required this.uyeler,
  });

  final String ligId;
  final Map<String, dynamic> uyeler;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Mac>>(
      stream: LigServisi.maclar(ligId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final takimAdlari = uyeler.map((k, v) => MapEntry(k, v.toString()));
        final tablo = puanTablosuHesapla(takimAdlari, snapshot.data!);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: DataTable(
            columnSpacing: 16,
            columns: const [
              DataColumn(label: Text('#')),
              DataColumn(label: Text('Takım')),
              DataColumn(label: Text('O')),
              DataColumn(label: Text('G')),
              DataColumn(label: Text('B')),
              DataColumn(label: Text('M')),
              DataColumn(label: Text('Av')),
              DataColumn(label: Text('P', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: List.generate(tablo.length, (i) {
              final s = tablo[i];
              return DataRow(
                cells: [
                  DataCell(Text('${i + 1}')),
                  DataCell(Text(s.takimAdi, style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Text('${s.oynanan}')),
                  DataCell(Text('${s.galibiyet}')),
                  DataCell(Text('${s.beraberlik}')),
                  DataCell(Text('${s.maglubiyet}')),
                  DataCell(Text('${s.averaj}')),
                  DataCell(Text('${s.puan}', style: const TextStyle(fontWeight: FontWeight.bold))),
                ],
              );
            }),
          ),
        );
      },
    );
  }
}