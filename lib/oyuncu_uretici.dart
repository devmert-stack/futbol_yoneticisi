import 'dart:math';

/// Oyuncunun sahadaki mevkisi.
enum Mevki { kaleci, defans, ortaSaha, forvet }

extension MevkiEtiket on Mevki {
  String get kisa => switch (this) {
        Mevki.kaleci => 'KL',
        Mevki.defans => 'DF',
        Mevki.ortaSaha => 'OS',
        Mevki.forvet => 'FV',
      };
}

/// Havuzdaki tek bir futbolcu. Tüm değerler 1-99 arasıdır.
class Oyuncu {
  final String id;
  final String ad;
  final String soyad;
  final Mevki mevki;
  final int yas;
  final int hucum;
  final int ortaSaha;
  final int savunma;
  final int kaleci;

  /// Milyon cinsinden fiyat.
  final double fiyat;

  /// Oyuncuyu satın alan takımın id'si. Boşta ise null.
  final String? takimId;

  const Oyuncu({
    required this.id,
    required this.ad,
    required this.soyad,
    required this.mevki,
    required this.yas,
    required this.hucum,
    required this.ortaSaha,
    required this.savunma,
    required this.kaleci,
    required this.fiyat,
    this.takimId,
  });

  String get tamAd => '$ad $soyad';

  /// Oyuncunun kendi mevkisindeki ana değeri.
  int get genel => switch (mevki) {
        Mevki.kaleci => kaleci,
        Mevki.defans => savunma,
        Mevki.ortaSaha => ortaSaha,
        Mevki.forvet => hucum,
      };

  Oyuncu copyWith({String? takimId, bool takimiSil = false}) => Oyuncu(
        id: id,
        ad: ad,
        soyad: soyad,
        mevki: mevki,
        yas: yas,
        hucum: hucum,
        ortaSaha: ortaSaha,
        savunma: savunma,
        kaleci: kaleci,
        fiyat: fiyat,
        takimId: takimiSil ? null : (takimId ?? this.takimId),
      );

  /// Firestore'a yazmak için.
  Map<String, dynamic> toMap() => {
        'ad': ad,
        'soyad': soyad,
        'mevki': mevki.name,
        'yas': yas,
        'hucum': hucum,
        'ortaSaha': ortaSaha,
        'savunma': savunma,
        'kaleci': kaleci,
        'fiyat': fiyat,
        'takimId': takimId,
      };

  /// Firestore'dan okumak için. [id] belge kimliğidir.
  factory Oyuncu.fromMap(String id, Map<String, dynamic> m) => Oyuncu(
        id: id,
        ad: m['ad'] as String,
        soyad: m['soyad'] as String,
        mevki: Mevki.values.byName(m['mevki'] as String),
        yas: m['yas'] as int,
        hucum: m['hucum'] as int,
        ortaSaha: m['ortaSaha'] as int,
        savunma: m['savunma'] as int,
        kaleci: m['kaleci'] as int,
        fiyat: (m['fiyat'] as num).toDouble(),
        takimId: m['takimId'] as String?,
      );
}

/// Rastgele ama gerçekçi görünen futbolcu havuzu üretir.
///
/// Aynı [seed] her zaman aynı havuzu verir. Çok oyunculu ligde havuzu
/// yalnızca lig kurucusu üretip Firestore'a yazmalı, diğerleri okumalıdır.
class OyuncuUretici {
  OyuncuUretici({int? seed}) : _rnd = Random(seed);

  final Random _rnd;

  // İlk sürüm için küçük havuz. Sonra 300+ isme çıkar.
  static const _adlar = [
    'Mehmet', 'Ahmet', 'Emre', 'Burak', 'Can', 'Kerem', 'Arda', 'Baran',
    'Efe', 'Mert', 'Onur', 'Yusuf', 'Selim', 'Tolga', 'Umut', 'Berk',
    'Cem', 'Deniz', 'Eren', 'Kaan', 'Lucas', 'Mateo', 'Rafael', 'Diego',
    'Marco', 'Luka', 'Viktor', 'Andrei', 'Jonas', 'Elias', 'Noah', 'Hugo',
    'Felix', 'Tomas', 'Ivan', 'Mikael', 'Samuel', 'Daniel', 'Pavel', 'Nikola',
  ];

  static const _soyadlar = [
    'Aksoy', 'Karaca', 'Erdem', 'Polat', 'Güneş', 'Tekin', 'Özkan', 'Aydın',
    'Koç', 'Bulut', 'Çelik', 'Sarı', 'Doğan', 'Kılıç', 'Avcı', 'Uçar',
    'Taş', 'Yalçın', 'Korkmaz', 'Arslan', 'Ferreira', 'Moreau', 'Novak',
    'Lindgren', 'Costa', 'Petrov', 'Hoffmann', 'Marin', 'Silva', 'Duarte',
    'Ribeiro', 'Kovač', 'Varga', 'Lopes', 'Becker', 'Larsen', 'Dumont',
    'Fontaine', 'Brandt', 'Bellini',
  ];

