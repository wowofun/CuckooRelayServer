#!/bin/bash

# Cuckoo Relay Server - One-Click Deployment Script
# Usage: ./deploy.sh

echo "🐦 Cuckoos Relay Server Deployment"
echo "==================================="

# Determine Wrangler Command
if command -v wrangler &> /dev/null; then
    WRANGLER="wrangler"
elif command -v npx &> /dev/null; then
    echo "⚠️  Global Wrangler not found, using npx..."
    WRANGLER="npx wrangler"
else
    echo "❌ Wrangler (Cloudflare CLI) not found."
    echo "👉 Please install it: npm install -g wrangler"
    exit 1
fi

# 1. Login
echo "🔑 Checking Cloudflare login..."
$WRANGLER whoami || $WRANGLER login

# 2. Create D1 Database
echo "📦 Creating D1 Database..."
DB_NAME="cuckoos-db-$(date +%s)"
CREATE_OUTPUT=$($WRANGLER d1 create $DB_NAME)
DB_ID=$(echo "$CREATE_OUTPUT" | grep "database_id" | awk -F '"' '{print $2}')

if [ -z "$DB_ID" ]; then
    echo "❌ Failed to create database. Please check your Cloudflare account limits."
    # Try to find existing
    echo "   Trying to use existing 'cuckoos-db'..."
    DB_ID=$($WRANGLER d1 list | grep "cuckoos-db" | awk '{print $1}' | head -n 1)
fi

if [ -z "$DB_ID" ]; then
   echo "❌ Could not create or find a database. Exiting."
   exit 1
fi

echo "✅ Database ID: $DB_ID"

# 3. Update wrangler.toml
echo "📝 Updating configuration..."

# Copy template if wrangler.toml doesn't exist
if [ ! -f "wrangler.toml" ]; then
    echo "   Creating wrangler.toml from template..."
    cp wrangler.toml.example wrangler.toml
fi

# Check if database_id is already set to something other than empty string
CURRENT_DB_ID=$(grep 'database_id = "' wrangler.toml | awk -F '"' '{print $2}')

if [ "$CURRENT_DB_ID" != "$DB_ID" ]; then
    echo "   Setting database_id in wrangler.toml..."
    # If it's empty, replace it
    if [ -z "$CURRENT_DB_ID" ]; then
         sed -i '' "s/database_id = \"\"/database_id = \"$DB_ID\"/" wrangler.toml
    else
         # If it's not empty, replace the existing ID
         sed -i '' "s/database_id = \".*\"/database_id = \"$DB_ID\"/" wrangler.toml
    fi
else
    echo "   database_id is already set correctly."
fi


# 4. Apply Schema (Optional, code now auto-inits, but good for safety)
# echo "🏗️ Applying database schema..."
# $WRANGLER d1 execute $DB_NAME --file=schema.sql --remote

# 5. Deploy Worker
echo "🚀 Deploying Worker..."
$WRANGLER deploy

echo "==================================="
echo "🎉 Deployment Complete!"
echo "1. Copy the URL above (e.g., https://cuckoos-relay.your-name.workers.dev)"
echo "2. Open Cuckoos App -> Settings -> Remote Connection"
echo "3. Enter the URL and any Secret Key you like."
echo "==================================="
