# Modul 3: E-Wallet System

## Masalah yang Ada

### 1. Saldo Bisa Negatif
```php
// WalletController.php - SALAH
public function withdraw(Request $request) {
    $wallet = Wallet::find($request->wallet_id);
    $wallet->balance -= $request->amount;
    $wallet->save(); // Tidak ada validasi, bisa negatif ❌
}
```

### 2. Tidak Ada Daily Limit
```php
// Wallet.php - SALAH
class Wallet extends Model {
    protected $fillable = ['user_id', 'balance'];
    // Tidak ada konsep daily_limit, daily_spent
    // User bisa transfer unlimited dalam sehari ❌
}
```

### 3. Race Condition - Double Spending
```php
// SALAH - dua request bersamaan bisa bikin saldo negatif
// Request 1: balance = 1000, withdraw 800
// Request 2: balance = 1000, withdraw 800
// Hasil: balance = -600 ❌
```

### 4. Anemic Model - Logika di Controller
```php
// WalletController.php - SALAH
public function transfer(Request $request) {
    $from = Wallet::find($request->from_wallet);
    $to = Wallet::find($request->to_wallet);
    
    $from->balance -= $request->amount;
    $to->balance += $request->amount;
    
    $from->save();
    $to->save();
    // Tidak atomic, bisa gagal di tengah ❌
    // Tidak ada validasi domain ❌
}
```

### 5. God Object
```php
// Wallet.php - SALAH
class Wallet extends Model {
    public function withdraw() { }
    public function deposit() { }
    public function transfer() { }
    public function checkLimit() { }
    public function sendNotification() { }
    public function calculateFee() { }
    public function generateReport() { }
    public function detectFraud() { }
    // Terlalu banyak tanggung jawab ❌
}
```

## Yang Harus Diperbaiki

### 1. Deep Model dengan Domain Rules
```php
// Wallet.php - BENAR
class Wallet extends Model {
    private const DAILY_LIMIT = 10000000; // 10 juta
    
    public function debit(Money $amount): void {
        if (!$this->canDebit($amount)) {
            throw new InsufficientBalanceException();
        }
        
        if ($this->exceedsDailyLimit($amount)) {
            throw new DailyLimitExceededException();
        }
        
        DB::transaction(function() use ($amount) {
            $this->lockForUpdate(); // Prevent race condition
            $this->balance = $this->balance->subtract($amount);
            $this->daily_spent = $this->daily_spent->add($amount);
            $this->save();
            
            event(new WalletDebited($this, $amount));
        });
    }
    
    public function credit(Money $amount): void {
        DB::transaction(function() use ($amount) {
            $this->lockForUpdate();
            $this->balance = $this->balance->add($amount);
            $this->save();
            
            event(new WalletCredited($this, $amount));
        });
    }
    
    private function canDebit(Money $amount): bool {
        return $this->balance->isGreaterThanOrEqual($amount);
    }
    
    private function exceedsDailyLimit(Money $amount): bool {
        return $this->daily_spent->add($amount)->isGreaterThan(
            Money::fromCents(self::DAILY_LIMIT)
        );
    }
}
```

### 2. Aggregate untuk Transfer
```php
// WalletTransferService.php - Domain Service
class WalletTransferService {
    public function transfer(
        Wallet $from, 
        Wallet $to, 
        Money $amount
    ): WalletTransaction {
        if ($from->id === $to->id) {
            throw new CannotTransferToSelfException();
        }
        
        DB::transaction(function() use ($from, $to, $amount) {
            $from->debit($amount);
            $to->credit($amount);
            
            $transaction = WalletTransaction::create([
                'from_wallet_id' => $from->id,
                'to_wallet_id' => $to->id,
                'amount' => $amount->toCents(),
                'type' => TransactionType::TRANSFER,
                'status' => TransactionStatus::COMPLETED,
            ]);
            
            event(new WalletTransferred($from, $to, $amount));
            
            return $transaction;
        });
    }
}
```

### 3. Value Objects
```php
// Money.php
final class Money {
    private function __construct(private int $cents) {
        if ($cents < 0) {
            throw new InvalidArgumentException('Money cannot be negative');
        }
    }
    
    public static function fromCents(int $cents): self {
        return new self($cents);
    }
    
    public static function fromRupiah(float $rupiah): self {
        return new self((int)($rupiah * 100));
    }
    
    public function add(Money $other): self {
        return new self($this->cents + $other->cents);
    }
    
    public function subtract(Money $other): self {
        return new self($this->cents - $other->cents);
    }
    
    public function isGreaterThan(Money $other): bool {
        return $this->cents > $other->cents;
    }
    
    public function isGreaterThanOrEqual(Money $other): bool {
        return $this->cents >= $other->cents;
    }
    
    public function toCents(): int {
        return $this->cents;
    }
    
    public function toRupiah(): float {
        return $this->cents / 100;
    }
}
```

