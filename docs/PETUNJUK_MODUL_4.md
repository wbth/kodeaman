# Modul 4: Voucher & Promo System

## Masalah yang Ada

### 1. Race Condition - Double Redemption
```php
// VoucherController.php - SALAH
public function redeem(Request $request) {
    $voucher = Voucher::find($request->voucher_id);
    
    // MASALAH: Dua request bersamaan bisa redeem voucher yang sama
    if ($voucher->usage_count >= $voucher->max_usage) {
        return response()->json(['error' => 'Voucher fully used']);
    }
    
    $voucher->usage_count++;
    $voucher->save();
    // Jika 2 request cek bersamaan, keduanya bisa lolos ❌
}
```

### 2. Primitive Obsession untuk Voucher Code
```php
// Voucher.php - SALAH
protected $fillable = ['code', 'discount_amount', 'max_usage'];
// code = string bebas, bisa "ABC", "abc", " ABC " (tidak konsisten) ❌
// discount_amount = double, bisa negatif ❌
```

### 3. Tidak Ada Konsep Quota/Limit
```php
// SALAH - tidak ada enforcement:
// - Max usage per user
// - Max usage total
// - Daily redemption limit
// - Concurrent redemption limit
```

### 4. Temporal Validity Tidak Enforced
```php
// Voucher.php - SALAH
protected $fillable = ['valid_from', 'valid_until'];
// Bisa redeem meskipun:
// - Belum valid_from ❌
// - Sudah lewat valid_until ❌
// - valid_until < valid_from ❌
```

### 5. Anemic Model - Validasi di Controller
```php
// VoucherController.php - SALAH
public function redeem(Request $request) {
    $voucher = Voucher::find($request->voucher_id);
    
    // Semua validasi di controller
    if ($voucher->valid_until < now()) {
        return response()->json(['error' => 'Expired']);
    }
    
    if ($voucher->usage_count >= $voucher->max_usage) {
        return response()->json(['error' => 'Fully used']);
    }
    
    // Validasi tersebar, mudah dibypass ❌
}
```

### 6. Tidak Ada Idempotency
```php
// SALAH - request yang sama bisa diproses berkali-kali
// Tidak ada idempotency key
// Retry bisa bikin double redemption ❌
```

### 7. Invalid State Bisa Direpresentasikan
```php
// SALAH - semua ini bisa terjadi:
$voucher->usage_count = -5; // Negatif ❌
$voucher->max_usage = 0; // Tidak masuk akal ❌
$voucher->discount_amount = -1000; // Discount negatif ❌
$voucher->valid_from = '2024-12-31';
$voucher->valid_until = '2024-01-01'; // Until sebelum from ❌
$voucher->code = ''; // Empty code ❌
```

## Yang Harus Diperbaiki

### 1. Value Objects

```php
// VoucherCode.php - Value Object
final class VoucherCode {
    private function __construct(private string $code) {
        if (empty($code)) {
            throw new InvalidArgumentException('Voucher code cannot be empty');
        }
        
        if (!preg_match('/^[A-Z0-9]{6,12}$/', $code)) {
            throw new InvalidArgumentException('Invalid voucher code format');
        }
    }
    
    public static function fromString(string $code): self {
        // Normalize: uppercase, trim
        $normalized = strtoupper(trim($code));
        return new self($normalized);
    }
    
    public function toString(): string {
        return $this->code;
    }
    
    public function equals(VoucherCode $other): bool {
        return $this->code === $other->code;
    }
}

// Discount.php - Value Object
final class Discount {
    private function __construct(
        private int $amountCents,
        private DiscountType $type
    ) {
        if ($amountCents < 0) {
            throw new InvalidArgumentException('Discount cannot be negative');
        }
        
        if ($type === DiscountType::PERCENTAGE && $amountCents > 10000) {
            throw new InvalidArgumentException('Percentage cannot exceed 100%');
        }
    }
    
    public static function percentage(int $percentage): self {
        return new self($percentage * 100, DiscountType::PERCENTAGE);
    }
    
    public static function fixed(Money $amount): self {
        return new self($amount->toCents(), DiscountType::FIXED);
    }
    
    public function apply(Money $originalPrice): Money {
        if ($this->type === DiscountType::PERCENTAGE) {
            $discountAmount = ($originalPrice->toCents() * $this->amountCents) / 10000;
            return Money::fromCents($originalPrice->toCents() - (int)$discountAmount);
        }
        
        $newAmount = $originalPrice->toCents() - $this->amountCents;
        return Money::fromCents(max(0, $newAmount));
    }
}

enum DiscountType: string {
    case PERCENTAGE = 'percentage';
    case FIXED = 'fixed';
}
```

