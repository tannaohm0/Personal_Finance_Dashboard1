# InvestIQ Personal Finance Dashboard

A comprehensive personal finance management application built with Next.js, Express.js, and Supabase. Features include expense tracking, budget management, financial reports, and AI-powered insights.

## 🚀 Features

- **User Authentication**: Secure login/registration with Supabase Auth
- **Transaction Management**: Add, edit, and delete income/expense transactions
- **Budget Tracking**: Set and monitor budgets for different categories
- **Financial Reports**: Comprehensive analytics with charts and insights
- **AI Assistant**: Personalized financial advice and recommendations
- **Responsive Design**: Works seamlessly on desktop and mobile devices
- **Real-time Data**: Instant updates across all components

## 🛠️ Tech Stack

### Frontend
- **Next.js 15** with App Router
- **Material-UI (MUI)** for components
- **Recharts** for data visualization
- **TypeScript** for type safety
- **Supabase Client** for database operations

### Backend
- **Node.js** with Express.js
- **Supabase** for database and authentication
- **JWT** for secure token management
- **Helmet** for security headers
- **CORS** for cross-origin requests

## 📋 Prerequisites

- Node.js (v18 or higher)
- npm or yarn
- Supabase account and project

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone <repository-url>
cd investiq
```

### 2. Set Up Supabase Database

1. Create a new Supabase project at [supabase.com](https://supabase.com)
2. Get your project URL and API keys from the project settings
3. **Run the SQL in `consolidated_migration.sql` in your Supabase SQL editor.**
   - This will set up all tables, policies, and migrations, including the credit system and category_name migration.

### 3. Backend Setup

```bash
cd backend

# Install dependencies
npm install

# Create environment file
cp .env.example .env
```

Edit `.env` with your Supabase credentials:

```env
PORT=5000
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
SUPABASE_URL=your-supabase-url
SUPABASE_ANON_KEY=your-supabase-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
```

```bash
# Start development server
npm run dev
```

### 4. Frontend Setup

```bash
cd frontend

# Install dependencies
npm install

# Create environment file
cp .env.example .env.local
```

Edit `.env.local` with your Supabase credentials:

```env
NEXT_PUBLIC_SUPABASE_URL=your-supabase-url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-supabase-anon-key
NEXT_PUBLIC_API_URL=http://localhost:5000/api
```

```bash
# Start development server
npm run dev
```

### 5. Access the Application

- Frontend: http://localhost:3000
- Backend API: http://localhost:5000

## 📁 Project Structure

```
investiq/
├── frontend/                 # Next.js application
│   ├── app/                 # App router pages (test/debug folders removed for production)
│   │   ├── dashboard/       # Dashboard page
│   │   ├── transactions/    # Transactions management
│   │   ├── budgets/         # Budget management
│   │   ├── reports/         # Financial reports
│   │   ├── finance-ai/      # AI assistant
│   │   ├── login/           # Login page
│   │   └── register/        # Registration page
│   ├── components/          # Reusable components
│   ├── context/             # React context providers
│   └── utils/               # Utility functions
├── backend/                  # Express.js API
│   ├── routes/              # API routes
│   ├── middleware/          # Express middleware
│   └── server.js            # Main server file
├── consolidated_migration.sql # Full database setup and migration
└── README.md
```

## 🔧 Available Scripts

### Backend
```bash
npm run dev      # Start development server with nodemon
npm start        # Start production server
```

### Frontend
```bash
npm run dev      # Start development server
npm run build    # Build for production
npm start        # Start production server
npm run lint     # Run ESLint
```

## 🔐 Authentication

The application uses Supabase Auth for user authentication. Users can:
- Register with email and password
- Login with existing credentials
- Access protected routes automatically
- Logout from any page

## 📊 Features Overview

### Dashboard
- Overview of financial metrics
- Monthly income vs expenses
- Category breakdown charts
- Recent activity summary

### Transactions
- Add new income/expense transactions
- Edit existing transactions
- Delete transactions
- Filter by date and category
- Bulk operations

### Budgets
- Set monthly budgets by category
- Track spending against budgets
- Visual progress indicators
- Budget alerts and notifications

### Reports
- Income vs expenses analysis
- Category spending breakdown
- Monthly trends and patterns
- Export functionality

### Finance AI
- Personalized financial advice
- Spending pattern analysis
- Budget recommendations
- Goal setting assistance

## 🚀 Deployment

### Frontend (Vercel)
1. Connect your GitHub repository to Vercel
2. Set environment variables in Vercel dashboard
3. Deploy automatically on push to main branch

### Backend (Railway/Heroku)
1. Connect your GitHub repository
2. Set environment variables
3. Deploy and get your API URL
4. Update frontend API URL

## 🗃️ Database Migration & Credit System
- All database setup and migration (including credit system tables and category_name migration) is handled by `consolidated_migration.sql`.
- Run this file in your Supabase SQL editor for both fresh and existing databases.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

If you encounter any issues or have questions:
- Check the [Issues] page
- Create a new issue with detailed information
- Contact support at support@investiq.com

## 🔮 Roadmap

- [ ] Investment tracking
- [ ] Bill reminders
- [ ] Multi-currency support
- [ ] Advanced AI features
- [ ] API integrations (banks, credit cards)
- [ ] Team/family accounts
- [ ] Advanced reporting
- [ ] Export to PDF/Excel
- [ ] Dark mode theme

---

Made with ❤️ by the InvestIQ team 