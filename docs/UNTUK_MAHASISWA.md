# 🎯 Panduan untuk Mahasiswa

## ⚠️ PENTING: Kode Sengaja Tidak Aman!

Semua kode di repository ini **SENGAJA DIBUAT TIDAK AMAN** untuk tujuan pembelajaran.

**Tugas Anda**: Memperbaiki kode yang bermasalah menjadi aman dengan menerapkan prinsip Security by Design.

---

## 📚 Apa yang Harus Anda Lakukan?

### 1. Jangan Langsung Coding!

Sebelum mulai coding, lakukan ini:

✅ Baca `PETUNJUK_MODUL_X.md` dengan teliti  
✅ Baca `KISI-KISI_PERBAIKAN.md` untuk tahu struktur solusi  
✅ Identifikasi SEMUA masalah yang ada  
✅ Baca test cases untuk tahu requirement  
✅ Buat design/diagram sederhana  
✅ Baru mulai coding

### 2. Gunakan Kisi-Kisi sebagai Panduan

File **`KISI-KISI_PERBAIKAN.md`** berisi:
- ✅ Checklist file apa saja yang harus dibuat
- ✅ Struktur class/method yang diperlukan
- ✅ Hint implementasi (tanpa kode lengkap)
- ✅ Urutan pengerjaan yang disarankan

**Contoh dari kisi-kisi**:
```
Model LoginAttempt harus punya method:
- recordFailure(string $email, string $ip): void
- shouldLockout(string $email): bool
- clearAttempts(string $email): void
```

Anda harus implementasi sendiri berdasarkan hint ini.

### 3. Pahami Konsep, Bukan Hanya Fix Bug

Lab ini bukan tentang "fix bug". Lab ini tentang **memahami kenapa desain yang buruk menyebabkan masalah keamanan**.

**Contoh Salah**:
```php
// Hanya tambah validasi di controller
if ($amount < 0) {
    return response()->json(['error' => 'Invalid amount']);
}
```

**Contoh Benar**:
```php
// Buat Value Object yang tidak bisa invalid
final class Money {
    private function __construct(private int $cents) {
        if ($cents < 0) {
            throw new InvalidArgumentException('Money cannot be negative');
        }
    }
}
```

### 3. Test-Driven Development

Test cases adalah requirement Anda:

```bash
# Jalankan test untuk satu modul
php artisan test --filter=Modul1AuthTest

# Semua test akan GAGAL di awal
# Perbaiki satu test pada satu waktu
# Jangan lanjut sebelum test PASS
```

**Workflow yang benar**:
1. Baca test case → tahu requirement
2. Baca kisi-kisi → tahu struktur solusi
3. Implementasi
4. Run test
5. Debug jika gagal
6. Repeat sampai PASS

---

## 🔍 Cara Mengidentifikasi Masalah

### Modul 1: Authentication

**Buka file**: `app/Http/Controllers/AuthController.php`

**Tanya diri Anda**:
- ❓ Apa yang terjadi jika attacker coba login 1000x dengan password berbeda?
- ❓ Apakah ada yang mencatat failed login attempts?
- ❓ Apakah ada lockout mechanism?
- ❓ Apakah session bisa dicuri dan dipakai di device lain?

**Buka file**: `app/Models/User.php`

**Tanya diri Anda**:
- ❓ Apakah model ini hanya data container?
- ❓ Apakah ada business logic untuk security?
- ❓ Apakah ada method seperti `isLocked()`, `canAttemptLogin()`?

### Modul 2: Order & Refund

**Buka file**: `app/Models/Order.php`

**Tanya diri Anda**:
- ❓ Apakah status bisa diubah langsung tanpa validasi?
- ❓ Apakah bisa refund tanpa melalui paid → shipped → delivered?
- ❓ Apakah amount bisa negatif?
- ❓ Apakah amount bisa diubah setelah order dibuat?
- ❓ Apakah kombinasi boolean invalid bisa terjadi? (is_refunded=true tapi is_paid=false)

### Modul 3: E-Wallet

**Buka file**: `app/Models/Wallet.php`

**Tanya diri Anda**:
- ❓ Apakah saldo bisa negatif?
- ❓ Apakah ada daily limit?
- ❓ Apa yang terjadi jika 2 request withdraw bersamaan?
- ❓ Apakah transfer atomic? (bisa gagal di tengah?)
- ❓ Apakah bisa transfer ke wallet sendiri?

### Modul 4: Voucher & Promo

