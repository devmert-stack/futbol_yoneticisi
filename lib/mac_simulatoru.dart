import 'dart:math';

import 'oyuncu_uretici.dart' show Mevki, Oyuncu;

/// İlk 11 dizilişi: 4-4-2 (1 kaleci, 4 defans, 4 orta saha, 2 forvet).
const ilkOnbirIhtiyaci = {
  Mevki.kaleci: 1,
  Mevki.defans: 4,
  Mevki.ortaSaha: 4,
  Mevki.forvet: 2,
};

const _mevkiAdi = {
  Mevki.kaleci: 'kaleci',
  Mevki.defans: 'defans',
  Mevki.ortaSaha: 'orta saha',
  Mevki.forvet: 'forvet',
};

/// Kadroda ilk 11 kurulabiliyor mu? Eksik mevkileri yazıyla döndürür, boşsa tamam.
List<String> eksikMevkiler(List<Oyuncu> kadro) {
  final eksik = <String>[];
  ilkOnbirIhtiyaci.forEach((mevki, gereken) {
    final sayi = kadro.where((o) => o.mevki == mevki).length;
    if (sayi < gereken) {
      eksik.add('${gereken - sayi} ${_mevkiAdi[mevki]} eksik');
    }
  });
  return eksik;
}

/// Bir takımın hücum ve savunma gücü (kabaca 0-100 arası).
class TakimGucu {
  const TakimGucu(this.hucum, this.savunma);
  final double hucum;
  final double savunma;
}

/// Kadrodaki en iyi 11'den takım gücünü hesaplar.
/// Hücum: forvetlerin hücumu (%60) + orta sahaların orta saha değeri (%40).
/// Savunma: defansların savunması (%60) + kalecinin kaleci değeri (%40).
TakimGucu takimGucuHesapla(List<Oyuncu> kadro) {
  List<Oyuncu> enIyi(Mevki m, int adet) {
    final l = kadro.where((o) => o.mevki == m).toList()
      ..sort((a, b) => b.genel.compareTo(a.genel));
    return l.take(adet).toList();
  }

  // Oyuncu yoksa 30 varsayılır (takım çok zayıf sayılır).
  double ort(Iterable<int> d) =>
      d.isEmpty ? 30 : d.reduce((a, b) => a + b) / d.length;

  final fv = enIyi(Mevki.forvet, ilkOnbirIhtiyaci[Mevki.forvet]!);
  final os = enIyi(Mevki.ortaSaha, ilkOnbirIhtiyaci[Mevki.ortaSaha]!);
  final df = enIyi(Mevki.defans, ilkOnbirIhtiyaci[Mevki.defans]!);
  final kl = enIyi(Mevki.kaleci, ilkOnbirIhtiyaci[Mevki.kaleci]!);

  final hucum =
      0.6 * ort(fv.map((o) => o.hucum)) + 0.4 * ort(os.map((o) => o.ortaSaha));
  final savunma =
      0.6 * ort(df.map((o) => o.savunma)) + 0.4 * ort(kl.map((o) => o.kaleci));
  return TakimGucu(hucum, savunma);
}

/// Maç sonucu üretir: gol sayıları, takım güçlerine bağlı Poisson dağılımıyla.
/// Güçlü takım daha sık kazanır ama sürpriz sonuçlar da olur.
class MacSimulatoru {
  MacSimulatoru([int? seed]) : _rnd = Random(seed);

  final Random _rnd;

  /// (ev sahibi golü, deplasman golü)
  (int, int) oyna(TakimGucu ev, TakimGucu dep) {
    final lamEv = _lambda(1.45, ev.hucum, dep.savunma); // ev avantajı
    final lamDep = _lambda(1.2, dep.hucum, ev.savunma);
    return (_poisson(lamEv), _poisson(lamDep));
  }

  double _lambda(double taban, double hucum, double savunma) {
    final oran = hucum / savunma;
    return (taban * pow(oran, 3)).clamp(0.2, 4.5).toDouble();
  }

  int _poisson(double lambda) {
    final l = exp(-lambda);
    var k = 0;
    var p = 1.0;
    do {
      k++;
      p *= _rnd.nextDouble();
    } while (p > l);
    return min(k - 1, 9);
  }
}

/// Dairesel yöntemle fikstür üretir. Her hafta bir liste (ev, deplasman) çiftidir.
/// Takım sayısı tekse her hafta bir takım dinlenir.
List<List<(String, String)>> fiksturUret(
  List<String> takimIdleri, {
  bool ciftDevre = false,
}) {
  final t = <String?>[...takimIdleri];
  if (t.length.isOdd) t.add(null);
  final m = t.length;

  final haftalar = <List<(String, String)>>[];
  for (var r = 0; r < m - 1; r++) {
    final hafta = <(String, String)>[];
    for (var i = 0; i < m ~/ 2; i++) {
      final a = t[i];
      final b = t[m - 1 - i];
      if (a == null || b == null) continue; // dinlenen takım
      final cevir = i == 0 && r.isOdd; // ev/deplasman dengesi
      hafta.add(cevir ? (b, a) : (a, b));
    }
    haftalar.add(hafta);
    t.insert(1, t.removeLast()); // ilk eleman sabit, diğerleri döner
  }

  if (ciftDevre) {
    haftalar.addAll([
      for (final h in haftalar) [for (final p in h) (p.$2, p.$1)],
    ]);
  }
  return haftalar;
}

