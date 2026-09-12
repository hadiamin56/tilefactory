from flask import Flask, render_template, request, jsonify, redirect, url_for, g
from database.db import init_db, get_db, DATABASE_URL, get_threshold, get_setting, next_invoice_no, get_or_create_customer
from database.models import db as db_orm
import os

app = Flask(__name__)
app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY', 'tilepro-local-secret')
app.config['SQLALCHEMY_DATABASE_URI'] = DATABASE_URL
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

with app.app_context():
    init_db()

db_orm.init_app(app)
with app.app_context():
    db_orm.create_all()

from blueprints.customers import customers_bp
from blueprints.suppliers import suppliers_bp
from blueprints.labour import labour_bp
from blueprints.loading import loading_bp
from blueprints.advance_orders import advance_bp

app.register_blueprint(customers_bp)
app.register_blueprint(suppliers_bp)
app.register_blueprint(labour_bp)
app.register_blueprint(loading_bp)
app.register_blueprint(advance_bp)

@app.teardown_appcontext
def close_db(error=None):
    db = g.pop('db', None)
    if db is not None:
        db.close()

# ─────────────────────────────────────────
#  DASHBOARD
# ─────────────────────────────────────────

@app.route('/')
def dashboard():
    db = get_db()
    feet_skus       = db.execute("SELECT COUNT(*) FROM feet_inventory").fetchone()[0]
    interlock_skus  = db.execute("SELECT COUNT(*) FROM interlock_inventory").fetchone()[0]
    feet_stock      = db.execute("SELECT COALESCE(SUM(stock),0) FROM feet_inventory").fetchone()[0]
    interlock_stock = db.execute("SELECT COALESCE(SUM(stock),0) FROM interlock_inventory").fetchone()[0]
    from datetime import date
    today         = date.today().isoformat()
    today_sales   = db.execute("SELECT COALESCE(SUM(quantity),0) FROM sales WHERE sale_date=?", (today,)).fetchone()[0]
    total_sales   = db.execute("SELECT COALESCE(SUM(quantity),0) FROM sales").fetchone()[0]
    today_revenue = db.execute("SELECT COALESCE(SUM(grand_total),0) FROM sales WHERE sale_date=?", (today,)).fetchone()[0]
    total_revenue = db.execute("SELECT COALESCE(SUM(grand_total),0) FROM sales").fetchone()[0]
    threshold     = get_threshold(db)
    low_feet      = db.execute("SELECT size, color FROM feet_inventory WHERE stock < ?", (threshold,)).fetchall()
    low_interlock = db.execute("SELECT size, shape, color FROM interlock_inventory WHERE stock < ?", (threshold,)).fetchall()
    low_count     = len(low_feet) + len(low_interlock)
    recent_sales  = db.execute("SELECT * FROM sales ORDER BY id DESC LIMIT 8").fetchall()
    low_items  = [{'cat':'Feet×Feet', 'desc':f"{r['size']} / {r['color']}", 'stock': db.execute("SELECT stock FROM feet_inventory WHERE size=? AND color=?",(r['size'],r['color'])).fetchone()[0]} for r in low_feet]
    low_items += [{'cat':'Interlock',  'desc':f"{r['size']} {r['shape']} / {r['color']}", 'stock': db.execute("SELECT stock FROM interlock_inventory WHERE size=? AND shape=? AND color=?",(r['size'],r['shape'],r['color'])).fetchone()[0]} for r in low_interlock]

    total_due_sales   = db.execute("SELECT COALESCE(SUM(amount_due),0) FROM sales").fetchone()[0]
    total_payments    = db.execute("SELECT COALESCE(SUM(amount),0) FROM payments").fetchone()[0]
    total_receivable  = round(total_due_sales - total_payments, 2)
    total_payable     = db.execute("SELECT COALESCE(SUM(amount_bakaya),0) FROM purchases").fetchone()[0]
    month_labour      = db.execute("""SELECT COALESCE(SUM(total_charge),0) FROM labour_entries
                                       WHERE strftime('%Y-%m', entry_date) = strftime('%Y-%m', 'now')""").fetchone()[0]
    month_loading     = db.execute("""SELECT COALESCE(SUM(charge_amount),0) FROM loading_charges
                                       WHERE strftime('%Y-%m', charge_date) = strftime('%Y-%m', 'now')""").fetchone()[0]
    pending_advances  = db.execute("SELECT COUNT(*) FROM advance_orders WHERE status='Pending'").fetchone()[0]

    return render_template('dashboard.html',
        feet_skus=feet_skus, interlock_skus=interlock_skus,
        feet_stock=feet_stock, interlock_stock=interlock_stock,
        today_sales=today_sales, total_sales=total_sales,
        today_revenue=today_revenue, total_revenue=total_revenue,
        total_receivable=total_receivable, total_payable=total_payable,
        month_labour_loading=round(month_labour + month_loading, 2),
        pending_advances=pending_advances,
        low_count=low_count, recent_sales=recent_sales,
        low_items=low_items, threshold=threshold
    )


