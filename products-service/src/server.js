const express = require('express');
const { Pool } = require('pg');

const app = express();
app.use(express.json());

const pool = new Pool({
  host: process.env.DB_HOST,
  port: Number(process.env.DB_PORT || 5432),
  database: process.env.DB_NAME,
  user: process.env.DB_USERNAME,
  password: process.env.DB_PASSWORD,
});

async function initializeDatabase() {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS products (
      id VARCHAR(100) PRIMARY KEY,
      name VARCHAR(255) NOT NULL,
      price NUMERIC(10, 2) NOT NULL CHECK (price >= 0)
    )
  `);

  const result = await pool.query('SELECT COUNT(*)::int AS count FROM products');

  if (result.rows[0].count === 0) {
    await pool.query(
      `
      INSERT INTO products (id, name, price)
      VALUES
        ($1, $2, $3),
        ($4, $5, $6)
      `,
      [
        'p-100',
        'Wireless Mouse',
        29.99,
        'p-200',
        'Mechanical Keyboard',
        89.99,
      ]
    );
  }
}

app.get('/products/health', async (_req, res) => {
  try {
    await pool.query('SELECT 1');

    return res.json({
      status: 'ok',
      service: 'products',
    });
  } catch (_error) {
    return res.status(503).json({
      status: 'error',
      service: 'products',
    });
  }
});

app.get('/products', async (_req, res) => {
  try {
    const result = await pool.query(`
      SELECT id, name, price
      FROM products
      ORDER BY id
    `);

    return res.json(
      result.rows.map((product) => ({
        ...product,
        price: Number(product.price),
      }))
    );
  } catch (_error) {
    return res.status(500).json({
      error: 'Failed to fetch products',
    });
  }
});

app.get('/products/:id', async (req, res) => {
  try {
    const result = await pool.query(
      `
      SELECT id, name, price
      FROM products
      WHERE id = $1
      `,
      [req.params.id]
    );

    if (!result.rows.length) {
      return res.status(404).json({
        error: 'Product not found',
      });
    }

    const product = result.rows[0];

    return res.json({
      ...product,
      price: Number(product.price),
    });
  } catch (_error) {
    return res.status(500).json({
      error: 'Failed to fetch product',
    });
  }
});

app.post('/products', async (req, res) => {
  const { id, name, price } = req.body;

  if (!id || !name || typeof price !== 'number') {
    return res.status(400).json({
      error: 'id, name, and numeric price are required',
    });
  }

  if (price < 0) {
    return res.status(400).json({
      error: 'price must be greater than or equal to 0',
    });
  }

  try {
    const result = await pool.query(
      `
      INSERT INTO products (id, name, price)
      VALUES ($1, $2, $3)
      RETURNING id, name, price
      `,
      [id, name, price]
    );

    const product = result.rows[0];

    return res.status(201).json({
      ...product,
      price: Number(product.price),
    });
  } catch (error) {
    if (error.code === '23505') {
      return res.status(409).json({
        error: 'Product already exists',
      });
    }

    return res.status(500).json({
      error: 'Failed to create product',
    });
  }
});

async function start() {
  try {
    await initializeDatabase();

    const port = process.env.PORT || 3001;

    app.listen(port, () => {
      console.log(`Products service listening on port ${port}`);
    });
  } catch (error) {
    console.error('Failed to initialize database', error);
    process.exit(1);
  }
}

start();