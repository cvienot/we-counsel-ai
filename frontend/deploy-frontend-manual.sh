#!/bin/bash

# Manual build and deploy script for Flutter web
# Use this for local testing or manual deployments

set -e

echo "🏗️  Building Flutter Web App..."
echo ""

# Clean previous build
echo "1. Cleaning previous build..."
flutter clean

# Get dependencies
echo "2. Getting dependencies..."
flutter pub get

# Build for web with production settings
echo "3. Building for production..."
flutter build web \
    --release \
    --dart-define=API_BASE_URL=https://your-app-runner-url.awsapprunner.com/api \
    --dart-define=ENVIRONMENT=production

# Amplify/S3 serves .ttf font assets reliably; keep the Flutter font
# manifest pointed at that deployed path for Material icons.
cp build/web/assets/fonts/MaterialIcons-Regular.otf build/web/assets/fonts/MaterialIcons-Regular.ttf
perl -0pi -e 's/fonts\/MaterialIcons-Regular\.otf/fonts\/MaterialIcons-Regular.ttf/g' \
    build/web/assets/FontManifest.json \
    build/web/flutter_service_worker.js

echo ""
echo "✅ Build complete!"
echo ""
echo "📦 Build output location: build/web/"
echo ""
echo "🧪 To test locally:"
echo "   cd build/web"
echo "   python3 -m http.server 8080"
echo "   Open: http://localhost:8080"
echo ""
echo "☁️  To deploy to Amplify:"
echo "   The build/web directory will be automatically deployed on git push"
echo ""
