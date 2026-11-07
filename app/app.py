"""ЦИТР.CRM v3.0 — CRUD + представления и хранимые процедуры (Flask + MySQL).

Списки читаются из VIEW, сделки создаются и переводятся по этапам процедурами.
Вход в систему и роли появятся в v4.0.
"""
import configparser
import os
from datetime import datetime
from functools import wraps

from flask import Flask, flash, redirect, render_template, request, url_for

from db import DBConnection, DBError

cfg = configparser.ConfigParser()
cfg.read(os.path.join(os.path.dirname(__file__), "config.ini"), encoding="utf-8")

app = Flask(__name__)
app.secret_key = cfg["app"]["secret_key"]


def login_required(view):
    return view  # авторизация появится в v4.0


def roles_required(*codes):
    return lambda view: view


@app.context_processor
def inject_flags():
    return dict(me={}, is_admin=False, can_edit=True)


def load_lookup(sql):
    """Универсальная загрузка справочника для выпадающего списка: [(id, name), ...]."""
    return [(r["id"], r["name"]) for r in DBConnection.fetch_all(sql)]


@app.route("/")
def index():
    return redirect(url_for("dashboard"))


# ---------------------------------------------------------------- главная
@app.route("/dashboard")
@login_required
def dashboard():
    pipeline = DBConnection.fetch_all("SELECT * FROM v_manager_pipeline ORDER BY open_amount DESC")
    totals = DBConnection.fetch_one(
        "SELECT COUNT(*) AS clients, "
        "(SELECT COUNT(*) FROM v_deals_full WHERE closed_at IS NULL) AS open_deals, "
        "(SELECT COALESCE(SUM(weighted_amount),0) FROM v_deals_full WHERE closed_at IS NULL) AS forecast, "
        "(SELECT COUNT(*) FROM interactions WHERE happened_at >= NOW() - INTERVAL 30 DAY) AS touches "
        "FROM clients")
    recent = DBConnection.fetch_all(
        "SELECT deal_id, title, client_name, stage_name, amount, updated_at "
        "FROM v_deals_full ORDER BY updated_at DESC LIMIT 5")
    return render_template("dashboard.html", pipeline=pipeline, totals=totals, recent=recent)


# ---------------------------------------------------------------- клиенты
@app.route("/clients")
@login_required
def clients():
    q = request.args.get("q", "").strip()
    sql = "SELECT * FROM v_clients_overview"
    params = ()
    if q:
        sql += " WHERE client_name LIKE %s OR inn LIKE %s OR city LIKE %s"
        params = (f"%{q}%",) * 3
    rows = DBConnection.fetch_all(sql + " ORDER BY client_name", params)
    return render_template("clients.html", rows=rows, q=q)


def _client_form_lookups():
    return dict(
        segments=load_lookup("SELECT segment_id AS id, segment_name AS name FROM client_segments ORDER BY segment_name"),
        managers=load_lookup("SELECT u.user_id AS id, u.full_name AS name FROM users u "
                             "JOIN roles r ON r.role_id = u.role_id "
                             "WHERE r.role_code = 'manager' AND u.is_active = 1 ORDER BY u.full_name"),
    )


def _client_params(form):
    return (form["client_type"], form["client_name"].strip(), form["inn"].strip() or None,
            form["phone"].strip() or None, form["email"].strip() or None,
            form["city"].strip() or None, form.get("segment_id") or None,
            form.get("manager_id") or None)


@app.route("/clients/new", methods=["GET", "POST"])
@login_required
@roles_required("admin", "manager")
def client_new():
    if request.method == "POST":
        try:
            new_id = DBConnection.execute(
                "INSERT INTO clients (client_type, client_name, inn, phone, email, city, segment_id, manager_id) "
                "VALUES (%s, %s, %s, %s, %s, %s, %s, %s)", _client_params(request.form))
            flash(f"Клиент добавлен (ID {new_id})", "ok")
            return redirect(url_for("clients"))
        except Exception as exc:  # дубль ИНН, нарушение CHECK и т.п.
            flash(f"Ошибка сохранения: {exc.args[-1]}", "error")
    return render_template("client_form.html", client=request.form, mode="new", **_client_form_lookups())


@app.route("/clients/<int:client_id>/edit", methods=["GET", "POST"])
@login_required
@roles_required("admin", "manager")
def client_edit(client_id):
    if request.method == "POST":
        try:
            DBConnection.execute(
                "UPDATE clients SET client_type=%s, client_name=%s, inn=%s, phone=%s, email=%s, "
                "city=%s, segment_id=%s, manager_id=%s WHERE client_id=%s",
                _client_params(request.form) + (client_id,))
            flash("Изменения сохранены", "ok")
            return redirect(url_for("clients"))
        except Exception as exc:
            flash(f"Ошибка сохранения: {exc.args[-1]}", "error")
    client = DBConnection.fetch_one("SELECT * FROM clients WHERE client_id = %s", (client_id,))
    contacts = DBConnection.fetch_all("SELECT * FROM contacts WHERE client_id = %s ORDER BY is_primary DESC",
                                      (client_id,))
    return render_template("client_form.html", client=client, contacts=contacts, mode="edit",
                           **_client_form_lookups())


