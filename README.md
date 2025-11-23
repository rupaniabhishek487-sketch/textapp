# Earnify - Earn Rewards Online

Earnify is a Progressive Web App built with Next.js 15 and Supabase that allows users to complete tasks, earn points, and get rewarded with real money.

## Features

- **Phone OTP Authentication**: Secure login using Supabase Auth with phone number verification
- **Task Management**: Complete typing and transcription tasks to earn points
- **Reward System**: Convert points to real money via UPI payouts
- **Admin Dashboard**: Manage users, submissions, and payout requests
- **PWA Support**: Install as a mobile app with offline capabilities
- **Real-time Updates**: Live status updates for tasks and payouts

## Tech Stack

- **Frontend**: Next.js 15, TypeScript, Tailwind CSS, shadcn/ui
- **Backend**: Supabase (PostgreSQL, Auth, Storage)
- **Authentication**: Supabase Auth (Phone OTP only)
- **Database**: Supabase PostgreSQL with RLS policies
- **Deployment**: Vercel (recommended)

## Quick Start

### Prerequisites

- Node.js 18+ 
- npm or yarn
- Supabase account

### 1. Clone and Install

```bash
git clone <repository-url>
cd earnify
npm install
```

### 2. Set up Supabase

1. Create a new project at [supabase.com](https://supabase.com)
2. Run the SQL schema from `supabase-schema.sql` in your Supabase SQL editor
3. Enable Phone Auth in Supabase Auth settings
4. Get your project URL and keys from Supabase settings

### 3. Environment Variables

Copy `.env.example` to `.env.local`:

```bash
cp .env.example .env.local
```

Fill in your Supabase credentials:

```env
NEXT_PUBLIC_SUPABASE_URL=your_supabase_project_url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_supabase_service_role_key
```

### 4. Run Development Server

```bash
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) in your browser.

## Database Schema

The app uses the following main tables:

- `profiles` - User profiles linked to auth.users
- `tasks` - Available tasks for users to complete
- `task_submissions` - User task submissions
- `transactions` - Financial transactions
- `payout_requests` - User payout requests
- `referrals` - Referral relationships
- `device_fingerprints` - Device tracking for fraud prevention

See `supabase-schema.sql` for the complete schema.

## Phone OTP Setup

### Production

1. In Supabase Dashboard → Auth → Settings:
   - Enable "Enable phone signups"
   - Configure your SMS provider (Twilio, MessageBird, etc.)
   - Set up phone number templates

### Development

For local development without SMS provider:

1. In Supabase Dashboard → Auth → Settings:
   - Enable "Enable phone signups"
   - Check "Enable custom access token hook"
   - Use the provided development hook or simulate OTPs

2. Set environment variable:
   ```env
   NEXT_PUBLIC_SIMULATE_SMS=true
   ```

## Admin Access

To access the admin dashboard, add your phone number to the admin list in `src/app/admin/page.tsx`:

```typescript
const ADMIN_PHONES = ['+919876543210', '+911234567890'] // Add your phone
```

## Key Features

### Task System

- **Typing Tasks**: Users type given text with accuracy scoring
- **Transcription Tasks**: Users upload audio and provide transcriptions
- **Auto-scoring**: Similarity algorithms for typing tasks
- **Manual Review**: Admin approval for transcription tasks

### Payout System

- **Points Conversion**: 1 point = ₹0.01
- **Minimum Payout**: 1000 points (₹10)
- **UPI Integration**: Direct bank transfers via UPI
- **Admin Approval**: Manual review of payout requests

### Security

- **Row Level Security**: Database access controls
- **Device Fingerprinting**: Fraud prevention
- **Phone Verification**: Secure user authentication
- **Input Validation**: XSS and SQL injection protection

## Deployment

### Vercel (Recommended)

1. Connect your repository to Vercel
2. Add environment variables in Vercel dashboard
3. Deploy automatically on push to main branch

### Other Platforms

Ensure your platform supports:
- Node.js 18+
- Environment variables
- Serverless functions
- File uploads (for audio tasks)

## API Routes

- `/api/submit-task` - Submit task completion
- `/api/request-payout` - Request payout
- `/api/auth/*` - Supabase Auth endpoints

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## Support

For issues and questions:
1. Check the [Issues](../../issues) page
2. Create a new issue with detailed description
3. Include environment details and error logs

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acceptance Checklist

- [x] Phone OTP authentication with Supabase
- [x] Task submission and scoring system
- [x] Payout request and management
- [x] Admin dashboard for moderation
- [x] Responsive design for mobile/desktop
- [x] PWA configuration and manifest
- [x] Database schema with RLS policies
- [x] Environment configuration
- [x] Documentation and setup instructions