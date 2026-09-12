"""SQLAlchemy models for the ledger modules (customers, suppliers, labour,
loading charges, advance orders). Kept separate from the older raw-sqlite3
tables (feet/interlock inventory, sales, settings, ...) so this app can move
to a hosted Postgres database later just by setting DATABASE_URL, without
having to rewrite the inventory/sales code that already works.
"""
from datetime import date
from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()


class Customer(db.Model):
    __tablename__ = 'customers'
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(120), unique=True, nullable=False)
    phone = db.Column(db.String(30), default='')


class Payment(db.Model):
    __tablename__ = 'payments'
    id = db.Column(db.Integer, primary_key=True)
    customer_id = db.Column(db.Integer, db.ForeignKey('customers.id'), nullable=False)
    amount = db.Column(db.Float, nullable=False, default=0)
    note = db.Column(db.String(255), default='')
    payment_date = db.Column(db.String(10), default=lambda: date.today().isoformat())


class Supplier(db.Model):
    __tablename__ = 'suppliers'
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(120), unique=True, nullable=False)
    phone = db.Column(db.String(30), default='')


class Purchase(db.Model):
    __tablename__ = 'purchases'
    id = db.Column(db.Integer, primary_key=True)
    supplier_id = db.Column(db.Integer, db.ForeignKey('suppliers.id'), nullable=False)
    material = db.Column(db.String(120), nullable=False)
    qty = db.Column(db.Float, nullable=False, default=0)
    unit_cost = db.Column(db.Float, nullable=False, default=0)
    total = db.Column(db.Float, nullable=False, default=0)
    amount_paid = db.Column(db.Float, nullable=False, default=0)
    amount_bakaya = db.Column(db.Float, nullable=False, default=0)
    purchase_date = db.Column(db.String(10), default=lambda: date.today().isoformat())


class LabourEntry(db.Model):
    __tablename__ = 'labour_entries'
    id = db.Column(db.Integer, primary_key=True)
    entry_date = db.Column(db.String(10), default=lambda: date.today().isoformat())
    work_type = db.Column(db.String(80), nullable=False)
    labour_names = db.Column(db.String(255), default='')
    labour_count = db.Column(db.Integer, default=1)
    rate = db.Column(db.Float, nullable=False, default=0)
    total_charge = db.Column(db.Float, nullable=False, default=0)
    order_id = db.Column(db.Integer, nullable=True)  # optional link to sales.id


class LoadingCharge(db.Model):
    __tablename__ = 'loading_charges'
    id = db.Column(db.Integer, primary_key=True)
    order_id = db.Column(db.Integer, nullable=True)  # optional link to sales.id
    transport_details = db.Column(db.String(255), default='')
    charge_amount = db.Column(db.Float, nullable=False, default=0)
    charge_date = db.Column(db.String(10), default=lambda: date.today().isoformat())


class AdvanceOrder(db.Model):
    __tablename__ = 'advance_orders'
    id = db.Column(db.Integer, primary_key=True)
    customer_id = db.Column(db.Integer, db.ForeignKey('customers.id'), nullable=False)
    item_details = db.Column(db.String(255), nullable=False)
    advance_amount = db.Column(db.Float, nullable=False, default=0)
    status = db.Column(db.String(20), nullable=False, default='Pending')  # Pending / Delivered
    order_date = db.Column(db.String(10), default=lambda: date.today().isoformat())
    delivered_date = db.Column(db.String(10), nullable=True)
    sale_id = db.Column(db.Integer, nullable=True)  # set once converted to a sale on delivery
