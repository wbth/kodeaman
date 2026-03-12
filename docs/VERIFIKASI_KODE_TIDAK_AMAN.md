# Verifikasi: Semua Kode Sengaja Tidak Aman

## ✅ Checklist Masalah Keamanan

### Modul 1: Authentication

**AuthController.php**
- ✅ Tidak ada rate limiting → brute force possible
- ✅ Tidak ada tracking login attempts
- ✅ Session tidak di-bind ke device fingerprint
- ✅ Tidak ada lockout mechanism
- ✅ Tidak ada audit trail

**User.php**
- ✅ Shallow model (hanya data container)
- ✅ Semua field fillable (mass assignment vulnerable)
- ✅ Tidak ada method domain logic
- ✅ Tidak ada konsep lockout

**Migration**
- ✅ Tidak ada field locked_until
- ✅ Tidak ada field failed_login_attempts
- ✅ Tidak ada table login_attempts

---

### Modul 2: Order & Refund

**OrderController.php**
- ✅ Amount bisa negatif (tidak ada validasi)
- ✅ Status bisa diubah langsung tanpa validasi urutan
- ✅ Bisa ship tanpa paid
- ✅ Bisa deliver tanpa shipped
- ✅ Bisa refund tanpa delivered
- ✅ Bisa approve refund tanpa request
- ✅ Amount bisa diubah setelah order dibuat
- ✅ Tidak ada audit trail
- ✅ Tidak ada event

**Order.php**
- ✅ Primitive obsession (status string, amount double)
- ✅ Boolean flag hell (is_paid, is_shipped, dll)
- ✅ Anemic model (tidak ada business logic)
- ✅ Semua field fillable (tidak ada immutability)
- ✅ Invalid state bisa terjadi:
  - is_refunded=true tapi is_paid=false
  - is_delivered=true tapi is_shipped=false
  - amount negatif
  - refund_date sebelum order_date

**Migration**
- ✅ amount bisa negatif (no constraint)
- ✅ status string bebas (no enum)
- ✅ Boolean flags (bukan state machine)

---

### Modul 3: E-Wallet

**WalletController.php**
- ✅ Balance bisa negatif (tidak ada validasi)
- ✅ Tidak ada daily limit check
- ✅ Transfer tidak atomic (bisa gagal di tengah)
- ✅ Tidak ada validasi transfer ke diri sendiri
- ✅ Race condition possible (tidak ada locking)
- ✅ Tidak ada transaction log
- ✅ God object (notification, report, fraud di controller)

**Wallet.php**
- ✅ Anemic model (hanya data container)
- ✅ Semua field fillable
- ✅ Tidak ada value object Money
- ✅ Tidak ada domain rules
- ✅ Method withdraw/deposit/transfer tidak aman:
  - Tidak ada validasi saldo
  - Tidak ada locking
  - Tidak atomic
- ✅ God object (notification, report, fraud di model)

**Migration**
- ✅ balance bisa negatif (no constraint)
- ✅ Tidak ada field daily_spent
- ✅ Tidak ada field daily_spent_date
- ✅ Tidak ada field is_suspended
- ✅ Tidak ada table wallet_transactions

---

### Modul 4: Voucher & Promo

**VoucherController.php**
- ✅ Race condition (tidak ada locking)
- ✅ Tidak ada idempotency key (retry bisa double redeem)
- ✅ Tidak ada validasi:
  - Voucher expired
  - Min purchase
  - User eligible
  - Max usage per user
- ✅ Code tidak di-normalize (case-sensitive, tidak trim)
- ✅ Tidak ada transaction log
- ✅ Tidak ada audit trail
- ✅ Tidak ada anomaly detection
- ✅ checkUsage() vulnerable to enumeration attack
- ✅ Expose internal data (usage_count, max_usage)

**Voucher.php**
- ✅ Primitive obsession (code string, discount_value double)
- ✅ Boolean flag hell (is_active, is_expired, dll)
- ✅ Anemic model (tidak ada business logic)
- ✅ Semua field fillable (termasuk usage_count!)
- ✅ Tidak ada domain rules
- ✅ Invalid state bisa terjadi:
  - discount_value negatif
  - max_usage 0 atau negatif
  - valid_until sebelum valid_from
  - usage_count > max_usage
  - usage_count negatif
  - code empty
  - is_active=true tapi is_expired=true
- ✅ Tidak ada enforcement:
  - Max usage per user
  - Idempotency
  - Pessimistic locking
- ✅ Tidak ada immutability:
  - code bisa diubah
  - max_usage bisa diubah
  - usage_count bisa dikurangi

