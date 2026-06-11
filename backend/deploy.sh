#!/bin/bash
# ============================================
# Kora Backend — Production Deploy Script
# ============================================

set -e

echo "🚀 Kora Backend Deploy — Starting..."

# 1. Pull latest code
echo "📥 Pulling latest code..."
git pull origin main

# 2. Install production dependencies
echo "📦 Installing Composer dependencies..."
composer install --no-dev --optimize-autoloader --no-interaction

# 3. Run migrations
echo "🗄️ Running database migrations..."
php artisan migrate --force

# 4. Clear and rebuild caches
echo "🔄 Rebuilding caches..."
php artisan config:cache
php artisan route:cache
php artisan view:cache
php artisan event:cache
php artisan icons:cache
php artisan filament:cache-components

# 5. Restart queue workers
echo "🔁 Restarting queue workers..."
php artisan queue:restart

# 6. Run storage link
echo "🔗 Linking storage..."
php artisan storage:link 2>/dev/null || true

echo ""
echo "✅ Kora Backend deployed successfully!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
