# 🛒 MyKasir - Modern POS & Table Management App

**MyKasir** adalah aplikasi *Point of Sale* (POS) modern berbasis **Flutter** dan **SQLite** yang dirancang khusus untuk manajemen kasir toko, warung, kafe, dan restoran. Aplikasi ini dilengkapi dengan alur pemilihan 20 nomor meja ala *cinema seat selection*, manajemen produk berfoto, laporan keuangan visual berdiagram, hingga fitur ganti shift kasir yang cepat.

---

## 🎨 Tema & Desain UI
* **Primary Color:** Emerald Green (`#15803D`) — memberi kesan segar, ramah, dan profesional.
* **Dark Accents:** Slate / Dark Blue (`#0F172A`) — untuk kartu ringkasan metrik.
* **Status Colors:** 
  * 🟢 **Hijau (Emerald):** Meja Kosong & Terpilih.
  * 🔴 **Merah:** Meja Terisi / Sedang Dipesan.
* **Layout:** Adaptif, bersih, responsif, dan mudah digunakan kasir saat jam sibuk.

---

## 🌟 Fitur Utama

### 👑 Hak Akses Owner (Pemilik Usaha)
1. **Katalog Produk & Ringkasan Stok:**
   * Kelola produk (Tambah, Edit, Hapus) lengkap dengan foto, harga jual, margin keuntungan, dan sisa stok.
   * Ringkasan otomatis total varian produk, total sisa stok, dan total nilai modal/stok.
   * Pencarian produk dan filter berdasarkan kategori.
2. **Laporan Penjualan (Financial Dashboard):**
   * Visualisasi grafik & diagram tren transaksi (Omzet & Keuntungan Bersih).
   * Metric card real-time: Total Omset, Keuntungan Bersih, Total Transaksi, dan Item Terjual.
   * Filter periode waktu: **Hari Ini**, **7 Hari**, dan **Bulan Ini**.
   * Ranking **Produk Terlaris (Best Seller)** per periode.
3. **Kelola Staff:**
   * Tambah dan hapus akun Staff/Kasir.
   * Menampilkan avatar, username, serta status staff yang sedang bertugas.
4. **Riwayat Invoice & Struk:**
   * Melihat riwayat seluruh transaksi.
   * Fitur **Cetak Ulang Struk** dan **Hapus Struk**.

---

### 👤 Hak Akses Staff (Kasir)
1. **Alur Pilih Meja (20 Meja Ala Bioskop):**
   * Grid interaktif **Meja 01** sampai **Meja 20**.
   * Penanda visual status meja: Kosong (Hijau) vs Terisi (Merah).
   * Fitur **Kosongkan Meja** manual ketika pelanggan selesai makan/membayar.
   * State meja terpilih tetap tersimpan (tanda hijau tidak hilang) saat kasir berpindah-pindah tab.
2. **Halaman Transaksi & Checkout:**
   * Katalag produk bergambar dengan kontrol jumlah barang di keranjang.
   * **Validasi Meja Terikat:** Tombol *Bayar* WAJIB memilih nomor meja terlebih dahulu.
   * Format otomatis keterangan item pesanan pada nota/invoice: `Nama Produk(meja no X)`.
3. **Riwayat Invoice Real-Time:**
   * Transaksi yang baru selesai dibayar langsung otomatis muncul di halaman Invoice secara *real-time*.
   * Cetak ulang dan manajemen struk kasir.

---

### 🔄 Fitur Bersama (Shared System)
* **Auto-Login Sesi Persisten:** Pengguna tidak perlu mengetik kredensial ulang setiap kali aplikasi dibuka.
* **Ganti Shift Kasir:** Modal pergantian shift kasir cepat dengan *chip selection* akun staff terdaftar.
* **Penyimpanan Lokal Offline:** Seluruh data (Produk, Meja, Invoice, User, Shift) tersimpan aman di database lokal **SQLite**.

---

## 📱 Alur Kerja Aplikasi (Workflow Kasir)

```text
[ Halaman Pilih Meja ] ──► Staff Klik Meja Kosong (Tanda Hijau "Pilih")
                                   │
                                   ▼
[ Halaman Transaksi ] ──► Pilih Produk / Tambah ke Keranjang
                                   │
                                   ▼
[ Pembayaran / Bayar ] ──► Validasi Meja ──► Cetak Nota `Kopi susu(meja no 1)`
                                   │
                                   ▼
[ Halaman Invoice ]   ◄── Otomatis Update Data & Status Meja Jadi Merah (Terisi)
```

---

## 🛠️ Teknologi & Packages

* **Framework:** [Flutter](https://flutter.dev/) (Dart)
* **Database:** [SQLite (`sqflite`)](https://pub.dev/packages/sqflite)
* **State Management:** Provider / Riverpod / SetState
* **Charts & Visuals:** [`fl_chart`](https://pub.dev/packages/fl_chart)
* **App Icon Generator:** [`flutter_launcher_icons`](https://pub.dev/packages/flutter_launcher_icons)
* **Image Picker / Storage:** `image_picker` & `path_provider`

---

## 🚀 Cara Menjalankan Proyek

1. **Clone Repositori:**
   ```bash
   git clone https://github.com/username-anda/mykasir.git
   cd mykasir
   ```

2. **Install Dependensi:**
   ```bash
   flutter pub get
   ```

3. **Generate Icon Aplikasi:**
   Pastikan aset ikon tersedia di `assets/icon/app_icon.png`, lalu jalankan:
   ```bash
   dart run flutter_launcher_icons
   ```

4. **Jalankan Aplikasi:**
   ```bash
   flutter run
   ```

---

## 📄 Lisensi
Hak Cipta © 2026 **MyKasir Team**. Diterbitkan di bawah lisensi MIT - bebas digunakan dan dikembangkan kembali.
