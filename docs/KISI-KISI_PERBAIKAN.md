# 📋 Kisi-Kisi Perbaikan Kode

## Panduan Struktur Solusi (Tanpa Kode Lengkap)

Dokumen ini memberikan **petunjuk struktur** apa yang harus dibuat untuk setiap modul, tanpa memberikan implementasi lengkap. Gunakan ini sebagai checklist.

---

## Modul 1: Authentication & Login Security

### ✅ Checklist Yang Harus Dibuat

#### 1. Migration Baru
**File**: `database/migrations/YYYY_MM_DD_create_login_attempts_table.php`

**Struktur table `login_attempts`**:
- [ ] `id` (primary key)
- [ ] `email` (string, indexed)
- [ ] `ip_address` (string)
- [ ] `user_agent` (text, nullable)
- [ ] `success` (boolean)
- [ ] `attempted_at` (timestamp)
- [ ] Index pada `(email, attempted_at)` untuk query cepat

**Update table `users`** (buat migration baru):
- [ ] `locked_until` (timestamp, nullable)
- [ ] `failed_login_attempts` (integer, default 0)

#### 2. Model Baru
**File**: `app/Models/LoginAttempt.php`

**Method yang harus ada**:
- [ ] `recordFailure(string $email, string $ip): void` - static method
- [ ] `recordSuccess(string $email, string $ip): void` - static method
- [ ] `shouldLockout(string $email): bool` - static method, cek apakah >= 5 attempts dalam 15 menit
- [ ] `clearAttempts(string $email): void` - static method

**Hint**: Gunakan `$timestamps = false` karena pakai `attempted_at` custom

#### 3. Update Model User
**File**: `app/Models/User.php`

**Method baru yang harus ditambahkan**:
- [ ] `isLocked(): bool` - cek apakah `locked_until` masih di masa depan
- [ ] `lockUntil(Carbon $until): void` - set `locked_until`
- [ ] `unlock(): void` - clear `locked_until` dan `failed_login_attempts`
- [ ] `canAttemptLogin(): bool` - return `!$this->isLocked()`
- [ ] `incrementFailedAttempts(): void` - increment counter, lock jika >= 5
- [ ] `clearFailedAttempts(): void` - reset counter ke 0

**Hint**: Gunakan `protected $casts = ['locked_until' => 'datetime']`

#### 4. Update AuthController
**File**: `app/Http/Controllers/AuthController.php`

**Logic yang harus ditambahkan di method `login()`**:
1. [ ] Ambil email dari request
2. [ ] Cek `LoginAttempt::shouldLockout($email)` - jika true, return 429
3. [ ] Cari user by email
4. [ ] Jika user ada, cek `$user->isLocked()` - jika true, return 429
5. [ ] Coba `Auth::attempt()`
6. [ ] Jika gagal:
   - Record dengan `LoginAttempt::recordFailure()`
   - Jika user ada, panggil `$user->incrementFailedAttempts()`
7. [ ] Jika berhasil:
   - Record dengan `LoginAttempt::recordSuccess()`
   - Clear dengan `LoginAttempt::clearAttempts()`
   - Clear dengan `$user->clearFailedAttempts()`

**Hint**: Jangan lupa `use Illuminate\Support\Facades\Auth;`

---

## Modul 2: Order & Refund System

### ✅ Checklist Yang Harus Dibuat

#### 1. Enum untuk Status
**File**: `app/Enums/OrderStatus.php`

**Cases yang harus ada**:
- [ ] `PENDING = 'pending'`
- [ ] `PAID = 'paid'`
- [ ] `SHIPPED = 'shipped'`
- [ ] `DELIVERED = 'delivered'`
- [ ] `REFUND_REQUESTED = 'refund_requested'`
- [ ] `REFUNDED = 'refunded'`
- [ ] `CANCELLED = 'cancelled'`

**Hint**: `enum OrderStatus: string { ... }`

#### 2. Value Object untuk Money
**File**: `app/ValueObjects/Money.php`

**Structure**:
- [ ] `private int $cents` - simpan dalam cents untuk precision
- [ ] `private function __construct(int $cents)` - validasi tidak negatif
- [ ] `public static function fromCents(int $cents): self`
- [ ] `public static function fromRupiah(float $rupiah): self`
- [ ] `public function toCents(): int`
- [ ] `public function toRupiah(): float`
- [ ] `public function isGreaterThan(Money $other): bool`

**Hint**: Class harus `final`, constructor harus `private`, throw `InvalidArgumentException` jika negatif

#### 3. Migration untuk Audit Log
**File**: `database/migrations/YYYY_MM_DD_create_audit_logs_table.php`

**Struktur table**:
- [ ] `id`
- [ ] `event` (string) - nama event
- [ ] `order_id` (foreign key, nullable)
- [ ] `user_id` (foreign key, nullable)
- [ ] `ip_address` (string)
- [ ] `data` (json, nullable)
- [ ] `created_at`

