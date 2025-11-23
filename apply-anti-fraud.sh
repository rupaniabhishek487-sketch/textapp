#!/bin/bash

echo "🚀 Applying Anti-Fraud Schema to Supabase..."
echo ""

# Check if DATABASE_URL is set
if [ -z "$DATABASE_URL" ]; then
    echo "❌ ERROR: DATABASE_URL environment variable is not set"
    echo "Please set your DATABASE_URL and try again"
    exit 1
fi

echo "📁 Reading anti-fraud schema..."
SCHEMA_FILE="anti-fraud-schema.sql"

if [ ! -f "$SCHEMA_FILE" ]; then
    echo "❌ ERROR: $SCHEMA_FILE not found"
    exit 1
fi

echo "🔗 Connecting to database and applying schema..."
echo ""

# Apply the schema using psql if available, otherwise provide instructions
if command -v psql &> /dev/null; then
    echo "✅ Using psql to apply schema..."
    psql "$DATABASE_URL" -f "$SCHEMA_FILE"
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "🎉 SUCCESS: Anti-fraud schema applied successfully!"
        echo ""
        echo "📋 Tables created:"
        echo "  - device_fingerprints"
        echo "  - rate_limits"
        echo "  - fraud_alerts"
        echo "  - user_suspensions"
        echo ""
        echo "🔧 Functions created:"
        echo "  - record_device_fingerprint()"
        echo "  - check_rate_limit()"
        echo "  - record_rate_limit_attempt()"
        echo "  - check_daily_submission_limit()"
        echo "  - is_user_suspended()"
        echo "  - suspend_user()"
        echo "  - lift_user_suspension()"
        echo "  - is_payout_eligible()"
        echo "  - get_suspicious_users()"
        echo "  - cleanup_old_rate_limits()"
        echo "  - cleanup_old_device_fingerprints()"
        echo ""
        echo "✨ Anti-fraud system is now ready!"
    else
        echo "❌ ERROR: Failed to apply schema"
        exit 1
    fi
else
    echo "⚠️  psql not found. Please apply the schema manually:"
    echo ""
    echo "1. Copy the contents of $SCHEMA_FILE"
    echo "2. Go to your Supabase dashboard > SQL Editor"
    echo "3. Paste and execute the schema"
    echo ""
    echo "📄 Schema file contents:"
    echo "=========================="
    cat "$SCHEMA_FILE"
    echo "=========================="
fi