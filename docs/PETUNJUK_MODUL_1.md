# Modul 1: Authentication & Login Security

## Masalah yang Ada

### 1. Tidak Ada Model untuk Login Attempts
```php
// AuthController.php - SALAH
if (!Auth::attempt($credentials)) {
    return back()->withErrors(['email' => 'Invalid credentials']);
}
```
**Masalah**: Tidak ada tracking, attacker bisa brute force tanpa batas.

### 2. Session Tidak Ter-bind dengan User
```php
// User.php - SALAH
// Session bisa dicuri dan dipakai di device lain tanpa deteksi
```

### 3. Shallow Model
```php
// User.php - SALAH
class User extends Model {
    protected $fillable = ['name', 'email', 'password'];
    // Hanya getter/setter, tidak ada aturan bisnis
}
```

## Yang Harus Diperbaiki

### 1. Buat Model LoginAttempt
- Track setiap percobaan login (berhasil/gagal)
- Simpan IP address, user agent, timestamp
- Implementasi lockout setelah N kali gagal

### 2. Implementasi Session Ownership
- Bind session dengan device fingerprint
- Deteksi session hijacking
- Force logout jika ada anomali

### 3. Deep Model untuk User
- Method `attemptLogin()` yang enforce aturan
- Method `lockAccount()` dan `unlockAccount()`
- Property `locked_until` untuk temporal lockout

## Struktur yang Diharapkan

```php
// LoginAttempt.php
class LoginAttempt extends Model {
    public static function recordFailure(string $email, string $ip): void;
    public static function shouldLockout(string $email): bool;
    public static function clearAttempts(string $email): void;
}

// User.php
class User extends Model {
    public function isLocked(): bool;
    public function lockUntil(Carbon $until): void;
    public function canAttemptLogin(): bool;
}

// Session.php
class Session extends Model {
    public function belongsToDevice(string $fingerprint): bool;
    public function isAnomaly(): bool;
}
```

## Test Cases
- [ ] Login gagal 5x → account terkunci 15 menit
- [ ] Session dari IP berbeda → force logout
- [ ] Setelah lockout expired → bisa login lagi
- [ ] Login berhasil → clear login attempts

## Referensi
- OWASP Authentication Cheat Sheet
- Laravel Fortify (tapi jangan pakai langsung, pahami konsepnya)
