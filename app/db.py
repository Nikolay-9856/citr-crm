"""Управление подключением к базе данных citr_crm."""
import configparser
import os
from contextlib import contextmanager

import pymysql
from pymysql.cursors import DictCursor

# Код ошибки MySQL, который возвращает SIGNAL SQLSTATE '45000'
SIGNAL_ERROR = 1644


class DBError(Exception):
    """Ошибка бизнес-логики, переданная из процедуры через SIGNAL."""


class DBConnection:
    """Создаёт подключения по параметрам из config.ini и выполняет запросы."""

    _settings = None

    @classmethod
    def _load(cls):
        if cls._settings is None:
            cfg = configparser.ConfigParser()
            cfg.read(os.path.join(os.path.dirname(__file__), "config.ini"), encoding="utf-8")
            db = cfg["database"]
            cls._settings = dict(
                host=db.get("host"), port=db.getint("port"),
                user=db.get("user"), password=db.get("password"),
                database=db.get("database"), charset=db.get("charset"),
                cursorclass=DictCursor, autocommit=False,
            )
        return cls._settings

    @classmethod
    def get_connection(cls):
        return pymysql.connect(**cls._load())

    @classmethod
    @contextmanager
    def cursor(cls):
        """Курсор с автоматическим commit/rollback и закрытием соединения."""
        conn = cls.get_connection()
        try:
            with conn.cursor() as cur:
                yield cur
            conn.commit()
        except pymysql.err.OperationalError as exc:
            conn.rollback()
            if exc.args and exc.args[0] == SIGNAL_ERROR:
                raise DBError(exc.args[1]) from exc
            raise
        except Exception:
            conn.rollback()
            raise
        finally:
            conn.close()

    # --- вспомогательные методы ---
    @classmethod
    def fetch_all(cls, sql, params=None):
        with cls.cursor() as cur:
            cur.execute(sql, params or ())
            return cur.fetchall()

    @classmethod
    def fetch_one(cls, sql, params=None):
        with cls.cursor() as cur:
            cur.execute(sql, params or ())
            return cur.fetchone()

    @classmethod
    def execute(cls, sql, params=None):
        with cls.cursor() as cur:
            cur.execute(sql, params or ())
            return cur.lastrowid or cur.rowcount

    @classmethod
    def call_proc(cls, name, args=()):
        """Вызов хранимой процедуры; возвращает первый набор строк (если есть)."""
        with cls.cursor() as cur:
            cur.callproc(name, args)
            rows = cur.fetchall()
            while cur.nextset():
                pass
            return rows
