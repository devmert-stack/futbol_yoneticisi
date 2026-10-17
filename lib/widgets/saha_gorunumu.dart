import 'package:flutter/material.dart';
import '../oyuncu_uretici.dart';

class SahaGorunumu extends StatelessWidget {
  final Map<String, Oyuncu?> kadro;
  final Function(String mevkiKodu)? onOyuncuSec;

  const SahaGorunumu({
    super.key,
    required this.kadro,
    this.onOyuncuSec,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.72,
      child: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF2E7D32),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            _buildSahaCizgileri(),
            // 2 FORVET (ST1, ST2)
            _buildOyuncuHatti(ustKonum: 0.12, mevkiler: const ['ST1', 'ST2']),
            // 4 ORTA SAHA (LM, LCM, RCM, RM)
            _buildOyuncuHatti(ustKonum: 0.38, mevkiler: const ['LM', 'LCM', 'RCM', 'RM']),
            // 4 DEFANS (LB, CB1, CB2, RB)
            _buildOyuncuHatti(ustKonum: 0.65, mevkiler: const ['LB', 'CB1', 'CB2', 'RB']),
            // 1 KALECİ (GK)
            _buildOyuncuHatti(ustKonum: 0.86, mevkiler: const ['GK']),
          ],
        ),
      ),
    );
  }

  Widget _buildOyuncuHatti({
    required double ustKonum,
    required List<String> mevkiler,
  }) {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              Positioned(
                top: constraints.maxHeight * ustKonum,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: mevkiler.map((mevkiKodu) {
                    final oyuncu = kadro[mevkiKodu];
                    return _buildOyuncuKarti(mevkiKodu, oyuncu);
                  }).toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOyuncuKarti(String mevkiKodu, Oyuncu? oyuncu) {
    final String fiyatMetni = oyuncu != null ? '${oyuncu.fiyat.toStringAsFixed(0)}M' : '';
    final String isimMetni = oyuncu != null ? '${oyuncu.ad} ${oyuncu.soyad}' : mevkiKodu;

    return GestureDetector(
      onTap: () => onOyuncuSec?.call(mevkiKodu),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: oyuncu != null ? Colors.amber[700] : Colors.black45,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Center(
              child: oyuncu != null
                  ? Text(
                      fiyatMetni,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    )
                  : const Icon(Icons.add, color: Colors.white70, size: 22),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              isimMetni,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSahaCizgileri() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        return Stack(
          children: [
            Positioned(
              top: h / 2 - 1,
              left: 0,
              right: 0,
              child: Container(height: 2, color: Colors.white.withValues(alpha: 0.6)),
            ),
            Center(
              child: Container(
                width: w * 0.32,
                height: w * 0.32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 2),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: w * 0.22,
              right: w * 0.22,
              child: Container(
                height: h * 0.16,
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.white.withValues(alpha: 0.6), width: 2),
                    left: BorderSide(color: Colors.white.withValues(alpha: 0.6), width: 2),
                    right: BorderSide(color: Colors.white.withValues(alpha: 0.6), width: 2),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: w * 0.22,
              right: w * 0.22,
              child: Container(
                height: h * 0.16,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.white.withValues(alpha: 0.6), width: 2),
                    left: BorderSide(color: Colors.white.withValues(alpha: 0.6), width: 2),
                    right: BorderSide(color: Colors.white.withValues(alpha: 0.6), width: 2),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}