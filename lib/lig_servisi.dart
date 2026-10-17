import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'mac_simulatoru.dart';
import 'oyuncu_uretici.dart' show Oyuncu, OyuncuUretici;

/// Kullanıcıya gösterilebilecek lig hatası.
class LigHatasi implements Exception {
  LigHatasi(this.mesaj);
  final String mesaj;

  @override
  String toString() => mesaj;
}

/// Firestore yapısı:
///   leagues/{ligId}                 -> lig bilgisi, üyeler, davet kodu, durum, aktifHafta
///   leagues/{ligId}/oyuncular/{id}  -> ligin kendi oyuncu havuzu
///   leagues/{ligId}/takimlar/{uid}  -> takım: ad, bütçe (milyon), kadro (oyuncu id listesi)
///   leagues/{ligId}/maclar/{macId}  -> maç: hafta, evId, depId, evAd, depAd, oynandi, skor
class LigServisi {
  LigServisi._();

  static const maxUye = 5;
  static const baslangicButcesi = 100.0; // milyon
  static const kadroSiniri = 15;

  // O/0 ve I/1 gibi karışan karakterler yok.
  static const _kodHarfleri = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  static final _db = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> get _ligler =>
      _db.collection('leagues');

  static String get _uid => FirebaseAuth.instance.currentUser!.uid;

  static String _kodUret() {
    final r = Random.secure();
    return List.generate(
      6,
      (_) => _kodHarfleri[r.nextInt(_kodHarfleri.length)],
    ).join();
  }

  static Map<String, dynamic> _yeniTakim(String ad) => {
        'ad': ad,
        'butce': baslangicButcesi,
        'kadro': <String>[],
      };

  /// Fiyatlar tek ondalıklı; kayan nokta kayması olmasın diye yuvarlıyoruz.
  static double _yuvarla(double d) => (d * 10).round() / 10;

  /// Yeni lig kurar, oyuncu havuzunu üretip yazar. Lig id'sini döndürür.
  static Future<String> ligKur({
    required String ligAdi,
    required String takimAdi,
  }) async {
    var kod = _kodUret();
    while ((await _ligler.where('davetKodu', isEqualTo: kod).limit(1).get())
        .docs
        .isNotEmpty) {
      kod = _kodUret();
    }

    final uid = _uid;
    final ligRef = _ligler.doc();
    final havuz = OyuncuUretici(seed: Random().nextInt(1 << 30)).havuzUret();

    final batch = _db.batch();
    batch.set(ligRef, {
      'ad': ligAdi,
      'davetKodu': kod,
      'kurucuId': uid,
      'durum': 'kurulum', // 'kurulum', 'devam_ediyor', 'bitti'
      'aktifHafta': 1,
      'toplamHafta': 0,
      'maxUye': maxUye,
      'uyeIdleri': [uid],
      'uyeler': {uid: takimAdi},
      'olusturma': FieldValue.serverTimestamp(),
    });
    batch.set(ligRef.collection('takimlar').doc(uid), _yeniTakim(takimAdi));
    for (final o in havuz) {
      batch.set(ligRef.collection('oyuncular').doc(o.id), o.toMap());
    }
    await batch.commit();
    return ligRef.id;
  }

