# 🚀 Earnify - SQL Setup Instructions

## ✅ **SQL Syntax Fixed!**

The SQL syntax error has been resolved. Please follow these steps:

## 📋 **Step 1: Run Main Schema**

1. Go to [Supabase Dashboard](https://supabase.com/dashboard/project/gxuewpsyslvhqvpytthj)
2. Navigate to **SQL Editor**
3. Copy-paste contents of `supabase-schema.sql`
4. Click **Run** ✅

## 📋 **Step 2: Run Additional Setup** (Optional)

1. In the same SQL Editor, copy-paste contents of `supabase-storage.sql`
2. Click **Run** ✅

## 🔧 **What Was Fixed:**

- ❌ `substr(gen_random_uuid()::text, 1, 8).toUpperCase()` 
- ✅ `upper(substr(gen_random_uuid()::text, 1, 8))`

- ❌ Line numbers in SQL output
- ✅ Clean SQL without formatting

## 🎯 **After Running SQL:**

You'll have:
- ✅ All tables created (profiles, tasks, submissions, etc.)
- ✅ Row Level Security policies
- ✅ Triggers for automatic profile creation
- ✅ Sample tasks for testing
- ✅ Storage bucket for audio uploads

## 🚀 **Ready to Test!**

After running the SQL, your Earnify app is fully functional:

```bash
npm run dev
# Open http://localhost:3000
```

### **Test Flow:**
1. **Login**: Use any phone number (check console for OTP)
2. **Complete Tasks**: Try typing and transcription tasks
3. **Request Payout**: Convert points to real money
4. **Admin Access**: Add your phone to admin list

## 🎉 **All Set!**

Your Earnify platform is now ready with:
- Phone OTP authentication ✅
- Complete database schema ✅  
- Task submission system ✅
- Payout management ✅
- Admin dashboard ✅

**Start your earning platform today!** 🚀