# ─────────────────────────────────────────
#  INVENTORY
# ─────────────────────────────────────────

@app.route('/inventory')
def inventory():
    db = get_db()
    threshold   = get_threshold(db)
    feet        = db.execute("SELECT * FROM feet_inventory ORDER BY size, color").fetchall()
    interlock   = db.execute("SELECT * FROM interlock_inventory ORDER BY size, shape, color").fetchall()
    colors_feet = {r['name']: r['hex'] for r in db.execute("SELECT name, hex FROM feet_colors").fetchall()}
    colors_il   = {r['name']: r['hex'] for r in db.execute("SELECT name, hex FROM interlock_colors").fetchall()}
    return render_template('inventory.html',
        feet=feet, interlock=interlock,
        colors_feet=colors_feet, colors_il=colors_il,
        threshold=threshold
    )


@app.route('/add-inventory', methods=['GET', 'POST'])
def add_inventory():
    db = get_db()
    if request.method == 'POST':
        cat      = request.form.get('cat')
        qty      = int(request.form.get('qty', 0))
        note     = request.form.get('note', '')
        added_by = request.form.get('added_by', '')
        from datetime import date as _date
        raw_date  = request.form.get('log_date', '').strip()
        log_date  = raw_date if raw_date else _date.today().isoformat()

        if cat == 'feet':
            size  = request.form.get('size')
            color = request.form.get('color')
            db.execute("INSERT INTO inventory_log (cat,size,shape,color,quantity,note,added_by,log_date) VALUES (?,?,?,?,?,?,?,?)",
                       ('feet', size, '', color, qty, note, added_by, log_date))
            existing = db.execute("SELECT id FROM feet_inventory WHERE size=? AND color=?", (size, color)).fetchone()
            if existing:
                db.execute("UPDATE feet_inventory SET stock=stock+?, updated=? WHERE size=? AND color=?", (qty, log_date, size, color))
            else:
                db.execute("INSERT INTO feet_inventory (size,color,stock,updated) VALUES (?,?,?,?)", (size, color, qty, log_date))
        else:
            size  = request.form.get('size')
            shape = request.form.get('shape')
            color = request.form.get('color')
            db.execute("INSERT INTO inventory_log (cat,size,shape,color,quantity,note,added_by,log_date) VALUES (?,?,?,?,?,?,?,?)",
                       ('interlock', size, shape, color, qty, note, added_by, log_date))
            existing = db.execute("SELECT id FROM interlock_inventory WHERE size=? AND shape=? AND color=?", (size, shape, color)).fetchone()
            if existing:
                db.execute("UPDATE interlock_inventory SET stock=stock+?, updated=? WHERE size=? AND shape=? AND color=?", (qty, log_date, size, shape, color))
            else:
                db.execute("INSERT INTO interlock_inventory (size,shape,color,stock,updated) VALUES (?,?,?,?,?)", (size, shape, color, qty, log_date))
        db.commit()
        return redirect(url_for('add_inventory') + '?success=1')

    feet_sizes  = [r['name'] for r in db.execute("SELECT name FROM feet_sizes ORDER BY name").fetchall()]
    feet_colors = db.execute("SELECT name, hex FROM feet_colors ORDER BY name").fetchall()
    il_sizes    = [r['name'] for r in db.execute("SELECT name FROM interlock_sizes ORDER BY name").fetchall()]
    il_shapes   = [r['name'] for r in db.execute("SELECT name FROM interlock_shapes ORDER BY name").fetchall()]
    il_colors   = db.execute("SELECT name, hex FROM interlock_colors ORDER BY name").fetchall()
    feet_inv    = db.execute("SELECT size, color, stock FROM feet_inventory ORDER BY size, color").fetchall()
    il_inv      = db.execute("SELECT size, shape, color, stock FROM interlock_inventory ORDER BY size, shape, color").fetchall()
    from datetime import date as _date
    return render_template('add_inventory.html',
        feet_sizes=feet_sizes, feet_colors=feet_colors,
        il_sizes=il_sizes, il_shapes=il_shapes, il_colors=il_colors,
        feet_inv=feet_inv, il_inv=il_inv,
        today=_date.today().isoformat(),
        success=request.args.get('success')
    )


