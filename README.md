# Lab Security by Design - Laravel

## ⚠️ PENTING: Kode Sengaja Tidak Aman!

**Semua kode di repository ini SENGAJA DIBUAT TIDAK AMAN untuk tujuan pembelajaran.**

**Tugas Anda**: Memperbaiki kode yang bermasalah menjadi aman dengan menerapkan prinsip Security by Design.

📖 **Baca dulu**: [`docs/UNTUK_MAHASISWA.md`](docs/UNTUK_MAHASISWA.md) sebelum mulai!

---

## Tujuan Lab

Mahasiswa akan memperbaiki kode Laravel yang memiliki masalah desain keamanan fundamental. Bukan sekadar menambah fitur keamanan, tapi memperbaiki model dan arsitektur.

**Filosofi**: Security bukan fitur tambahan. Security harus dibangun ke dalam desain dari awal.

## Struktur Lab

### Modul 1: Authentication & Login Security
- **File**: `app/Http/Controllers/AuthController.php`, `app/Models/User.php`
- **Masalah**: Tidak ada model untuk login attempts, session tidak ter-bind dengan benar
- **Target**: Implementasi LoginAttempt model, lockout mechanism, session ownership

### Modul 2: Order & Refund System
- **File**: `app/Models/Order.php`, `app/Http/Controllers/OrderController.php`
- **Masalah**: Status string bebas, amount bisa diubah, refund tanpa validasi urutan
- **Target**: State machine, immutability, transition methods

### Modul 3: E-Wallet System
- **File**: `app/Models/Wallet.php`, `app/Http/Controllers/WalletController.php`
- **Masalah**: Saldo negatif, tidak ada daily limit, race condition
- **Target**: Domain rules, aggregate, transaction safety

### Modul 4: Voucher & Promo System
- **File**: `app/Models/Voucher.php`, `app/Http/Controllers/VoucherController.php`
- **Masalah**: Race condition double redemption, tidak ada idempotency, quota tidak enforced
- **Target**: Pessimistic locking, idempotency, value objects, anomaly detection

## Cara Menggunakan

1. Clone repository ini
2. Install dependencies: `composer install`
3. Setup database: `php artisan migrate`
4. Jalankan seeder untuk data test: `php artisan db:seed`
5. Baca petunjuk di setiap modul
6. Perbaiki kode sesuai instruksi
7. Jalankan test: `php artisan test`

## Konsep yang Dipelajari

- Shallow vs Deep Model
- Primitive Obsession
- Boolean Flag Hell
- Anemic Domain Model
- Temporal Coupling
- God Object
- Invalid State Representation
- State Machine Pattern
- Immutability
- Domain-Driven Design
- Audit Trail & Anomaly Detection
- Race Condition Prevention
- Idempotency Pattern
- Pessimistic Locking
- Quota Management

## 📚 File Penting untuk Mahasiswa

### Wajib Dibaca
1. **`UNTUK_MAHASISWA.md`** - Panduan lengkap untuk mahasiswa
2. **`KISI-KISI_PERBAIKAN.md`** - ⭐ Struktur solusi & checklist (TANPA kode lengkap)
3. **`CARA_MENGERJAKAN.md`** - Step-by-step cara mengerjakan
4. **`KONSEP_SECURITY_BY_DESIGN.md`** - Penjelasan konsep

### Petunjuk Per Modul
5. **`PETUNJUK_MODUL_1.md`** - Authentication & Login Security
6. **`PETUNJUK_MODUL_2.md`** - Order & Refund System
7. **`PETUNJUK_MODUL_3.md`** - E-Wallet System
8. **`PETUNJUK_MODUL_4.md`** - Voucher & Promo System

### Referensi
9. **`VERIFIKASI_KODE_TIDAK_AMAN.md`** - Daftar semua masalah yang ada
10. **`RINGKASAN_LAB.md`** - Overview lengkap lab

### Untuk Dosen/Asisten
11. **`PANDUAN_DOSEN.md`** - Panduan mengajar & grading

---

## ⚡ Quick Start

```bash
# 1. Clone repository
git clone [repository-url]

# 2. Install dependencies
composer install

# 3. Setup database
cp .env.example .env
php artisan key:generate
php artisan migrate

# 4. Baca panduan
cat UNTUK_MAHASISWA.md

# 5. Mulai dengan Modul 1
cat PETUNJUK_MODUL_1.md

# 6. Jalankan test
php artisan test --filter=Modul1AuthTest
```

---

## 🎯 Ekspektasi

Setelah menyelesaikan lab ini, mahasiswa akan:

✅ Memahami perbedaan Shallow vs Deep Model  
✅ Bisa mengidentifikasi Primitive Obsession  
✅ Memahami bahaya Boolean Flag Hell  
✅ Bisa implementasi State Machine Pattern  
✅ Memahami konsep Immutability  
✅ Bisa handle Race Condition dengan Pessimistic Locking  
✅ Memahami Idempotency Pattern  
✅ Bisa implementasi Domain Events untuk Audit Trail  
✅ Memahami Value Objects dan kapan menggunakannya  
✅ Bisa mendesain sistem yang aman dari awal (Security by Design)

---

## 📞 Bantuan

Jika stuck:
1. Baca petunjuk lagi dengan teliti
2. Lihat test case untuk clue
3. Baca `KONSEP_SECURITY_BY_DESIGN.md`
4. Diskusi dengan teman (konsep, bukan copy-paste kode)
5. Tanya asisten lab

---

**Good luck! 🚀**
