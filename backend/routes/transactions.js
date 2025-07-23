const express = require('express');
const { createClient } = require('@supabase/supabase-js');
const { authenticateToken } = require('../middleware/auth');
const router = express.Router();

// Create Supabase client with environment variables
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !supabaseKey) {
  console.error('Missing Supabase environment variables:', {
    SUPABASE_URL: supabaseUrl ? 'SET' : 'MISSING',
    SUPABASE_SERVICE_ROLE_KEY: supabaseKey ? 'SET' : 'MISSING'
  });
}

const supabase = createClient(supabaseUrl, supabaseKey);

// Apply authentication to all routes
router.use(authenticateToken);

// Get all transactions for user
router.get('/', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('transactions')
      .select('*')
      .eq('user_id', req.user.id)
      .order('transaction_date', { ascending: false });
    if (error) {
      return res.status(400).json({ error: error.message });
    }
    res.json(data);
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Create transaction
router.post('/', async (req, res) => {
  try {
    const { amount, description, category_name, transaction_date, type } = req.body;
    const { data, error } = await supabase
      .from('transactions')
      .insert([
        {
          user_id: req.user.id,
          amount,
          description,
          category_name,
          transaction_date,
          type,
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

// Update transaction
router.put('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { amount, description, category_name, transaction_date, type } = req.body;
    const { data, error } = await supabase
      .from('transactions')
      .update({
        amount,
        description,
        category_name,
        transaction_date,
        type,
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

// Delete transaction
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;

    const { error } = await supabase
      .from('transactions')
      .delete()
      .eq('id', id)
      .eq('user_id', req.user.id);

    if (error) {
      return res.status(400).json({ error: error.message });
    }

    res.json({ message: 'Transaction deleted successfully' });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

module.exports = router; 