**Buka file**: `app/Models/Voucher.php`

**Tanya diri Anda**:
- ❓ Apa yang terjadi jika 2 user redeem voucher yang sama bersamaan?
- ❓ Apakah ada idempotency? (retry bisa double redeem?)
- ❓ Apakah voucher code case-sensitive?
- ❓ Apakah discount bisa negatif?
- ❓ Apakah max usage enforced?
- ❓ Apakah ada max usage per user?

---

## 🛠️ Apa yang Harus Dibuat?

> 💡 **Lihat detail lengkap di `KISI-KISI_PERBAIKAN.md`**

### Untuk Setiap Modul, Anda Akan Membuat:

#### 1. Value Objects
Untuk domain concepts yang tidak boleh invalid:
- `Money` (tidak bisa negatif)
- `VoucherCode` (format valid, normalized)
- `Discount` (type-safe)

#### 2. Enums
Untuk status yang terbatas:
- `OrderStatus` (bukan string bebas)
- `DiscountType` (percentage atau fixed)
- `TransactionType` (deposit, withdrawal, transfer)

#### 3. Domain Models (Deep Models)
Dengan business logic dan domain rules:
- Method untuk enforce rules: `canBeRedeemed()`, `isLocked()`
- Method untuk transitions: `confirmPayment()`, `ship()`
- Private methods untuk validation

#### 4. Domain Services
Untuk operasi yang melibatkan multiple entities:
- `WalletTransferService` (atomic transfer)
- `VoucherRedemptionService` (with locking)

#### 5. Domain Events
Untuk audit trail:
- `OrderPaid`, `OrderRefunded`
- `WalletDebited`, `WalletSuspended`
- `VoucherRedeemed`, `VoucherAbuseDetected`

#### 6. Listeners
Untuk side effects:
- `LogOrderEvent` (audit log)
- `DetectAnomalousActivity` (anomaly detection)
- `DetectVoucherAbuse` (abuse prevention)

#### 7. Migrations
Untuk table baru:
- `login_attempts`
- `audit_logs`
- `wallet_transactions`
- `voucher_redemptions`

#### 8. Exceptions
Untuk domain errors:
- `InvalidStateTransition`
- `InsufficientBalanceException`
- `VoucherCannotBeRedeemedException`

---

## 📋 Cara Menggunakan Kisi-Kisi

File `KISI-KISI_PERBAIKAN.md` adalah panduan struktur solusi Anda.

### Contoh: Modul 1 - LoginAttempt

**Kisi-kisi memberitahu**:
```
Model LoginAttempt harus punya:
- recordFailure(string $email, string $ip): void
- shouldLockout(string $email): bool  
- clearAttempts(string $email): void
```

**Anda harus implementasi**:
```php
class LoginAttempt extends Model {
    public static function recordFailure(string $email, string $ip): void {
        // TODO: Implementasi Anda
        // Hint: Create record dengan success=false
    }
    
    public static function shouldLockout(string $email): bool {
        // TODO: Implementasi Anda
        // Hint: Count attempts dalam 15 menit terakhir
        // Return true jika >= 5
    }
}
```

### Contoh: Modul 2 - Value Object Money

**Kisi-kisi memberitahu**:
```
Value Object Money harus:
- private int $cents
- private function __construct(int $cents) - validasi tidak negatif
- public static function fromCents(int $cents): self
- public function toCents(): int
```

**Anda harus implementasi**:
```php
final class Money {
    private function __construct(private int $cents) {
        // TODO: Throw exception jika negatif
    }
    
    public static function fromCents(int $cents): self {
        // TODO: Return new instance
    }
}
```

### Kisi-Kisi BUKAN Solusi Lengkap

Kisi-kisi hanya memberikan:
- ✅ Struktur (file apa, class apa, method apa)
- ✅ Signature method (parameter dan return type)
- ✅ Hint singkat (validasi apa, logic apa)

Kisi-kisi TIDAK memberikan:
- ❌ Implementasi lengkap
- ❌ Kode copy-paste
- ❌ Solusi detail

**Anda harus berpikir dan mengimplementasikan sendiri!**

---

## ✅ Checklist Sebelum Submit

### Functionality
- [ ] Semua test PASS
- [ ] Tidak ada bug
- [ ] Edge cases tertangani

### Code Quality
- [ ] Clean code (readable, maintainable)
- [ ] Proper naming (descriptive, consistent)
- [ ] No code duplication
- [ ] Separation of concerns

