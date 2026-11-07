# ЦИТР.CRM — учёт клиентов и сделок ООО «ЦИТР» (v4.0)

Учебный проект производственной практики по ПМ.07 «Соадминистрирование и автоматизация баз данных и серверов». Предметная область — автоматизация взаимоотношений с клиентами (CRM).

**Стек:** MySQL 8.0 (InnoDB, utf8mb4), Python 3.11+, Flask 3, PyMySQL.

## История версий

| Версия | Содержание |
|---|---|
| v1.0 — DDL + данные | Схема БД из 9 таблиц (3НФ), ER-диаграмма, тестовые данные. |
| v2.0 — CRUD | Веб-приложение на Flask: CRUD клиентов и сделок, журнал взаимодействий, запросы INNER/LEFT/RIGHT JOIN, GROUP BY + HAVING. |
| v3.0 — VIEW + процедуры | Представления v_deals_full, v_manager_pipeline, v_clients_overview; процедуры sp_create_deal, sp_change_deal_stage, sp_log_interaction, sp_stage_report; приложение читает данные из VIEW и вызывает процедуры. |
| v4.0 — триггеры + роли | Триггеры аудита и авто-timestamp; роли СУБД crm_reader / crm_operator / crm_admin; хэширование паролей SHA-256 + соль; вход, регистрация, разграничение интерфейса по ролям. |

## Структура репозитория

```
README.md
app/app.py
app/config.example.ini
app/db.py
app/rehash_passwords.py
app/security.py
app/static/style.css
app/templates/  (HTML-шаблоны Jinja2)
docs/access_model.png
docs/architecture.png
docs/er_diagram.png
docs/navigation.png
requirements.txt
sql/01_schema.sql
sql/02_data.sql
sql/03_views_procedures.sql
sql/04_triggers.sql
sql/05_security.sql
sql/queries_join.sql
```

## Развёртывание базы данных

Выполните скрипты по порядку (MySQL 8.0, пользователь с правами администратора):

```bash
mysql -u root -p < sql/01_schema.sql    # создание БД и 9 таблиц (DDL)
mysql -u root -p < sql/02_data.sql    # тестовые данные (INSERT)
mysql -u root -p < sql/03_views_procedures.sql    # представления и хранимые процедуры
mysql -u root -p < sql/04_triggers.sql    # триггеры
mysql -u root -p < sql/05_security.sql    # соль пароля, процедуры аутентификации, роли и пользователи СУБД
```

## Запуск приложения

```bash
pip install -r requirements.txt
cd app
cp config.example.ini config.ini     # Windows: copy config.example.ini config.ini
python rehash_passwords.py          # пересчёт паролей тестовых пользователей с солью
python app.py
```

Приложение откроется по адресу http://127.0.0.1:5000

Тестовые учётные записи:

| Логин | Пароль | Роль |
|---|---|---|
| voronin | Adm!n2026 | Администратор |
| belova | Crm#Belova7 | Менеджер |
| martynov | Rop$Mart5 | Руководитель отдела продаж (только просмотр) |

## Описание SQL-скриптов

- `sql/01_schema.sql` — создание БД и 9 таблиц (DDL)
- `sql/02_data.sql` — тестовые данные (INSERT)
- `sql/03_views_procedures.sql` — представления и хранимые процедуры
- `sql/04_triggers.sql` — триггеры
- `sql/05_security.sql` — соль пароля, процедуры аутентификации, роли и пользователи СУБД
- `sql/queries_join.sql` — запросы INNER / LEFT / RIGHT JOIN, GROUP BY + HAVING (выполнять по желанию)

> Все данные (клиенты, сотрудники, сделки) — условные тестовые записи.
