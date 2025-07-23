const express = require('express');
const { createClient } = require('@supabase/supabase-js');
const { authenticateToken } = require('../middleware/auth');
const router = express.Router();

// Create Supabase client with environment variables
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !supabaseKey) {
  console.error('Missing Supabase environment variables in reports:', {
    SUPABASE_URL: supabaseUrl ? 'SET' : 'MISSING',
    SUPABASE_SERVICE_ROLE_KEY: supabaseKey ? 'SET' : 'MISSING'
  });
}

const supabase = createClient(supabaseUrl, supabaseKey);

// Apply authentication to all routes
router.use(authenticateToken);

// Get monthly summary
router.get('/monthly-summary', async (req, res) => {
  try {
    const { month, year } = req.query;
    const targetMonth = month || new Date().getMonth() + 1;
    const targetYear = year || new Date().getFullYear();
    const { data: transactions, error } = await supabase
      .from('transactions')
      .select('*')
      .eq('user_id', req.user.id)
      .gte('transaction_date', `${targetYear}-${targetMonth.toString().padStart(2, '0')}-01`)
      .lt('transaction_date', `${targetYear}-${(targetMonth + 1).toString().padStart(2, '0')}-01`);
    if (error) {
      return res.status(400).json({ error: error.message });
    }
    const income = transactions
      .filter(t => t.type === 'income')
      .reduce((sum, t) => sum + parseFloat(t.amount), 0);
    const expenses = transactions
      .filter(t => t.type === 'expense')
      .reduce((sum, t) => sum + parseFloat(t.amount), 0);
    const categoryBreakdown = {};
    transactions
      .filter(t => t.type === 'expense')
      .forEach(t => {
        const categoryName = t.category_name || 'Uncategorized';
        if (!categoryBreakdown[categoryName]) {
          categoryBreakdown[categoryName] = 0;
        }
        categoryBreakdown[categoryName] += parseFloat(t.amount);
      });
    res.json({
      month: targetMonth,
      year: targetYear,
      income,
      expenses,
      netIncome: income - expenses,
      transactionCount: transactions.length,
      categoryBreakdown
    });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Get spending trends
router.get('/spending-trends', async (req, res) => {
  try {
    const { months = 6 } = req.query;
    const trends = [];

    for (let i = 0; i < parseInt(months); i++) {
      const date = new Date();
      date.setMonth(date.getMonth() - i);
      const month = date.getMonth() + 1;
      const year = date.getFullYear();

      const { data: transactions, error } = await supabase
        .from('transactions')
        .select('*')
        .eq('user_id', req.user.id)
        .eq('type', 'expense')
        .gte('transaction_date', `${year}-${month.toString().padStart(2, '0')}-01`)
        .lt('transaction_date', `${year}-${(month + 1).toString().padStart(2, '0')}-01`);

      if (error) {
        return res.status(400).json({ error: error.message });
      }

      const totalExpenses = transactions.reduce((sum, t) => sum + parseFloat(t.amount), 0);
      trends.unshift({
        month: month,
        year: year,
        expenses: totalExpenses
      });
    }

    res.json(trends);
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Get budget vs actual
router.get('/budget-vs-actual', async (req, res) => {
  try {
    const { data: budgets, error: budgetError } = await supabase
      .from('budgets')
      .select('*')
      .eq('user_id', req.user.id);
    if (budgetError) {
      return res.status(400).json({ error: budgetError.message });
    }
    const currentDate = new Date();
    const currentMonth = currentDate.getMonth() + 1;
    const currentYear = currentDate.getFullYear();
    const { data: transactions, error: transactionError } = await supabase
      .from('transactions')
      .select('*')
      .eq('user_id', req.user.id)
      .eq('type', 'expense')
      .gte('transaction_date', `${currentYear}-${currentMonth.toString().padStart(2, '0')}-01`)
      .lt('transaction_date', `${currentYear}-${(currentMonth + 1).toString().padStart(2, '0')}-01`);
    if (transactionError) {
      return res.status(400).json({ error: transactionError.message });
    }
    const budgetVsActual = budgets.map(budget => {
      const categoryTransactions = transactions.filter(t => t.category_name === budget.category_name);
      const actualAmount = categoryTransactions.reduce((sum, t) => sum + parseFloat(t.amount), 0);
      return {
        category: budget.category_name,
        budgetAmount: parseFloat(budget.amount),
        actualAmount,
        difference: parseFloat(budget.amount) - actualAmount,
        percentageUsed: (actualAmount / parseFloat(budget.amount)) * 100
      };
    });
    res.json(budgetVsActual);
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

module.exports = router; 