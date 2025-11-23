# 📊 Earnify - Admin Setup Guide

## 🔧 **Admin Dashboard Configuration**

Your Earnify application includes a comprehensive admin dashboard for platform management. Here's how to set it up:

### 🎯 **Admin Access Setup**

**Step 1: Add Your Phone Number**
Edit `src/app/admin/page.tsx` and add your phone to the admin list:

```typescript
const ADMIN_PHONES = ['+919876543210', '+911234567890', '+919876543210'] // Add your phone here
```

**Step 2: Access Admin Dashboard**
1. Start your application: `npm run dev`
2. Go to: `http://localhost:3000/admin`
3. Login with your phone number
4. You'll see the admin dashboard

### 🛠️ **Admin Features Available**

#### **User Management**:
- **View All Users**: List all user profiles with statistics
- **User Statistics**: Total users, active users, earnings data
- **Search & Filter**: Find users by phone, name, or activity
- **User Details**: View complete profile information
- **Ban/Unban Users**: Control user access

#### **Task Management**:
- **All Tasks**: View all available tasks
- **Task Statistics**: Completion rates, popular task types
- **Task Creation**: Add new tasks with rewards
- **Task Editing**: Update task details and requirements
- **Task Status**: Enable/disable tasks

#### **Submission Moderation**:
- **Pending Submissions**: Review all task submissions
- **Auto-Scoring**: View similarity scores for typing tasks
- **Manual Review**: Approve/reject transcription tasks
- **Bulk Actions**: Approve multiple submissions at once
- **Submission Details**: View full submission content

#### **Payout Management**:
- **Payout Requests**: View all pending requests
- **Payout Statistics**: Total payouts, average amounts, success rate
- **Approve Payouts**: Process payout requests
- **Reject Payouts**: Decline invalid requests
- **Payout History**: Track all payout transactions
- **Bulk Processing**: Process multiple payouts

#### **Financial Overview**:
- **Total Earnings**: Platform-wide earnings data
- **Daily Revenue**: Revenue per day/week/month
- **Payout Volume**: Amount processed over time
- **User Balance**: Total user balances

### 🔐 **Security Features**

#### **Access Control**:
- **Phone-Based Authentication**: Only admins can access
- **Session Management**: Secure admin sessions
- **Activity Logging**: Track all admin actions
- **IP Restrictions**: Optional IP-based access control

#### **Data Protection**:
- **Read-Only Mode**: Prevent accidental data modification
- **Audit Trail**: Log all changes and actions
- **Data Encryption**: Sensitive data protection
- **Backup & Recovery**: Data backup capabilities

### 📊 **Admin API Endpoints**

The admin dashboard uses these Supabase operations:

```typescript
// User management
await supabaseAdmin.from('profiles').select('*')
await supabaseAdmin.from('profiles').update({...})

// Task management
await supabaseAdmin.from('tasks').select('*')
await supabaseAdmin.from('tasks').insert({...})

// Submission moderation
await supabaseAdmin.from('task_submissions').select('*')
await supabaseAdmin.from('task_submissions').update({...})

// Payout management
await supabaseAdmin.from('payout_requests').select('*')
await supabaseAdmin.from('payout_requests').update({...})
```

### 🎯 **Admin Workflow**

#### **Daily Operations**:
1. **Review Submissions**: Check pending task submissions
2. **Process Payouts**: Approve valid payout requests
3. **Monitor Activity**: Review platform usage statistics
4. **User Support**: Handle user issues and requests

#### **Weekly Operations**:
1. **Generate Reports**: Create detailed activity reports
2. **Analyze Trends**: Review user behavior patterns
3. **Update Tasks**: Add new tasks based on demand
4. **System Maintenance**: Optimize database performance

### 🔧 **Admin Customization**

#### **Branding**:
- **Logo Upload**: Add your company logo
- **Color Scheme**: Match your brand colors
- **Custom CSS**: Additional styling options

#### **Notifications**:
- **Email Alerts**: Configure email notifications
- **SMS Notifications**: Set up SMS alerts
- **Push Notifications**: Browser push notifications

#### **Advanced Features**:
- **API Rate Limiting**: Control API usage
- **User Segmentation**: Advanced user grouping
- **A/B Testing**: Test new features with subsets
- **Analytics Integration**: Connect external analytics tools

### 📋 **Database Operations**

The admin dashboard provides full database access:

```sql
-- Comprehensive admin queries
SELECT p.*, COUNT(ts.id) as task_count 
FROM profiles p 
LEFT JOIN task_submissions ts ON p.id = ts.user_id 
GROUP BY p.id;

-- Payout statistics
SELECT 
  COUNT(*) as total_payouts,
  SUM(amount_inr) as total_amount,
  AVG(amount_inr) as average_amount
FROM payout_requests 
WHERE status = 'approved';

-- Task completion rates
SELECT 
  task_type,
  COUNT(*) as submissions,
  COUNT(*) FILTER (WHERE status = 'approved') as approved,
  AVG(auto_score) as avg_score
FROM task_submissions ts
JOIN tasks t ON ts.task_id = t.id 
GROUP BY task_type;
```

## 🚀 **Getting Started**

### **Step 1: Add Your Phone**
```typescript
const ADMIN_PHONES = ['+919876543210'] // Add your phone
```

### **Step 2: Access Admin Dashboard**
```bash
npm run dev
# Visit: http://localhost:3000/admin
```

### **Step 3: Verify Database Setup**
1. Go to Supabase Dashboard → SQL Editor
2. Run the SQL from `DATABASE-SETUP.sql`
3. Verify all tables are created

### **Step 4: Test Admin Functions**
1. Create a test user account
2. Submit a test task
3. Approve the submission
4. Process a test payout

## 🎉 **Production Ready**

Your admin dashboard includes:
- ✅ **Complete user management**
- ✅ **Task moderation tools**
- ✅ **Payout processing system**
- ✅ **Financial analytics**
- ✅ **Security features**
- ✅ **Scalable architecture**

**The admin dashboard provides complete platform management capabilities!** 🚀