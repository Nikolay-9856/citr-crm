"""ЦИТР.CRM v2.0 — CRUD для клиентов и сделок (Flask + MySQL).

В этой версии в БД есть только таблицы и данные: выборки строятся
JOIN-запросами прямо в коде, изменения — параметризованными INSERT/UPDATE/DELETE.
Вход в систему появится в v4.0.
"""
import configparser
import os
from datetime import datetime

from flask import Flask, flash, redirect, render_template, request, url_for

from db import DBConnection

cfg = configparser.ConfigParser()
cfg.read(os.path.join(os.path.dirname(__file__), "config.ini"), encoding="utf-8")

app = Flask(__name__)
app.secret_key = cfg["app"]["secret_key"]

# Сделка в развёрнутом виде (в v3.0 будет вынесено в VIEW v_deals_full)
DEALS_SQL = """
SELECT d.deal_id, d.title, c.client_id, c.client_name, seg.segment_name,
       u.user_id AS manager_id, u.full_name AS manager_name,
       s.stage_id, s.stage_name, s.probability, d.amount,
       ROUND(d.amount * s.probability / 100, 2) AS weighted_amount,
       d.expected_close, d.closed_at, d.updated_at
FROM deals d
JOIN clients     c ON c.client_id = d.client_id
JOIN deal_stages s ON s.stage_id  = d.stage_id
JOIN users       u ON u.user_id   = d.manager_id
LEFT JOIN client_segments seg ON seg.segment_id = c.segment_id
"""

# Список клиентов: сегмент, менеджер, основной контакт, число сделок, последний контакт
CLIENTS_SQL = """
SELECT c.client_id, c.client_type, c.client_name, c.inn, c.phone, c.city,
       seg.segment_name, u.full_name AS manager_name,
       ct.full_name AS main_contact,
       COUNT(DISTINCT d.deal_id) AS deals_cnt,
       MAX(i.happened_at) AS last_touch
FROM clients c
LEFT JOIN client_segments seg ON seg.segment_id = c.segment_id
LEFT JOIN users u             ON u.user_id = c.manager_id
LEFT JOIN contacts ct         ON ct.client_id = c.client_id AND ct.is_primary = 1
LEFT JOIN deals d             ON d.client_id = c.client_id
LEFT JOIN interactions i      ON i.client_id = c.client_id
{where}
GROUP BY c.client_id, c.client_type, c.client_name, c.inn, c.phone, c.city,
         seg.segment_name, u.full_name, ct.full_name
ORDER BY c.client_name
"""

PIPELINE_SQL = """
SELECT u.user_id, u.full_name AS manager_name,
       COUNT(d.deal_id) AS deals_total,
       SUM(CASE WHEN s.is_final = 0 THEN 1 ELSE 0 END) AS deals_open,
       COALESCE(SUM(CASE WHEN s.is_final = 0 THEN d.amount END), 0) AS open_amount,
       ROUND(COALESCE(SUM(CASE WHEN s.is_final = 0 THEN d.amount * s.probability / 100 END), 0), 2) AS forecast,
       SUM(CASE WHEN s.stage_name = 'Успешно закрыта' THEN 1 ELSE 0 END) AS deals_won,
       COALESCE(SUM(CASE WHEN s.stage_name = 'Успешно закрыта' THEN d.amount END), 0) AS won_amount
FROM users u
JOIN roles r ON r.role_id = u.role_id AND r.role_code = 'manager'
LEFT JOIN deals d       ON d.manager_id = u.user_id
LEFT JOIN deal_stages s ON s.stage_id = d.stage_id
GROUP BY u.user_id, u.full_name
"""


@app.context_processor
def inject_flags():
    # До появления авторизации (v4.0) все операции доступны
    return dict(me={}, is_admin=False, can_edit=True)


def load_lookup(sql):
    return [(r["id"], r["name"]) for r in DBConnection.fetch_all(sql)]


@app.route("/")
def index():
    return redirect(url_for("dashboard"))


@app.route("/dashboard")
def dashboard():
    pipeline = DBConnection.fetch_all(PIPELINE_SQL + " ORDER BY open_amount DESC")
    totals = DBConnection.fetch_one(
        "SELECT (SELECT COUNT(*) FROM clients) AS clients, "
        "(SELECT COUNT(*) FROM deals WHERE closed_at IS NULL) AS open_deals, "
        "(SELECT COALESCE(SUM(d.amount * s.probability / 100), 0) FROM deals d "
        " JOIN deal_stages s ON s.stage_id = d.stage_id WHERE s.is_final = 0) AS forecast, "
        "(SELECT COUNT(*) FROM interactions WHERE happened_at >= NOW() - INTERVAL 30 DAY) AS touches")
    recent = DBConnection.fetch_all(DEALS_SQL + " ORDER BY d.updated_at DESC LIMIT 5")
    return render_template("dashboard.html", pipeline=pipeline, totals=totals, recent=recent)


