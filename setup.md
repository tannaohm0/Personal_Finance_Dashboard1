# InvestIQ Setup Guide

## 🚀 Quick Setup Instructions

### Step 1: Environment Configuration

#### Backend (.env file)
Create a file named `.env` in the `backend` folder with the following content:

```env
PORT=5000
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
SUPABASE_URL=your-supabase-url
SUPABASE_ANON_KEY=your-supabase-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
```

#### Frontend (.env.local file)
Create a file named `.env.local` in the `frontend` folder with the following content:

```env
NEXT_PUBLIC_SUPABASE_URL=your-supabase-url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-supabase-anon-key
NEXT_PUBLIC_API_URL=http://localhost:5000/api
```

### Step 2: Supabase Setup

1. Go to [supabase.com](https://supabase.com) and create a new project
2. Get your project URL and API keys from Settings > API
3. Replace the placeholder values in your .env files with your actual Supabase credentials
4. Run the SQL commands from the README.md file in your Supabase SQL editor

### Step 3: Start the Application

#### Start Backend Server
```bash
cd backend
npm run dev
```

#### Start Frontend Server (in a new terminal)
```bash
cd frontend
npm run dev
```

### Step 4: Access the Application

- Frontend: http://localhost:3000
- Backend API: http://localhost:5000

## 🎯 What's Been Implemented

### ✅ Completed Features

1. **Authentication System**
   - User registration and login
   - Secure JWT token management
   - Protected routes

2. **Dashboard**
   - Financial overview with key metrics
   - Income vs expenses visualization
   - Category breakdown charts
   - Recent activity summary

3. **Transaction Management**
   - Add, edit, and delete transactions
   - Category-based organization
   - Date filtering and sorting
   - Income and expense tracking

4. **Budget Management**
   - Set budgets by category
   - Visual progress indicators
   - Budget alerts and notifications
   - Period-based budgeting

5. **Financial Reports**
   - Income vs expenses analysis
   - Category spending breakdown
   - Monthly trends and patterns
   - Interactive charts and graphs

6. **AI Assistant**
   - Personalized financial advice
   - Spending pattern analysis
   - Budget recommendations
   - Goal setting assistance

7. **Additional Pages**
   - About page with project information
   - Contact page with support form
   - Responsive navigation

### 🛠️ Technical Implementation

- **Frontend**: Next.js 15 with App Router, Material-UI, Recharts
- **Backend**: Express.js with Supabase integration
- **Database**: PostgreSQL with Supabase
- **Authentication**: Supabase Auth with JWT
- **Charts**: Recharts for data visualization
- **Styling**: Material-UI components and theming

## 🔧 Troubleshooting

### Common Issues

1. **Environment Variables Not Loading**
   - Make sure .env files are in the correct locations
   - Restart the development servers after adding environment variables

2. **Supabase Connection Issues**
   - Verify your Supabase URL and API keys
   - Check that Row Level Security policies are set up correctly

3. **Port Conflicts**
   - Backend runs on port 5000
   - Frontend runs on port 3000
   - Make sure these ports are available

4. **Database Schema Issues**
   - Run the SQL commands exactly as provided in the README
   - Check that all tables and policies are created correctly

### Getting Help

If you encounter any issues:
1. Check the browser console for frontend errors
2. Check the terminal for backend errors
3. Verify your Supabase configuration
4. Ensure all dependencies are installed correctly

## 🎉 Next Steps

Once the application is running:

1. **Create an Account**: Register with your email and password
2. **Add Transactions**: Start tracking your income and expenses
3. **Set Budgets**: Create budgets for different spending categories
4. **Explore Reports**: View your financial analytics and insights
5. **Try the AI Assistant**: Get personalized financial advice

## 📱 Features to Explore

- **Dashboard**: Overview of your financial health
- **Transactions**: Manage your income and expenses
- **Budgets**: Set and track spending limits
- **Reports**: Analyze your financial patterns
- **Finance AI**: Get personalized recommendations
- **About**: Learn more about the application
- **Contact**: Get support and provide feedback

The application is now fully functional and ready for use! 🚀 