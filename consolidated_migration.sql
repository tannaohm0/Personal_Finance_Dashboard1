-- InvestIQ Consolidated Migration & Setup Script
-- This script is idempotent and safe for fresh or existing databases.
-- Run in your Supabase SQL editor.

-- 1. Create user_profiles table (extends Supabase auth.users)
CREATE TABLE IF NOT EXISTS public.user_profiles (
  id UUID PRIMARY KEY REFERENCES auth.users ON DELETE CASCADE,
  email VARCHAR(255) UNIQUE NOT NULL,
  full_name VARCHAR(255),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  currency VARCHAR(10) DEFAULT 'USD',
  date_format VARCHAR(20) DEFAULT 'YYYY-MM-DD',
  income_categories TEXT DEFAULT 'Salary, Freelance, Gifts, Investments, Other',
  expense_categories TEXT DEFAULT 'Food, Housing, Transportation, Utilities, Entertainment, Healthcare, Education, Shopping, Personal, Other'
);

-- 2. Create categories table (optional, for migration)
CREATE TABLE IF NOT EXISTS public.categories (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  type VARCHAR(20) CHECK (type IN ('income', 'expense')),
  color VARCHAR(7),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'categories_name_unique') THEN
        ALTER TABLE public.categories ADD CONSTRAINT categories_name_unique UNIQUE (name);
    END IF;
END $$;

-- 3. Create transactions table
CREATE TABLE IF NOT EXISTS public.transactions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  amount DECIMAL(12, 2) NOT NULL,
  description TEXT,
  transaction_date DATE NOT NULL,
  type VARCHAR(20) CHECK (type IN ('income', 'expense')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  category_name VARCHAR(100)
);

-- 4. Create budgets table
CREATE TABLE IF NOT EXISTS public.budgets (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  amount DECIMAL(12, 2) NOT NULL,
  period VARCHAR(20) DEFAULT 'monthly',
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  category_name VARCHAR(100)
);

-- 5. Insert default categories (for migration)
INSERT INTO public.categories (name, type, color) VALUES
('Salary', 'income', '#4CAF50'),
('Freelance', 'income', '#8BC34A'),
('Food & Dining', 'expense', '#FF9800'),
('Transportation', 'expense', '#2196F3'),
('Shopping', 'expense', '#E91E63'),
('Entertainment', 'expense', '#9C27B0'),
('Bills & Utilities', 'expense', '#F44336'),
('Healthcare', 'expense', '#00BCD4')
ON CONFLICT (name) DO NOTHING;

-- 6. Add category_name columns if not exist (for legacy DBs)
ALTER TABLE transactions ADD COLUMN IF NOT EXISTS category_name VARCHAR(100);
ALTER TABLE budgets ADD COLUMN IF NOT EXISTS category_name VARCHAR(100);

-- 7. Migrate data from category_id to category_name (if needed)
UPDATE transactions t
SET category_name = c.name
FROM categories c
WHERE t.category_id = c.id AND t.category_name IS NULL;

UPDATE budgets b
SET category_name = c.name
FROM categories c
WHERE b.category_id = c.id AND b.category_name IS NULL;

-- 8. Remove category_id columns and constraints (if exist)
ALTER TABLE transactions DROP CONSTRAINT IF EXISTS transactions_category_id_fkey;
ALTER TABLE budgets DROP CONSTRAINT IF EXISTS budgets_category_id_fkey;
ALTER TABLE transactions DROP COLUMN IF EXISTS category_id;
ALTER TABLE budgets DROP COLUMN IF EXISTS category_id;

-- 9. (Optional) Drop categories table if you are done with it
-- DROP TABLE IF EXISTS categories;

-- 10. Create user_credits table
CREATE TABLE IF NOT EXISTS public.user_credits (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  points INTEGER DEFAULT 1000,
  level VARCHAR(20) DEFAULT 'Bronze',
  total_transactions INTEGER DEFAULT 0,
  budget_violations INTEGER DEFAULT 0,
  successful_months INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id)
);