# ---------------------------------------------------------------- клиенты
@app.route("/clients")
def clients():
    q = request.args.get("q", "").strip()
    if q:
        rows = DBConnection.fetch_all(
            CLIENTS_SQL.format(where="WHERE c.client_name LIKE %s OR c.inn LIKE %s OR c.city LIKE %s"),
            (f"%{q}%",) * 3)
    else:
        rows = DBConnection.fetch_all(CLIENTS_SQL.format(where=""))
    return render_template("clients.html", rows=rows, q=q)


def _client_lookups():
    return dict(
        segments=load_lookup("SELECT segment_id AS id, segment_name AS name FROM client_segments ORDER BY segment_name"),
        managers=load_lookup("SELECT u.user_id AS id, u.full_name AS name FROM users u "
                             "JOIN roles r ON r.role_id = u.role_id WHERE r.role_code = 'manager' ORDER BY u.full_name"),
    )


def _client_params(form):
    return (form["client_type"], form["client_name"].strip(), form["inn"].strip() or None,
            form["phone"].strip() or None, form["email"].strip() or None,
            form["city"].strip() or None, form.get("segment_id") or None, form.get("manager_id") or None)


@app.route("/clients/new", methods=["GET", "POST"])
def client_new():
    if request.method == "POST":
        try:
            new_id = DBConnection.execute(
                "INSERT INTO clients (client_type, client_name, inn, phone, email, city, segment_id, manager_id) "
                "VALUES (%s, %s, %s, %s, %s, %s, %s, %s)", _client_params(request.form))
            flash(f"Клиент добавлен (ID {new_id})", "ok")
            return redirect(url_for("clients"))
        except Exception as exc:
            flash(f"Ошибка сохранения: {exc.args[-1]}", "error")
    return render_template("client_form.html", client=request.form, mode="new", **_client_lookups())


@app.route("/clients/<int:client_id>/edit", methods=["GET", "POST"])
def client_edit(client_id):
    if request.method == "POST":
        try:
            DBConnection.execute(
                "UPDATE clients SET client_type=%s, client_name=%s, inn=%s, phone=%s, email=%s, "
                "city=%s, segment_id=%s, manager_id=%s, updated_at=NOW() WHERE client_id=%s",
                _client_params(request.form) + (client_id,))
            flash("Изменения сохранены", "ok")
            return redirect(url_for("clients"))
        except Exception as exc:
            flash(f"Ошибка сохранения: {exc.args[-1]}", "error")
    client = DBConnection.fetch_one("SELECT * FROM clients WHERE client_id = %s", (client_id,))
    contacts = DBConnection.fetch_all("SELECT * FROM contacts WHERE client_id = %s ORDER BY is_primary DESC",
                                      (client_id,))
    return render_template("client_form.html", client=client, contacts=contacts, mode="edit", **_client_lookups())


@app.route("/clients/<int:client_id>/delete", methods=["POST"])
def client_delete(client_id):
    try:
        DBConnection.execute("DELETE FROM clients WHERE client_id = %s", (client_id,))
        flash("Клиент удалён вместе с контактами и историей взаимодействий", "ok")
    except Exception:
        flash("Удаление невозможно: у клиента есть сделки", "error")
    return redirect(url_for("clients"))


# ---------------------------------------------------------------- сделки
def _deal_lookups():
    return dict(
        clients=load_lookup("SELECT client_id AS id, client_name AS name FROM clients ORDER BY client_name"),
        managers=_client_lookups()["managers"],
        stages=load_lookup("SELECT stage_id AS id, stage_name AS name FROM deal_stages ORDER BY sort_order"),
    )


@app.route("/deals")
def deals():
    stage = request.args.get("stage", "")
    if stage:
        rows = DBConnection.fetch_all(DEALS_SQL + " WHERE d.stage_id = %s ORDER BY d.updated_at DESC", (stage,))
    else:
        rows = DBConnection.fetch_all(DEALS_SQL + " ORDER BY d.updated_at DESC")
    stages = load_lookup("SELECT stage_id AS id, stage_name AS name FROM deal_stages ORDER BY sort_order")
    return render_template("deals.html", rows=rows, stages=stages, stage=stage)


@app.route("/deals/new", methods=["GET", "POST"])
def deal_new():
    if request.method == "POST":
        f = request.form
        try:
            new_id = DBConnection.execute(
                "INSERT INTO deals (client_id, manager_id, stage_id, title, amount, expected_close) "
                "VALUES (%s, %s, (SELECT stage_id FROM deal_stages ORDER BY sort_order LIMIT 1), %s, %s, %s)",
                (f["client_id"], f["manager_id"], f["title"].strip(), f["amount"] or 0, f["expected_close"] or None))
            flash(f"Сделка №{new_id} создана", "ok")
            return redirect(url_for("deals"))
        except Exception as exc:
            flash(f"Ошибка сохранения: {exc.args[-1]}", "error")
    return render_template("deal_form.html", deal=request.form, mode="new", **_deal_lookups())


