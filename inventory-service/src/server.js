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
    CREATE TABLE IF NOT EXISTS inventory (
      product_id VARCHAR(100) PRIMARY KEY,
      quantity INTEGER NOT NULL CHECK (quantity >= 0)
    )
  `);

  await pool.query(`
    CREATE TABLE IF NOT EXISTS reservations (
      order_id UUID PRIMARY KEY,
      status VARCHAR(50) NOT NULL,
      items JSONB NOT NULL,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    )
  `);

  const result = await pool.query(
    'SELECT COUNT(*)::int AS count FROM inventory'
  );

  if (result.rows[0].count === 0) {
    await pool.query(
      `
      INSERT INTO inventory (product_id, quantity)
      VALUES
        ($1, $2),
        ($3, $4)
      `,
      ['p-100', 25, 'p-200', 10]
    );
  }
}

app.get('/inventory/health', async (_req, res) => {
  try {
    await pool.query('SELECT 1');

    return res.json({
      status: 'ok',
      service: 'inventory',
    });
  } catch (_error) {
    return res.status(503).json({
      status: 'error',
      service: 'inventory',
    });
  }
});

app.get('/inventory/:productId', async (req, res) => {
  try {
    const result = await pool.query(
      `
      SELECT product_id, quantity
      FROM inventory
      WHERE product_id = $1
      `,
      [req.params.productId]
    );

    if (!result.rows.length) {
      return res.status(404).json({
        error: 'Inventory item not found',
      });
    }

    return res.json({
      productId: result.rows[0].product_id,
      quantity: result.rows[0].quantity,
    });
  } catch (_error) {
    return res.status(500).json({
      error: 'Failed to fetch inventory',
    });
  }
});

app.post('/reservations', async (req, res) => {
  const { orderId, items } = req.body;

  if (!orderId || !Array.isArray(items) || !items.length) {
    return res.status(400).json({
      error: 'orderId and at least one item are required',
    });
  }

  for (const item of items) {
    if (
      !item ||
      !item.productId ||
      !Number.isInteger(item.quantity) ||
      item.quantity < 1
    ) {
      return res.status(400).json({
        error: 'Each item requires productId and a positive integer quantity',
      });
    }
  }

  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    // Idempotent retry:
    // If this order was already reserved, return the existing reservation.
    const existingReservation = await client.query(
      `
      SELECT order_id, status, items
      FROM reservations
      WHERE order_id = $1
      `,
      [orderId]
    );

    if (existingReservation.rows.length) {
      await client.query('COMMIT');

      return res.json({
        orderId: existingReservation.rows[0].order_id,
        status: existingReservation.rows[0].status,
        items: existingReservation.rows[0].items,
      });
    }

    // Lock the relevant inventory rows while checking stock.
    for (const item of items) {
      const result = await client.query(
        `
        SELECT product_id, quantity
        FROM inventory
        WHERE product_id = $1
        FOR UPDATE
        `,
        [item.productId]
      );

      if (!result.rows.length) {
        await client.query('ROLLBACK');

        return res.status(409).json({
          error: 'Insufficient stock',
          productId: item.productId,
        });
      }

      if (result.rows[0].quantity < item.quantity) {
        await client.query('ROLLBACK');

        return res.status(409).json({
          error: 'Insufficient stock',
          productId: item.productId,
        });
      }
    }

    // Decrement stock.
    for (const item of items) {
      await client.query(
        `
        UPDATE inventory
        SET quantity = quantity - $1
        WHERE product_id = $2
        `,
        [item.quantity, item.productId]
      );
    }

    const reservation = {
      orderId,
      status: 'reserved',
      items,
    };

    await client.query(
      `
      INSERT INTO reservations (order_id, status, items)
      VALUES ($1, $2, $3)
      `,
      [orderId, 'reserved', JSON.stringify(items)]
    );

    await client.query('COMMIT');

    return res.status(201).json(reservation);
  } catch (error) {
    await client.query('ROLLBACK');

    // Handles a race where another request created the same reservation.
    if (error.code === '23505') {
      const existingReservation = await pool.query(
        `
        SELECT order_id, status, items
        FROM reservations
        WHERE order_id = $1
        `,
        [orderId]
      );

      if (existingReservation.rows.length) {
        return res.json({
          orderId: existingReservation.rows[0].order_id,
          status: existingReservation.rows[0].status,
          items: existingReservation.rows[0].items,
        });
      }
    }

    console.error('Reservation failed', error);

    return res.status(500).json({
      error: 'Failed to create reservation',
    });
  } finally {
    client.release();
  }
});

async function start() {
  try {
    await initializeDatabase();

    const port = process.env.PORT || 3002;

    app.listen(port, () => {
      console.log(`Inventory service listening on port ${port}`);
    });
  } catch (error) {
    console.error('Failed to initialize database', error);
    process.exit(1);
  }
}

start();