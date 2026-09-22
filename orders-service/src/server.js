const express = require('express');
const crypto = require('crypto');

const app = express();
app.use(express.json());
const orders = new Map();
const inventoryUrl = process.env.INVENTORY_URL || 'http://localhost:3002';

app.get('/orders/health', (_req, res) => res.json({ status: 'ok', service: 'orders' }));
app.get('/orders', (_req, res) => res.json([...orders.values()]));
app.get('/orders/:id', (req, res) => {
  const order = orders.get(req.params.id);
  return order ? res.json(order) : res.status(404).json({ error: 'Order not found' });
});
app.post('/orders', async (req, res) => {
  const { items } = req.body;
  if (!Array.isArray(items) || !items.length) return res.status(400).json({ error: 'At least one item is required' });
  const id = crypto.randomUUID();
  try {
    const response = await fetch(`${inventoryUrl}/reservations`, {
      method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify({ orderId: id, items })
    });
    if (!response.ok) return res.status(response.status).json(await response.json());
    const order = { id, status: 'confirmed', items, createdAt: new Date().toISOString() };
    orders.set(id, order);
    return res.status(201).json(order);
  } catch (_error) {
    return res.status(503).json({ error: 'Inventory service is unavailable' });
  }
});

app.listen(process.env.PORT || 3003, () => console.log('Orders service listening'));