**Migration**
- ✅ code tidak ada constraint format
- ✅ discount_amount bisa negatif
- ✅ discount_type string bebas (no enum)
- ✅ max_usage bisa 0 atau negatif
- ✅ usage_count bisa lebih dari max_usage
- ✅ Boolean flags (bukan state machine)
- ✅ Tidak ada table voucher_redemptions

---

## 🔴 Kategori Masalah Keamanan

### 1. Design Flaws
- ✅ Shallow/Anemic Models (semua modul)
- ✅ Primitive Obsession (Modul 2, 4)
- ✅ Boolean Flag Hell (Modul 2, 4)
- ✅ God Object (Modul 3)
- ✅ Invalid State Representation (semua modul)

### 2. Concurrency Issues
- ✅ Race Condition (Modul 3, 4)
- ✅ No Pessimistic Locking (Modul 3, 4)
- ✅ Non-Atomic Operations (Modul 3)
- ✅ No Idempotency (Modul 4)

### 3. Data Integrity
- ✅ No Immutability (Modul 2, 4)
- ✅ No Value Objects (Modul 2, 3, 4)
- ✅ Mass Assignment Vulnerable (semua modul)
- ✅ No Domain Validation (semua modul)

### 4. Business Logic
- ✅ No State Machine (Modul 2)
- ✅ No Temporal Coupling Enforcement (Modul 2)
- ✅ No Quota Management (Modul 4)
- ✅ Logic in Controller (semua modul)

### 5. Observability & Audit
- ✅ No Audit Trail (semua modul)
- ✅ No Domain Events (semua modul)
- ✅ No Transaction Log (Modul 3, 4)
- ✅ No Anomaly Detection (Modul 3, 4)

### 6. Authentication & Authorization
- ✅ No Rate Limiting (Modul 1)
- ✅ No Lockout Mechanism (Modul 1)
- ✅ No Session Binding (Modul 1)
- ✅ No Login Attempt Tracking (Modul 1)

### 7. Input Validation
- ✅ Negative Values Allowed (Modul 2, 3, 4)
- ✅ No Format Validation (Modul 4)
- ✅ No Normalization (Modul 4)
- ✅ String Typos Possible (Modul 2, 4)

### 8. Information Disclosure
- ✅ Enumeration Attack Possible (Modul 4)
- ✅ Internal Data Exposed (Modul 4)
- ✅ No Rate Limiting on Check (Modul 4)

---

## 🎯 Ekspektasi Perbaikan

### Modul 1
Mahasiswa harus:
- Buat model LoginAttempt dengan tracking
- Implementasi lockout mechanism di User model
- Bind session dengan device fingerprint
- Pindahkan logic ke domain model
- Tambah audit trail

### Modul 2
Mahasiswa harus:
- Buat enum OrderStatus
- Buat value object Money
- Implementasi state machine dengan transition methods
- Enforce immutability untuk field penting
- Tambah domain events
- Buat audit log

### Modul 3
Mahasiswa harus:
- Buat value object Money
- Implementasi domain rules (saldo tidak negatif, daily limit)
- Gunakan pessimistic locking
- Buat WalletTransferService (atomic)
- Buat WalletTransaction model (immutable)
- Separate concerns (service untuk notification, report)
- Tambah anomaly detection

### Modul 4
Mahasiswa harus:
- Buat value object VoucherCode (normalized)
- Buat value object Discount
- Implementasi domain rules (canBeRedeemed)
- Gunakan pessimistic locking
- Implementasi idempotency pattern
- Enforce quota (total, per user)
- Buat VoucherRedemption model (immutable)
- Tambah anomaly detection
- Remove enumeration vulnerability

---

## ✅ Verifikasi Akhir

**Semua kode yang dibuat SENGAJA TIDAK AMAN dan SALAH.**

Tujuannya adalah agar mahasiswa:
1. Mengidentifikasi masalah keamanan
2. Memahami konsep Security by Design
3. Memperbaiki dengan solusi yang benar
4. Belajar dari kesalahan yang umum terjadi

**Test cases akan GAGAL pada kode yang bermasalah.**
**Test cases akan PASS setelah diperbaiki dengan benar.**

---

## 📝 Catatan untuk Dosen/Asisten

Jika mahasiswa bertanya "Kenapa kode ini tidak aman?", jangan langsung kasih jawaban. Gunakan Socratic method:

1. "Coba jelaskan, apa yang terjadi jika...?"
2. "Bagaimana attacker bisa exploit ini?"
3. "Apa yang bisa salah dengan desain ini?"
4. "Kenapa ini berbahaya?"

Biarkan mahasiswa berpikir dan menemukan sendiri. Ini bagian dari pembelajaran.

---

**Status**: ✅ VERIFIED - Semua kode sengaja tidak aman untuk tujuan pembelajaran
