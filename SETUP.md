# 🚀 Earnify - Quick Setup Guide

## ✅ **Your Supabase is Configured!**

Your environment is now set up with:
- **URL**: https://gxuewpsyslvhqvpytthj.supabase.co
- **Keys**: Properly configured for client and server access

## 📋 **Setup Steps (5 minutes)**

### 1️⃣ **Database Setup** (2 minutes)

1. Go to [Supabase Dashboard](https://supabase.com/dashboard/project/gxuewpsyslvhqvpytthj)
2. Navigate to **SQL Editor**
3. Copy-paste contents of `supabase-schema.sql`
4. Click **Run** to create all tables
5. Copy-paste contents of `supabase-extra.sql`
6. Click **Run** to add sample data and functions

### 2️⃣ **Authentication Setup** (2 minutes)

1. Go to **Authentication** → **Settings**
2. Enable **"Enable phone signups"**
3. Configure SMS provider (Twilio recommended)
4. Set up phone verification templates

### 3️⃣ **Storage Setup** (1 minute)

1. Go to **Storage** → **Policies**
2. Create new bucket named `audio-uploads`
3. Set up RLS policies (already in schema)

### 4️⃣ **Start Development** (30 seconds)

```bash
npm run dev
```

Open http://localhost:3000

## 🎯 **Test the App**

### **Phone OTP Flow:**
1. Go to http://localhost:3000/login
2. Enter any phone number (e.g., +919876543210)
3. Check console for OTP (development mode)
4. Enter OTP to verify

### **Admin Access:**
1. After login, edit `src/app/admin/page.tsx`
2. Add your phone number to `ADMIN_PHONES` array
3. Access /admin for dashboard

## 📱 **PWA Features**

- Install as mobile app from browser menu
- Offline support for basic features
- App-like experience on mobile

## 🔧 **Development Notes**

### **SMS Simulation (Development)**
In development, OTPs are logged in console:
```javascript
// Check browser console for: 
// "OTP for +919876543210: 123456"
```

### **Sample Tasks**
The schema includes sample tasks:
- Typing Task (50 points)
- Transcription Task (100 points)
- Survey Task (30 points)

## 🚀 **Production Deployment**

### **Vercel (Recommended)**
1. Connect repository to Vercel
2. Add environment variables in Vercel dashboard
3. Deploy automatically

### **Environment Variables for Production:**
```env
NEXT_PUBLIC_SUPABASE_URL=https://gxuewpsyslvhqvpytthj.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

## 🎉 **You're Ready!**

Your Earnify app is now fully configured with:
- ✅ Phone OTP authentication
- ✅ Complete database schema
- ✅ Task submission system
- ✅ Payout management
- ✅ Admin dashboard
- ✅ PWA support
- ✅ Responsive design

**Start earning with your own rewards platform!** 🚀