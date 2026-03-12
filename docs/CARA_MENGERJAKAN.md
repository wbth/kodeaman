# Cara Mengerjakan Lab Security by Design

## Persiapan

1. Clone repository ini
2. Install dependencies:
   ```bash
   composer install
   ```

3. Setup database:
   ```bash
   cp .env.example .env
   php artisan key:generate
   php artisan migrate
   ```

4. Jalankan test untuk melihat masalah:
   ```bash
   php artisan test
   ```
   Semua test akan GAGAL karena kode memang sengaja bermasalah.

## Urutan Pengerjaan

### Modul 1: Authentication (Estimasi: 3-4 jam)

1. Baca `PETUNJUK_MODUL_1.md`
2. Identifikasi masalah di:
   - `app/Http/Controllers/AuthController.php`
   - `app/Models/User.php`
   - `database/migrations/2024_01_01_000001_create_users_table.php`

3. Yang harus dibuat:
   - Migration untuk `login_attempts` table
   - Model `LoginAttempt` dengan method:
     - `recordFailure()`
     - `shouldLockout()`
     - `clearAttempts()`
   - Update `User` model dengan method:
     - `isLocked()`
     - `lockUntil()`
     - `canAttemptLogin()`
   - Update `AuthController` untuk enforce rules

4. Jalankan test:
   ```bash
   php artisan test --filter=Modul1AuthTest
   ```

5. Semua test harus PASS sebelum lanjut ke modul berikutnya.

### Modul 2: Order & Refund (Estimasi: 4-5 jam)

1. Baca `PETUNJUK_MODUL_2.md`
2. Identifikasi masalah di:
   - `app/Http/Controllers/OrderController.php`
   - `app/Models/Order.php`
   - `database/migrations/2024_01_01_000002_create_orders_table.php`

3. Yang harus dibuat:
   - Enum `OrderStatus` (atau class)
   - Value Object `Money`
   - Update `Order` model dengan transition methods:
     - `confirmPayment()`
     - `ship()`
     - `confirmDelivery()`
     - `requestRefund()`
     - `approveRefund()`
   - Migration untuk `audit_logs` table
   - Model `AuditLog`
   - Events: `OrderPaid`, `OrderRefunded`
   - Listener: `LogOrderEvent`
   - Update `OrderController` untuk pakai transition methods

4. Jalankan test:
   ```bash
   php artisan test --filter=Modul2OrderTest
   ```

### Modul 3: E-Wallet (Estimasi: 5-6 jam)

1. Baca `PETUNJUK_MODUL_3.md`
2. Identifikasi masalah di:
   - `app/Http/Controllers/WalletController.php`
   - `app/Models/Wallet.php`
   - `database/migrations/2024_01_01_000003_create_wallets_table.php`

3. Yang harus dibuat:
   - Value Object `Money` (jika belum dari modul 2)
   - Update `Wallet` model dengan method:
     - `debit(Money $amount)`
     - `credit(Money $amount)`
     - `canDebit(Money $amount)`
     - `exceedsDailyLimit(Money $amount)`
     - `suspend(string $reason)`
   - Service `WalletTransferService`
   - Migration untuk `wallet_transactions` table
   - Model `WalletTransaction` (immutable)
   - Enums: `TransactionType`, `TransactionStatus`
   - Events: `WalletDebited`, `WalletCredited`, `WalletTransferred`, `WalletSuspended`
   - Listener: `DetectAnomalousActivity`
   - Update `WalletController` untuk pakai service

4. Jalankan test:
   ```bash
   php artisan test --filter=Modul3WalletTest
   ```

### Modul 4: Voucher & Promo (Estimasi: 4-5 jam)

1. Baca `PETUNJUK_MODUL_4.md`
2. Identifikasi masalah di:
   - `app/Http/Controllers/VoucherController.php`
   - `app/Models/Voucher.php`
   - `database/migrations/2024_01_01_000004_create_vouchers_table.php`

3. Yang harus dibuat:
   - Value Objects: `VoucherCode`, `DiscountValue`, `ValidityPeriod`
   - Enum `DiscountType`
   - Update `Voucher` model dengan method:
     - `canBeRedeemedBy(User, Order)`
     - `isActive()`
     - `isUsedUp()`
     - `calculateDiscount(Money)`
   - Service `VoucherRedemptionService` dengan locking
   - Migration untuk `voucher_redemptions` table
   - Model `VoucherRedemption` (immutable)
   - Events: `VoucherRedeemed`, `SuspiciousVoucherActivity`
   - Listener: `DetectVoucherAbuse`

4. Jalankan test:
   ```bash
   php artisan test --filter=Modul4VoucherTest
   ```

### Modul 5: Session & Auth Token (Estimasi: 4-5 jam)