@app.route("/clients/<int:client_id>/delete", methods=["POST"])
@login_required
@roles_required("admin", "manager")
def client_delete(client_id):
    try:
        DBConnection.execute("DELETE FROM clients WHERE client_id = %s", (client_id,))
        flash("Клиент удалён вместе с контактами и историей взаимодействий", "ok")
    except Exception:
        flash("Удаление невозможно: у клиента есть сделки", "error")
    return redirect(url_for("clients"))


# ---------------------------------------------------------------- сделки
@app.route("/deals")
@login_required
def deals():
    stage = request.args.get("stage", "")
    sql = "SELECT * FROM v_deals_full"
    params = ()
    if stage:
        sql += " WHERE stage_id = %s"
        params = (stage,)
    rows = DBConnection.fetch_all(sql + " ORDER BY updated_at DESC", params)
    stages = load_lookup("SELECT stage_id AS id, stage_name AS name FROM deal_stages ORDER BY sort_order")
    return render_template("deals.html", rows=rows, stages=stages, stage=stage)


def _deal_lookups():
    return dict(
        clients=load_lookup("SELECT client_id AS id, client_name AS name FROM clients ORDER BY client_name"),
        managers=_client_form_lookups()["managers"],
        stages=load_lookup("SELECT stage_id AS id, stage_name AS name FROM deal_stages ORDER BY sort_order"),
    )


@app.route("/deals/new", methods=["GET", "POST"])
@login_required
@roles_required("admin", "manager")
def deal_new():
    if request.method == "POST":
        f = request.form
        try:
            with DBConnection.cursor() as cur:
                cur.callproc("sp_create_deal", (int(f["client_id"]), int(f["manager_id"]), f["title"].strip(),
                                                f["amount"] or 0, f["expected_close"] or None, 0))
                cur.execute("SELECT @_sp_create_deal_5 AS deal_id")
                new_id = cur.fetchone()["deal_id"]
            flash(f"Сделка №{new_id} создана на этапе «Новый лид»", "ok")
            return redirect(url_for("deals"))
        except DBError as err:
            flash(str(err), "error")
    return render_template("deal_form.html", deal=request.form, mode="new", **_deal_lookups())


@app.route("/deals/<int:deal_id>/edit", methods=["GET", "POST"])
@login_required
@roles_required("admin", "manager")
def deal_edit(deal_id):
    if request.method == "POST":
        f = request.form
        try:
            DBConnection.execute(
                "UPDATE deals SET client_id=%s, manager_id=%s, title=%s, amount=%s, expected_close=%s "
                "WHERE deal_id=%s",
                (f["client_id"], f["manager_id"], f["title"].strip(), f["amount"], f["expected_close"] or None,
                 deal_id))
            if f.get("stage_id") and f["stage_id"] != f["current_stage"]:
                DBConnection.call_proc("sp_change_deal_stage",
                                       (deal_id, int(f["stage_id"]), int(f["manager_id"])))
            flash("Сделка обновлена", "ok")
            return redirect(url_for("deals"))
        except DBError as err:
            flash(str(err), "error")
    deal = DBConnection.fetch_one("SELECT * FROM v_deals_full WHERE deal_id = %s", (deal_id,))
    history = DBConnection.fetch_all(
        "SELECT h.changed_at, so.stage_name AS old_stage, sn.stage_name AS new_stage, u.full_name "
        "FROM deal_stage_history h "
        "LEFT JOIN deal_stages so ON so.stage_id = h.old_stage_id "
        "JOIN deal_stages sn ON sn.stage_id = h.new_stage_id "
        "LEFT JOIN users u ON u.user_id = h.changed_by "
        "WHERE h.deal_id = %s ORDER BY h.changed_at DESC", (deal_id,))
    return render_template("deal_form.html", deal=deal, history=history, mode="edit", **_deal_lookups())


@app.route("/deals/<int:deal_id>/delete", methods=["POST"])
@login_required
@roles_required("admin", "manager")
def deal_delete(deal_id):
    DBConnection.execute("DELETE FROM deals WHERE deal_id = %s", (deal_id,))
    flash(f"Сделка №{deal_id} удалена", "ok")
    return redirect(url_for("deals"))


# ---------------------------------------------------------------- взаимодействия
@app.route("/interactions", methods=["GET", "POST"])
@login_required
def interactions():
    if request.method == "POST":
        f = request.form
        try:
            DBConnection.call_proc("sp_log_interaction", (
                int(f["client_id"]), int(f["deal_id"]) if f.get("deal_id") else None,
                int(f["user_id"]), f["channel"], f["subject"].strip(), f["note"].strip()))
            flash("Взаимодействие записано", "ok")
        except DBError as err:
            flash(str(err), "error")
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


# ---------------------------------------------------------------- отчёты
@app.route("/reports")
@login_required
def reports():
    d_from = request.args.get("from", "2026-09-01")
    d_to = request.args.get("to", datetime.now().strftime("%Y-%m-%d"))
    pipeline = DBConnection.fetch_all("SELECT * FROM v_manager_pipeline ORDER BY forecast DESC")
    stage_report = DBConnection.call_proc("sp_stage_report", (d_from, d_to))
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
