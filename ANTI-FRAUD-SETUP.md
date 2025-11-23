# 🚀 Anti-Fraud System Setup Guide

## ⚠️ QUICK FIX NEEDED

You're getting this error: `column "fingerprint_hash" does not exist` because the database schema hasn't been applied yet.

## 📋 IMMEDIATE STEPS TO FIX

### Step 1: Apply Database Schema (Required)

**Option A: Use the Setup Page (Recommended)**
1. Go to: `http://localhost:3000/setup/anti-fraud`
2. Click "Download SQL" to download the schema file
3. Open your Supabase Dashboard
4. Go to SQL Editor
5. Paste the entire SQL content
6. Click "Run"

**Option B: Manual Copy-Paste**
1. Copy the entire content of `anti-fraud-schema.sql` file
2. Go to your Supabase Dashboard → SQL Editor
3. Paste and execute

### Step 2: Verify Schema Applied

After running the SQL, verify these tables exist:
- `device_fingerprints`
- `rate_limits` 
- `fraud_alerts`
- `user_suspensions`

And these functions:
- `record_device_fingerprint()`
- `check_rate_limit()`
- `is_user_suspended()`
- `suspend_user()`
- `is_payout_eligible()`
- `get_suspicious_users()`

### Step 3: Test the System

1. Visit the admin dashboard: `http://localhost:3000/admin`
2. Look for the "Fraud Center" tab
3. Test device fingerprinting by logging in/out
4. Try rapid submissions to test rate limiting

## 🔧 What the Schema Creates

### Tables:
- **device_fingerprints**: Tracks user devices, IPs, and detects duplicates
- **rate_limits**: Enforces submission rate limits (30s/45s/50 daily)
- **fraud_alerts**: Records suspicious activity automatically
- **user_suspensions**: Manages user suspension with audit trail

### Functions:
- Device tracking and multi-account detection
- Rate limiting enforcement
- User suspension management
- 48-hour payout eligibility check
- Admin fraud data retrieval

## 🛡️ Security Features Enabled

1. **Device Fingerprinting**: Tracks browser fingerprints to detect multiple accounts
2. **IP Address Tracking**: Monitors IP addresses for suspicious patterns
3. **Rate Limiting**: 
   - Text submissions: 1 per 30 seconds
   - Audio submissions: 1 per 45 seconds
   - Daily limit: 50 submissions total
4. **Multi-Account Detection**: Automatic alerts for duplicate devices/IPs
5. **48-Hour Payout Hold**: New accounts must wait 48 hours before withdrawing
6. **User Suspension**: Admin can suspend users with reasons
7. **Fraud Center**: Admin dashboard for managing suspicious users

## 🎯 Expected Behavior After Setup

- Device fingerprints recorded on every login
- Rate limiting enforced on task submissions
- Fraud alerts generated for suspicious activity
- Admin dashboard shows "Fraud Center" tab
- Suspended users cannot claim/submit tasks
- New accounts blocked from payouts for 48 hours

## 🚨 Troubleshooting

If you still get errors after applying the schema:

1. **Check Table Names**: Ensure all 4 tables were created
2. **Check Functions**: Verify all 11 functions exist in Database Functions
3. **Refresh Connection**: Restart the development server
4. **Clear Cache**: Clear browser cache and retry

## 📞 Need Help?

The setup page at `/setup/anti-fraud` provides:
- Step-by-step instructions
- Download links for the SQL file
- Copy to clipboard functionality
- Direct link to Supabase dashboard

Visit: `http://localhost:3000/setup/anti-fraud`

---

**Once the schema is applied, the anti-fraud system will be fully operational!** 🎉