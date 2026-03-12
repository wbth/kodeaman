#!/bin/bash

# Script untuk deploy ke GitHub
# Jalankan dengan: bash DEPLOY_COMMANDS.sh

echo "🚀 Starting deployment to GitHub..."

# Initialize git if not already
if [ ! -d .git ]; then
    echo "📦 Initializing git repository..."
    git init
fi

# Add all files
echo "📝 Adding all files..."
git add .

# Commit
echo "💾 Creating commit..."
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

# Check if remote exists
if git remote | grep -q origin; then
    echo "✅ Remote 'origin' already exists"
else
    echo "❌ Remote 'origin' not found!"
    echo ""
    echo "Silakan jalankan command berikut:"
    echo "git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git"
    echo ""
    echo "Ganti YOUR_USERNAME dan YOUR_REPO dengan repository Anda"
    exit 1
fi

# Push to GitHub
echo "🚀 Pushing to GitHub..."
git branch -M main
git push -u origin main

echo ""
echo "✅ Deployment complete!"
echo ""
echo "📋 Next steps:"
echo "1. Buka repository di GitHub"
echo "2. Tambahkan topics: laravel, security, security-by-design, education"
echo "3. Edit description"
echo "4. Share link ke mahasiswa"
