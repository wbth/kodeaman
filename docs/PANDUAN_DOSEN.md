# Panduan untuk Dosen/Asisten Lab

## Overview Lab

Lab ini dirancang untuk mengajarkan Security by Design melalui praktik memperbaiki kode Laravel yang sengaja dibuat bermasalah. Berbeda dengan lab security tradisional yang fokus pada tools (firewall, encryption, dll), lab ini fokus pada desain dan arsitektur yang aman dari awal.

## Filosofi Lab

### Security ≠ Fitur Tambahan
Security bukan sesuatu yang ditambahkan di akhir development. Security harus dibangun ke dalam desain, model, dan arsitektur aplikasi.

### Contoh Mindset Shift:
- ❌ "Tambahkan rate limiting untuk prevent brute force"
- ✅ "Desain model LoginAttempt yang track dan enforce lockout"

- ❌ "Validasi input di controller"
- ✅ "Buat Value Object yang tidak bisa invalid"

- ❌ "Tambahkan transaction untuk prevent race condition"
- ✅ "Desain aggregate dengan pessimistic locking"

## Struktur Modul

### Modul 1: Foundation (3-4 jam)
**Tujuan**: Memahami deep model dan domain rules

**Konsep Kunci**:
- Shallow vs Deep Model
- Domain Rules di Model, bukan Controller
- Audit Trail

**Red Flags untuk Dicari**:
- Logic di controller
- Validasi hanya di request validation
- Tidak ada tracking

### Modul 2: Intermediate (4-5 jam)
**Tujuan**: State machine dan value objects

**Konsep Kunci**:
- State Machine vs Boolean Flags
- Value Objects vs Primitives
- Immutability
- Domain Events

**Red Flags untuk Dicari**:
- Boolean flag hell
- String/double untuk domain concepts
- Field penting bisa diubah
- Tidak ada event

### Modul 3: Advanced (5-6 jam)
**Tujuan**: Aggregate dan concurrency

**Konsep Kunci**:
- Aggregate Pattern
- Pessimistic Locking
- Domain Services
- Separation of Concerns

**Red Flags untuk Dicari**:
- Race condition
- Non-atomic operations
- God object
- Tidak ada locking

### Modul 4: Expert (5-6 jam)
**Tujuan**: Idempotency dan quota management

**Konsep Kunci**:
- Idempotency Pattern
- Quota Enforcement
- Anomaly Detection
- Immutable Records

**Red Flags untuk Dicari**:
- Tidak ada idempotency key
- Quota bisa dibypass
- Tidak ada abuse detection
- Records bisa diubah

## Cara Mengajar

### 1. Jangan Langsung Kasih Solusi
Biarkan mahasiswa struggle sedikit. Ini bagian dari pembelajaran.

**Jika mahasiswa stuck**:
- Tanya: "Apa masalahnya menurut kamu?"
- Tanya: "Kenapa ini berbahaya?"
- Tanya: "Bagaimana attacker bisa exploit ini?"
- Baru kasih hint, bukan solusi lengkap

### 2. Gunakan Socratic Method
Contoh dialog:

**Mahasiswa**: "Test saya gagal terus untuk race condition"

**Dosen**: "Coba jelaskan, apa yang terjadi saat 2 request bersamaan?"

**Mahasiswa**: "Keduanya baca usage_count yang sama"

**Dosen**: "Terus?"

**Mahasiswa**: "Keduanya increment dan save"

**Dosen**: "Jadi masalahnya di mana?"

**Mahasiswa**: "Di antara read dan write, tidak ada lock"

**Dosen**: "Bagus! Sekarang cari cara untuk lock di Laravel"

### 3. Code Review Session
Setelah mahasiswa selesai satu modul, lakukan code review:

**Checklist Review**:
- [ ] Apakah logic di model atau controller?
- [ ] Apakah menggunakan value objects?
- [ ] Apakah ada validasi domain rules?
- [ ] Apakah state transitions enforced?
- [ ] Apakah ada audit trail?
- [ ] Apakah handle race condition?
- [ ] Apakah code clean dan readable?