### Security
- [ ] Domain rules enforced di model
- [ ] Invalid state tidak bisa terjadi
- [ ] Audit trail lengkap
- [ ] Race condition handled
- [ ] Immutability enforced untuk field penting

### Documentation
- [ ] Code comments untuk logic kompleks
- [ ] README untuk setiap modul (opsional tapi recommended)
- [ ] Penjelasan design decisions

---

## 🚫 Kesalahan Umum yang Harus Dihindari

### ❌ Hanya Tambah Validasi di Controller
```php
// SALAH - validasi bisa dibypass dari controller lain
public function refund($id) {
    if ($order->status !== 'delivered') {
        return response()->json(['error' => 'Cannot refund']);
    }
    $order->status = 'refunded';
}
```

### ✅ Pindahkan Logic ke Model
```php
// BENAR - validasi di model, tidak bisa dibypass
class Order {
    public function requestRefund(): void {
        if ($this->status !== OrderStatus::DELIVERED) {
            throw new CannotRefundException();
        }
        $this->status = OrderStatus::REFUND_REQUESTED;
    }
}
```

### ❌ Pakai Primitives untuk Domain Concepts
```php
// SALAH
public float $amount; // Bisa negatif
public string $status; // Bisa typo
```

### ✅ Pakai Value Objects dan Enums
```php
// BENAR
public Money $amount; // Tidak bisa negatif
public OrderStatus $status; // Type-safe
```

### ❌ Tidak Pakai Transaction dan Locking
```php
// SALAH - race condition
$voucher->usage_count++;
$voucher->save();
```

### ✅ Pakai Transaction dan Locking
```php
// BENAR
DB::transaction(function() {
    $voucher = Voucher::lockForUpdate()->find($id);
    $voucher->usage_count++;
    $voucher->save();
});
```

---

## 💡 Tips Sukses

### 1. Baca Dokumentasi Laravel
- Eloquent Events
- Database Transactions
- Pessimistic Locking
- Custom Casts
- Enums (PHP 8.1+)

### 2. Diskusi dengan Teman
- Diskusi konsep: ✅ OK
- Copy-paste kode: ❌ TIDAK OK

### 3. Gunakan Debugger
- Jangan hanya `dd()` atau `var_dump()`
- Pelajari Xdebug atau Laravel Telescope

### 4. Commit Sering
```bash
git add .
git commit -m "Modul 1: Add LoginAttempt model"
git commit -m "Modul 1: Implement lockout mechanism"
```

### 5. Jangan Skip Test
Test adalah requirement. Jika test gagal, ada yang salah dengan implementasi Anda.

---

## 📖 Referensi

### Books
- Domain-Driven Design by Eric Evans
- Clean Code by Robert C. Martin

### Online
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Laravel Documentation](https://laravel.com/docs)
- [Martin Fowler's Blog](https://martinfowler.com/)

### File di Repository Ini
- `KONSEP_SECURITY_BY_DESIGN.md` - Penjelasan konsep
- `PETUNJUK_MODUL_X.md` - Petunjuk detail per modul
- `VERIFIKASI_KODE_TIDAK_AMAN.md` - Daftar masalah yang ada

---

## ❓ FAQ

**Q: Boleh pakai package Laravel seperti Fortify?**  
A: Tidak untuk Modul 1. Tujuannya adalah memahami konsep, bukan pakai package.

**Q: Harus pakai DDD pattern strict?**  
A: Tidak harus strict DDD. Yang penting konsep security by design diterapkan.

**Q: Boleh pakai AI untuk bantuan?**  
A: Boleh untuk memahami konsep, tapi jangan copy-paste solusi. Harus paham kenapa solusi itu benar.

**Q: Berapa lama seharusnya mengerjakan?**  
A: 20-25 jam total untuk 4 modul. Jangan terburu-buru, fokus pada pemahaman.

**Q: Test gagal terus, apa yang salah?**  
A: Baca error message dengan teliti. Debug dengan `dd()`. Cek apakah migration sudah dijalankan.

---

## 🎓 Mindset yang Benar

### ❌ Mindset Salah:
"Saya harus fix bug ini secepat mungkin"

### ✅ Mindset Benar:
"Saya harus memahami kenapa desain ini tidak aman, dan bagaimana cara mendesain yang benar"

---

## 🚀 Selamat Belajar!

Ingat: **Security by Design bukan tentang tools atau fitur tambahan. Security by Design adalah tentang desain dan arsitektur yang aman dari awal.**

Good luck! 💪
