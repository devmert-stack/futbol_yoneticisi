import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'oyuncu_uretici.dart';
import 'widgets/saha_gorunumu.dart';
import 'lig_servisi.dart';
import 'mac_simulatoru.dart';

class KadroEkrani extends StatelessWidget {
  final String ligId;

  const KadroEkrani({super.key, required this.ligId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F0),
      appBar: AppBar(
        title: const Text('Kadro & Taktik (4-4-2)'),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: LigServisi.benimOyuncularim(ligId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }

          final docs = snapshot.data?.docs ?? [];
          final List<Oyuncu> gelenOyuncular = docs.map((doc) {
            final data = doc.data();

            Mevki mevkiEnum = Mevki.ortaSaha;
            final dynamic rawMevki = data['mevki'];
            if (rawMevki != null) {
              final str = rawMevki.toString().toLowerCase();
              if (str.contains('kale') || str.contains('kl')) {
                mevkiEnum = Mevki.kaleci;
              } else if (str.contains('defan') || str.contains('df') || str.contains('stoper')) {
                mevkiEnum = Mevki.defans;
              } else if (str.contains('forvet') || str.contains('fv') || str.contains('snt')) {
                mevkiEnum = Mevki.forvet;
              }
            }

            double fiyatVal = 0.0;
            if (data['fiyat'] is num) {
              fiyatVal = (data['fiyat'] as num).toDouble();
            } else if (data['fiyat'] != null) {
              fiyatVal = double.tryParse(data['fiyat'].toString()) ?? 0.0;
            }

            return Oyuncu(
              id: doc.id,
              ad: (data['ad'] ?? '').toString(),
              soyad: (data['soyad'] ?? '').toString(),
              mevki: mevkiEnum,
              yas: (data['yas'] is num) ? (data['yas'] as num).toInt() : 20,
              hucum: (data['hucum'] is num) ? (data['hucum'] as num).toInt() : 60,
              ortaSaha: (data['ortaSaha'] is num) ? (data['ortaSaha'] as num).toInt() : 60,
              savunma: (data['savunma'] is num) ? (data['savunma'] as num).toInt() : 60,
              kaleci: (data['kaleci'] is num) ? (data['kaleci'] as num).toInt() : 60,
              fiyat: fiyatVal,
            );
          }).toList();

          gelenOyuncular.sort((a, b) => b.fiyat.compareTo(a.fiyat));

          // 4-4-2 Şablonu (1 GK, 4 DEF, 4 MID, 2 FWD)
          final Map<String, Oyuncu?> kadro = {
            'ST1': null, 'ST2': null,
            'LM': null, 'LCM': null, 'RCM': null, 'RM': null,
            'LB': null, 'CB1': null, 'CB2': null, 'RB': null,
            'GK': null,
          };

          for (final oyuncu in gelenOyuncular) {
            _mevkiyeYerlestir(kadro, oyuncu);
          }

          final sahadaOlanlar = kadro.values.whereType<Oyuncu>().toList();
          final double toplamDeger = sahadaOlanlar.fold<double>(
            0.0,
            (toplam, o) => toplam + o.fiyat,
          );

          return SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text(
                          'Oyuncu: ${sahadaOlanlar.length}/11',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          'Kadro Değeri: ${toplamDeger.toStringAsFixed(1)} M €',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green[800],
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SahaGorunumu(kadro: kadro),

                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber[800],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.sports),
                      label: const Text(
                        'Simülasyon Maçı Yap',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      onPressed: () => _maciBaslat(context, sahadaOlanlar),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _maciBaslat(BuildContext context, List<Oyuncu> oyuncularim) {
    final eksikler = eksikMevkiler(oyuncularim);
    if (eksikler.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maç yapılamaz: ${eksikler.join(', ')}'),
          backgroundColor: Colors.red[700],
        ),
      );
      return;
    }

    final evGucu = takimGucuHesapla(oyuncularim);
    final depGucu = TakimGucu(
      (evGucu.hucum + (Random().nextInt(10) - 5)).clamp(30.0, 95.0),
      (evGucu.savunma + (Random().nextInt(10) - 5)).clamp(30.0, 95.0),
    );

    final simulator = MacSimulatoru();
    final (evGol, depGol) = simulator.oyna(evGucu, depGucu);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Center(
          child: Text('MAÇ SONUCU', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.green[800],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  const Expanded(
                    child: Text(
                      'Takımım\n(Ev)',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(
                    '$evGol - $depGol',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Yapay Zeka\n(Dep)',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              evGol > depGol
                  ? '🎉 Tebrikler, maçı kazandınız!'
                  : (evGol == depGol ? '🤝 Berabere bitti!' : '❌ Maçı kaybettiniz!'),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: evGol > depGol ? Colors.green[800] : (evGol == depGol ? Colors.orange : Colors.red),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  void _mevkiyeYerlestir(Map<String, Oyuncu?> kadro, Oyuncu oyuncu) {
    switch (oyuncu.mevki) {
      case Mevki.kaleci:
        kadro['GK'] ??= oyuncu;
        break;
      case Mevki.forvet:
        if (kadro['ST1'] == null) {
          kadro['ST1'] = oyuncu;
        } else if (kadro['ST2'] == null) {
          kadro['ST2'] = oyuncu;
        }
        break;
      case Mevki.ortaSaha:
        if (kadro['LCM'] == null) {
          kadro['LCM'] = oyuncu;
        } else if (kadro['RCM'] == null) {
          kadro['RCM'] = oyuncu;
        } else if (kadro['LM'] == null) {
          kadro['LM'] = oyuncu;
        } else if (kadro['RM'] == null) {
          kadro['RM'] = oyuncu;
        }
        break;
      case Mevki.defans:
        if (kadro['CB1'] == null) {
          kadro['CB1'] = oyuncu;
        } else if (kadro['CB2'] == null) {
          kadro['CB2'] = oyuncu;
        } else if (kadro['LB'] == null) {
          kadro['LB'] = oyuncu;
        } else if (kadro['RB'] == null) {
          kadro['RB'] = oyuncu;
        }
        break;
    }
  }
}