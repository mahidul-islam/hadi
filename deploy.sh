#!/bin/bash

# =============================================================================
# Hadi Game - Firebase Deployment Script
# =============================================================================
# This script builds and deploys the Flutter web app to Firebase Hosting
# 
# Prerequisites:
#   - Flutter SDK installed and in PATH
#   - Firebase CLI installed (npm install -g firebase-tools)
#   - Logged into Firebase (firebase login)
#   - Firebase project configured (go-hadi)
#
# Usage:
#   ./deploy.sh           # Full build and deploy
#   ./deploy.sh --skip-build  # Deploy existing build only
# =============================================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored message
print_step() {
    echo -e "${BLUE}==>${NC} ${GREEN}$1${NC}"
}

print_warning() {
    echo -e "${YELLOW}Warning:${NC} $1"
}

print_error() {
    echo -e "${RED}Error:${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# =============================================================================
# Step 0: Pre-flight checks
# =============================================================================
print_step "Running pre-flight checks..."

# Check Flutter
if ! command_exists flutter; then
    print_error "Flutter is not installed or not in PATH"
    exit 1
fi
print_success "Flutter found"

# Check Firebase CLI
if ! command_exists firebase; then
    print_error "Firebase CLI is not installed. Run: npm install -g firebase-tools"
    exit 1
fi
print_success "Firebase CLI found"

# Check if logged into Firebase
if ! firebase projects:list >/dev/null 2>&1; then
    print_error "Not logged into Firebase. Run: firebase login"
    exit 1
fi
print_success "Firebase authentication verified"

# =============================================================================
# Step 1: Clean previous build
# =============================================================================
SKIP_BUILD=false
if [[ "$1" == "--skip-build" ]]; then
    SKIP_BUILD=true
    print_warning "Skipping build step, using existing build..."
fi

if [ "$SKIP_BUILD" = false ]; then
    print_step "Cleaning previous build..."
    flutter clean
    print_success "Clean complete"

    # =============================================================================
    # Step 2: Get dependencies
    # =============================================================================
    print_step "Getting dependencies..."
    flutter pub get
    print_success "Dependencies fetched"

    # =============================================================================
    # Step 3: Build web release
    # =============================================================================
    print_step "Building web release..."
    flutter build web --release --tree-shake-icons
    print_success "Web build complete"
fi

# =============================================================================
# Step 4: Verify build exists
# =============================================================================
if [ ! -d "build/web" ]; then
    print_error "Build directory not found. Run without --skip-build flag."
    exit 1
fi
print_success "Build directory verified"

# =============================================================================
# Step 5: Deploy to Firebase Hosting
# =============================================================================
print_step "Deploying to Firebase Hosting..."
firebase deploy --only hosting

# =============================================================================
# Done!
# =============================================================================
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Deployment Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "Your app is now live at:"
echo -e "${BLUE}  https://go-hadi.web.app${NC}"
echo -e "${BLUE}  https://go-hadi.firebaseapp.com${NC}"
echo ""