-- 11. Create credit_transactions table
CREATE TABLE IF NOT EXISTS public.credit_transactions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  transaction_type VARCHAR(50) NOT NULL,
  points_change INTEGER NOT NULL,
  description TEXT,
  related_transaction_id UUID REFERENCES public.transactions(id) ON DELETE SET NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 12. Insert default credit record for existing users
INSERT INTO public.user_credits (user_id, points, level)
SELECT id, 1000, 'Bronze'
FROM auth.users
WHERE id NOT IN (SELECT user_id FROM public.user_credits);

-- 13. Enable RLS on all tables
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.budgets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_credits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.credit_transactions ENABLE ROW LEVEL SECURITY;

-- 14. Drop existing policies (if any)
DROP POLICY IF EXISTS "Users can view own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can view own transactions" ON public.transactions;
DROP POLICY IF EXISTS "Users can insert own transactions" ON public.transactions;
DROP POLICY IF EXISTS "Users can update own transactions" ON public.transactions;
DROP POLICY IF EXISTS "Users can delete own transactions" ON public.transactions;
DROP POLICY IF EXISTS "Users can view own budgets" ON public.budgets;
DROP POLICY IF EXISTS "Users can insert own budgets" ON public.budgets;
DROP POLICY IF EXISTS "Users can update own budgets" ON public.budgets;
DROP POLICY IF EXISTS "Users can delete own budgets" ON public.budgets;
DROP POLICY IF EXISTS "Users can view own credits" ON public.user_credits;
DROP POLICY IF EXISTS "Users can update own credits" ON public.user_credits;
DROP POLICY IF EXISTS "Users can insert own credits" ON public.user_credits;
DROP POLICY IF EXISTS "Users can view own credit transactions" ON public.credit_transactions;
DROP POLICY IF EXISTS "Users can insert own credit transactions" ON public.credit_transactions;

-- 15. Create policies for user_profiles
CREATE POLICY "Users can view own profile" ON public.user_profiles
  FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile" ON public.user_profiles
  FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON public.user_profiles
  FOR UPDATE USING (auth.uid() = id);

-- 16. Create policies for transactions
CREATE POLICY "Users can view own transactions" ON public.transactions
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own transactions" ON public.transactions
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own transactions" ON public.transactions
  FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own transactions" ON public.transactions
  FOR DELETE USING (auth.uid() = user_id);

-- 17. Create policies for budgets
CREATE POLICY "Users can view own budgets" ON public.budgets
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own budgets" ON public.budgets
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own budgets" ON public.budgets
  FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own budgets" ON public.budgets
  FOR DELETE USING (auth.uid() = user_id);

-- 18. Create policies for user_credits
CREATE POLICY "Users can view own credits" ON public.user_credits
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can update own credits" ON public.user_credits
  FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own credits" ON public.user_credits
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 19. Create policies for credit_transactions
CREATE POLICY "Users can view own credit transactions" ON public.credit_transactions
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own credit transactions" ON public.credit_transactions
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 20. Create function and trigger for user level updates
CREATE OR REPLACE FUNCTION update_user_level()
RETURNS TRIGGER AS $$
BEGIN
  NEW.level = CASE
    WHEN NEW.points >= 5000 THEN 'Diamond'
    WHEN NEW.points >= 3000 THEN 'Platinum'
    WHEN NEW.points >= 2000 THEN 'Gold'
    WHEN NEW.points >= 1000 THEN 'Silver'
    ELSE 'Bronze'
  END;
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS trigger_update_user_level ON public.user_credits;
CREATE TRIGGER trigger_update_user_level
  BEFORE UPDATE ON public.user_credits
  FOR EACH ROW
  EXECUTE FUNCTION update_user_level();

-- 21. Verification queries
SELECT 'user_profiles' as table_name, COUNT(*) as row_count FROM public.user_profiles
UNION ALL
SELECT 'transactions' as table_name, COUNT(*) as row_count FROM public.transactions
UNION ALL
SELECT 'budgets' as table_name, COUNT(*) as row_count FROM public.budgets
UNION ALL
SELECT 'user_credits' as table_name, COUNT(*) as row_count FROM public.user_credits
UNION ALL
SELECT 'credit_transactions' as table_name, COUNT(*) as row_count FROM public.credit_transactions;

-- Show all policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname; 