# Integrasi Mobile HTR (Backend + Flutter)

Panduan ini untuk menjalankan keseluruhan sistem:
- Backend API HTR (`FastAPIpy`) berbasis Flask
- Expose API ke publik via Ngrok
- Aplikasi Flutter (`MobileApp`) di emulator Android

## Struktur Folder

```text
Integrasi_Mobile/
  FastAPIpy/   -> Backend API (Flask)
  MobileApp/   -> Aplikasi Flutter
```

## Prasyarat

- Python environment sudah siap (venv)
- Flutter SDK sudah terpasang
- Emulator Android sudah jalan
- Ngrok sudah terpasang

## Urutan Menjalankan Sistem

Jalankan dalam 3 terminal terpisah.

### Terminal 1 - Jalankan Backend API

```powershell
cd "d:\Dokumen Kuliah\TA\Kode Kaggle\Integrasi_Mobile\FastAPIpy"
& "d:/Dokumen Kuliah/TA/Kode Kaggle/venv/Scripts/python.exe" .\app.py
```

Jika ingin pakai aktivasi venv manual:

```powershell
cd "d:\Dokumen Kuliah\TA\Kode Kaggle"
& ".\venv\Scripts\Activate.ps1"
cd ".\Integrasi_Mobile\FastAPIpy"
python .\app.py
```

Health check (opsional):

```powershell
Invoke-RestMethod "http://127.0.0.1:5000/api/health"
```

Jika sukses, response mengandung `"status": "ok"`.

### Terminal 2 - Jalankan Ngrok

```powershell
cd "d:\Dokumen Kuliah\TA\Kode Kaggle"
ngrok http 5000
```

Ambil URL `Forwarding` HTTPS, contoh:

```text
https://abc123.ngrok-free.dev
```

Catatan:
- URL Ngrok berubah saat restart ngrok (plan free)
- Gunakan URL HTTPS untuk aplikasi Flutter

### Terminal 3 - Jalankan Flutter App

```powershell
cd "d:\Dokumen Kuliah\TA\Kode Kaggle\Integrasi_Mobile\MobileApp"
flutter pub get
flutter run -d emulator-5554
```

Jika ingin melihat device yang tersedia:

```powershell
flutter devices
```

## Hubungkan Flutter ke URL Ngrok

Di aplikasi Flutter:

1. Buka tab `Settings`
2. Masuk ke bagian `API Configuration`
3. Isi `Base URL API` dengan URL Ngrok (contoh `https://abc123.ngrok-free.dev`)
4. Tekan `Test Koneksi`
5. Jika sukses, tekan `Simpan URL`

Setelah itu fitur recognition di `Home` akan memakai URL Ngrok yang disimpan.

## Alur Penggunaan Cepat

1. Pilih gambar dari `Gallery` atau `Camera`
2. (Opsional) `Preview Full` atau `Crop`
3. Pilih mode `Single Line` / `Paragraph`
4. Tekan `Recognize`
5. Edit hasil OCR jika perlu
6. Tekan `Save` untuk simpan ke `History`

## Troubleshooting

### 1) API tidak terhubung dari Flutter

- Pastikan backend di Terminal 1 masih jalan
- Pastikan Ngrok di Terminal 2 masih jalan
- Pastikan URL di Settings memakai URL Ngrok terbaru
- Tekan `Test Koneksi` lagi

### 2) Ngrok menampilkan halaman warning HTML

Project ini sudah menambahkan header bypass ngrok di service Flutter.
Jika masih muncul, restart ngrok lalu simpan ulang URL terbaru.

### 3) Flutter gagal build setelah ganti dependency

```powershell
cd "d:\Dokumen Kuliah\TA\Kode Kaggle\Integrasi_Mobile\MobileApp"
flutter clean
flutter pub get
flutter run -d emulator-5554
```

### 4) Backend error saat startup

- Cek path model di `FastAPIpy/config.py`
- Pastikan file model dan LM tersedia
- Cek log error di terminal backend

## Endpoint Backend yang Dipakai Flutter

- `GET /api/health`
- `GET /api/model/info`
- `POST /api/recognize/line`
- `POST /api/recognize/paragraph`
- `POST /api/preprocess`

## Catatan Penting

- Nama folder backend adalah `FastAPIpy`, tetapi implementasi API saat ini menggunakan Flask.
- Untuk deployment production, disarankan gunakan reverse proxy/domain tetap (bukan URL ngrok dinamis).
