# 🚀 Instruksi Deploy ke GitHub

## Langkah 1: Buat Repository di GitHub

1. Buka https://github.com
2. Klik **"New"** atau **"+"** → **"New repository"**
3. Isi:
   - **Repository name**: `laravel-security-by-design-lab`
   - **Description**: `Lab Security by Design - Laravel. Kode sengaja tidak aman untuk pembelajaran.`
   - **Visibility**: Public atau Private
   - ❌ JANGAN centang "Add README"
4. Klik **"Create repository"**
5. **Copy URL** yang muncul (contoh: `https://github.com/username/laravel-security-by-design-lab.git`)

---

## Langkah 2: Deploy dari Terminal

Buka terminal di folder project ini, lalu jalankan:

```bash
# 1. Initialize git (jika belum)
git init

# 2. Add all files
git add .

# 3. Commit
git commit -m "Initial commit: Lab Security by Design - Laravel

✨ Features:
- 4 modul pembelajaran (Authentication, Order, Wallet, Voucher)
- 60+ masalah keamanan untuk diperbaiki
- 29 test cases
- Dokumentasi lengkap di folder docs/
- Kisi-kisi perbaikan tanpa solusi lengkap

📁 Structure:
- app/ - Kode tidak aman (sengaja)
- docs/ - Dokumentasi lengkap
- tests/ - Test cases
- database/migrations/ - Database schema

⚠️ CATATAN: Kode sengaja tidak aman untuk tujuan pembelajaran!"

# 4. Add remote (GANTI dengan URL repository Anda!)
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git

# 5. Push
git branch -M main
git push -u origin main
```

---

## Langkah 3: Konfigurasi Repository

### Tambah Topics
Di halaman repository GitHub, klik "Add topics":
```
laravel
security
security-by-design
ddd
domain-driven-design
education
lab
php
learning
```

### Edit About
Klik "Edit" di sebelah About:
```
Lab Security by Design - Laravel. Kode sengaja tidak aman untuk pembelajaran. 
60+ masalah keamanan, 4 modul, 29 test cases.
```

---

## Langkah 4: Verifikasi

Pastikan di GitHub:
- ✅ README.md tampil di halaman utama
- ✅ Folder `docs/` berisi dokumentasi
- ✅ Folder `app/` berisi kode
- ✅ Folder `tests/` berisi test cases

---

## Langkah 5: Share ke Mahasiswa

Berikan link ini ke mahasiswa:

```
Repository: https://github.com/YOUR_USERNAME/laravel-security-by-design-lab

Cara clone:
git clone https://github.com/YOUR_USERNAME/laravel-security-by-design-lab.git
cd laravel-security-by-design-lab

Setup:
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate

Dokumentasi:
- README.md - Mulai di sini
- docs/UNTUK_MAHASISWA.md - Panduan lengkap
- docs/KISI-KISI_PERBAIKAN.md - Struktur solusi
```

---

## Troubleshooting

### Error: Permission Denied
```bash
# Cek remote
git remote -v

# Jika salah, hapus dan tambah lagi
git remote remove origin
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git
```

### Error: Already Exists
```bash
# Hapus git lama
rm -rf .git

# Mulai dari awal
git init
```

---

## Alternative: Gunakan Script

Atau jalankan script yang sudah disediakan:

```bash
# Berikan permission
chmod +x DEPLOY_COMMANDS.sh

# Jalankan
./DEPLOY_COMMANDS.sh
```

**Catatan**: Anda tetap perlu add remote dulu sebelum menjalankan script.

---

✅ **Selesai! Repository siap digunakan!**
