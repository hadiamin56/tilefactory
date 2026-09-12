from flask import Blueprint, render_template, request, redirect, url_for
from database.db import get_db

suppliers_bp = Blueprint('suppliers', __name__)


def _supplier_summary(db, supplier_id):
    row = db.execute("""SELECT COALESCE(SUM(total),0) as purchased,
                                COALESCE(SUM(amount_paid),0) as paid,
                                COALESCE(SUM(amount_bakaya),0) as bakaya
                         FROM purchases WHERE supplier_id=?""", (supplier_id,)).fetchone()
    return dict(row)


@suppliers_bp.route('/suppliers', methods=['GET', 'POST'])
def suppliers_list():
    db = get_db()
    if request.method == 'POST':
        name = request.form.get('name', '').strip()
        phone = request.form.get('phone', '').strip()
        if name:
            db.execute("INSERT OR IGNORE INTO suppliers (name, phone) VALUES (?,?)", (name, phone))
            db.commit()
        return redirect(url_for('suppliers.suppliers_list'))

    rows = db.execute("SELECT id, name, phone FROM suppliers ORDER BY name").fetchall()
    suppliers = []
    total_payable = 0
    for r in rows:
        summary = _supplier_summary(db, r['id'])
        suppliers.append({'id': r['id'], 'name': r['name'], 'phone': r['phone'], **summary})
        total_payable += summary['bakaya']
    return render_template('suppliers.html', suppliers=suppliers, total_payable=round(total_payable, 2))


@suppliers_bp.route('/suppliers/<int:sid>', methods=['GET', 'POST'])
def supplier_detail(sid):
    db = get_db()
    supplier = db.execute("SELECT * FROM suppliers WHERE id=?", (sid,)).fetchone()
    if not supplier:
        return "Supplier not found", 404

    if request.method == 'POST':
        action = request.form.get('action')
        if action == 'add_purchase':
            material = request.form.get('material', '').strip()
            qty = float(request.form.get('qty', 0) or 0)
            unit_cost = float(request.form.get('unit_cost', 0) or 0)
            total = round(qty * unit_cost, 2)
            amount_paid_raw = request.form.get('amount_paid', '').strip()
            amount_paid = round(float(amount_paid_raw), 2) if amount_paid_raw else 0
            amount_paid = max(0, min(amount_paid, total))
            amount_bakaya = round(total - amount_paid, 2)
            if material and qty > 0:
                db.execute("""INSERT INTO purchases
                    (supplier_id, material, qty, unit_cost, total, amount_paid, amount_bakaya, purchase_date)
                    VALUES (?,?,?,?,?,?,?,date('now'))""",
                    (sid, material, qty, unit_cost, total, amount_paid, amount_bakaya))
                db.commit()
        elif action == 'pay_purchase':
            purchase_id = request.form.get('purchase_id')
            pay_amount = round(float(request.form.get('pay_amount', 0) or 0), 2)
            purchase = db.execute("SELECT * FROM purchases WHERE id=? AND supplier_id=?", (purchase_id, sid)).fetchone()
            if purchase and pay_amount > 0:
                new_paid = min(purchase['amount_paid'] + pay_amount, purchase['total'])
                new_bakaya = round(purchase['total'] - new_paid, 2)
                db.execute("UPDATE purchases SET amount_paid=?, amount_bakaya=? WHERE id=?",
                           (round(new_paid, 2), new_bakaya, purchase_id))
                db.commit()
        return redirect(url_for('suppliers.supplier_detail', sid=sid))

    purchases = db.execute("SELECT * FROM purchases WHERE supplier_id=? ORDER BY id DESC", (sid,)).fetchall()
    return render_template('supplier_detail.html', supplier=supplier, purchases=purchases,
                            summary=_supplier_summary(db, sid))
