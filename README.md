# TilePro — Concrete Tile Business Manager

A small Flask app for a concrete tile factory/shop: inventory, sales, and now
full money tracking — customer udhaar (credit), supplier bakaya (payables),
labour costs, loading/transport charges, and advance orders.

## Features

- Dashboard with live stats, receivables/payables, and low-stock alerts
- Feet×Feet and Interlock tile inventory (by size/shape/color)
- Sales with GST, discounts, invoices, and partial-payment (udhaar) tracking
- **Customer Ledger** — running balance per customer, record payments
- **Supplier Ledger** — raw material purchases, amount paid/bakaya per supplier
- **Labour Charges** — per-entry cost, optionally linked to an order, monthly summary
- **Loading / Transport Charges** — per-order transport cost
- **Advance Orders** — take an advance, auto-adjust it against the final bill on delivery
- Manage options (sizes, shapes, colors, prices, low-stock threshold)
- Reports (top sellers, monthly breakdown)

## Running locally

```bash
pip install -r requirements.txt
python app.py
```

Visit http://localhost:5000. A SQLite database is created automatically at
`instance/tilepro.db` on first run.

## Configuration (environment variables)

- `SECRET_KEY` — Flask session secret (defaults to a local dev value)
- `DATABASE_URL` — set this to a Postgres URL (e.g. from Neon or Supabase) to
  move off SQLite for hosting; if unset, the app keeps using the local
  SQLite file
- `PORT` — port to bind when running `python app.py` directly (Render/Railway
  set this automatically when using the Procfile/gunicorn)

## Deploying

The app ships with a `Procfile` (`gunicorn app:app`) and `render.yaml` for
one-click deploys on [Render](https://render.com) or
[Railway](https://railway.app). Both give a free tier that's plenty for a
single-shop tool (the free tier sleeps when idle — the first request after
a while will be slow to wake up).

1. Push this repo to GitHub.
2. Create a new Web Service on Render/Railway pointed at the repo.
3. Set `DATABASE_URL` if you're using a hosted Postgres DB (optional —
   SQLite works fine for low traffic, but isn't persisted across redeploys
   on most free hosting, so Postgres is recommended for production).
4. Deploy. `requirements.txt` and the `Procfile` are picked up automatically.

Back up the database regularly (export the SQLite file, or `pg_dump` for
Postgres) — there's no automated backup built in yet.

## Project layout

- `app.py` — core routes (dashboard, inventory, sales, manage, reports)
- `blueprints/` — the newer ledger modules (customers, suppliers, labour,
  loading charges, advance orders), each its own Flask blueprint
- `database/db.py` — SQLite connection + schema for the original
  inventory/sales tables (unchanged from the original app, plus a few
  added columns for the customer ledger)
- `database/models.py` — SQLAlchemy models for the newer ledger tables,
  making a future move to Postgres straightforward (just set `DATABASE_URL`)
- `templates/`, `static/` — Jinja2 templates and CSS/JS
