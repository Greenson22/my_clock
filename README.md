# Multi Timer

Manajemen Timer dan Alarm Andal Anda

[Tempatkan GIF Demo Aplikasi atau Screenshot di sini]

## 🚀 Tentang Aplikasi

Multi Timer adalah aplikasi utilitas yang dibangun menggunakan Flutter, dirancang untuk mengelola beberapa *countdown timer* dan *alarm* standar secara bersamaan. Aplikasi ini ideal untuk berbagai aktivitas seperti memasak, berolahraga, belajar, atau situasi apa pun yang memerlukan beberapa pengatur waktu sekaligus.

Kekuatan utama aplikasi ini adalah layanan latar belakang (background service) yang persisten. Ini memastikan semua timer countdown Anda tetap berjalan akurat dan berbunyi bahkan saat aplikasi ditutup atau perangkat di-restart.

## ✨ Fitur Utama

### ⏰ Countdown Timer
* **Timer Ganda:** Buat, jeda, lanjutkan, dan reset beberapa timer secara bersamaan.
* **Personalisasi Penuh:**
    * Ubah nama timer (misalnya, "Rebus Telur", "Latihan").
    * Pilih ikon unik untuk setiap timer menggunakan pemilih Emoji atau input keyboard.
* **Suara Alarm Kustom:** Pilih file audio (MP3, WAV, dll.) Anda sendiri dari penyimpanan perangkat sebagai nada dering timer.
* **Manajemen Mudah:** Hapus semua timer sekaligus atau atur ulang tata letak grid dengan fitur *drag-and-drop*.
* **Visual Progres:** Setiap timer memiliki indikator kemajuan lingkaran yang jelas.

### 🔔 Alarm Standar
* **Mode Cepat:** Setel alarm dengan cepat "dalam X menit" (misalnya, alarm berbunyi 10 menit dari sekarang).
* **Mode Manual:** Setel alarm pada waktu tertentu dengan opsi pengulangan harian (Senin-Minggu).
* **Integrasi Sistem:** Menggunakan API jam alarm asli perangkat (`FlutterAlarmClock`) untuk memastikan keandalan maksimum.

### ⚙️ Layanan Latar Belakang & Notifikasi
* **Berjalan Persisten:** Timer countdown berjalan di `flutter_background_service` yang terisolasi, memastikan timer tetap berjalan bahkan jika aplikasi ditutup paksa (force close).
* **Notifikasi Cerdas:**
    * Notifikasi *foreground service* yang sedang berjalan menunjukkan status semua timer yang aktif.
    * Saat timer selesai, notifikasi prioritas tinggi akan muncul.
    * Tombol "Matikan Alarm" pada notifikasi dapat menghentikan audio bahkan saat aplikasi ditutup (menggunakan `SharedPreferences` sebagai jembatan komunikasi).
* **Penyimpanan Lokal:** Semua timer dan alarm Anda disimpan dengan aman di perangkat menggunakan `shared_preferences`.

### 🎨 Lainnya
* **Tema Terang & Gelap:** Beralih antara mode terang dan gelap, atau biarkan aplikasi mengikuti preferensi sistem Anda.
* **Halaman Tentang:** Menampilkan informasi aplikasi dan nomor versi saat ini.

## 🛠️ Teknologi yang Digunakan

* **Flutter:** Framework UI untuk membangun aplikasi.
* **Provider:** Untuk manajemen state, terutama untuk `ThemeProvider`.
* **`flutter_background_service`:** Komponen inti untuk menjalankan timer di latar belakang secara persisten.
* **`flutter_local_notifications`:** Untuk menampilkan notifikasi progres dan notifikasi saat timer selesai.
* **`shared_preferences`:** Untuk menyimpan semua data timer, alarm, dan pengaturan tema.
* **`just_audio` / `flutter_ringtone_player`:** Untuk memutar suara alarm default atau kustom.
* **`file_picker`:** Untuk memungkinkan pengguna memilih file audio kustom.
* **`flutter_alarm_clock`:** Untuk mengintegrasikan dengan layanan jam alarm sistem Android/iOS.
* **`reorderable_grid_view`:** Untuk fungsionalitas *drag-and-drop* pada halaman countdown.
* **`percent_indicator`:** Untuk menampilkan UI lingkaran progres timer.
* **`package_info_plus`:** Untuk mengambil versi aplikasi secara dinamis di halaman "Tentang".

## 🔧 Instalasi dan Penyiapan

Aplikasi ini dibuat dengan Flutter. Pastikan Anda memiliki Flutter SDK yang terinstal.

1.  **Clone repositori:**
    ```
    git clone [URL_REPOSITORI_ANDA_DI_SINI]
    ```

2.  **Pindah ke direktori:**
    ```
    cd multi_timer
    ```

3.  **Instal dependensi:**
    ```
    flutter pub get
    ```

4.  **Jalankan aplikasi:**
    ```
    flutter run
    ```

**Catatan:** Aplikasi ini memerlukan izin **Notifikasi** untuk berfungsi dengan benar.

## 👨‍💻 Dibuat Oleh

* **Frendy Rikal Gerung, S.Kom.**
* *Sarjana Komputer dari Universitas Negeri Manado*