# ЦИТР.CRM — учёт клиентов и сделок ООО «ЦИТР» (v2.0)

Учебный проект производственной практики по ПМ.07 «Соадминистрирование и автоматизация баз данных и серверов». Предметная область — автоматизация взаимоотношений с клиентами (CRM).

**Стек:** MySQL 8.0 (InnoDB, utf8mb4), Python 3.11+, Flask 3, PyMySQL.

## История версий

| Версия | Содержание |
|---|---|
| v1.0 — DDL + данные | Схема БД из 9 таблиц (3НФ), ER-диаграмма, тестовые данные. |
| v2.0 — CRUD | Веб-приложение на Flask: CRUD клиентов и сделок, журнал взаимодействий, запросы INNER/LEFT/RIGHT JOIN, GROUP BY + HAVING. |

## Структура репозитория

```
README.md
app/app.py
app/config.example.ini
app/db.py
app/static/style.css
app/templates/  (HTML-шаблоны Jinja2)
docs/er_diagram.png
requirements.txt
sql/01_schema.sql
sql/02_data.sql
sql/queries_join.sql
```

## Развёртывание базы данных

Выполните скрипты по порядку (MySQL 8.0, пользователь с правами администратора):

```bash
mysql -u root -p < sql/01_schema.sql    # создание БД и 9 таблиц (DDL)
mysql -u root -p < sql/02_data.sql    # тестовые данные (INSERT)
```

## Запуск приложения

```bash
pip install -r requirements.txt
cd app
cp config.example.ini config.ini     # Windows: copy config.example.ini config.ini
python app.py
```

Приложение откроется по адресу http://127.0.0.1:5000

## Описание SQL-скриптов

- `sql/01_schema.sql` — создание БД и 9 таблиц (DDL)
- `sql/02_data.sql` — тестовые данные (INSERT)
- `sql/queries_join.sql` — запросы INNER / LEFT / RIGHT JOIN, GROUP BY + HAVING (выполнять по желанию)

> Все данные (клиенты, сотрудники, сделки) — условные тестовые записи.