@app.route('/inventory-log')
def inventory_log():
    db = get_db()
    cat  = request.args.get('cat', '')
    date = request.args.get('date', '')
    query = "SELECT * FROM inventory_log WHERE 1=1"
    params = []
    if cat:  query += " AND cat=?";      params.append(cat)
    if date: query += " AND log_date=?"; params.append(date)
    query += " ORDER BY id DESC"
    records = db.execute(query, params).fetchall()
    daily   = db.execute("SELECT log_date, cat, SUM(quantity) as total FROM inventory_log GROUP BY log_date, cat ORDER BY log_date DESC LIMIT 30").fetchall()
    return render_template('inventory_log.html', records=records, daily=daily, cat=cat, date=date)


# ─────────────────────────────────────────
#  SALES
# ─────────────────────────────────────────

@app.route('/sales', methods=['GET', 'POST'])
def sales():
    db = get_db()
    if request.method == 'POST':
        cat            = request.form.get('cat')
        qty            = int(request.form.get('qty', 0))
        price_per_unit = float(request.form.get('price_per_unit', 0) or 0)
        use_loading    = request.form.get('use_loading') == 'on'
        loading_rate   = float(get_setting(db, 'loading_charge') or 0)
        loading_total  = round(loading_rate * qty, 2) if use_loading else 0
        subtotal       = round(price_per_unit * qty, 2)
        discount_type  = request.form.get('discount_type', '')
        discount_value = float(request.form.get('discount_value', 0) or 0)
        if discount_type == 'percent':
            discount_amount = round(subtotal * discount_value / 100, 2)
        elif discount_type == 'amount':
            discount_amount = min(round(discount_value, 2), subtotal)
        else:
            discount_amount = 0
        gst         = request.form.get('gst', '').strip()
        gst_amount  = round((subtotal - discount_amount + loading_total) * 0.18, 2) if gst else 0
        grand_total = round(subtotal - discount_amount + loading_total + gst_amount, 2)
        customer = request.form.get('customer', '')
        phone    = request.form.get('phone', '')
        address  = request.form.get('address', '')
        note     = request.form.get('note', '')
        customer_id = get_or_create_customer(db, customer, phone)
        # amount_paid defaults to the full grand total (cash sale) unless the
        # cashier records a partial payment, leaving the rest as udhaar (due)
        amount_paid_raw = request.form.get('amount_paid', '').strip()
        amount_paid = round(float(amount_paid_raw), 2) if amount_paid_raw else grand_total
        amount_paid = max(0, min(amount_paid, grand_total))
        amount_due  = round(grand_total - amount_paid, 2)
        # Generate invoice number
        prefix  = get_setting(db, 'invoice_prefix') or 'INV'
        counter = int(get_setting(db, 'invoice_counter') or 1)
        invoice_no = f"{prefix}{counter}"
        db.execute("UPDATE settings SET value=? WHERE key='invoice_counter'", (str(counter + 1),))

        if cat == 'feet':
            size  = request.form.get('size')
            color = request.form.get('color')
            row   = db.execute("SELECT stock FROM feet_inventory WHERE size=? AND color=?", (size, color)).fetchone()
            if not row or row['stock'] < qty:
                return redirect(url_for('sales') + '?error=stock')
            db.execute("UPDATE feet_inventory SET stock=stock-?, updated=date('now') WHERE size=? AND color=?", (qty, size, color))
            desc = f"{size} / {color}"
            db.execute("""INSERT INTO sales
                (cat,description,size,shape,color,quantity,price_per_unit,subtotal,
                 loading_charge,discount_type,discount_value,discount_amount,grand_total,
                 customer,phone,address,gst,gst_amount,invoice_no,note,sale_date,
                 customer_id,amount_paid,amount_due)
                VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,date('now'),?,?,?)""",
                ('feet',desc,size,'',color,qty,price_per_unit,subtotal,
                 loading_total,discount_type,discount_value,discount_amount,grand_total,
                 customer,phone,address,gst,gst_amount,invoice_no,note,
                 customer_id,amount_paid,amount_due))
        else:
            size  = request.form.get('size')
            shape = request.form.get('shape')
            color = request.form.get('color')
            row   = db.execute("SELECT stock FROM interlock_inventory WHERE size=? AND shape=? AND color=?", (size, shape, color)).fetchone()
            if not row or row['stock'] < qty:
                return redirect(url_for('sales') + '?error=stock')
            db.execute("UPDATE interlock_inventory SET stock=stock-?, updated=date('now') WHERE size=? AND shape=? AND color=?", (qty, size, shape, color))
            desc = f"{size} {shape} / {color}"
            db.execute("""INSERT INTO sales
                (cat,description,size,shape,color,quantity,price_per_unit,subtotal,
                 loading_charge,discount_type,discount_value,discount_amount,grand_total,
                 customer,phone,address,gst,gst_amount,invoice_no,note,sale_date,
                 customer_id,amount_paid,amount_due)
                VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,date('now'),?,?,?)""",
                ('interlock',desc,size,shape,color,qty,price_per_unit,subtotal,
                 loading_total,discount_type,discount_value,discount_amount,grand_total,
                 customer,phone,address,gst,gst_amount,invoice_no,note,
                 customer_id,amount_paid,amount_due))
        db.commit()
        sale_id = db.execute('SELECT last_insert_rowid()').fetchone()[0]
        return redirect(url_for('invoice', sale_id=sale_id))

    feet_sizes     = [r['name'] for r in db.execute("SELECT name FROM feet_sizes ORDER BY name").fetchall()]
    feet_colors    = db.execute("SELECT name, hex FROM feet_colors ORDER BY name").fetchall()
    il_sizes       = [r['name'] for r in db.execute("SELECT name FROM interlock_sizes ORDER BY name").fetchall()]
    il_shapes      = [r['name'] for r in db.execute("SELECT name FROM interlock_shapes ORDER BY name").fetchall()]
    il_colors      = db.execute("SELECT name, hex FROM interlock_colors ORDER BY name").fetchall()
    loading_charge = get_setting(db, 'loading_charge') or '0'

    # Price lookup: feet -> cat|size, interlock -> cat|size|shape
    prices = {}
    for r in db.execute("SELECT cat, size, shape, price FROM price_list").fetchall():
        key = f"{r['cat']}|{r['size']}|{r['shape']}"
        prices[key] = r['price']

    return render_template('sales.html',
        feet_sizes=feet_sizes, feet_colors=feet_colors,
        il_sizes=il_sizes, il_shapes=il_shapes, il_colors=il_colors,
        loading_charge=loading_charge,
        prices=prices,
        success=request.args.get('success'),
        error=request.args.get('error')
    )


