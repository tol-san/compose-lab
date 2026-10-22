import os

import redis
import requests
from flask import Flask, redirect, render_template_string, request, url_for

app = Flask(__name__)

cache = redis.Redis(
    host=os.getenv("REDIS_HOST", "redis"),
    port=int(os.getenv("REDIS_PORT", "6379")),
    socket_connect_timeout=2,
)
API_URL = os.getenv("API_URL", "http://api:5000")

PAGE = """
<!doctype html>
<title>Compose Lab</title>
<body style="font-family: sans-serif; max-width: 600px; margin: 2rem auto;">
  <h1>Hello from Docker Compose!</h1>
  <p>This page has been seen <strong>{{ hits }}</strong> time(s) (Redis).</p>

  <h2>Notes</h2>
  <form method="post" action="/notes">
    <input name="text" placeholder="Write a note..." required>
    <button type="submit">Add</button>
  </form>

  {% if error %}
    <p style="color: red;">API error: {{ error }}</p>
  {% endif %}

  <ul>
    {% for n in notes %}
      <li>#{{ n.id }}: {{ n.text }}</li>
    {% else %}
      <li><em>No notes yet.</em></li>
    {% endfor %}
  </ul>
</body>
"""


@app.route("/")
def index():
    hits = cache.incr("hits")
    notes, error = [], None
    try:
        resp = requests.get(f"{API_URL}/notes", timeout=3)
        resp.raise_for_status()
        notes = resp.json()
    except requests.RequestException as exc:
        error = str(exc)
    return render_template_string(PAGE, hits=hits, notes=notes, error=error)


@app.route("/notes", methods=["POST"])
def add_note():
    text = request.form.get("text", "").strip()
    if text:
        try:
            requests.post(f"{API_URL}/notes", json={"text": text}, timeout=3)
        except requests.RequestException:
            pass  # the index page will show the API error on reload
    return redirect(url_for("index"))


@app.route("/health")
def health():
    return {"status": "ok"}