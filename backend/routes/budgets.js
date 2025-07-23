const express = require('express');
const { createClient } = require('@supabase/supabase-js');
const { authenticateToken } = require('../middleware/auth');
const router = express.Router();

// Create Supabase client with environment variables
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !supabaseKey) {
  console.error('Missing Supabase environment variables in budgets:', {
    SUPABASE_URL: supabaseUrl ? 'SET' : 'MISSING',
    SUPABASE_SERVICE_ROLE_KEY: supabaseKey ? 'SET' : 'MISSING'
  });
}

const supabase = createClient(supabaseUrl, supabaseKey);

// Apply authentication to all routes
router.use(authenticateToken);

// Get all budgets for user
router.get('/', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('budgets')
      .select('*')
      .eq('user_id', req.user.id)
      .order('created_at', { ascending: false });
    if (error) {
      return res.status(400).json({ error: error.message });
    }
    res.json(data);
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Create budget
router.post('/', async (req, res) => {
  try {
    const { category_name, amount, period, start_date, end_date } = req.body;
    const { data, error } = await supabase
      .from('budgets')
      .insert([
        {
          user_id: req.user.id,
          category_name,
          amount,
          period,
          start_date,
          end_date,
        }
      ])
      .select();
    if (error) {
      return res.status(400).json({ error: error.message });
    }
    res.status(201).json(data[0]);
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Update budget
router.put('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { category_name, amount, period, start_date, end_date } = req.body;
    const { data, error } = await supabase
      .from('budgets')
      .update({
        category_name,
        amount,
        period,
        start_date,
        end_date,
        updated_at: new Date().toISOString(),
      })
      .eq('id', id)
      .eq('user_id', req.user.id)
      .select();
    if (error) {
      return res.status(400).json({ error: error.message });
    }
    res.json(data[0]);
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Delete budget
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;

    const { error } = await supabase
      .from('budgets')
      .delete()
      .eq('id', id)
      .eq('user_id', req.user.id);

    if (error) {
      return res.status(400).json({ error: error.message });
    }

    res.json({ message: 'Budget deleted successfully' });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

module.exports = router; 