### 4. Live Coding Session (Optional)
Untuk konsep yang sulit, lakukan live coding:
- Modul 1: Demo LoginAttempt model
- Modul 2: Demo state machine
- Modul 3: Demo pessimistic locking
- Modul 4: Demo idempotency

## Common Mistakes & How to Guide

### Mistake 1: Validasi Hanya di Controller
```php
// SALAH
public function refund($id) {
    $order = Order::find($id);
    if ($order->status !== 'delivered') {
        return response()->json(['error' => 'Cannot refund']);
    }
    $order->status = 'refunded';
    $order->save();
}
```

**Guidance**:
"Apa yang terjadi jika ada controller lain yang langsung set status? Bagaimana cara memastikan validasi selalu dijalankan?"

**Expected Answer**: Pindahkan validasi ke model method.

### Mistake 2: Tidak Pakai Transaction
```php
// SALAH
$from->balance -= $amount;
$from->save();
$to->balance += $amount;
$to->save();
```

**Guidance**:
"Apa yang terjadi jika save() kedua gagal? Kemana uangnya?"

**Expected Answer**: Wrap dalam DB::transaction().

### Mistake 3: Tidak Pakai Locking
```php
// SALAH
DB::transaction(function() {
    $voucher = Voucher::find($id);
    if ($voucher->usage_count < $voucher->max_usage) {
        $voucher->usage_count++;
        $voucher->save();
    }
});
```

**Guidance**:
"Transaction saja cukup? Coba jalankan test race condition. Apa yang terjadi?"

**Expected Answer**: Perlu lockForUpdate().

### Mistake 4: Value Object Masih Bisa Invalid
```php
// SALAH
class Money {
    public function __construct(public int $cents) {}
}

$money = new Money(-100); // Bisa negatif!
```

**Guidance**:
"Apakah Money dengan nilai negatif valid? Bagaimana cara prevent ini?"

**Expected Answer**: Validasi di constructor, private constructor + static factory.

## Grading Rubric

### Functionality (40 points)
- [ ] Semua test PASS (20 points)
- [ ] Edge cases handled (10 points)
- [ ] No bugs (10 points)

### Code Quality (30 points)
- [ ] Clean code (10 points)
- [ ] Proper naming (5 points)
- [ ] No duplication (5 points)
- [ ] SOLID principles (10 points)

### Security (20 points)
- [ ] Domain rules enforced (5 points)
- [ ] Invalid state prevented (5 points)
- [ ] Audit trail complete (5 points)
- [ ] Concurrency handled (5 points)

### Documentation (10 points)
- [ ] Code comments (3 points)
- [ ] README clear (4 points)
- [ ] Design decisions explained (3 points)

**Total**: 100 points

### Bonus (up to 10 points)
- Implementasi extensi modul
- Exceptional code quality
- Creative solutions
- Helping other students

## Timeline Management

### Week 1: Introduction & Modul 1
- **Day 1**: Penjelasan konsep Security by Design (2 jam)
- **Day 2**: Demo Modul 1 (1 jam)
- **Day 3-5**: Mahasiswa mengerjakan Modul 1
- **Day 5**: Code review Modul 1

### Week 2: Modul 2
- **Day 1**: Penjelasan State Machine & Value Objects (1 jam)
- **Day 2-5**: Mahasiswa mengerjakan Modul 2
- **Day 5**: Code review Modul 2

### Week 3: Modul 3
- **Day 1**: Penjelasan Aggregate & Concurrency (1 jam)
- **Day 2-5**: Mahasiswa mengerjakan Modul 3
- **Day 5**: Code review Modul 3

### Week 4: Modul 4
- **Day 1**: Penjelasan Idempotency & Quota (1 jam)
- **Day 2-5**: Mahasiswa mengerjakan Modul 4
- **Day 5**: Code review Modul 4

### Week 5: Finalisasi
- **Day 1-3**: Refactoring & documentation
- **Day 4**: Final presentation
- **Day 5**: Submission & grading

## Discussion Topics

### After Modul 1
- Kenapa login attempts harus di-track?
- Apa bedanya shallow vs deep model?
- Bagaimana cara balance security vs UX?