@app.route('/sales-history')
def sales_history():
    db = get_db()
    cat  = request.args.get('cat', '')
    date = request.args.get('date', '')
    gst_filter = request.args.get('gst_filter', '')
    query = "SELECT * FROM sales WHERE 1=1"
    params = []
    if cat:        query += " AND cat=?";              params.append(cat)
    if date:       query += " AND sale_date=?";        params.append(date)
    if gst_filter == 'yes': query += " AND gst != '' AND gst IS NOT NULL AND gst != 'None'"
    if gst_filter == 'no':  query += " AND (gst = '' OR gst IS NULL OR gst = 'None')"
    query += " ORDER BY id DESC"
    records       = db.execute(query, params).fetchall()
    total_revenue = sum(r['grand_total'] for r in records)
    return render_template('sales_history.html', records=records, cat=cat, date=date,
                           gst_filter=gst_filter, total_revenue=total_revenue)


# ─────────────────────────────────────────
#  MANAGE
# ─────────────────────────────────────────


@app.route('/invoice/<int:sale_id>')
def invoice(sale_id):
    db = get_db()
    sale = db.execute("SELECT * FROM sales WHERE id=?", (sale_id,)).fetchone()
    if not sale:
        return "Invoice not found", 404
    biz = {
        'name':    get_setting(db, 'biz_name')    or 'Your Business Name',
        'address': get_setting(db, 'biz_address') or '',
        'phone':   get_setting(db, 'biz_phone')   or '',
        'email':   get_setting(db, 'biz_email')   or '',
        'gstin':   get_setting(db, 'biz_gstin')   or '',
        'state':   get_setting(db, 'biz_state')   or '',
    }
    return render_template('invoice.html', sale=sale, biz=biz)

