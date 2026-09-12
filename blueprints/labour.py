from flask import Blueprint, render_template, request, redirect, url_for
from database.db import get_db

labour_bp = Blueprint('labour', __name__)


@labour_bp.route('/labour', methods=['GET', 'POST'])
def labour_list():
    db = get_db()
    if request.method == 'POST':
        work_type = request.form.get('work_type', '').strip()
        labour_names = request.form.get('labour_names', '').strip()
        labour_count = int(request.form.get('labour_count', 1) or 1)
        rate = float(request.form.get('rate', 0) or 0)
        order_id = request.form.get('order_id') or None
        total_charge = round(rate * labour_count, 2)
        if work_type:
            db.execute("""INSERT INTO labour_entries
                (entry_date, work_type, labour_names, labour_count, rate, total_charge, order_id)
                VALUES (date('now'),?,?,?,?,?,?)""",
                (work_type, labour_names, labour_count, rate, total_charge, order_id))
            db.commit()
        return redirect(url_for('labour.labour_list'))

    entries = db.execute("SELECT * FROM labour_entries ORDER BY id DESC").fetchall()
    monthly = db.execute("""SELECT strftime('%Y-%m', entry_date) as month, SUM(total_charge) as total
                             FROM labour_entries GROUP BY month ORDER BY month DESC LIMIT 12""").fetchall()
    recent_sales = db.execute("SELECT id, description, customer FROM sales ORDER BY id DESC LIMIT 50").fetchall()
    return render_template('labour.html', entries=entries, monthly=monthly, recent_sales=recent_sales)


@labour_bp.route('/labour/<int:lid>/delete', methods=['POST'])
def delete_labour(lid):
    db = get_db()
    db.execute("DELETE FROM labour_entries WHERE id=?", (lid,))
    db.commit()
    return redirect(url_for('labour.labour_list'))