### 2. Deep Model dengan Domain Rules

```php
// Voucher.php - BENAR
class Voucher extends Model {
    protected $guarded = ['id'];
    
    protected $casts = [
        'valid_from' => 'datetime',
        'valid_until' => 'datetime',
        'is_active' => 'boolean',
    ];
    
    // Domain rules
    public function canBeRedeemed(User $user): bool {
        return $this->isActive()
            && $this->isWithinValidityPeriod()
            && $this->hasRemainingUsage()
            && !$this->hasUserExceededLimit($user);
    }
    
    public function isActive(): bool {
        return $this->is_active;
    }
    
    public function isWithinValidityPeriod(): bool {
        $now = now();
        return $now->greaterThanOrEqualTo($this->valid_from)
            && $now->lessThanOrEqualTo($this->valid_until);
    }
    
    public function hasRemainingUsage(): bool {
        return $this->usage_count < $this->max_usage;
    }
    
    public function hasUserExceededLimit(User $user): bool {
        if ($this->max_usage_per_user === null) {
            return false;
        }
        
        $userUsage = VoucherRedemption::where('voucher_id', $this->id)
            ->where('user_id', $user->id)
            ->count();
            
        return $userUsage >= $this->max_usage_per_user;
    }
    
    public function redeem(User $user, string $idempotencyKey): VoucherRedemption {
        // Check idempotency
        $existing = VoucherRedemption::where('idempotency_key', $idempotencyKey)->first();
        if ($existing) {
            return $existing; // Already processed
        }
        
        if (!$this->canBeRedeemed($user)) {
            throw new VoucherCannotBeRedeemedException();
        }
        
        return DB::transaction(function() use ($user, $idempotencyKey) {
            // Pessimistic lock untuk prevent race condition
            $voucher = self::lockForUpdate()->find($this->id);
            
            // Double-check setelah lock
            if (!$voucher->canBeRedeemed($user)) {
                throw new VoucherCannotBeRedeemedException();
            }
            
            // Increment usage
            $voucher->usage_count++;
            $voucher->save();
            
            // Create redemption record
            $redemption = VoucherRedemption::create([
                'voucher_id' => $voucher->id,
                'user_id' => $user->id,
                'idempotency_key' => $idempotencyKey,
                'redeemed_at' => now(),
                'ip_address' => request()->ip(),
            ]);
            
            event(new VoucherRedeemed($voucher, $user));
            
            return $redemption;
        });
    }
    
    public function deactivate(string $reason): void {
        $this->is_active = false;
        $this->deactivated_reason = $reason;
        $this->deactivated_at = now();
        $this->save();
        
        event(new VoucherDeactivated($this, $reason));
    }
}
```

### 3. Immutable Redemption Record

```php
// VoucherRedemption.php
class VoucherRedemption extends Model {
    protected $guarded = ['id'];
    
    protected $casts = [
        'redeemed_at' => 'datetime',
    ];
    
    // Immutable - tidak bisa diubah atau dihapus
    public static function boot() {
        parent::boot();
        
        static::updating(function() {
            throw new ImmutableRecordException('Redemption records cannot be modified');
        });
        
        static::deleting(function() {
            throw new ImmutableRecordException('Redemption records cannot be deleted');
        });
    }
    
    public function voucher() {
        return $this->belongsTo(Voucher::class);
    }
    
    public function user() {
        return $this->belongsTo(User::class);
    }
}
```

### 4. Domain Service untuk Complex Logic

```php
// VoucherRedemptionService.php
class VoucherRedemptionService {
    public function redeemVoucher(
        VoucherCode $code,
        User $user,
        Order $order,
        string $idempotencyKey
    ): VoucherRedemption {
        $voucher = Voucher::where('code', $code->toString())->firstOrFail();
        
        // Business rules
        if (!$voucher->canBeRedeemed($user)) {
            throw new VoucherCannotBeRedeemedException();
        }
        
        if ($order->hasVoucherApplied()) {
            throw new OrderAlreadyHasVoucherException();
        }
        
        // Redeem
        $redemption = $voucher->redeem($user, $idempotencyKey);
        
        // Apply discount to order
        $discount = $this->calculateDiscount($voucher, $order);
        $order->applyVoucher($voucher, $discount);
        
        return $redemption;
    }
    
    private function calculateDiscount(Voucher $voucher, Order $order): Money {
        $discount = Discount::fromVoucher($voucher);
        return $discount->apply($order->getTotal());
    }
}
```

### 5. Anomaly Detection

