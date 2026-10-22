import os
from pathlib import Path

import psycopg2
from flask import Flask, jsonify, request
from psycopg2.extras import RealDictCursor

app = Flask(__name__)


def read_secret(name, default=None):
    """Prefer NAME_FILE (Docker secret) over NAME (plain env var)."""
    file_path = os.getenv(f"{name}_FILE")
    if file_path:
        return Path(file_path).read_text().strip()
    return os.getenv(name, default)


def get_conn():
    return psycopg2.connect(
        host=os.getenv("DB_HOST", "db"),
        port=int(os.getenv("DB_PORT", "5432")),
        user=os.getenv("DB_USER"),
        password=read_secret("DB_PASSWORD"),
        dbname=os.getenv("DB_NAME"),
        connect_timeout=3,
    )


def run_query(sql, params=None):
    conn = get_conn()
    try:
        # `with conn` commits on success, rolls back on error
        with conn, conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute(sql, params)
            return cur.fetchall()
    finally:
        conn.close()


@app.route("/health")
def health():
    return {"status": "ok"}


@app.route("/notes", methods=["GET"])
def list_notes():
    rows = run_query("SELECT id, text, created_at FROM notes ORDER BY id DESC LIMIT 20")
    return jsonify(rows)


@app.route("/notes", methods=["POST"])
def create_note():
    data = request.get_json(silent=True) or {}
    text = (data.get("text") or "").strip()
    if not text:
        return {"error": "text is required"}, 400
    rows = run_query(
        "INSERT INTO notes (text) VALUES (%s) RETURNING id, text, created_at",
        (text,),
    )
    return jsonify(rows[0]), 201