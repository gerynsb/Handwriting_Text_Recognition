import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tentang'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'HTR - Handwriting Recognition',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Aplikasi ini digunakan untuk pengenalan teks tulisan tangan berbasis model CRNN + CTC.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _infoCard(
              context,
              title: 'Fitur Utama',
              lines: const [
                '1. Scan gambar dari kamera atau galeri',
                '2. OCR mode single line dan paragraph',
                '3. Penyimpanan riwayat hasil OCR',
                '4. Konfigurasi backend API langsung dari aplikasi',
              ],
            ),
            const SizedBox(height: 12),
            _infoCard(
              context,
              title: 'Untuk Tugas Akhir',
              lines: const [
                'Tampilan didesain minimalis agar alur penggunaan lebih fokus.',
                'Struktur aplikasi: Flutter (UI) + Flask (inference backend).',
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(BuildContext context,
      {required String title, required List<String> lines}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...lines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                line,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
