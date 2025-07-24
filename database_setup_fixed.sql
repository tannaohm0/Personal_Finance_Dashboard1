-- Users table (extends Supabase auth.users)
CREATE TABLE IF NOT EXISTS public.user_profiles (
  id UUID PRIMARY KEY REFERENCES auth.users ON DELETE CASCADE,
  email VARCHAR(255) UNIQUE NOT NULL,
  full_name VARCHAR(255),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Categories table
CREATE TABLE IF NOT EXISTS public.categories (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  type VARCHAR(20) CHECK (type IN ('income', 'expense')),
  color VARCHAR(7), -- hex color
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add unique constraint to categories name (if it doesn't exist)
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'categories_name_unique') THEN
        ALTER TABLE public.categories ADD CONSTRAINT categories_name_unique UNIQUE (name);
    END IF;
END $$;

-- Transactions table
CREATE TABLE IF NOT EXISTS public.transactions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  amount DECIMAL(12, 2) NOT NULL,
  description TEXT,
  category_id UUID REFERENCES public.categories(id),
  category_name VARCHAR(100),
  transaction_date DATE NOT NULL,
  type VARCHAR(20) CHECK (type IN ('income', 'expense')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Budgets table
CREATE TABLE IF NOT EXISTS public.budgets (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  category_id UUID REFERENCES public.categories(id),
  category_name VARCHAR(100),
  amount DECIMAL(12, 2) NOT NULL,
  period VARCHAR(20) DEFAULT 'monthly',
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert default categories with proper conflict handling
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

-- Enable Row Level Security
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.budgets ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist and recreate them
DROP POLICY IF EXISTS "Users can view own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can view own transactions" ON public.transactions;
DROP POLICY IF EXISTS "Users can view own budgets" ON public.budgets;

-- Create policies
CREATE POLICY "Users can view own profile" ON public.user_profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.user_profiles
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can view own transactions" ON public.transactions
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can view own budgets" ON public.budgets
  FOR ALL USING (auth.uid() = user_id); 

-- 1. Add category_name columns if not exist
ALTER TABLE transactions ADD COLUMN IF NOT EXISTS category_name VARCHAR(100);
ALTER TABLE budgets ADD COLUMN IF NOT EXISTS category_name VARCHAR(100);

-- 2. Migrate data from category_id to category_name (preserves old records)
UPDATE transactions t
SET category_name = c.name
FROM categories c
WHERE t.category_id = c.id;

UPDATE budgets b
SET category_name = c.name
FROM categories c
WHERE b.category_id = c.id;

-- 3. Remove category_id columns and constraints
ALTER TABLE transactions DROP CONSTRAINT IF EXISTS transactions_category_id_fkey;
ALTER TABLE budgets DROP CONSTRAINT IF EXISTS budgets_category_id_fkey;
ALTER TABLE transactions DROP COLUMN IF EXISTS category_id;
ALTER TABLE budgets DROP COLUMN IF EXISTS category_id;

-- 4. (Optional) Drop categories table if you are done with it
-- DROP TABLE IF EXISTS categories; 