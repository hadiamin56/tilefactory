from flask import Blueprint, render_template, request, redirect, url_for
from database.db import get_db

loading_bp = Blueprint('loading', __name__)


@loading_bp.route('/loading-charges', methods=['GET', 'POST'])
def loading_list():
    db = get_db()
    if request.method == 'POST':
        order_id = request.form.get('order_id') or None
        transport_details = request.form.get('transport_details', '').strip()
        charge_amount = round(float(request.form.get('charge_amount', 0) or 0), 2)
        if charge_amount > 0:
            db.execute("""INSERT INTO loading_charges (order_id, transport_details, charge_amount, charge_date)
                          VALUES (?,?,?,date('now'))""", (order_id, transport_details, charge_amount))
            db.commit()
        return redirect(url_for('loading.loading_list'))

    charges = db.execute("""SELECT lc.*, s.description as order_desc, s.customer as order_customer
                             FROM loading_charges lc
                             LEFT JOIN sales s ON s.id = lc.order_id
                             ORDER BY lc.id DESC""").fetchall()
    month_total = db.execute("""SELECT COALESCE(SUM(charge_amount),0) FROM loading_charges
                                 WHERE strftime('%Y-%m', charge_date) = strftime('%Y-%m', 'now')""").fetchone()[0]
    recent_sales = db.execute("SELECT id, description, customer FROM sales ORDER BY id DESC LIMIT 50").fetchall()
    return render_template('loading_charges.html', charges=charges, month_total=month_total, recent_sales=recent_sales)


@loading_bp.route('/loading-charges/<int:lid>/delete', methods=['POST'])
def delete_loading(lid):
    db = get_db()
    db.execute("DELETE FROM loading_charges WHERE id=?", (lid,))
    db.commit()
    return redirect(url_for('loading.loading_list'))