### 4. Transaction Log untuk Audit
```php
// WalletTransaction.php
class WalletTransaction extends Model {
    protected $fillable = [
        'from_wallet_id',
        'to_wallet_id',
        'amount',
        'type',
        'status',
        'metadata',
    ];
    
    protected $casts = [
        'type' => TransactionType::class,
        'status' => TransactionStatus::class,
        'metadata' => 'array',
    ];
    
    // Immutable - tidak bisa diubah setelah dibuat
    public static function boot() {
        parent::boot();
        
        static::updating(function() {
            throw new ImmutableRecordException();
        });
    }
}

enum TransactionType: string {
    case DEPOSIT = 'deposit';
    case WITHDRAWAL = 'withdrawal';
    case TRANSFER = 'transfer';
}

enum TransactionStatus: string {
    case PENDING = 'pending';
    case COMPLETED = 'completed';
    case FAILED = 'failed';
    case REVERSED = 'reversed';
}
```

### 5. Anomaly Detection dengan Events
```php
// Events
class WalletDebited {
    public function __construct(
        public Wallet $wallet,
        public Money $amount
    ) {}
}

class WalletSuspended {
    public function __construct(
        public Wallet $wallet,
        public string $reason
    ) {}
}

// Listener
class DetectAnomalousActivity {
    public function handle(WalletDebited $event) {
        // Deteksi pola mencurigakan
        $recentTransactions = WalletTransaction::where('from_wallet_id', $event->wallet->id)
            ->where('created_at', '>', now()->subMinutes(5))
            ->count();
        
        if ($recentTransactions > 10) {
            $event->wallet->suspend('Too many transactions in short time');
            event(new WalletSuspended($event->wallet, 'Anomaly detected'));
        }
    }
}
```

### 6. Separate Concerns
```php
// Wallet.php - hanya domain logic
class Wallet extends Model {
    public function debit(Money $amount): void { }
    public function credit(Money $amount): void { }
    public function suspend(string $reason): void { }
}

// WalletTransferService.php - transfer logic
class WalletTransferService {
    public function transfer(Wallet $from, Wallet $to, Money $amount): void { }
}

// WalletNotificationService.php - notification logic
class WalletNotificationService {
    public function notifyDebit(Wallet $wallet, Money $amount): void { }
}

// WalletReportService.php - reporting logic
class WalletReportService {
    public function generateMonthlyReport(Wallet $wallet): Report { }
}
```

## Test Cases
- [ ] Saldo tidak bisa negatif
- [ ] Daily limit enforced (10 juta per hari)
- [ ] Race condition prevented dengan locking
- [ ] Transfer atomic (gagal semua atau berhasil semua)
- [ ] Tidak bisa transfer ke wallet sendiri
- [ ] Transaction log immutable
- [ ] Anomaly detection: 10+ transaksi dalam 5 menit → suspend
- [ ] Setiap transaksi tercatat dengan lengkap

## Struktur File
```
app/
├── Models/
│   ├── Wallet.php (deep model)
│   └── WalletTransaction.php (immutable log)
├── Services/
│   ├── WalletTransferService.php
│   ├── WalletNotificationService.php
│   └── WalletReportService.php
├── ValueObjects/
│   └── Money.php
├── Enums/
│   ├── TransactionType.php
│   └── TransactionStatus.php
├── Events/
│   ├── WalletDebited.php
│   ├── WalletCredited.php
│   ├── WalletTransferred.php
│   └── WalletSuspended.php
├── Listeners/
│   └── DetectAnomalousActivity.php
└── Exceptions/
    ├── InsufficientBalanceException.php
    ├── DailyLimitExceededException.php
    └── CannotTransferToSelfException.php
```

## Konsep DDD yang Diterapkan
- **Entity**: Wallet (memiliki identity)
- **Value Object**: Money (immutable, no identity)
- **Aggregate**: WalletTransferService (koordinasi multi-entity)
- **Domain Event**: WalletDebited, WalletSuspended
- **Domain Service**: WalletTransferService
- **Repository**: Eloquent ORM