@app.route("/deals/<int:deal_id>/edit", methods=["GET", "POST"])
def deal_edit(deal_id):
    if request.method == "POST":
        f = request.form
        try:
            DBConnection.execute(
                "UPDATE deals SET client_id=%s, manager_id=%s, stage_id=%s, title=%s, amount=%s, "
                "expected_close=%s, updated_at=NOW() WHERE deal_id=%s",
                (f["client_id"], f["manager_id"], f["stage_id"], f["title"].strip(), f["amount"],
                 f["expected_close"] or None, deal_id))
            flash("Сделка обновлена", "ok")
            return redirect(url_for("deals"))
        except Exception as exc:
            flash(f"Ошибка сохранения: {exc.args[-1]}", "error")
    deal = DBConnection.fetch_one(DEALS_SQL + " WHERE d.deal_id = %s", (deal_id,))
    return render_template("deal_form.html", deal=deal, history=[], mode="edit", **_deal_lookups())


@app.route("/deals/<int:deal_id>/delete", methods=["POST"])
def deal_delete(deal_id):
    DBConnection.execute("DELETE FROM deals WHERE deal_id = %s", (deal_id,))
    flash(f"Сделка №{deal_id} удалена", "ok")
    return redirect(url_for("deals"))


# ---------------------------------------------------------------- взаимодействия
@app.route("/interactions", methods=["GET", "POST"])
def interactions():
    if request.method == "POST":
        f = request.form
        DBConnection.execute(
            "INSERT INTO interactions (client_id, deal_id, user_id, channel, subject, result_note) "
            "VALUES (%s, %s, %s, %s, %s, %s)",
            (f["client_id"], f.get("deal_id") or None, f["user_id"], f["channel"], f["subject"].strip(),
             f["note"].strip()))
        flash("Взаимодействие записано", "ok")
        return redirect(url_for("interactions"))
    rows = DBConnection.fetch_all(
        "SELECT i.happened_at, i.channel, i.subject, i.result_note, c.client_name, "
        "d.title AS deal_title, u.full_name AS author "
        "FROM interactions i JOIN clients c ON c.client_id = i.client_id "
        "LEFT JOIN deals d ON d.deal_id = i.deal_id JOIN users u ON u.user_id = i.user_id "
        "ORDER BY i.happened_at DESC")
    return render_template("interactions.html", rows=rows, **_deal_lookups(),
                           users=load_lookup("SELECT user_id AS id, full_name AS name FROM users ORDER BY full_name"),
                           deals=load_lookup("SELECT deal_id AS id, CONCAT('№', deal_id, ' ', title) AS name "
                                             "FROM deals WHERE closed_at IS NULL ORDER BY deal_id"))


# ---------------------------------------------------------------- отчёты (JOIN-запросы)
@app.route("/reports")
def reports():
    d_from = request.args.get("from", "2026-09-01")
    d_to = request.args.get("to", datetime.now().strftime("%Y-%m-%d"))
    pipeline = DBConnection.fetch_all(PIPELINE_SQL + " ORDER BY forecast DESC")
    stage_report = DBConnection.fetch_all(
        "SELECT s.stage_name, COUNT(h.history_id) AS transitions, COUNT(DISTINCT h.deal_id) AS deals, "
        "COALESCE(SUM(d.amount), 0) AS amount "
        "FROM deal_stages s "
        "LEFT JOIN deal_stage_history h ON h.new_stage_id = s.stage_id "
        "     AND h.changed_at >= %s AND h.changed_at < %s + INTERVAL 1 DAY "
        "LEFT JOIN deals d ON d.deal_id = h.deal_id "
        "GROUP BY s.stage_id, s.stage_name, s.sort_order ORDER BY s.sort_order", (d_from, d_to))
    segments = DBConnection.fetch_all(
        "SELECT seg.segment_name, COUNT(c.client_id) AS clients "
        "FROM clients c RIGHT JOIN client_segments seg ON seg.segment_id = c.segment_id "
        "GROUP BY seg.segment_id, seg.segment_name ORDER BY clients DESC")
    return render_template("reports.html", pipeline=pipeline, stage_report=stage_report,
                           segments=segments, d_from=d_from, d_to=d_to)


@app.template_filter("money")
def money(value):
    return f"{float(value or 0):,.0f}".replace(",", " ") + " ₽"


@app.template_filter("dt")
def dt(value, fmt="%d.%m.%Y %H:%M"):
    return value.strftime(fmt) if value else "—"


if __name__ == "__main__":
    app.run(host="127.0.0.1", port=5000, debug=False)
