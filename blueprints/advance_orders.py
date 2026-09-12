from flask import Blueprint, render_template, request, redirect, url_for
from database.db import get_db, get_or_create_customer, next_invoice_no

advance_bp = Blueprint('advance_orders', __name__)


@advance_bp.route('/advance-orders', methods=['GET', 'POST'])
def advance_list():
    db = get_db()
    if request.method == 'POST':
        customer = request.form.get('customer', '').strip()
        phone = request.form.get('phone', '').strip()
        item_details = request.form.get('item_details', '').strip()
        advance_amount = round(float(request.form.get('advance_amount', 0) or 0), 2)
        if customer and item_details:
            customer_id = get_or_create_customer(db, customer, phone)
            db.execute("""INSERT INTO advance_orders
                (customer_id, item_details, advance_amount, status, order_date)
                VALUES (?,?,?, 'Pending', date('now'))""", (customer_id, item_details, advance_amount))
            db.commit()
        return redirect(url_for('advance_orders.advance_list'))

    orders = db.execute("""SELECT a.*, c.name as customer_name, c.phone as customer_phone
                            FROM advance_orders a JOIN customers c ON c.id = a.customer_id
                            ORDER BY a.status ASC, a.id DESC""").fetchall()
    pending_count = db.execute("SELECT COUNT(*) FROM advance_orders WHERE status='Pending'").fetchone()[0]
    return render_template('advance_orders.html', orders=orders, pending_count=pending_count)


@advance_bp.route('/advance-orders/<int:aid>/deliver', methods=['GET', 'POST'])
def deliver_order(aid):
    db = get_db()
    order = db.execute("""SELECT a.*, c.name as customer_name, c.phone as customer_phone
                           FROM advance_orders a JOIN customers c ON c.id = a.customer_id
                           WHERE a.id=?""", (aid,)).fetchone()
    if not order:
        return "Advance order not found", 404

    if request.method == 'POST':
        final_total = round(float(request.form.get('final_total', 0) or 0), 2)
        extra_paid = round(float(request.form.get('extra_paid', 0) or 0), 2)
        amount_paid = min(order['advance_amount'] + extra_paid, final_total)
        amount_paid = max(0, amount_paid)
        amount_due = round(final_total - amount_paid, 2)
        invoice_no = next_invoice_no(db)

        cur = db.execute("""INSERT INTO sales
            (cat, description, size, shape, color, quantity, price_per_unit, subtotal,
             loading_charge, discount_type, discount_value, discount_amount, grand_total,
             customer, phone, address, gst, gst_amount, invoice_no, note, sale_date,
             customer_id, amount_paid, amount_due)
            VALUES ('advance', ?, '', '', '', 1, ?, ?, 0, '', 0, 0, ?, ?, ?, '', '', 0, ?, ?, date('now'), ?, ?, ?)""",
            (order['item_details'], final_total, final_total, final_total,
             order['customer_name'], order['customer_phone'], invoice_no,
             f"Advance order #{aid}, advance ₹{order['advance_amount']:.2f} adjusted",
             order['customer_id'], round(amount_paid, 2), amount_due))
        sale_id = cur.lastrowid

        db.execute("""UPDATE advance_orders SET status='Delivered', delivered_date=date('now'), sale_id=?
                      WHERE id=?""", (sale_id, aid))
        db.commit()
        return redirect(url_for('invoice', sale_id=sale_id))

    return render_template('advance_order_deliver.html', order=order)