  /// Varsayılan dağılım: toplam 120 oyuncu.
  /// 5 takım x 15 kişilik kadro (2 KL, 5 DF, 5 OS, 3 FV) = 75 oyuncu gerekir;
  /// geri kalan ~45 oyuncu seçim payı ve geç gelen transferler içindir.
  static const varsayilanDagilim = {
    Mevki.kaleci: 16,
    Mevki.defans: 40,
    Mevki.ortaSaha: 40,
    Mevki.forvet: 24,
  };

  List<Oyuncu> havuzUret({Map<Mevki, int> dagilim = varsayilanDagilim}) {
    final kullanilanIsimler = <String>{};
    final havuz = <Oyuncu>[];
    var sayac = 0;

    dagilim.forEach((mevki, adet) {
      for (var i = 0; i < adet; i++) {
        sayac++;
        havuz.add(_tekOyuncu('p$sayac', mevki, kullanilanIsimler));
      }
    });
    return havuz;
  }

  Oyuncu _tekOyuncu(String id, Mevki mevki, Set<String> kullanilan) {
    // Benzersiz isim
    late String ad, soyad;
    do {
      ad = _adlar[_rnd.nextInt(_adlar.length)];
      soyad = _soyadlar[_rnd.nextInt(_soyadlar.length)];
    } while (!kullanilan.add('$ad $soyad'));

    final yas = 18 + _rnd.nextInt(19); // 18-36

    // Kalite: üç rastgele sayının ortalaması, yani çan eğrisi.
    // Çok güçlü oyuncu azdır, çoğu ortada toplanır.
    final q = (_rnd.nextDouble() + _rnd.nextDouble() + _rnd.nextDouble()) / 3;
    var ana = 45 + (q * 47).round();
    if (yas <= 20) ana -= 4; // çok genç oyuncular biraz daha zayıf
    ana = ana.clamp(40, 95);

    int dusuk(int min, int max) =>
        (ana - (min + _rnd.nextInt(max - min + 1))).clamp(1, 99);
    int zayif() => 5 + _rnd.nextInt(21); // 5-25

    int hucum, ortaSaha, savunma, kaleci;
    switch (mevki) {
      case Mevki.kaleci:
        kaleci = ana;
        hucum = zayif();
        ortaSaha = zayif();
        savunma = zayif();
      case Mevki.defans:
        savunma = ana;
        ortaSaha = dusuk(15, 30);
        hucum = dusuk(25, 40);
        kaleci = 5 + _rnd.nextInt(11);
      case Mevki.ortaSaha:
        ortaSaha = ana;
        hucum = dusuk(10, 25);
        savunma = dusuk(10, 25);
        kaleci = 5 + _rnd.nextInt(11);
      case Mevki.forvet:
        hucum = ana;
        ortaSaha = dusuk(15, 30);
        savunma = dusuk(30, 45);
        kaleci = 5 + _rnd.nextInt(11);
    }

    return Oyuncu(
      id: id,
      ad: ad,
      soyad: soyad,
      mevki: mevki,
      yas: yas,
      hucum: hucum,
      ortaSaha: ortaSaha,
      savunma: savunma,
      kaleci: kaleci,
      fiyat: fiyatHesapla(ana, yas),
    );
  }

  /// Fiyat, ana değerle üstel olarak artar: 60 civarı ~2.6 milyon,
  /// ortalama oyuncu (~68) ~4.5 milyon, 90 civarı ~22 milyon.
  /// 100 milyonluk bütçeyle ortalama bir 15 kişilik kadro ~70-75 milyona gelir.
  /// Genç oyuncu %20 pahalı, 32 yaş ve üstü %30 ucuz.
  static double fiyatHesapla(int ana, int yas) {
    var fiyat = 0.6 * pow(1.075, ana - 40).toDouble();
    if (yas <= 21) fiyat *= 1.2;
    if (yas >= 32) fiyat *= 0.7;
    return (fiyat * 10).round() / 10; // 1 ondalık
  }
}

/// Konsolda test: `dart run oyuncu_uretici.dart`
void main() {
  final havuz = OyuncuUretici(seed: 42).havuzUret();

  print('Toplam oyuncu: ${havuz.length}\n');
  print('${'İsim'.padRight(22)}MVK YAŞ  HÜC OSA SAV KAL  FİYAT');

  final sirali = [...havuz]..sort((a, b) => b.fiyat.compareTo(a.fiyat));
  for (final o in sirali.take(10)) {
    print('${o.tamAd.padRight(22)}${o.mevki.kisa.padRight(4)}'
        '${o.yas.toString().padRight(5)}'
        '${o.hucum.toString().padRight(4)}${o.ortaSaha.toString().padRight(4)}'
        '${o.savunma.toString().padRight(4)}${o.kaleci.toString().padRight(5)}'
        '${o.fiyat}M');
  }

  print('\nMevkiye göre ortalama fiyat:');
  for (final m in Mevki.values) {
    final liste = havuz.where((o) => o.mevki == m).toList();
    final ort = liste.map((o) => o.fiyat).reduce((a, b) => a + b) / liste.length;
    print('  ${m.name.padRight(9)} ${liste.length} oyuncu, ort. ${ort.toStringAsFixed(1)}M');
  }

  final toplam = havuz.map((o) => o.fiyat).reduce((a, b) => a + b);
  print('\nHavuzun toplam değeri: ${toplam.toStringAsFixed(0)}M');
}
