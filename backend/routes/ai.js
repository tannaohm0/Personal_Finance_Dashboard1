const express = require('express');
const { createClient } = require('@supabase/supabase-js');
const { authenticateToken } = require('../middleware/auth');
const router = express.Router();

// Create Supabase client with environment variables
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !supabaseKey) {
  console.error('Missing Supabase environment variables in ai:', {
    SUPABASE_URL: supabaseUrl ? 'SET' : 'MISSING',
    SUPABASE_SERVICE_ROLE_KEY: supabaseKey ? 'SET' : 'MISSING'
  });
}

const supabase = createClient(supabaseUrl, supabaseKey);

// Apply authentication to all routes
router.use(authenticateToken);

// Get AI insights
router.post('/insights', async (req, res) => {
  try {
    const { message } = req.body;

    // Fetch user's financial data
    const { data: transactions, error: transactionError } = await supabase
      .from('transactions')
      .select(`
        *,
        categories (
          name,
          type,
          color
        )
      `)
      .eq('user_id', req.user.id);

    if (transactionError) {
      return res.status(400).json({ error: transactionError.message });
    }

    const { data: budgets, error: budgetError } = await supabase
      .from('budgets')
      .select(`
        *,
        categories (
          name,
          type,
          color
        )
      `)
      .eq('user_id', req.user.id);

    if (budgetError) {
      return res.status(400).json({ error: budgetError.message });
    }

    // Generate AI response based on user data and message
    const aiResponse = generateAIResponse(message, { transactions, budgets });

    res.json({
      response: aiResponse,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Get financial summary for AI
router.get('/financial-summary', async (req, res) => {
  try {
    const { data: transactions, error } = await supabase
      .from('transactions')
      .select(`
        *,
        categories (
          name,
          type,
          color
        )
      `)
      .eq('user_id', req.user.id);

    if (error) {
      return res.status(400).json({ error: error.message });
    }

    const currentMonth = new Date().getMonth();
    const currentYear = new Date().getFullYear();

    const monthlyTransactions = transactions.filter(t => {
      const transactionDate = new Date(t.transaction_date);
      return transactionDate.getMonth() === currentMonth && 
             transactionDate.getFullYear() === currentYear;
    });

    const totalIncome = transactions
      .filter(t => t.type === 'income')
      .reduce((sum, t) => sum + parseFloat(t.amount), 0);

    const totalExpenses = transactions
      .filter(t => t.type === 'expense')
      .reduce((sum, t) => sum + parseFloat(t.amount), 0);

    const monthlyIncome = monthlyTransactions
      .filter(t => t.type === 'income')
      .reduce((sum, t) => sum + parseFloat(t.amount), 0);

    const monthlyExpenses = monthlyTransactions
      .filter(t => t.type === 'expense')
      .reduce((sum, t) => sum + parseFloat(t.amount), 0);

    // Category spending analysis
    const categorySpending = {};
    monthlyTransactions
      .filter(t => t.type === 'expense')
      .forEach(t => {
        const categoryName = t.categories?.name || 'Uncategorized';
        if (!categorySpending[categoryName]) {
          categorySpending[categoryName] = 0;
        }
        categorySpending[categoryName] += parseFloat(t.amount);
      });

    const topSpendingCategory = Object.entries(categorySpending)
      .sort(([,a], [,b]) => b - a)[0];

    res.json({
      totalBalance: totalIncome - totalExpenses,
      monthlyIncome,
      monthlyExpenses,
      monthlyNetIncome: monthlyIncome - monthlyExpenses,
      totalTransactions: transactions.length,
      monthlyTransactions: monthlyTransactions.length,
      topSpendingCategory: topSpendingCategory ? {
        name: topSpendingCategory[0],
        amount: topSpendingCategory[1]
      } : null,
      categoryBreakdown: categorySpending
    });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Helper function to generate AI responses
function generateAIResponse(message, financialData) {
  const { transactions, budgets } = financialData;
  const currentMonth = new Date().getMonth();
  const currentYear = new Date().getFullYear();

  // Calculate financial metrics
  const monthlyTransactions = transactions.filter(t => {
    const transactionDate = new Date(t.transaction_date);
    return transactionDate.getMonth() === currentMonth && 
           transactionDate.getFullYear() === currentYear;
  });

  const monthlyIncome = monthlyTransactions
    .filter(t => t.type === 'income')
    .reduce((sum, t) => sum + parseFloat(t.amount), 0);

  const monthlyExpenses = monthlyTransactions
    .filter(t => t.type === 'expense')
    .reduce((sum, t) => sum + parseFloat(t.amount), 0);

  const totalBalance = transactions
    .reduce((sum, t) => sum + parseFloat(t.amount) * (t.type === 'income' ? 1 : -1), 0);

  // Category spending analysis
  const categorySpending = {};
  monthlyTransactions
    .filter(t => t.type === 'expense')
    .forEach(t => {
      const categoryName = t.categories?.name || 'Uncategorized';
      if (!categorySpending[categoryName]) {
        categorySpending[categoryName] = 0;
      }
      categorySpending[categoryName] += parseFloat(t.amount);
    });

  const topSpendingCategory = Object.entries(categorySpending)
    .sort(([,a], [,b]) => b - a)[0];

  const messageLower = message.toLowerCase();

  // Generate contextual responses based on message content
  if (messageLower.includes('spending') || messageLower.includes('expense')) {
    return `Based on your recent activity, you've spent $${monthlyExpenses.toLocaleString()} this month. Your highest spending category is "${topSpendingCategory?.[0] || 'N/A'}" with $${topSpendingCategory?.[1]?.toLocaleString() || '0'}.

💡 **Recommendations:**
• Consider setting a budget limit for your top spending categories
• Track daily expenses to identify unnecessary purchases
• Look for subscription services you might not be using
${monthlyExpenses > monthlyIncome ? '• Your expenses exceed income this month - focus on reducing discretionary spending' : ''}`;
  }

  if (messageLower.includes('budget') || messageLower.includes('save')) {
    const savingsRate = monthlyIncome > 0 ? ((monthlyIncome - monthlyExpenses) / monthlyIncome * 100).toFixed(1) : 0;
    return `Your current savings rate is ${savingsRate}% this month (saving $${(monthlyIncome - monthlyExpenses).toLocaleString()}).

💡 **Budget Suggestions:**
• Aim for the 50/30/20 rule: 50% needs, 30% wants, 20% savings
• Your recommended monthly savings target: $${(monthlyIncome * 0.2).toLocaleString()}
• Consider automatic transfers to a savings account
${parseFloat(savingsRate) < 20 ? '• Try to increase your savings rate by reducing discretionary spending' : '• Great job on maintaining a healthy savings rate!'}`;
  }

  if (messageLower.includes('income') || messageLower.includes('earn')) {
    return `Your monthly income is $${monthlyIncome.toLocaleString()}.

💡 **Income Optimization Tips:**
• Consider side hustles or freelance work in your spare time
• Ask for a raise if you haven't had one recently
• Explore passive income opportunities like investments
• Track all income sources including bonuses and gifts`;
  }

  if (messageLower.includes('balance') || messageLower.includes('total')) {
    return `Your current balance is $${totalBalance.toLocaleString()}.

📊 **Financial Summary:**
• Monthly Income: $${monthlyIncome.toLocaleString()}
• Monthly Expenses: $${monthlyExpenses.toLocaleString()}
• Net Cash Flow: $${(monthlyIncome - monthlyExpenses).toLocaleString()}

${totalBalance < 0 ? '⚠️ Consider creating a debt payoff plan and increasing income or reducing expenses.' : '✅ You\'re maintaining a positive balance!'}`;
  }

  if (messageLower.includes('goal') || messageLower.includes('plan')) {
    return `Let me help you set financial goals based on your current situation:

🎯 **Recommended Goals:**
• Emergency Fund: Aim for $${(monthlyExpenses * 3).toLocaleString()} (3 months expenses)
• Monthly Savings: $${(monthlyIncome * 0.2).toLocaleString()} (20% of income)
• Debt Payoff: ${totalBalance < 0 ? `Focus on eliminating $${Math.abs(totalBalance).toLocaleString()} debt` : 'Great job staying debt-free!'}

📈 **Action Steps:**
1. Set up automatic savings transfers
2. Review and optimize your spending categories
3. Consider increasing income through skill development`;
  }

  // Default response with general insights
  return `I can help you with various financial topics! Here's a quick overview of your finances:

📊 **This Month:**
• Income: $${monthlyIncome.toLocaleString()}
• Expenses: $${monthlyExpenses.toLocaleString()}
• Balance: $${totalBalance.toLocaleString()}

💡 **Ask me about:**
• Budgeting strategies and savings tips
• Spending analysis and expense reduction
• Financial goal setting and planning
• Income optimization ideas

What specific area would you like to focus on?`;
}

module.exports = router; 