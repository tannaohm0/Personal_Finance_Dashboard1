-- Credit System Schema for InvestIQ
-- This file only manages the credit system (user_credits, credit_transactions).
-- For category_name migration and main schema changes, see database_setup_fixed.sql
-- Run this in your Supabase SQL Editor

-- Create user_credits table to track points and levels
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

-- Create credit_transactions table to track point changes
CREATE TABLE IF NOT EXISTS public.credit_transactions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  transaction_type VARCHAR(50) NOT NULL, -- 'budget_violation', 'budget_success', 'bonus', 'penalty'
  points_change INTEGER NOT NULL,
  description TEXT,
  related_transaction_id UUID REFERENCES public.transactions(id) ON DELETE SET NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.user_credits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.credit_transactions ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view own credits" ON public.user_credits;
DROP POLICY IF EXISTS "Users can update own credits" ON public.user_credits;
DROP POLICY IF EXISTS "Users can insert own credits" ON public.user_credits;
DROP POLICY IF EXISTS "Users can view own credit transactions" ON public.credit_transactions;
DROP POLICY IF EXISTS "Users can insert own credit transactions" ON public.credit_transactions;

-- Create policies for user_credits
CREATE POLICY "Users can view own credits" ON public.user_credits
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update own credits" ON public.user_credits
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own credits" ON public.user_credits
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Create policies for credit_transactions
CREATE POLICY "Users can view own credit transactions" ON public.credit_transactions
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own credit transactions" ON public.credit_transactions
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Insert default credit record for existing users
INSERT INTO public.user_credits (user_id, points, level)
SELECT id, 1000, 'Bronze'
FROM auth.users
WHERE id NOT IN (SELECT user_id FROM public.user_credits);

-- Create function to update user level based on points
CREATE OR REPLACE FUNCTION update_user_level()
RETURNS TRIGGER AS $$
BEGIN
  -- Update level based on points
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

-- Create trigger to automatically update level
DROP TRIGGER IF EXISTS trigger_update_user_level ON public.user_credits;
CREATE TRIGGER trigger_update_user_level
  BEFORE UPDATE ON public.user_credits
  FOR EACH ROW
  EXECUTE FUNCTION update_user_level();

-- Verify tables are created
SELECT 'user_credits' as table_name, COUNT(*) as row_count FROM public.user_credits
UNION ALL
SELECT 'credit_transactions' as table_name, COUNT(*) as row_count FROM public.credit_transactions; 