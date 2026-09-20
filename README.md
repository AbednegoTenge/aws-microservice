# Store microservices starter

A small, runnable microservices example with three independently deployable Node.js services:

| Service | Port | Responsibility |
| --- | --- | --- |
| Products | 3001 | Product catalogue and prices |
| Inventory | 3002 | Stock levels and reservations |
| Orders | 3003 | Order lifecycle and orchestration |

The Orders service asks Inventory to reserve stock before it records an order. Products remains the source of truth for catalogue data. Each service intentionally keeps its own in-memory data store so the ownership boundary is visible; replace these with separate databases in production.

## Run it

```bash
docker compose up --build
```

Create an order:

```bash
curl -X POST http://localhost:3003/orders \
  -H 'content-type: application/json' \
  -d '{"items":[{"productId":"p-100","quantity":2}]}'
```

Useful endpoints:

```bash
curl http://localhost:3001/products
curl http://localhost:3002/inventory/p-100
curl http://localhost:3003/orders
```

## Project layout

```
products-service/   catalogue API
inventory-service/  stock and reservations API
orders-service/     order API and workflow
docker-compose.yml  local service wiring
```

All services expose `GET /health` for container health checks.
