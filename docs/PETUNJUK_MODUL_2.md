# Modul 2: Order & Refund System

## Masalah yang Ada

### 1. Primitive Obsession
```php
// Order.php - SALAH
protected $fillable = ['status', 'amount', 'user_id', 'order_date'];
// status = string bebas: "paid", "Paid", "PAID", "payed" ❌
// amount = double, bisa negatif ❌
// user_id = integer, tidak ada validasi ❌
```

### 2. Boolean Flag Hell
```php
// Order.php - SALAH
protected $casts = [
    'is_paid' => 'boolean',
    'is_shipped' => 'boolean',
    'is_delivered' => 'boolean',
    'is_refunded' => 'boolean',
    'is_refund_approved' => 'boolean',
];
// Kombinasi invalid: is_refunded=true tapi is_paid=false ❌
```

### 3. Anemic Domain Model
```php
// OrderController.php - SALAH
public function refund($id) {
    $order = Order::find($id);
    $order->status = 'refunded'; // Tidak ada validasi
    $order->refund_amount = request('amount'); // Bisa lebih besar dari amount
    $order->save();
}
```

### 4. Temporal Coupling Tersembunyi
```php
// SALAH - bisa refund sebelum paid/delivered
$order->status = 'refunded';
// Tidak ada enforcement urutan: pending → paid → shipped → delivered → (refund_requested) → refunded
```

### 5. Invalid State Bisa Direpresentasikan
```php
// SALAH - semua ini bisa terjadi:
$order->refund_approved_at = now();
$order->refund_requested_at = null; // Approved tanpa request ❌

$order->amount = -1000; // Amount negatif ❌

$order->refund_date = '2024-01-01';
$order->order_date = '2024-12-31'; // Refund sebelum order ❌

$order->status = 'REFUNDEDD'; // Typo ❌
```

## Yang Harus Diperbaiki

### 1. Gunakan Value Objects
```php
// OrderStatus.php - enum atau class
enum OrderStatus: string {
    case PENDING = 'pending';
    case PAID = 'paid';
    case SHIPPED = 'shipped';
    case DELIVERED = 'delivered';
    case REFUND_REQUESTED = 'refund_requested';
    case REFUNDED = 'refunded';
    case CANCELLED = 'cancelled';
}

// Money.php - value object
class Money {
    private function __construct(private int $cents) {
        if ($cents < 0) throw new InvalidArgumentException();
    }
    public static function fromCents(int $cents): self;
    public function isGreaterThan(Money $other): bool;
}
```

### 2. State Machine dengan Transition Methods
```php
// Order.php - BENAR
class Order extends Model {
    // Bukan setter status langsung
    public function confirmPayment(): void {
        if ($this->status !== OrderStatus::PENDING) {
            throw new InvalidStateTransition();
        }
        $this->status = OrderStatus::PAID;
        $this->paid_at = now();
        $this->save();
        event(new OrderPaid($this));
    }
    
    public function ship(): void {
        if ($this->status !== OrderStatus::PAID) {
            throw new InvalidStateTransition();
        }
        $this->status = OrderStatus::SHIPPED;
        $this->shipped_at = now();
        $this->save();
    }
    
    public function confirmDelivery(): void {
        if ($this->status !== OrderStatus::SHIPPED) {
            throw new InvalidStateTransition();
        }
        $this->status = OrderStatus::DELIVERED;
        $this->delivered_at = now();
        $this->save();
    }
    
    public function requestRefund(string $reason): void {
        if (!in_array($this->status, [OrderStatus::DELIVERED])) {
            throw new CannotRefundException();
        }
        $this->status = OrderStatus::REFUND_REQUESTED;
        $this->refund_requested_at = now();
        $this->refund_reason = $reason;
        $this->save();
    }
    
    public function approveRefund(): void {
        if ($this->status !== OrderStatus::REFUND_REQUESTED) {
            throw new InvalidStateTransition();
        }
        $this->status = OrderStatus::REFUNDED;
        $this->refunded_at = now();
        $this->save();
        event(new OrderRefunded($this));
    }
}
```

### 3. Immutability untuk Data Penting
```php
// Order.php
protected $guarded = ['amount', 'order_date', 'user_id'];
// Setelah dibuat, tidak bisa diubah

// Atau gunakan accessor yang throw exception
public function setAmountAttribute($value) {
    if ($this->exists) {
        throw new ImmutableFieldException('amount');
    }
    $this->attributes['amount'] = $value;
}
```

### 4. Domain Events untuk Audit Trail
```php
// Events
class OrderPaid {
    public function __construct(public Order $order) {}
}

class OrderRefunded {
    public function __construct(public Order $order) {}
}

// Listener untuk audit
class LogOrderEvent {
    public function handle($event) {
        AuditLog::create([
            'event' => class_basename($event),
            'order_id' => $event->order->id,
            'user_id' => auth()->id(),
            'ip' => request()->ip(),
            'timestamp' => now(),
        ]);
    }
}
```

## Test Cases
- [ ] Order baru hanya bisa status PENDING
- [ ] Tidak bisa ship sebelum paid
- [ ] Tidak bisa refund sebelum delivered
- [ ] Amount tidak bisa negatif
- [ ] Amount tidak bisa diubah setelah order dibuat
- [ ] Refund tidak bisa approved tanpa request dulu
- [ ] Status typo tidak bisa disimpan
- [ ] Setiap state transition tercatat di audit log

## Struktur File
```
app/
├── Models/
│   ├── Order.php (deep model dengan transition methods)
│   └── AuditLog.php
├── ValueObjects/
│   ├── Money.php
│   └── OrderStatus.php (enum)
├── Events/
│   ├── OrderPaid.php
│   └── OrderRefunded.php
├── Exceptions/
│   ├── InvalidStateTransition.php
│   └── CannotRefundException.php
└── Listeners/
    └── LogOrderEvent.php
```
