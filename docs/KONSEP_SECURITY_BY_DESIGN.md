# Konsep Security by Design

## Ringkasan Konsep yang Dipelajari di Lab Ini

### 1. Shallow Model vs Deep Model

**Shallow Model (SALAH)**
```php
class Order extends Model {
    protected $fillable = ['status', 'amount', 'user_id'];
    // Hanya getter/setter, tidak ada business logic
}

// Logic di controller
$order->status = 'refunded';
$order->save();
```

**Deep Model (BENAR)**
```php
class Order extends Model {
    public function approveRefund(): void {
        if ($this->status !== OrderStatus::REFUND_REQUESTED) {
            throw new InvalidStateTransition();
        }
        $this->status = OrderStatus::REFUNDED;
        $this->save();
        event(new OrderRefunded($this));
    }
}

// Logic di model
$order->approveRefund();
```

**Kenapa Deep Model Lebih Aman?**
- Business rules ada di satu tempat (model)
- Tidak bisa dibypass dari controller lain
- Validasi selalu dijalankan
- Mudah di-test

---

### 2. Primitive Obsession

**Primitive Obsession (SALAH)**
```php
class Order {
    public float $amount; // Bisa negatif
    public string $status; // Bisa typo: "payed", "PAID"
    public int $userId; // Tidak ada validasi
}
```

**Value Objects (BENAR)**
```php
final class Money {
    private function __construct(private int $cents) {
        if ($cents < 0) throw new InvalidArgumentException();
    }
    public static function fromCents(int $cents): self;
}

enum OrderStatus: string {
    case PENDING = 'pending';
    case PAID = 'paid';
    // ...
}
```

**Kenapa Value Objects Lebih Aman?**
- Invalid value tidak bisa dibuat
- Type safety
- Encapsulation logic (e.g., Money calculation)
- Self-documenting code

---

### 3. Boolean Flag Hell

**Boolean Flags (SALAH)**
```php
class Order {
    public bool $is_paid;
    public bool $is_shipped;
    public bool $is_delivered;
    public bool $is_refunded;
    
    // Kombinasi invalid bisa terjadi:
    // is_refunded=true tapi is_paid=false ❌
}
```

**State Machine (BENAR)**
```php
enum OrderStatus: string {
    case PENDING = 'pending';
    case PAID = 'paid';
    case SHIPPED = 'shipped';
    case DELIVERED = 'delivered';
    case REFUNDED = 'refunded';
}

class Order {
    public OrderStatus $status; // Hanya 1 state pada satu waktu
}
```

**Kenapa State Machine Lebih Aman?**
- Hanya 1 state pada satu waktu
- Tidak ada kombinasi invalid
- Transition bisa dikontrol
- Mudah visualisasi flow

---

### 4. Anemic Domain Model

**Anemic Model (SALAH)**
```php
// Model hanya data
class Wallet extends Model {
    public float $balance;
}

// Logic di controller
$wallet->balance -= $amount;
$wallet->save();
```

**Rich Domain Model (BENAR)**
```php
class Wallet extends Model {
    public function debit(Money $amount): void {
        if (!$this->canDebit($amount)) {
            throw new InsufficientBalanceException();
        }
        DB::transaction(function() use ($amount) {
            $this->lockForUpdate();
            $this->balance -= $amount->toRupiah();
            $this->save();
        });
    }
    
    private function canDebit(Money $amount): bool {
        return $this->balance >= $amount->toRupiah();
    }
}
```

**Kenapa Rich Model Lebih Aman?**
- Encapsulation
- Invariants enforced
- Single responsibility
- Testable

---

### 5. Temporal Coupling

**Temporal Coupling (SALAH)**
```php
// Urutan penting tapi tidak enforced
$order->status = 'shipped';
$order->status = 'delivered';
$order->status = 'refunded';

// Bisa langsung refunded tanpa melalui shipped/delivered ❌
```