@app.route('/manage', methods=['GET', 'POST'])
def manage():
    db = get_db()
    if request.method == 'POST':
        action = request.form.get('action')
        table  = request.form.get('table')
        name   = request.form.get('name', '').strip()
        hex_v  = request.form.get('hex', '#888888')
        rid    = request.form.get('id')
        color_tables = ['feet_colors', 'interlock_colors']

        if action == 'add' and name:
            if table in color_tables:
                db.execute(f"INSERT OR IGNORE INTO {table} (name, hex) VALUES (?,?)", (name, hex_v))
            else:
                db.execute(f"INSERT OR IGNORE INTO {table} (name) VALUES (?)", (name,))
            db.commit()
        elif action == 'delete' and rid:
            db.execute(f"DELETE FROM {table} WHERE id=?", (rid,))
            db.commit()
        elif action == 'threshold':
            db.execute("UPDATE settings SET value=? WHERE key='low_threshold'", (name,))
            db.commit()
        elif action == 'loading_charge':
            val = request.form.get('loading_charge', '0')
            db.execute("INSERT OR REPLACE INTO settings (key,value) VALUES ('loading_charge',?)", (val,))
            db.commit()
        elif action == 'business':
            for key in ['biz_name','biz_address','biz_phone','biz_email','biz_gstin','biz_state','invoice_prefix']:
                val = request.form.get(key, '')
                db.execute("INSERT OR REPLACE INTO settings (key,value) VALUES (?,?)", (key, val))
            db.commit()
        elif action == 'set_price':
            cat   = request.form.get('price_cat')
            size  = request.form.get('price_size')
            # feet: shape='', interlock: shape from form
            shape = request.form.get('price_shape', '') if cat == 'interlock' else ''
            price = float(request.form.get('price_value', 0) or 0)
            db.execute("""INSERT INTO price_list (cat, size, shape, price)
                          VALUES (?, ?, ?, ?)
                          ON CONFLICT(cat, size, shape) DO UPDATE SET price=excluded.price""",
                       (cat, size, shape, price))
            db.commit()
        elif action == 'delete_price' and rid:
            db.execute("DELETE FROM price_list WHERE id=?", (rid,))
            db.commit()
        return redirect(url_for('manage'))

    feet_sizes    = db.execute("SELECT * FROM feet_sizes ORDER BY name").fetchall()
    feet_colors   = db.execute("SELECT * FROM feet_colors ORDER BY name").fetchall()
    il_sizes      = db.execute("SELECT * FROM interlock_sizes ORDER BY name").fetchall()
    il_shapes     = db.execute("SELECT * FROM interlock_shapes ORDER BY name").fetchall()
    il_colors     = db.execute("SELECT * FROM interlock_colors ORDER BY name").fetchall()
    price_list    = db.execute("SELECT * FROM price_list ORDER BY cat, size, shape").fetchall()
    loading_charge = get_setting(db, 'loading_charge') or '0'

    biz = {k: (get_setting(db,k) or '') for k in ['biz_name','biz_address','biz_phone','biz_email','biz_gstin','biz_state','invoice_prefix']}
    return render_template('manage.html',
        feet_sizes=feet_sizes, feet_colors=feet_colors,
        interlock_sizes=il_sizes, interlock_shapes=il_shapes, interlock_colors=il_colors,
        price_list=price_list,
        loading_charge=loading_charge,
        threshold=get_threshold(db),
        all_feet_sizes=[r['name'] for r in feet_sizes],
        all_il_sizes=[r['name'] for r in il_sizes],
        all_il_shapes=[r['name'] for r in il_shapes],
        biz=biz,
    )


# ─────────────────────────────────────────
#  REPORTS
# ─────────────────────────────────────────