#### 4. Model AuditLog
**File**: `app/Models/AuditLog.php`

**Casts**:
- [ ] `'data' => 'array'`

**Hint**: Model ini immutable (tidak bisa update/delete)

#### 5. Update Model Order
**File**: `app/Models/Order.php`

**Ubah**:
- [ ] `protected $fillable` → `protected $guarded = ['id', 'amount', 'order_date', 'user_id']`
- [ ] Tambah cast: `'status' => OrderStatus::class`
- [ ] Hapus semua boolean flags (`is_paid`, `is_shipped`, dll)

**Method baru (transition methods)**:
- [ ] `confirmPayment(): void` - validasi status PENDING, ubah ke PAID, set `paid_at`, emit event
- [ ] `ship(): void` - validasi status PAID, ubah ke SHIPPED, set `shipped_at`
- [ ] `confirmDelivery(): void` - validasi status SHIPPED, ubah ke DELIVERED, set `delivered_at`
- [ ] `requestRefund(string $reason): void` - validasi status DELIVERED, ubah ke REFUND_REQUESTED
- [ ] `approveRefund(): void` - validasi status REFUND_REQUESTED, ubah ke REFUNDED, emit event

**Accessor untuk immutability**:
```php
public function setAmountAttribute($value) {
    if ($this->exists) {
        throw new ImmutableFieldException('amount');
    }
    $this->attributes['amount'] = $value;
}
```

**Hint**: Setiap transition throw `InvalidStateTransition` jika state salah

#### 6. Domain Events
**Files**:
- [ ] `app/Events/OrderPaid.php` - constructor menerima `Order $order`
- [ ] `app/Events/OrderRefunded.php` - constructor menerima `Order $order`

#### 7. Event Listener
**File**: `app/Listeners/LogOrderEvent.php`

**Method**: `handle($event)` - create AuditLog dengan data dari event

**Hint**: Register di `EventServiceProvider`

#### 8. Exception Classes
**Files**:
- [ ] `app/Exceptions/InvalidStateTransition.php` - extends `Exception`
- [ ] `app/Exceptions/ImmutableFieldException.php` - extends `Exception`

#### 9. Update OrderController
**File**: `app/Http/Controllers/OrderController.php`

**Ubah semua method untuk pakai transition methods**:
- [ ] `pay()` → panggil `$order->confirmPayment()`
- [ ] `ship()` → panggil `$order->ship()`
- [ ] `deliver()` → panggil `$order->confirmDelivery()`
- [ ] `requestRefund()` → panggil `$order->requestRefund($reason)`
- [ ] `approveRefund()` → panggil `$order->approveRefund()`
- [ ] Hapus method `updateAmount()` (tidak boleh ada)

**Hint**: Wrap dalam try-catch untuk handle exceptions

---

## Modul 3: E-Wallet System

### ✅ Checklist Yang Harus Dibuat

#### 1. Value Object Money (jika belum dari Modul 2)
Sama seperti Modul 2

#### 2. Migration untuk Wallet Transactions
**File**: `database/migrations/YYYY_MM_DD_create_wallet_transactions_table.php`

**Struktur table**:
- [ ] `id`
- [ ] `from_wallet_id` (foreign key, nullable)
- [ ] `to_wallet_id` (foreign key, nullable)
- [ ] `amount` (integer) - dalam cents
- [ ] `type` (string) - deposit/withdrawal/transfer
- [ ] `status` (string) - pending/completed/failed
- [ ] `metadata` (json, nullable)
- [ ] `created_at`, `updated_at`

#### 3. Update Migration Wallets
**File**: Buat migration baru untuk alter table

**Tambah kolom**:
- [ ] `daily_spent` (decimal, default 0)
- [ ] `daily_spent_date` (date, nullable)
- [ ] `is_suspended` (boolean, default false)
- [ ] `suspended_reason` (string, nullable)
- [ ] `suspended_at` (timestamp, nullable)

#### 4. Enums
**Files**:
- [ ] `app/Enums/TransactionType.php` - DEPOSIT, WITHDRAWAL, TRANSFER
- [ ] `app/Enums/TransactionStatus.php` - PENDING, COMPLETED, FAILED, REVERSED

#### 5. Model WalletTransaction
**File**: `app/Models/WalletTransaction.php`

**Immutable**: Tambah di `boot()` method untuk prevent update/delete

#### 6. Update Model Wallet
**File**: `app/Models/Wallet.php`

**Constants**:
- [ ] `private const DAILY_LIMIT = 10000000;` (10 juta)