### After Modul 2
- Kenapa state machine lebih aman dari boolean flags?
- Kapan harus pakai value objects?
- Apa trade-off immutability?

### After Modul 3
- Kenapa perlu pessimistic locking?
- Kapan pakai optimistic vs pessimistic?
- Bagaimana cara design aggregate boundary?

### After Modul 4
- Kenapa idempotency penting?
- Bagaimana cara detect abuse?
- Trade-off antara performance vs security?

## Red Flags dalam Submission

### Critical Issues (Harus Diperbaiki)
- ❌ Test tidak PASS
- ❌ Race condition masih ada
- ❌ Invalid state bisa terjadi
- ❌ Tidak ada audit trail
- ❌ Logic di controller

### Major Issues (Nilai dikurangi signifikan)
- ⚠️ Tidak pakai value objects
- ⚠️ Tidak pakai state machine
- ⚠️ Tidak pakai domain events
- ⚠️ Code duplication banyak

### Minor Issues (Nilai dikurangi sedikit)
- ⚠️ Naming kurang jelas
- ⚠️ Comments kurang
- ⚠️ Documentation kurang detail

## Variasi untuk Prevent Plagiarism

### Variasi Modul 1
- Tambah requirement: 2FA
- Tambah requirement: Device fingerprinting
- Ubah lockout duration: 30 menit instead of 15

### Variasi Modul 2
- Tambah state: CANCELLED
- Tambah requirement: Partial refund
- Ubah flow: Allow refund before delivery dengan approval

### Variasi Modul 3
- Ubah daily limit: 5 juta instead of 10
- Tambah requirement: Wallet freeze
- Tambah requirement: Transaction reversal

### Variasi Modul 4
- Tambah requirement: Voucher stacking
- Ubah max usage per user: 1 instead of 2
- Tambah requirement: Referral codes

## Tools untuk Asisten

### 1. Automated Testing
```bash
# Run all tests
php artisan test

# Run specific module
php artisan test --filter=Modul1AuthTest

# Run with coverage
php artisan test --coverage
```

### 2. Static Analysis
```bash
# Install PHPStan
composer require --dev phpstan/phpstan

# Run analysis
./vendor/bin/phpstan analyse app
```

### 3. Code Formatting
```bash
# Install Pint
composer require --dev laravel/pint

# Format code
./vendor/bin/pint
```

## FAQ untuk Asisten

**Q: Mahasiswa pakai package Laravel Fortify, boleh?**
A: Tidak untuk Modul 1. Tujuannya adalah memahami konsep, bukan pakai package.

**Q: Mahasiswa tidak pakai DDD strict, nilai dikurangi?**
A: Tidak harus strict DDD. Yang penting konsep security by design diterapkan.

**Q: Mahasiswa pakai AI untuk bantuan, boleh?**
A: Boleh untuk memahami konsep, tapi harus bisa explain kenapa solusi itu benar. Jika tidak bisa explain, kemungkinan copy-paste.

**Q: Test PASS tapi code quality jelek, nilai berapa?**
A: Functionality 40/40, tapi Code Quality bisa 10-15/30 tergantung seberapa jelek.

**Q: Mahasiswa tidak sempat selesai semua modul, boleh submit partial?**
A: Boleh, tapi nilai proporsional. Misal hanya 2 modul selesai = max 50 points.

## Resources untuk Dosen

### Books
- Domain-Driven Design by Eric Evans
- Implementing Domain-Driven Design by Vaughn Vernon
- Secure by Design by Dan Bergh Johnsson

### Online Courses
- Laracasts: Domain-Driven Design in Laravel
- Symfony Casts: Design Patterns
- OWASP: Secure Coding Practices

### Papers
- "Making Illegal States Unrepresentable" by Yaron Minsky
- "Parse, Don't Validate" by Alexis King

## Kontak & Support

Jika ada pertanyaan tentang lab ini:
- Email: [email_koordinator]
- Slack: #security-by-design-lab
- Office Hours: [jadwal]

---

**Good luck teaching! 🎓**