**Enforced Transitions (BENAR)**
```php
class Order {
    public function ship(): void {
        if ($this->status !== OrderStatus::PAID) {
            throw new InvalidStateTransition();
        }
        $this->status = OrderStatus::SHIPPED;
    }
    
    public function confirmDelivery(): void {
        if ($this->status !== OrderStatus::SHIPPED) {
            throw new InvalidStateTransition();
        }
        $this->status = OrderStatus::DELIVERED;
    }
}
```

**Kenapa Enforced Transitions Lebih Aman?**
- Urutan dijamin benar
- Tidak bisa skip step
- Business rules terpenuhi
- Audit trail jelas

---

### 6. God Object

**God Object (SALAH)**
```php
class Wallet extends Model {
    public function withdraw() { }
    public function deposit() { }
    public function transfer() { }
    public function sendNotification() { }
    public function generateReport() { }
    public function detectFraud() { }
    // Terlalu banyak tanggung jawab ❌
}
```

**Separation of Concerns (BENAR)**
```php
// Domain logic
class Wallet extends Model {
    public function debit(Money $amount): void { }
    public function credit(Money $amount): void { }
}

// Application service
class WalletTransferService {
    public function transfer(Wallet $from, Wallet $to, Money $amount): void { }
}

// Infrastructure
class WalletNotificationService {
    public function notifyDebit(Wallet $wallet, Money $amount): void { }
}
```

**Kenapa Separation Lebih Baik?**
- Single Responsibility Principle
- Easier to test
- Easier to maintain
- Reusable components

---

### 7. Invalid State Representation

**Invalid State Possible (SALAH)**
```php
$order->refund_approved_at = now();
$order->refund_requested_at = null; // Approved tanpa request ❌

$order->amount = -1000; // Negatif ❌

$order->refund_date = '2024-01-01';
$order->order_date = '2024-12-31'; // Refund sebelum order ❌
```

**Make Invalid State Unrepresentable (BENAR)**
```php
class Order {
    // Immutable fields
    protected $guarded = ['amount', 'order_date'];
    
    // Validation
    protected static function boot() {
        static::creating(function($order) {
            if ($order->amount < 0) {
                throw new InvalidArgumentException();
            }
        });
    }
    
    // State machine
    public function approveRefund(): void {
        if ($this->status !== OrderStatus::REFUND_REQUESTED) {
            throw new InvalidStateTransition();
        }
        // ...
    }
}
```

---

### 8. Race Condition

**Race Condition (SALAH)**
```php
// Request 1 dan 2 bersamaan
$voucher = Voucher::find($id);
if ($voucher->usage_count < $voucher->max_usage) {
    $voucher->usage_count++; // Keduanya bisa lolos ❌
    $voucher->save();
}
```

**Pessimistic Locking (BENAR)**
```php
DB::transaction(function() use ($id) {
    $voucher = Voucher::lockForUpdate()->find($id);
    
    if ($voucher->usage_count < $voucher->max_usage) {
        $voucher->usage_count++;
        $voucher->save();
    }
});
```

**Kenapa Locking Penting?**
- Prevent concurrent modification
- Data consistency
- ACID compliance
- Critical untuk financial transactions

---

### 9. Idempotency

**No Idempotency (SALAH)**
```php
// Retry bisa bikin double processing
public function redeem(Request $request) {
    $voucher->usage_count++;
    $voucher->save();
}
```

**Idempotent (BENAR)**
```php
public function redeem(Request $request) {
    $key = $request->header('Idempotency-Key');
    
    // Check if already processed
    $existing = VoucherRedemption::where('idempotency_key', $key)->first();
    if ($existing) {
        return $existing; // Return same result
    }
    
    // Process
    $redemption = $voucher->redeem($user, $key);
    return $redemption;
}
```

**Kenapa Idempotency Penting?**
- Safe retry
- Network reliability
- Prevent duplicate charges
- Better UX

---

### 10. Immutability

**Mutable (SALAH)**
```php
class Order {
    protected $fillable = ['amount', 'order_date', 'user_id'];
    // Semua bisa diubah setelah dibuat ❌
}

$order->amount = 999999; // Fraud!
```