```php
// DetectVoucherAbuse.php - Listener
class DetectVoucherAbuse {
    public function handle(VoucherRedeemed $event) {
        $user = $event->user;
        $voucher = $event->voucher;
        
        // Deteksi redemption terlalu cepat
        $recentRedemptions = VoucherRedemption::where('user_id', $user->id)
            ->where('created_at', '>', now()->subMinutes(5))
            ->count();
        
        if ($recentRedemptions > 10) {
            $voucher->deactivate('Abuse detected: too many redemptions');
            $user->suspend('Voucher abuse detected');
            
            event(new VoucherAbuseDetected($user, $voucher));
        }
        
        // Deteksi redemption dari banyak IP
        $uniqueIPs = VoucherRedemption::where('voucher_id', $voucher->id)
            ->where('created_at', '>', now()->subHour())
            ->distinct('ip_address')
            ->count();
        
        if ($uniqueIPs > 50) {
            $voucher->deactivate('Abuse detected: too many unique IPs');
            event(new VoucherAbuseDetected(null, $voucher));
        }
    }
}
```

### 6. Validation di Domain Level

```php
// Voucher.php - Boot method
protected static function boot() {
    parent::boot();
    
    static::creating(function($voucher) {
        // Validasi validity period
        if ($voucher->valid_until <= $voucher->valid_from) {
            throw new InvalidArgumentException('valid_until must be after valid_from');
        }
        
        // Validasi max_usage
        if ($voucher->max_usage <= 0) {
            throw new InvalidArgumentException('max_usage must be positive');
        }
        
        // Validasi code format
        $code = VoucherCode::fromString($voucher->code);
        $voucher->code = $code->toString();
    });
    
    static::updating(function($voucher) {
        // Immutable fields
        if ($voucher->isDirty(['code', 'max_usage', 'valid_from'])) {
            throw new ImmutableFieldException('Cannot modify code, max_usage, or valid_from');
        }
        
        // Usage count tidak bisa dikurangi
        if ($voucher->isDirty('usage_count') && $voucher->usage_count < $voucher->getOriginal('usage_count')) {
            throw new InvalidArgumentException('usage_count cannot be decreased');
        }
    });
}
```

## Test Cases

- [ ] Race condition: 2 request bersamaan hanya 1 yang berhasil
- [ ] Idempotency: request dengan key sama tidak double redeem
- [ ] Voucher expired tidak bisa dipakai
- [ ] Voucher belum valid tidak bisa dipakai
- [ ] Max usage enforced
- [ ] Max usage per user enforced
- [ ] Voucher code case-insensitive dan trimmed
- [ ] Discount tidak bisa negatif
- [ ] Percentage discount max 100%
- [ ] Redemption record immutable
- [ ] Anomaly detection: 10+ redemption dalam 5 menit → deactivate
- [ ] Setiap redemption tercatat dengan IP dan timestamp

## Struktur File

```
app/
├── Models/
│   ├── Voucher.php (deep model)
│   └── VoucherRedemption.php (immutable)
├── Services/
│   └── VoucherRedemptionService.php
├── ValueObjects/
│   ├── VoucherCode.php
│   └── Discount.php
├── Enums/
│   └── DiscountType.php
├── Events/
│   ├── VoucherRedeemed.php
│   ├── VoucherDeactivated.php
│   └── VoucherAbuseDetected.php
├── Listeners/
│   └── DetectVoucherAbuse.php
└── Exceptions/
    ├── VoucherCannotBeRedeemedException.php
    ├── OrderAlreadyHasVoucherException.php
    └── ImmutableRecordException.php
```

## Konsep DDD yang Diterapkan

- **Value Object**: VoucherCode, Discount (immutable, no identity)
- **Entity**: Voucher (has identity, mutable state)
- **Aggregate**: VoucherRedemptionService (koordinasi Voucher + Order)
- **Domain Event**: VoucherRedeemed, VoucherAbuseDetected
- **Domain Service**: VoucherRedemptionService
- **Invariant**: canBeRedeemed(), usage_count <= max_usage
- **Idempotency**: Prevent duplicate processing
- **Pessimistic Locking**: Prevent race condition
- **Immutability**: VoucherRedemption tidak bisa diubah
- **Audit Trail**: Setiap redemption tercatat lengkap

## Perbedaan dengan Modul Lain

Modul ini fokus pada:
- **Concurrency**: Race condition dan pessimistic locking
- **Idempotency**: Prevent duplicate processing
- **Quota Management**: Multiple limits (total, per user, daily)
- **Anomaly Detection**: Real-time abuse detection
- **Value Objects**: VoucherCode dengan normalization
