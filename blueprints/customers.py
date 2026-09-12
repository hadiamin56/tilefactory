from flask import Blueprint, render_template, request, redirect, url_for
from database.db import get_db

customers_bp = Blueprint('customers', __name__)


def _balance(db, customer_id):
    total_due = db.execute("SELECT COALESCE(SUM(amount_due),0) FROM sales WHERE customer_id=?", (customer_id,)).fetchone()[0]
    total_paid = db.execute("SELECT COALESCE(SUM(amount),0) FROM payments WHERE customer_id=?", (customer_id,)).fetchone()[0]
    return round(total_due - total_paid, 2)


@customers_bp.route('/customers')
def customers_list():
    db = get_db()
    rows = db.execute("SELECT id, name, phone FROM customers ORDER BY name").fetchall()
    customers = [{'id': r['id'], 'name': r['name'], 'phone': r['phone'], 'balance': _balance(db, r['id'])} for r in rows]
    total_receivable = round(sum(c['balance'] for c in customers if c['balance'] > 0), 2)
    return render_template('customers.html', customers=customers, total_receivable=total_receivable)


@customers_bp.route('/customers/<int:cid>')
def customer_detail(cid):
    db = get_db()
    customer = db.execute("SELECT * FROM customers WHERE id=?", (cid,)).fetchone()
    if not customer:
        return "Customer not found", 404
    sales = db.execute("SELECT * FROM sales WHERE customer_id=? ORDER BY id DESC", (cid,)).fetchall()
    payments = db.execute("SELECT * FROM payments WHERE customer_id=? ORDER BY id DESC", (cid,)).fetchall()
    return render_template('customer_detail.html', customer=customer, sales=sales, payments=payments,
                            balance=_balance(db, cid))


@customers_bp.route('/customers/<int:cid>/payment', methods=['POST'])
def record_payment(cid):
    db = get_db()
    amount = round(float(request.form.get('amount', 0) or 0), 2)
    note = request.form.get('note', '')
    if amount > 0:
        db.execute("INSERT INTO payments (customer_id, amount, note, payment_date) VALUES (?,?,?,date('now'))",
                   (cid, amount, note))
        db.commit()
    return redirect(url_for('customers.customer_detail', cid=cid))
