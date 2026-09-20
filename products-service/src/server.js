const express = require('express');

const app = express();
app.use(express.json());

const products = new Map([
  ['p-100', { id: 'p-100', name: 'Wireless Mouse', price: 29.99 }],
  ['p-200', { id: 'p-200', name: 'Mechanical Keyboard', price: 89.99 }]
]);

app.get('/health', (_req, res) => res.json({ status: 'ok', service: 'products' }));
app.get('/products', (_req, res) => res.json([...products.values()]));
app.get('/products/:id', (req, res) => {
  const product = products.get(req.params.id);
  return product ? res.json(product) : res.status(404).json({ error: 'Product not found' });
});
app.post('/products', (req, res) => {
  const { id, name, price } = req.body;
  if (!id || !name || typeof price !== 'number') return res.status(400).json({ error: 'id, name, and numeric price are required' });
  if (products.has(id)) return res.status(409).json({ error: 'Product already exists' });
  const product = { id, name, price };
  products.set(id, product);
  return res.status(201).json(product);
});

app.listen(process.env.PORT || 3001, () => console.log('Products service listening'));
