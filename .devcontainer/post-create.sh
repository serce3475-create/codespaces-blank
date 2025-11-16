#!/bin/bash
set -e

echo "🚀 Flutter + Node.js Dev Environment Setup"

# Install Flutter SDK
if ! command -v flutter &> /dev/null; then
  echo "📥 Installing Flutter SDK..."
  mkdir -p ~/flutter
  cd ~/flutter
  
  # Download Flutter for Linux
  if ! [ -d "flutter" ]; then
    git clone -b stable https://github.com/flutter/flutter.git
  fi
  
  export PATH="$PATH:$(pwd)/flutter/bin"
  
  # Run flutter doctor
  flutter doctor
  
  # Accept Android licenses
  flutter config --no-analytics
  yes | flutter doctor --android-licenses || true
  
  echo "✅ Flutter SDK installed successfully!"
else
  echo "✅ Flutter already installed"
fi

# Ensure Node.js dependencies are installed in the project
echo "📦 Installing project dependencies..."
cd /workspaces/codespaces-blank/SkyFleet_App

if [ -f "functions/package.json" ]; then
  echo "Installing functions dependencies..."
  cd functions
  npm ci --no-audit --no-fund || npm install --no-audit --no-fund
  cd ..
fi

if [ -f "pubspec.yaml" ]; then
  echo "Installing Flutter dependencies..."
  flutter pub get
fi

echo "✨ Setup complete!"
