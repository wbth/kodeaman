# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-01-01

### Added

#### Dokumentasi (13 files)
- `README.md` - Entry point dengan overview lab
- `UNTUK_MAHASISWA.md` - Panduan lengkap untuk mahasiswa
- `KISI-KISI_PERBAIKAN.md` - Struktur solusi tanpa kode lengkap
- `CARA_MENGERJAKAN.md` - Step-by-step guide
- `KONSEP_SECURITY_BY_DESIGN.md` - Referensi konsep Security by Design
- `PETUNJUK_MODUL_1.md` - Authentication & Login Security
- `PETUNJUK_MODUL_2.md` - Order & Refund System
- `PETUNJUK_MODUL_3.md` - E-Wallet System
- `PETUNJUK_MODUL_4.md` - Voucher & Promo System
- `VERIFIKASI_KODE_TIDAK_AMAN.md` - Daftar semua masalah keamanan
- `RINGKASAN_LAB.md` - Overview lengkap lab
- `PANDUAN_DOSEN.md` - Panduan untuk dosen/asisten
- `DAFTAR_FILE.md` - Daftar lengkap file

#### Modul 1: Authentication & Login Security
- Controller: `AuthController.php` dengan 9 masalah keamanan
- Model: `User.php` (shallow model)
- Migration: `create_users_table.php`
- Tests: 5 test cases
- Konsep: Deep Model, Domain Rules, Lockout Mechanism

#### Modul 2: Order & Refund System
- Controller: `OrderController.php` dengan 7 masalah keamanan
- Model: `Order.php` (primitive obsession, boolean flag hell)
- Migration: `create_orders_table.php`
- Tests: 8 test cases
- Konsep: State Machine, Immutability, Value Objects

#### Modul 3: E-Wallet System
- Controller: `WalletController.php` dengan 8 masalah keamanan
- Model: `Wallet.php` (anemic model, god object)
- Migration: `create_wallets_table.php`
- Tests: 8 test cases
- Konsep: Aggregate, Pessimistic Locking, Domain Events

#### Modul 4: Voucher & Promo System
- Controller: `VoucherController.php` dengan 10+ masalah keamanan
- Model: `Voucher.php` (race condition, no idempotency)
- Migration: `create_vouchers_table.php`
- Tests: 8 test cases
- Konsep: Idempotency, Quota Management, Anomaly Detection

#### Infrastructure
- `routes/api.php` - API routes untuk semua modul
- `composer.json` - Dependencies
- `.env.example` - Environment template
- `.gitignore` - Git ignore rules
- `LICENSE` - MIT License
- `CONTRIBUTING.md` - Contribution guidelines
- `DEPLOY_GITHUB.md` - Panduan deploy ke GitHub
- `CHANGELOG.md` - This file

### Features

- **60+ Masalah Keamanan**: Tersebar di 4 modul
- **29 Test Cases**: Semua akan GAGAL di kode tidak aman
- **12 Konsep Security by Design**: Dari shallow model sampai idempotency
- **Kisi-Kisi Lengkap**: Struktur solusi tanpa kode copy-paste
- **Dokumentasi Komprehensif**: 13 file dokumentasi

### Security (Intentional Vulnerabilities)

**CATATAN**: Semua vulnerability di bawah ini SENGAJA untuk tujuan pembelajaran

#### Modul 1
- No rate limiting (brute force possible)
- No login attempt tracking
- No lockout mechanism
- Session not bound to device
- Shallow model
- Mass assignment vulnerable
- No audit trail

#### Modul 2
- Primitive obsession
- Boolean flag hell
- Anemic domain model
- Negative amounts possible
- Direct status modification
- No temporal coupling enforcement
- Mutable critical fields
- Invalid state representable

#### Modul 3
- Negative balance possible
- No daily limit
- Race conditions
- Non-atomic transfers
- No pessimistic locking
- God object
- No transaction log
- No anomaly detection

#### Modul 4
- Race condition (double redemption)
- No idempotency
- No pessimistic locking
- Code not normalized
- Negative discount possible
- Quota not enforced
- Enumeration attack possible
- Internal data exposed

---

## [Unreleased]

### Planned

- [ ] Modul 5: API Rate Limiting & Throttling
- [ ] Modul 6: File Upload Security
- [ ] Video tutorial untuk setiap modul
- [ ] Interactive playground
- [ ] Automated grading system
- [ ] Terjemahan ke bahasa Inggris

### Ideas

- GitHub Classroom integration guide
- Docker setup untuk easy deployment
- CI/CD pipeline example
- Monitoring & logging module
- RBAC (Role-Based Access Control) module

---

## Version History

### Version Numbering

Format: `MAJOR.MINOR.PATCH`

- **MAJOR**: Breaking changes (incompatible API changes)
- **MINOR**: New features (backward compatible)
- **PATCH**: Bug fixes (backward compatible)

### Release Schedule

- **v1.0.0**: Initial release (2026-01-01)
- **v1.1.0**: Planned (Q2 2026) - Additional modules
- **v2.0.0**: Planned (Q4 2026) - Major restructure

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for details on how to contribute.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**Note**: This is an educational project. The code is intentionally insecure for learning purposes. DO NOT use in production.
