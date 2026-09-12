import sqlite3
import os
from flask import g

INSTANCE_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'instance')
DB_PATH = os.path.join(INSTANCE_DIR, 'tilepro.db')

# Used by SQLAlchemy (new ledger tables) so both engines point at the same
# database, keeping a single source of truth for local dev / SQLite.
DATABASE_URL = os.environ.get('DATABASE_URL', f'sqlite:///{DB_PATH}')
if DATABASE_URL.startswith('postgres://'):
    # SQLAlchemy 1.4+/2.x dropped support for the old "postgres://" scheme.
    DATABASE_URL = DATABASE_URL.replace('postgres://', 'postgresql://', 1)


def get_db():
    if 'db' not in g:
        g.db = sqlite3.connect(DB_PATH)
        g.db.row_factory = sqlite3.Row
        g.db.execute("PRAGMA foreign_keys = ON")
    return g.db


def get_threshold(db):
    row = db.execute("SELECT value FROM settings WHERE key='low_threshold'").fetchone()
    return int(row['value']) if row else 50


def get_setting(db, key):
    row = db.execute("SELECT value FROM settings WHERE key=?", (key,)).fetchone()
    return row['value'] if row else None


def set_setting(db, key, value):
    db.execute("INSERT OR REPLACE INTO settings (key,value) VALUES (?,?)", (key, value))


def next_invoice_no(db):
    prefix = get_setting(db, 'invoice_prefix') or 'INV'
    counter = int(get_setting(db, 'invoice_counter') or 1)
    db.execute("UPDATE settings SET value=? WHERE key='invoice_counter'", (str(counter + 1),))
    return f"{prefix}{counter}"


def get_or_create_customer(db, name, phone=''):
    """Find a customer by name (+phone if given) or create one. Returns id."""
    name = (name or '').strip()
    if not name:
        return None
    row = db.execute("SELECT id FROM customers WHERE name=?", (name,)).fetchone()
    if row:
        if phone:
            db.execute("UPDATE customers SET phone=? WHERE id=? AND (phone IS NULL OR phone='')", (phone, row['id']))
        return row['id']
    cur = db.execute("INSERT INTO customers (name, phone) VALUES (?,?)", (name, phone or ''))
    return cur.lastrowid


def migrate(db):
    existing_cols = {r[1] for r in db.execute("PRAGMA table_info(sales)")}
    new_cols = {
        'price_per_unit':  'REAL DEFAULT 0',
        'subtotal':        'REAL DEFAULT 0',
        'loading_charge':  'REAL DEFAULT 0',
        'discount_type':   'TEXT DEFAULT ""',
        'discount_value':  'REAL DEFAULT 0',
        'discount_amount': 'REAL DEFAULT 0',
        'grand_total':     'REAL DEFAULT 0',
        'phone':           'TEXT DEFAULT ""',
        'address':         'TEXT DEFAULT ""',
        'gst':             'TEXT DEFAULT ""',
        'gst_amount':      'REAL DEFAULT 0',
        'invoice_no':      'TEXT DEFAULT ""',
        'customer_id':     'INTEGER',
        'amount_paid':     'REAL DEFAULT 0',
        'amount_due':      'REAL DEFAULT 0',
    }
    for col, coldef in new_cols.items():
        if col not in existing_cols:
            db.execute(f"ALTER TABLE sales ADD COLUMN {col} {coldef}")
    db.execute("""CREATE TABLE IF NOT EXISTS inventory_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cat TEXT NOT NULL, size TEXT NOT NULL, shape TEXT DEFAULT '',
        color TEXT NOT NULL, quantity INTEGER NOT NULL,
        note TEXT DEFAULT '', added_by TEXT DEFAULT '', log_date TEXT NOT NULL
    )""")
    tables = {r[0] for r in db.execute("SELECT name FROM sqlite_master WHERE type='table'")}
    if 'price_list' not in tables:
        db.execute("""CREATE TABLE price_list (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            cat TEXT NOT NULL, size TEXT NOT NULL, shape TEXT DEFAULT '',
            price REAL DEFAULT 0, UNIQUE(cat, size, shape)
        )""")
    else:
        pl_cols = {r[1] for r in db.execute("PRAGMA table_info(price_list)")}
        if 'color' in pl_cols:
            db.execute("DROP TABLE price_list")
            db.execute("""CREATE TABLE price_list (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                cat TEXT NOT NULL, size TEXT NOT NULL, shape TEXT DEFAULT '',
                price REAL DEFAULT 0, UNIQUE(cat, size, shape)
            )""")
    if 'customers' not in tables:
        db.execute("""CREATE TABLE customers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT UNIQUE NOT NULL, phone TEXT DEFAULT ''
        )""")
    db.commit()

