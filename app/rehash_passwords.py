"""Однократный пересчёт паролей тестовых пользователей по схеме SHA-256 + соль
(выполняется после ALTER TABLE users ADD password_salt)."""
from db import DBConnection
from security import PasswordHelper

INITIAL = {
    "voronin": "Adm!n2026", "belova": "Crm#Belova7", "gusev": "Crm#Gusev8",
    "litvinova": "Crm#Litv9", "martynov": "Rop$Mart5",
}

for login, password in INITIAL.items():
    salt = PasswordHelper.generate_salt()
    DBConnection.execute(
        "UPDATE users SET password_salt = %s, password_hash = %s WHERE login = %s",
        (salt, PasswordHelper.hash_password(password, salt), login))
    print(f"{login:<10} соль={salt}")