@app.route('/reports')
def reports():
    db = get_db()
    feet_sold     = db.execute("SELECT COALESCE(SUM(quantity),0) FROM sales WHERE cat='feet'").fetchone()[0]
    il_sold       = db.execute("SELECT COALESCE(SUM(quantity),0) FROM sales WHERE cat='interlock'").fetchone()[0]
    feet_stock    = db.execute("SELECT COALESCE(SUM(stock),0) FROM feet_inventory").fetchone()[0]
    il_stock      = db.execute("SELECT COALESCE(SUM(stock),0) FROM interlock_inventory").fetchone()[0]
    total_revenue = db.execute("SELECT COALESCE(SUM(grand_total),0) FROM sales").fetchone()[0]
    top_feet      = db.execute("""
        SELECT size, color, SUM(quantity) as total, SUM(grand_total) as revenue
        FROM sales WHERE cat='feet'
        GROUP BY size, color ORDER BY total DESC LIMIT 10""").fetchall()
    top_interlock = db.execute("""
        SELECT size, shape, color, SUM(quantity) as total, SUM(grand_total) as revenue
        FROM sales WHERE cat='interlock'
        GROUP BY size, shape, color ORDER BY total DESC LIMIT 10""").fetchall()
    monthly = db.execute("""
        SELECT strftime('%Y-%m', sale_date) as month, cat,
               SUM(quantity) as total, SUM(grand_total) as revenue
        FROM sales GROUP BY month, cat ORDER BY month DESC LIMIT 20""").fetchall()
    colors_feet = {r['name']: r['hex'] for r in db.execute("SELECT name, hex FROM feet_colors").fetchall()}
    colors_il   = {r['name']: r['hex'] for r in db.execute("SELECT name, hex FROM interlock_colors").fetchall()}
    return render_template('reports.html',
        feet_sold=feet_sold, il_sold=il_sold,
        feet_stock=feet_stock, il_stock=il_stock,
        total_revenue=total_revenue,
        top_feet=top_feet, top_interlock=top_interlock,
        monthly=monthly, colors_feet=colors_feet, colors_il=colors_il
    )


# ─────────────────────────────────────────
#  API
# ─────────────────────────────────────────

@app.route('/api/stock')
def api_stock():
    db    = get_db()
    cat   = request.args.get('cat')
    size  = request.args.get('size')
    shape = request.args.get('shape', '')
    color = request.args.get('color')
    if cat == 'feet':
        row = db.execute("SELECT stock FROM feet_inventory WHERE size=? AND color=?", (size, color)).fetchone()
        # price key: cat|size|shape(empty for feet)
        price_row = db.execute("SELECT price FROM price_list WHERE cat='feet' AND size=? AND shape=''", (size,)).fetchone()
    else:
        row = db.execute("SELECT stock FROM interlock_inventory WHERE size=? AND shape=? AND color=?", (size, shape, color)).fetchone()
        price_row = db.execute("SELECT price FROM price_list WHERE cat='interlock' AND size=? AND shape=?", (size, shape)).fetchone()
    return jsonify({
        'stock': row['stock'] if row else 0,
        'price': price_row['price'] if price_row else 0
    })


@app.route('/api/inventory/update', methods=['POST'])
def api_update_inventory():
    db    = get_db()
    data  = request.json
    cat   = data.get('cat')
    stock = int(data.get('stock', 0))
    if cat == 'feet':
        db.execute("UPDATE feet_inventory SET stock=?, updated=date('now') WHERE size=? AND color=?",
                   (stock, data['size'], data['color']))
    else:
        db.execute("UPDATE interlock_inventory SET stock=?, updated=date('now') WHERE size=? AND shape=? AND color=?",
                   (stock, data['size'], data['shape'], data['color']))
    db.commit()
    return jsonify({'ok': True})


@app.route('/api/inventory/delete', methods=['POST'])
def api_delete_inventory():
    db   = get_db()
    data = request.json
    cat  = data.get('cat')
    if cat == 'feet':
        db.execute("DELETE FROM feet_inventory WHERE size=? AND color=?", (data['size'], data['color']))
    else:
        db.execute("DELETE FROM interlock_inventory WHERE size=? AND shape=? AND color=?",
                   (data['size'], data['shape'], data['color']))
    db.commit()
    return jsonify({'ok': True})


@app.route('/api/sales/delete', methods=['POST'])
def api_delete_sale():
    db  = get_db()
    sid = request.json.get('id')
    db.execute("DELETE FROM sales WHERE id=?", (sid,))
    db.commit()
    return jsonify({'ok': True})


@app.route('/api/inventory-log/delete', methods=['POST'])
def api_delete_log_entry():
    db  = get_db()
    lid = request.json.get('id')
    db.execute("DELETE FROM inventory_log WHERE id=?", (lid,))
    db.commit()
    return jsonify({'ok': True})


if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    print(f"\n  TilePro Dashboard running at: http://localhost:{port}\n")
    app.run(debug=False, port=port, host='0.0.0.0')