**Method baru**:
- [ ] `debit(Money $amount): void` - validasi, lock, decrement, emit event
- [ ] `credit(Money $amount): void` - lock, increment, emit event
- [ ] `canDebit(Money $amount): bool` - private, cek saldo cukup
- [ ] `exceedsDailyLimit(Money $amount): bool` - private, cek daily limit
- [ ] `suspend(string $reason): void` - set suspended flags, emit event

**Hint**: Gunakan `DB::transaction()` dan `lockForUpdate()`

#### 7. Domain Service
**File**: `app/Services/WalletTransferService.php`

**Method**:
- [ ] `transfer(Wallet $from, Wallet $to, Money $amount): WalletTransaction`
  - Validasi tidak transfer ke diri sendiri
  - Wrap dalam `DB::transaction()`
  - Panggil `$from->debit()` dan `$to->credit()`
  - Create `WalletTransaction` record
  - Emit event

#### 8. Domain Events
**Files**:
- [ ] `app/Events/WalletDebited.php`
- [ ] `app/Events/WalletCredited.php`
- [ ] `app/Events/WalletTransferred.php`
- [ ] `app/Events/WalletSuspended.php`

#### 9. Event Listener untuk Anomaly Detection
**File**: `app/Listeners/DetectAnomalousActivity.php`

**Logic**: Handle `WalletDebited`, cek transaksi dalam 5 menit terakhir, jika > 10 maka suspend

#### 10. Update WalletController
**File**: `app/Http/Controllers/WalletController.php`

**Ubah**:
- [ ] `deposit()` → panggil `$wallet->credit(Money::fromRupiah($amount))`
- [ ] `withdraw()` → panggil `$wallet->debit(Money::fromRupiah($amount))`
- [ ] `transfer()` → inject `WalletTransferService`, panggil `$service->transfer()`
- [ ] Hapus method `sendNotification()`, `generateReport()`, `detectFraud()`

---

## Modul 4: Voucher & Promo System

### ✅ Checklist Yang Harus Dibuat

#### 1. Value Object VoucherCode
**File**: `app/ValueObjects/VoucherCode.php`

**Structure**:
- [ ] `private string $code`
- [ ] `private function __construct(string $code)` - validasi format `/^[A-Z0-9]{6,12}$/`
- [ ] `public static function fromString(string $code): self` - normalize (uppercase, trim)
- [ ] `public function toString(): string`
- [ ] `public function equals(VoucherCode $other): bool`

#### 2. Value Object Discount
**File**: `app/ValueObjects/Discount.php`

**Structure**:
- [ ] `private int $amountCents`
- [ ] `private DiscountType $type`
- [ ] `private function __construct(int $amountCents, DiscountType $type)` - validasi
- [ ] `public static function percentage(int $percentage): self`
- [ ] `public static function fixed(Money $amount): self`
- [ ] `public function apply(Money $originalPrice): Money` - hitung discount

#### 3. Enum DiscountType
**File**: `app/Enums/DiscountType.php`

**Cases**:
- [ ] `PERCENTAGE = 'percentage'`
- [ ] `FIXED = 'fixed'`

#### 4. Migration untuk Voucher Redemptions
**File**: `database/migrations/YYYY_MM_DD_create_voucher_redemptions_table.php`

**Struktur table**:
- [ ] `id`
- [ ] `voucher_id` (foreign key)
- [ ] `user_id` (foreign key)
- [ ] `order_id` (foreign key, nullable)
- [ ] `idempotency_key` (string, unique) - **PENTING untuk prevent double redeem**
- [ ] `discount_amount` (integer) - dalam cents
- [ ] `ip_address` (string)
- [ ] `redeemed_at` (timestamp)
- [ ] `created_at`, `updated_at`
- [ ] Index pada `(voucher_id, user_id)`
- [ ] Index pada `idempotency_key`

#### 5. Model VoucherRedemption
**File**: `app/Models/VoucherRedemption.php`

**Immutable**: Tambah di `boot()` untuk prevent update/delete

#### 6. Update Model Voucher
**File**: `app/Models/Voucher.php`

**Ubah**:
- [ ] `protected $guarded = ['id', 'usage_count']` - usage_count tidak boleh diubah manual
- [ ] Tambah cast: `'valid_from' => 'datetime'`, `'valid_until' => 'datetime'`

**Validation di boot()**:
- [ ] `creating()` - validasi `valid_until > valid_from`, `max_usage > 0`, normalize code
- [ ] `updating()` - prevent ubah `code`, `max_usage`, `valid_from`; prevent kurangi `usage_count`