1. Baca `PETUNJUK_MODUL_5.md`
2. Identifikasi masalah di:
   - `app/Models/AuthToken.php`
   - `database/migrations/2024_01_01_000005_create_auth_tokens_table.php`

3. Yang harus dibuat:
   - Value Object `SessionFingerprint`
   - Update `AuthToken` model dengan method:
     - `isValid()`
     - `isExpired()`
     - `isRevoked()`
     - `belongsToFingerprint()`
     - `use()`
     - `revoke()`
     - `refresh()`
   - Middleware `ValidateAuthToken`
   - Service `TokenCleanupService`
   - Events: `TokenRevoked`, `SuspiciousTokenActivity`
   - Exception: `TokenHijackedException`

4. Jalankan test:
   ```bash
   php artisan test --filter=Modul5AuthTokenTest
   ```

### Modul 4: Voucher & Promo (Estimasi: 5-6 jam)

1. Baca `PETUNJUK_MODUL_4.md`
2. Identifikasi masalah di:
   - `app/Http/Controllers/VoucherController.php`
   - `app/Models/Voucher.php`
   - `database/migrations/2024_01_01_000004_create_vouchers_table.php`

3. Yang harus dibuat:
   - Value Objects: `VoucherCode`, `Discount`
   - Enum: `DiscountType`
   - Update `Voucher` model dengan method:
     - `canBeRedeemed(User $user)`
     - `isActive()`
     - `isWithinValidityPeriod()`
     - `hasRemainingUsage()`
     - `hasUserExceededLimit(User $user)`
     - `redeem(User $user, string $idempotencyKey)`
     - `deactivate(string $reason)`
   - Migration untuk `voucher_redemptions` table
   - Model `VoucherRedemption` (immutable)
   - Service `VoucherRedemptionService`
   - Events: `VoucherRedeemed`, `VoucherDeactivated`, `VoucherAbuseDetected`
   - Listener: `DetectVoucherAbuse`
   - Update `VoucherController` untuk pakai service

4. Jalankan test:
   ```bash
   php artisan test --filter=Modul4VoucherTest
   ```

## Tips Pengerjaan

### 1. Jangan Langsung Coding
- Baca petunjuk dengan teliti
- Identifikasi semua masalah dulu
- Buat design/diagram sederhana
- Baru mulai coding

### 2. Test-Driven Development
- Baca test case dulu untuk tahu requirement
- Jalankan test untuk lihat error
- Perbaiki satu test case pada satu waktu
- Jangan lanjut sebelum test PASS

### 3. Commit Sering
```bash
git add .
git commit -m "Modul 1: Add LoginAttempt model"
git commit -m "Modul 1: Implement lockout mechanism"
```

### 4. Gunakan Laravel Features
- Eloquent Events
- Database Transactions
- Pessimistic Locking (`lockForUpdate()`)
- Enum (PHP 8.1+)
- Custom Casts

### 5. Jangan Skip Konsep
Setiap modul mengajarkan konsep penting:
- Modul 1: Deep Model, Domain Rules
- Modul 2: State Machine, Immutability, Value Objects
- Modul 3: Aggregate, Domain Events, Separation of Concerns
- Modul 4: Race Condition Prevention, Pessimistic Locking
- Modul 5: Session Security, Token Binding, Hijacking Detection
- Modul 4: Race Condition, Idempotency, Pessimistic Locking, Quota Management

## Kriteria Penilaian

### Functionality (40%)
- Semua test PASS
- Tidak ada bug
- Edge cases tertangani

### Code Quality (30%)
- Clean code
- Proper naming
- No code duplication
- Separation of concerns

### Security (20%)
- Domain rules enforced
- Invalid state tidak bisa terjadi
- Audit trail lengkap
- Race condition handled

### Documentation (10%)
- Code comments
- README untuk setiap modul
- Penjelasan design decisions

## Troubleshooting

### Test Gagal Terus
- Baca error message dengan teliti
- Debug dengan `dd()` atau `dump()`
- Cek database dengan `php artisan tinker`

### Migration Error
```bash
php artisan migrate:fresh
```

### Autoload Error
```bash
composer dump-autoload
```

### Cache Issue
```bash
php artisan config:clear
php artisan cache:clear
php artisan route:clear
```

## Referensi

- [Laravel Documentation](https://laravel.com/docs)
- [Domain-Driven Design](https://martinfowler.com/tags/domain%20driven%20design.html)
- [OWASP Security Cheat Sheet](https://cheatsheetseries.owasp.org/)
- [State Pattern](https://refactoring.guru/design-patterns/state)
- [Value Objects](https://martinfowler.com/bliki/ValueObject.html)

## Bantuan

Jika stuck:
1. Baca petunjuk lagi
2. Lihat test case untuk clue
3. Diskusi dengan teman (tapi jangan copy-paste)
4. Tanya asisten lab

Good luck! 🚀
