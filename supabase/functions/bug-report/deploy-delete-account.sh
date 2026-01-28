#!/bin/bash

# 🗑️ Deploy Account Deletion Edge Function
# This script sets up the account deletion function for App Store compliance

set -e

echo "🗑️  Setting up Account Deletion Function..."
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
    exit 1
fi

echo -e "${GREEN}✓${NC} Supabase CLI is installed"

# Check if already linked
echo ""
echo "🔗 Linking to Supabase project..."
supabase link --project-ref ikihabdfvjicjuatpjvd || echo "Already linked"

# Get Service Role Key
echo ""
echo -e "${YELLOW}⚠️  IMPORTANT: Service Role Key Needed${NC}"
echo ""
echo "This function needs your Supabase SERVICE ROLE KEY (not anon key)."
echo "This key has admin privileges, so keep it SECRET!"
echo ""
echo "To get it:"
echo "1. Go to: https://supabase.com/dashboard/project/ikihabdfvjicjuatpjvd/settings/api"
echo "2. Find 'Service Role Key' (click to reveal)"
echo "3. Copy the key (starts with eyJ...)"
echo ""
read -p "Enter your Service Role Key: " SERVICE_ROLE_KEY

# Set the secret
echo ""
echo "📝 Setting service role key..."
supabase secrets set SUPABASE_SERVICE_ROLE_KEY="$SERVICE_ROLE_KEY"

echo -e "${GREEN}✓${NC} Service role key configured"

# Create function directory if it doesn't exist
echo ""
echo "📁 Setting up function directory..."
mkdir -p supabase/functions/delete-account

# Copy the function file
if [ -f "delete-account-function.ts" ]; then
    cp delete-account-function.ts supabase/functions/delete-account/index.ts
    echo -e "${GREEN}✓${NC} Function file copied"
else
    echo -e "${RED}❌ delete-account-function.ts not found${NC}"
    echo "Make sure you're in the project root directory"
    exit 1
fi

# Deploy function
echo ""
echo "🚀 Deploying delete-account function..."
supabase functions deploy delete-account

echo ""
echo -e "${GREEN}✅ Deployment complete!${NC}"
echo ""
echo "📋 Next steps:"
echo "  1. Run your iOS app"
echo "  2. Create a test account"
echo "  3. Go to Profile → Delete Account"
echo "  4. Confirm deletion by typing DELETE"
echo "  5. Try to sign in again → Should fail (account deleted)"
echo ""
echo "🔍 To view function logs:"
echo "  supabase functions logs delete-account --follow"
echo ""
echo "✅ Your app is now App Store compliant for account deletion!"
echo ""