  /// Davet koduyla bir lige katılır. Lig id'sini döndürür.
  static Future<String> ligeKatil({
    required String kod,
    required String takimAdi,
  }) async {
    final uid = _uid;
    final sonuc = await _ligler
        .where('davetKodu', isEqualTo: kod.trim().toUpperCase())
        .limit(1)
        .get();
    if (sonuc.docs.isEmpty) throw LigHatasi('Bu kodla bir lig bulunamadı.');
    final ref = sonuc.docs.first.reference;

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final veri = snap.data()!;
      final uyeIdleri = List<String>.from(veri['uyeIdleri'] as List);

      if (uyeIdleri.contains(uid)) return;
      if (veri['durum'] != 'kurulum') {
        throw LigHatasi('Bu lig başlamış, artık katılamazsın.');
      }
      if (uyeIdleri.length >= (veri['maxUye'] as int)) {
        throw LigHatasi('Lig dolu.');
      }

      tx.update(ref, {
        'uyeIdleri': FieldValue.arrayUnion([uid]),
        'uyeler.$uid': takimAdi,
      });
      tx.set(ref.collection('takimlar').doc(uid), _yeniTakim(takimAdi));
    });
    return ref.id;
  }

  /// Havuzdaki boş bir oyuncuyu bütçeyle satın alır.
  static Future<void> oyuncuAl({
    required String ligId,
    required String oyuncuId,
  }) async {
    final uid = _uid;
    final lig = _ligler.doc(ligId);
    final oyuncuRef = lig.collection('oyuncular').doc(oyuncuId);
    final takimRef = lig.collection('takimlar').doc(uid);

    await _db.runTransaction((tx) async {
      final oyuncuSnap = await tx.get(oyuncuRef);
      final takimSnap = await tx.get(takimRef);
      final oyuncu = oyuncuSnap.data();
      final takim = takimSnap.data();

      if (oyuncu == null) throw LigHatasi('Oyuncu bulunamadı.');
      if (takim == null) {
        throw LigHatasi(
            'Takımın bulunamadı. Bu lig eski sürümle kurulmuş, yeni bir lig kur.');
      }
      if (oyuncu['takimId'] != null) {
        throw LigHatasi('Bu oyuncu az önce başka takıma geçti.');
      }

      final kadro = List<String>.from(takim['kadro'] as List);
      final butce = (takim['butce'] as num).toDouble();
      final fiyat = (oyuncu['fiyat'] as num).toDouble();

      if (kadro.length >= kadroSiniri) {
        throw LigHatasi('Kadro dolu (en fazla $kadroSiniri oyuncu).');
      }
      if (fiyat > butce) throw LigHatasi('Bütçen yetmiyor.');

      tx.update(oyuncuRef, {'takimId': uid});
      tx.update(takimRef, {
        'butce': _yuvarla(butce - fiyat),
        'kadro': FieldValue.arrayUnion([oyuncuId]),
      });
    });
  }

  /// Kendi oyuncunu satar; bütçen geri döner.
  static Future<void> oyuncuSat({
    required String ligId,
    required String oyuncuId,
  }) async {
    final uid = _uid;
    final lig = _ligler.doc(ligId);
    final oyuncuRef = lig.collection('oyuncular').doc(oyuncuId);
    final takimRef = lig.collection('takimlar').doc(uid);

    await _db.runTransaction((tx) async {
      final oyuncuSnap = await tx.get(oyuncuRef);
      final takimSnap = await tx.get(takimRef);
      final oyuncu = oyuncuSnap.data();
      final takim = takimSnap.data();

      if (oyuncu == null || takim == null) {
        throw LigHatasi('Oyuncu ya da takım bulunamadı.');
      }
      if (oyuncu['takimId'] != uid) {
        throw LigHatasi('Bu oyuncu senin takımında değil.');
      }

      final butce = (takim['butce'] as num).toDouble();
      final fiyat = (oyuncu['fiyat'] as num).toDouble();

      tx.update(oyuncuRef, {'takimId': null});
      tx.update(takimRef, {
        'butce': _yuvarla(butce + fiyat),
        'kadro': FieldValue.arrayRemove([oyuncuId]),
      });
    });
  }

  /// Kurucu tarafından sezonu başlatır ve fikstürü üretip kaydeder.
  static Future<void> sezonuBaslat(String ligId) async {
    final ligDoc = await _ligler.doc(ligId).get();
    if (!ligDoc.exists) throw LigHatasi('Lig bulunamadı.');
    final ligData = ligDoc.data()!;

    if (ligData['kurucuId'] != _uid) {
      throw LigHatasi('Yalnızca lig kurucusu sezonu başlatabilir.');
    }
    if (ligData['durum'] != 'kurulum') {
      throw LigHatasi('Bu ligde sezon zaten başlatılmış.');
    }

    final uyeler = Map<String, dynamic>.from(ligData['uyeler'] as Map);
    final takimIdleri = List<String>.from(ligData['uyeIdleri'] as List);

    if (takimIdleri.length < 2) {
      throw LigHatasi('Sezonu başlatmak için en az 2 takım gereklidir.');
    }

    // Tüm oyuncuları bir kerede çekip eşleyelim
    final oyuncularSnap = await _ligler.doc(ligId).collection('oyuncular').get();
    final oyuncuHaritasi = {
      for (final doc in oyuncularSnap.docs)
        doc.id: Oyuncu.fromMap(doc.id, doc.data())
    };

    // Tüm takımların ilk 11 şartını kontrol et
    final takimlarSnap = await _ligler.doc(ligId).collection('takimlar').get();
    for (final doc in takimlarSnap.docs) {
      final takimVeri = doc.data();
      final takimAdi = takimVeri['ad'] ?? uyeler[doc.id] ?? 'Takım';
      final kadroIdleri = List<String>.from((takimVeri['kadro'] as List?) ?? []);

      final kadroOyuncular = kadroIdleri
          .map((id) => oyuncuHaritasi[id])
          .whereType<Oyuncu>()
          .toList();

      final eksikler = eksikMevkiler(kadroOyuncular);
      if (eksikler.isNotEmpty) {
        throw LigHatasi(
          '$takimAdi kadrosunu tamamlamadı:\n${eksikler.join(', ')}',
        );
      }
    }

    // Fikstür üret (çift devre: iç saha ve deplasman)
    final fikstur = fiksturUret(takimIdleri, ciftDevre: true);

    final batch = _db.batch();
    final maclarRef = _ligler.doc(ligId).collection('maclar');

    var macSayaci = 1;
    for (var h = 0; h < fikstur.length; h++) {
      final haftaNo = h + 1;
      for (final mac in fikstur[h]) {
        final evId = mac.$1;
        final depId = mac.$2;
        final evAd = uyeler[evId] as String? ?? 'Ev';
        final depAd = uyeler[depId] as String? ?? 'Dep';

        final yeniMacRef = maclarRef.doc('mac_$macSayaci');
        batch.set(yeniMacRef, {
          'hafta': haftaNo,
          'evId': evId,
          'depId': depId,
          'evAd': evAd,
          'depAd': depAd,
          'oynandi': false,
          'evGol': null,
          'depGol': null,
        });
        macSayaci++;
      }
    }

    // Lig durumunu güncelle
    batch.update(_ligler.doc(ligId), {
      'durum': 'devam_ediyor',
      'aktifHafta': 1,
      'toplamHafta': fikstur.length,
    });

    await batch.commit();
  }

  /// Aktif haftanın maçlarını oynatır ve sonuçları kaydeder.
  static Future<void> haftayiOyna(String ligId) async {
    final ligDoc = await _ligler.doc(ligId).get();
    if (!ligDoc.exists) throw LigHatasi('Lig bulunamadı.');
    final ligData = ligDoc.data()!;

    if (ligData['kurucuId'] != _uid) {
      throw LigHatasi('Yalnızca lig kurucusu haftayı simüle edebilir.');
    }
    if (ligData['durum'] != 'devam_ediyor') {
      throw LigHatasi('Lig devam etmiyor.');
    }

    final aktifHafta = ligData['aktifHafta'] as int? ?? 1;
    final toplamHafta = ligData['toplamHafta'] as int? ?? 1;

    final maclarRef = _ligler.doc(ligId).collection('maclar');
    final haftaMaclariSnap = await maclarRef
        .where('hafta', isEqualTo: aktifHafta)
        .where('oynandi', isEqualTo: false)
        .get();

    if (haftaMaclariSnap.docs.isEmpty) {
      throw LigHatasi('$aktifHafta. hafta maçları zaten oynandı.');
    }

    // Oyuncuları çekip haritala
    final oyuncularSnap = await _ligler.doc(ligId).collection('oyuncular').get();
    final oyuncuHaritasi = {
      for (final doc in oyuncularSnap.docs)
        doc.id: Oyuncu.fromMap(doc.id, doc.data())
    };

    // Takımların kadro güçlerini hesapla
    final takimlarSnap = await _ligler.doc(ligId).collection('takimlar').get();
    final takimGucleri = <String, TakimGucu>{};

    for (final doc in takimlarSnap.docs) {
      final kadroIdleri =
          List<String>.from((doc.data()['kadro'] as List?) ?? []);
      final kadro = kadroIdleri
          .map((id) => oyuncuHaritasi[id])
          .whereType<Oyuncu>()
          .toList();
      takimGucleri[doc.id] = takimGucuHesapla(kadro);
    }

    // Maçları simüle et
    final sim = MacSimulatoru();
    final batch = _db.batch();

    for (final macDoc in haftaMaclariSnap.docs) {
      final m = macDoc.data();
      final evId = m['evId'] as String;
      final depId = m['depId'] as String;

      final evGuc = takimGucleri[evId] ?? const TakimGucu(50, 50);
      final depGuc = takimGucleri[depId] ?? const TakimGucu(50, 50);

      final sonuc = sim.oyna(evGuc, depGuc);

      batch.update(macDoc.reference, {
        'oynandi': true,
        'evGol': sonuc.$1,
        'depGol': sonuc.$2,
      });
    }

    // Bir sonraki haftaya geç veya ligi bitir
    if (aktifHafta < toplamHafta) {
      batch.update(_ligler.doc(ligId), {
        'aktifHafta': aktifHafta + 1,
      });
    } else {
      batch.update(_ligler.doc(ligId), {
        'durum': 'bitti',
      });
    }

    await batch.commit();
  }

  //// Yalnızca lig kurucusu ligi ve altındaki tüm koleksiyonları toplu (Batch) olarak siler.
  static Future<void> ligiSil(String ligId) async {
    final ligRef = _ligler.doc(ligId);
    final ligDoc = await ligRef.get();
    if (!ligDoc.exists) throw LigHatasi('Lig bulunamadı.');

    if (ligDoc.data()?['kurucuId'] != _uid) {
      throw LigHatasi('Yalnızca lig kurucusu ligi silebilir.');
    }

    // Koleksiyonları eşzamanlı (paralel) çek
    final sonuclar = await Future.wait([
      ligRef.collection('maclar').get(),
      ligRef.collection('takimlar').get(),
      ligRef.collection('oyuncular').get(),
    ]);

    // Tek bir batch paketi oluştur
    final batch = _db.batch();

    // Alt belgeleri pakete ekle
    for (final snap in sonuclar) {
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
    }

    // Ana lig belgesini de aynı pakete ekle
    batch.delete(ligRef);

    // Hepsini tek bir istekte Firebase'e gönder
    await batch.commit();
  }
  /// Ligdeki tüm maçları canlı dinler.
  static Stream<List<Mac>> maclar(String ligId) => _ligler
      .doc(ligId)
      .collection('maclar')
      .orderBy('hafta')
      .snapshots()
      .map((s) => s.docs.map((d) => Mac.fromMap(d.id, d.data())).toList());

  /// Giriş yapan kullanıcının üye olduğu ligler.
  static Stream<QuerySnapshot<Map<String, dynamic>>> benimLigler() =>
      _ligler.where('uyeIdleri', arrayContains: _uid).snapshots();

  /// Tek bir ligin canlı verisi.
  static Stream<DocumentSnapshot<Map<String, dynamic>>> lig(String id) =>
      _ligler.doc(id).snapshots();

  /// Ligin oyuncu havuzu.
  static Stream<QuerySnapshot<Map<String, dynamic>>> oyuncular(String ligId) =>
      _ligler.doc(ligId).collection('oyuncular').snapshots();

  /// Kullanıcının bu ligdeki takımı (bütçe ve kadro).
  static Stream<DocumentSnapshot<Map<String, dynamic>>> benimTakim(
          String ligId) =>
      _ligler.doc(ligId).collection('takimlar').doc(_uid).snapshots();

  /// Kullanıcının takımındaki oyuncular.
  static Stream<QuerySnapshot<Map<String, dynamic>>> benimOyuncularim(
          String ligId) =>
      _ligler
          .doc(ligId)
          .collection('oyuncular')
          .where('takimId', isEqualTo: _uid)
          .snapshots();
}