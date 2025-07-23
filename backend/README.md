# InvestIQ Backend API

This is the backend API for the InvestIQ Personal Finance Dashboard, built with Express.js and Supabase.

## Features

- User authentication with JWT
- Transaction management (CRUD operations)
- Budget tracking and management
- Financial reports and analytics
- AI-powered financial insights
- Secure API endpoints with JWT authentication

## Setup

1. Install dependencies:

```bash
npm install
```

2. Create a `.env` file in the root directory:

```env
PORT=5000
SUPABASE_URL=your-supabase-url
SUPABASE_KEY=your-supabase-key
JWT_SECRET=your-super-secret-jwt-key-change-in-production
```

3. Set up your Supabase database.

4. Run the development server:

```bash
npm run dev
```

## Database Schema

The application uses Supabase to manage the schema and data for the following models:

- `User`: Stores user information (name, email, password).
- `Transaction`: Stores financial transactions (amount, description, category, date, type).
- `Category`: Stores transaction categories (name, type, color).
- `Budget`: Stores user-defined budgets (category, amount, period).
- `UserCredit`: Stores user credit information.
- `CreditTransaction`: Stores credit transactions.
- `BudgetViolation`: Stores budget violation information.

## API Endpoints

### Authentication

- `POST /api/auth/register` - Register a new user
- `POST /api/auth/login` - Login user
- `POST /api/auth/logout` - Logout user

### Transactions

- `GET /api/transactions` - Get all transactions for user
- `POST /api/transactions` - Create new transaction
- `PUT /api/transactions/:id` - Update transaction
- `DELETE /api/transactions/:id` - Delete transaction
- `GET /api/transactions/categories` - Get all categories

### Budgets

- `GET /api/budgets` - Get all budgets for user
- `POST /api/budgets` - Create new budget
- `PUT /api/budgets/:id` - Update budget
- `DELETE /api/budgets/:id` - Delete budget

### Reports

- `GET /api/reports/monthly-summary` - Get monthly financial summary
- `GET /api/reports/spending-trends` - Get spending trends over time
- `GET /api/reports/budget-vs-actual` - Compare budget vs actual spending

### AI Assistant

- `POST /api/ai/insights` - Get AI-powered financial insights
- `GET /api/ai/financial-summary` - Get financial summary for AI analysis

## Scripts

- `npm start` - Start production server
- `npm run dev` - Start development server with nodemon

## Security

- All routes (except auth) require JWT authentication
- CORS enabled for frontend communication
- Helmet.js for security headers
- Input validation and sanitization