**Method baru**:
- [ ] `canBeRedeemed(User $user): bool` - gabungan semua validasi
- [ ] `isActive(): bool` - cek `is_active`
- [ ] `isWithinValidityPeriod(): bool` - cek now between valid_from dan valid_until
- [ ] `hasRemainingUsage(): bool` - cek `usage_count < max_usage`
- [ ] `hasUserExceededLimit(User $user): bool` - query VoucherRedemption, cek per-user limit
- [ ] `redeem(User $user, string $idempotencyKey): VoucherRedemption` - **PENTING**:
  - Cek idempotency key dulu (return existing jika ada)
  - Validasi `canBeRedeemed()`
  - Wrap dalam `DB::transaction()`
  - `lockForUpdate()` untuk prevent race condition
  - Double-check setelah lock
  - Increment `usage_count`
  - Create `VoucherRedemption` record
  - Emit event
- [ ] `deactivate(string $reason): void` - set `is_active = false`, emit event

#### 7. Domain Service
**File**: `app/Services/VoucherRedemptionService.php`

**Method**:
- [ ] `redeemVoucher(VoucherCode $code, User $user, Order $order, string $idempotencyKey): VoucherRedemption`
  - Find voucher by code
  - Validasi `canBeRedeemed()`
  - Validasi order belum punya voucher
  - Panggil `$voucher->redeem()`
  - Calculate discount
  - Apply ke order

#### 8. Domain Events
**Files**:
- [ ] `app/Events/VoucherRedeemed.php`
- [ ] `app/Events/VoucherDeactivated.php`
- [ ] `app/Events/VoucherAbuseDetected.php`

#### 9. Event Listener
**File**: `app/Listeners/DetectVoucherAbuse.php`

**Logic**:
- [ ] Handle `VoucherRedeemed`
- [ ] Cek redemption user dalam 5 menit terakhir, jika > 10 maka deactivate voucher
- [ ] Cek unique IP dalam 1 jam terakhir, jika > 50 maka deactivate voucher

#### 10. Update VoucherController
**File**: `app/Http/Controllers/VoucherController.php`

**Ubah**:
- [ ] `redeem()` - inject `VoucherRedemptionService`, generate idempotency key dari request header atau generate UUID
- [ ] `create()` - validasi input, normalize code
- [ ] Hapus method `checkUsage()` (security risk - enumeration attack)

---

## 🎯 Tips Implementasi

### Urutan Pengerjaan yang Disarankan

**Modul 1**:
1. Buat migration `login_attempts`
2. Buat model `LoginAttempt` dengan static methods
3. Update migration `users` (tambah kolom)
4. Update model `User` dengan methods
5. Update `AuthController`
6. Test

**Modul 2**:
1. Buat enum `OrderStatus`
2. Buat value object `Money`
3. Buat exceptions
4. Update model `Order` (guarded, casts, transition methods)
5. Buat migration `audit_logs`
6. Buat events dan listeners
7. Update `OrderController`
8. Test

**Modul 3**:
1. Buat enums (`TransactionType`, `TransactionStatus`)
2. Buat migration `wallet_transactions`
3. Update migration `wallets` (tambah kolom)
4. Update model `Wallet` (methods dengan locking)
5. Buat model `WalletTransaction` (immutable)
6. Buat service `WalletTransferService`
7. Buat events dan listeners
8. Update `WalletController`
9. Test

**Modul 4**:
1. Buat enum `DiscountType`
2. Buat value objects (`VoucherCode`, `Discount`)
3. Buat migration `voucher_redemptions`
4. Update model `Voucher` (validation di boot, methods)
5. Buat model `VoucherRedemption` (immutable)
6. Buat service `VoucherRedemptionService`
7. Buat events dan listeners
8. Update `VoucherController`
9. Test

### Pola Umum yang Sering Dipakai

**1. Pessimistic Locking**:
```php
DB::transaction(function() {
    $model = Model::lockForUpdate()->find($id);
    // ... modify model
    $model->save();
});
```

**2. Immutable Model**:
```php
protected static function boot() {
    parent::boot();
    static::updating(fn() => throw new Exception('Immutable'));
    static::deleting(fn() => throw new Exception('Immutable'));
}
```

**3. Value Object Pattern**:
```php
final class ValueObject {
    private function __construct(private $value) {
        // validate
    }
    public static function from($value): self {
        return new self($value);
    }
}
```

**4. Domain Event**:
```php
class SomethingHappened {
    public function __construct(public Model $model) {}
}

// Di model
event(new SomethingHappened($this));
```

---

## ✅ Checklist Akhir

Sebelum submit, pastikan:

- [ ] Semua test PASS
- [ ] Tidak ada kode duplikasi
- [ ] Semua exception di-handle
- [ ] Semua domain rules di model, bukan controller
- [ ] Semua field penting immutable
- [ ] Semua operasi critical pakai locking
- [ ] Semua event penting tercatat
- [ ] Code clean dan readable

---

**Catatan**: Kisi-kisi ini memberikan struktur dan hint, tapi TIDAK memberikan implementasi lengkap. Anda harus berpikir dan mengimplementasikan sendiri berdasarkan konsep yang sudah dipelajari.