/// Firestore'daki bir maç.
class Mac {
  const Mac({
    required this.id,
    required this.hafta,
    required this.evId,
    required this.depId,
    required this.evAd,
    required this.depAd,
    required this.oynandi,
    this.evGol,
    this.depGol,
  });

  final String id;
  final int hafta;
  final String evId;
  final String depId;
  final String evAd;
  final String depAd;
  final bool oynandi;
  final int? evGol;
  final int? depGol;

  factory Mac.fromMap(String id, Map<String, dynamic> m) => Mac(
        id: id,
        hafta: m['hafta'] as int,
        evId: m['evId'] as String,
        depId: m['depId'] as String,
        evAd: m['evAd'] as String,
        depAd: m['depAd'] as String,
        oynandi: m['oynandi'] as bool,
        evGol: m['evGol'] as int?,
        depGol: m['depGol'] as int?,
      );
}

/// Puan tablosunda bir takımın satırı.
class PuanSatiri {
  PuanSatiri(this.takimId, this.takimAdi);

  final String takimId;
  final String takimAdi;
  int oynanan = 0;
  int galibiyet = 0;
  int beraberlik = 0;
  int maglubiyet = 0;
  int atilan = 0;
  int yenilen = 0;

  int get averaj => atilan - yenilen;
  int get puan => galibiyet * 3 + beraberlik;
}

/// Oynanmış maçlardan puan tablosunu çıkarır. Sıralama: puan, averaj, atılan gol.
List<PuanSatiri> puanTablosuHesapla(
  Map<String, String> takimAdlari,
  Iterable<Mac> maclar,
) {
  final oynanmisMaclar = maclar.where((m) => m.oynandi).toList();

  final tablo = {
    for (final e in takimAdlari.entries) e.key: PuanSatiri(e.key, e.value),
  };

  // İstatistikleri hesapla
  for (final m in oynanmisMaclar) {
    final ev = tablo[m.evId];
    final dep = tablo[m.depId];
    if (ev == null || dep == null) continue;

    final evGol = m.evGol ?? 0;
    final depGol = m.depGol ?? 0;
    ev.oynanan++;
    dep.oynanan++;
    ev.atilan += evGol;
    ev.yenilen += depGol;
    dep.atilan += depGol;
    dep.yenilen += evGol;

    if (evGol > depGol) {
      ev.galibiyet++;
      dep.maglubiyet++;
    } else if (evGol < depGol) {
      dep.galibiyet++;
      ev.maglubiyet++;
    } else {
      ev.beraberlik++;
      dep.beraberlik++;
    }
  }

  final liste = tablo.values.toList();

  liste.sort((a, b) {
    // 1. Kriter: Toplam Puan
    final puanFarki = b.puan.compareTo(a.puan);
    if (puanFarki != 0) return puanFarki;

    // 2. Kriter: İkili Averaj (Sadece iki takımın puanı eşitse aralarındaki maçlara bakılır)
    final ikiliKarsilastirma = _ikiliAverajKarsilastir(a.takimId, b.takimId, oynanmisMaclar);
    if (ikiliKarsilastirma != 0) return ikiliKarsilastirma;

    // 3. Kriter: Genel Averaj
    final averajFarki = b.averaj.compareTo(a.averaj);
    if (averajFarki != 0) return averajFarki;

    // 4. Kriter: Atılan Gol
    final atilanFarki = b.atilan.compareTo(a.atilan);
    if (atilanFarki != 0) return atilanFarki;

    // 5. Kriter: Takım Adı
    return a.takimAdi.compareTo(b.takimAdi);
  });

  return liste;
}

/// İki takım arasındaki maçların puan ve averaj farkını hesaplar.
/// Negatif dönerse 'a' üstte, pozitif dönerse 'b' üstte yer alır.
int _ikiliAverajKarsilastir(String takimA, String takimB, List<Mac> maclar) {
  final aralarindakiMaclar = maclar.where((m) =>
      (m.evId == takimA && m.depId == takimB) ||
      (m.evId == takimB && m.depId == takimA));

  if (aralarindakiMaclar.isEmpty) return 0;

  int aPuan = 0;
  int bPuan = 0;
  int aGol = 0;
  int bGol = 0;

  for (final m in aralarindakiMaclar) {
    final evGol = m.evGol ?? 0;
    final depGol = m.depGol ?? 0;

    if (m.evId == takimA) {
      aGol += evGol;
      bGol += depGol;
      if (evGol > depGol) {
        aPuan += 3;
      } else if (evGol < depGol) {
        bPuan += 3;
      } else {
        aPuan += 1;
        bPuan += 1;
      }
    } else {
      bGol += evGol;
      aGol += depGol;
      if (evGol > depGol) {
        bPuan += 3;
      } else if (evGol < depGol) {
        aPuan += 3;
      } else {
        aPuan += 1;
        bPuan += 1;
      }
    }
  }

  // Önce aralarındaki puan üstünlüğü
  if (bPuan != aPuan) {
    return bPuan.compareTo(aPuan);
  }

  // Puanlar eşitse aralarındaki averaj (gol farkı)
  final aAveraj = aGol - bGol;
  final bAveraj = bGol - aGol;
  return bAveraj.compareTo(aAveraj);
}