**Immutable (BENAR)**
```php
class Order {
    protected $guarded = ['amount', 'order_date', 'user_id'];
    
    public function setAmountAttribute($value) {
        if ($this->exists) {
            throw new ImmutableFieldException();
        }
        $this->attributes['amount'] = $value;
    }
}
```

**Kenapa Immutability Penting?**
- Data integrity
- Audit trail
- Prevent fraud
- Easier reasoning

---

### 11. Domain Events

**No Events (SALAH)**
```php
public function approveRefund() {
    $this->status = 'refunded';
    $this->save();
    // Tidak ada audit trail
    // Tidak ada notification
}
```

**With Events (BENAR)**
```php
public function approveRefund() {
    $this->status = 'refunded';
    $this->save();
    
    event(new OrderRefunded($this));
}

// Listener
class LogOrderRefund {
    public function handle(OrderRefunded $event) {
        AuditLog::create([...]);
    }
}

class NotifyUserRefund {
    public function handle(OrderRefunded $event) {
        Mail::to($event->order->user)->send(...);
    }
}
```

**Kenapa Events Penting?**
- Loose coupling
- Audit trail
- Extensibility
- Separation of concerns

---

### 12. Aggregate Pattern

**No Aggregate (SALAH)**
```php
// Transfer tidak atomic
$from->balance -= $amount;
$from->save();

$to->balance += $amount;
$to->save(); // Bisa gagal di sini, uang hilang ❌
```

**Aggregate (BENAR)**
```php
class WalletTransferService {
    public function transfer(Wallet $from, Wallet $to, Money $amount) {
        return DB::transaction(function() use ($from, $to, $amount) {
            $from->debit($amount);
            $to->credit($amount);
            
            WalletTransaction::create([...]);
            
            return $transaction;
        });
    }
}
```

**Kenapa Aggregate Penting?**
- Consistency boundary
- Transaction management
- Business invariants
- Atomic operations

---

## Prinsip Umum Security by Design

### 1. Defense in Depth
Jangan hanya validasi di 1 layer:
- Validasi di form (client-side)
- Validasi di controller (request validation)
- Validasi di model (domain rules)
- Validasi di database (constraints)

### 2. Fail Secure
Jika ada error, default ke state yang aman:
```php
public function canAccess(): bool {
    try {
        return $this->checkPermission();
    } catch (Exception $e) {
        return false; // Fail secure, bukan true
    }
}
```

### 3. Least Privilege
Hanya beri akses yang diperlukan:
```php
protected $guarded = ['id']; // Lebih aman dari $fillable = [...]
```

### 4. Complete Mediation
Setiap aksi harus melalui security check:
```php
public function ship(): void {
    if ($this->status !== OrderStatus::PAID) {
        throw new InvalidStateTransition(); // Always check
    }
    // ...
}
```

### 5. Audit Trail
Semua aksi penting harus tercatat:
```php
event(new OrderRefunded($this)); // Akan di-log oleh listener
```

---

## Checklist Security by Design

Saat membuat fitur baru, tanya:

- [ ] Apakah invalid state bisa direpresentasikan?
- [ ] Apakah ada race condition?
- [ ] Apakah field penting immutable?
- [ ] Apakah ada audit trail?
- [ ] Apakah validasi di domain model, bukan hanya controller?
- [ ] Apakah menggunakan value objects untuk domain concepts?
- [ ] Apakah state transitions enforced?
- [ ] Apakah ada idempotency untuk critical operations?
- [ ] Apakah menggunakan pessimistic locking untuk concurrent access?
- [ ] Apakah ada anomaly detection?

---

## Referensi Lebih Lanjut

- **Domain-Driven Design** by Eric Evans
- **Implementing Domain-Driven Design** by Vaughn Vernon
- **OWASP Top 10** - https://owasp.org/www-project-top-ten/
- **Laravel Security Best Practices** - https://laravel.com/docs/security
- **Martin Fowler's Blog** - https://martinfowler.com/
