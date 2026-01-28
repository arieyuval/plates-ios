#!/bin/bash

# 🚀 Plates Bug Report Function Deployment Script
# This script deploys the bug report Edge Function to Supabase

set -e  # Exit on error

echo "🔧 Setting up Supabase Edge Function for Bug Reporting..."
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if supabase CLI is installed
if ! command -v supabase &> /dev/null; then
    echo -e "${RED}❌ Supabase CLI is not installed${NC}"
    echo ""
    echo "Install it with:"
    echo "  npm install -g supabase"
    echo ""
    exit 1
fi

echo -e "${GREEN}✓${NC} Supabase CLI is installed"

# Check if already linked
echo ""
echo "🔗 Linking to Supabase project..."
supabase link --project-ref ikihabdfvjicjuatpjvd || echo "Already linked"

# Check for secrets
echo ""
echo -e "${YELLOW}⚙️  Setting up secrets...${NC}"
echo ""
echo "You need to provide three values:"
echo ""
echo "1. GitHub Personal Access Token (from https://github.com/settings/tokens)"
echo "   - Click 'Generate new token (classic)'"
echo "   - Select 'repo' scope"
echo "   - Copy the token (starts with ghp_)"
echo ""
echo "2. Your GitHub username"
echo "3. Your repository name (probably 'Plates')"
echo ""

# Prompt for GitHub token
read -p "Enter your GitHub token (ghp_...): " GITHUB_TOKEN
read -p "Enter your GitHub username: " GITHUB_REPO_OWNER
read -p "Enter repository name [Plates]: " GITHUB_REPO_NAME
GITHUB_REPO_NAME=${GITHUB_REPO_NAME:-Plates}

# Set secrets using correct syntax
echo ""
echo "📝 Setting secrets in Supabase..."
supabase secrets set GITHUB_TOKEN="$GITHUB_TOKEN"
supabase secrets set GITHUB_REPO_OWNER="$GITHUB_REPO_OWNER"
supabase secrets set GITHUB_REPO_NAME="$GITHUB_REPO_NAME"

echo -e "${GREEN}✓${NC} Secrets configured"

# Deploy function
echo ""
echo "🚀 Deploying Edge Function..."
supabase functions deploy bug-report

echo ""
echo -e "${GREEN}✅ Deployment complete!${NC}"
echo ""
echo "📋 Next steps:"
echo "  1. Run your iOS app"
echo "  2. Go to Profile → Report a Bug"
echo "  3. Submit a test bug report"
echo "  4. Check your GitHub repository for a new issue"
echo ""
echo "🔍 To view function logs:"
echo "  supabase functions logs bug-report"
echo ""
