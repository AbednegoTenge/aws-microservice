const express = require('express');
const crypto = require('crypto');
const { Pool } = require('pg');

const app = express();
app.use(express.json());

const inventoryUrl = process.env.INVENTORY_URL || 'http://localhost:3002';

const pool = new Pool({
  host: process.env.DB_HOST,
  port: Number(process.env.DB_PORT || 5432),
  database: process.env.DB_NAME,
  user: process.env.DB_USERNAME,
  password: process.env.DB_PASSWORD,
  max: 10,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 5000,
});

// Initialize database table
async function initializeDatabase() {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS orders (
      id UUID PRIMARY KEY,
      status VARCHAR(50) NOT NULL,
      items JSONB NOT NULL,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );
  `);

  console.log('Orders database initialized');
}

app.get('/orders/health', async (_req, res) => {
  try {
    await pool.query('SELECT 1');

    res.json({
      status: 'ok',
      service: 'orders',
      database: 'ok'
    });
  } catch (_error) {
    res.status(503).json({
      status: 'error',
      service: 'orders',
      database: 'unavailable'
    });
  }
});

app.get('/orders', async (_req, res) => {
  try {
    const result = await pool.query(`
      SELECT
        id,
        status,
        items,
        created_at AS "createdAt"
      FROM orders
      ORDER BY created_at DESC
    `);

    res.json(result.rows);
  } catch (error) {
    console.error('Failed to retrieve orders:', error);
    res.status(500).json({ error: 'Failed to retrieve orders' });
  }
});

app.get('/orders/:id', async (req, res) => {
  try {
    const result = await pool.query(
      `
      SELECT
        id,
        status,
        items,
        created_at AS "createdAt"
      FROM orders
      WHERE id = $1
      `,
      [req.params.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Order not found' });
    }

    return res.json(result.rows[0]);
  } catch (error) {
    console.error('Failed to retrieve order:', error);
    return res.status(500).json({ error: 'Failed to retrieve order' });
  }
});

app.post('/orders', async (req, res) => {
  const { items } = req.body;

  if (!Array.isArray(items) || !items.length) {
    return res.status(400).json({
      error: 'At least one item is required'
    });
  }

  const id = crypto.randomUUID();

  try {
    // Reserve inventory first
    const response = await fetch(`${inventoryUrl}/reservations`, {
      method: 'POST',
      headers: {
        'content-type': 'application/json'
      },
      body: JSON.stringify({
        orderId: id,
        items
      })
    });

    if (!response.ok) {
      return res
        .status(response.status)
        .json(await response.json());
    }

    // Store order in PostgreSQL
    const result = await pool.query(
      `
      INSERT INTO orders (id, status, items)
      VALUES ($1, $2, $3)
      RETURNING
        id,
        status,
        items,
        created_at AS "createdAt"
      `,
      [id, 'confirmed', JSON.stringify(items)]
    );

    return res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error('Failed to create order:', error);

    return res.status(503).json({
      error: 'Orders database is unavailable'
    });
  }
});

const port = Number(process.env.PORT || 3003);

async function start() {
  try {
    await initializeDatabase();

    app.listen(port, () => {
      console.log(`Orders service listening on port ${port}`);
    });
  } catch (error) {
    console.error('Failed to initialize Orders service:', error);
    process.exit(1);
  }
}

start();