def init_db():
    os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)
    db = sqlite3.connect(DB_PATH)
    db.row_factory = sqlite3.Row
    db.executescript(CREATE_TABLES)
    migrate(db)
    db.execute("INSERT OR IGNORE INTO settings (key, value) VALUES (?, ?)", ('low_threshold', '50'))
    db.execute("INSERT OR IGNORE INTO settings (key, value) VALUES (?, ?)", ('loading_charge', '0'))
    db.execute("INSERT OR IGNORE INTO settings (key, value) VALUES (?, ?)", ('biz_name', ''))
    db.execute("INSERT OR IGNORE INTO settings (key, value) VALUES (?, ?)", ('biz_address', ''))
    db.execute("INSERT OR IGNORE INTO settings (key, value) VALUES (?, ?)", ('biz_phone', ''))
    db.execute("INSERT OR IGNORE INTO settings (key, value) VALUES (?, ?)", ('biz_email', ''))
    db.execute("INSERT OR IGNORE INTO settings (key, value) VALUES (?, ?)", ('biz_gstin', ''))
    db.execute("INSERT OR IGNORE INTO settings (key, value) VALUES (?, ?)", ('biz_state', ''))
    db.execute("INSERT OR IGNORE INTO settings (key, value) VALUES (?, ?)", ('invoice_prefix', 'TFS'))
    db.execute("INSERT OR IGNORE INTO settings (key, value) VALUES (?, ?)", ('invoice_counter', '1'))
    # Feet
    db.executemany("INSERT OR IGNORE INTO feet_sizes (name) VALUES (?)",
        [('1x1',)])
    db.executemany("INSERT OR IGNORE INTO feet_colors (name, hex) VALUES (?, ?)",
        [('Red','#e85252'), ('Yellow','#f5c842'), ('Grey','#888888')])
    # Interlock
    db.executemany("INSERT OR IGNORE INTO interlock_sizes (name) VALUES (?)",
        [('60mm',), ('40mm',), ('50mm',)])
    db.executemany("INSERT OR IGNORE INTO interlock_shapes (name) VALUES (?)",
        [('Tortoise',), ('L-Shape',), ('Dumbbell',)])
    db.executemany("INSERT OR IGNORE INTO interlock_colors (name, hex) VALUES (?, ?)",
        [('Red','#e85252'), ('Yellow','#f5c842'), ('Grey','#888888')])
    db.commit()
    db.close()

CREATE_TABLES = """
CREATE TABLE IF NOT EXISTS feet_sizes (
    id   INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE NOT NULL
);
CREATE TABLE IF NOT EXISTS feet_colors (
    id   INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE NOT NULL,
    hex  TEXT DEFAULT '#888888'
);
CREATE TABLE IF NOT EXISTS interlock_sizes (
    id   INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE NOT NULL
);
CREATE TABLE IF NOT EXISTS interlock_shapes (
    id   INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE NOT NULL
);
CREATE TABLE IF NOT EXISTS interlock_colors (
    id   INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE NOT NULL,
    hex  TEXT DEFAULT '#888888'
);
CREATE TABLE IF NOT EXISTS feet_inventory (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    size TEXT NOT NULL, color TEXT NOT NULL,
    stock INTEGER DEFAULT 0, updated TEXT, UNIQUE(size, color)
);
CREATE TABLE IF NOT EXISTS interlock_inventory (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    size TEXT NOT NULL, shape TEXT NOT NULL, color TEXT NOT NULL,
    stock INTEGER DEFAULT 0, updated TEXT, UNIQUE(size, shape, color)
);
CREATE TABLE IF NOT EXISTS sales (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    cat TEXT NOT NULL, description TEXT,
    size TEXT, shape TEXT DEFAULT '', color TEXT,
    quantity INTEGER NOT NULL,
    price_per_unit REAL DEFAULT 0, subtotal REAL DEFAULT 0,
    loading_charge REAL DEFAULT 0,
    discount_type TEXT DEFAULT '', discount_value REAL DEFAULT 0,
    discount_amount REAL DEFAULT 0, grand_total REAL DEFAULT 0,
    customer TEXT DEFAULT '', phone TEXT DEFAULT '',
    address TEXT DEFAULT '', gst TEXT DEFAULT '', gst_amount REAL DEFAULT 0,
    invoice_no TEXT DEFAULT '', note TEXT DEFAULT '',
    sale_date TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS settings (
    key TEXT PRIMARY KEY, value TEXT
);
"""