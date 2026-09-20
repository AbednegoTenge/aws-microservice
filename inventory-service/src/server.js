const express = require('express');

const app = express();
app.use(express.json());
const stock = new Map([['p-100', 25], ['p-200', 10]]);
const reservations = new Map();

app.get('/health', (_req, res) => res.json({ status: 'ok', service: 'inventory' }));
app.get('/inventory/:productId', (req, res) => {
  const quantity = stock.get(req.params.productId);
  return quantity === undefined ? res.status(404).json({ error: 'Inventory item not found' }) : res.json({ productId: req.params.productId, quantity });
});
app.post('/reservations', (req, res) => {
  const { orderId, items } = req.body;
  if (!orderId || !Array.isArray(items) || !items.length) return res.status(400).json({ error: 'orderId and at least one item are required' });
  if (reservations.has(orderId)) return res.json(reservations.get(orderId)); // idempotent retry
  const unavailable = items.find(({ productId, quantity }) => !Number.isInteger(quantity) || quantity < 1 || (stock.get(productId) || 0) < quantity);
  if (unavailable) return res.status(409).json({ error: 'Insufficient stock', productId: unavailable.productId });
  items.forEach(({ productId, quantity }) => stock.set(productId, stock.get(productId) - quantity));
  const reservation = { orderId, status: 'reserved', items };
  reservations.set(orderId, reservation);
  return res.status(201).json(reservation);
});

app.listen(process.env.PORT || 3002, () => console.log('Inventory service listening'));
