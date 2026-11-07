"""Хэширование паролей пользователей приложения: SHA-256 + соль."""
import hashlib
import hmac
import secrets


class PasswordHelper:
    SALT_BYTES = 16  # 16 байт -> 32 hex-символа

    @staticmethod
    def generate_salt() -> str:
        """Криптографически стойкая случайная соль."""
        return secrets.token_hex(PasswordHelper.SALT_BYTES)

    @staticmethod
    def hash_password(password: str, salt: str) -> str:
        """SHA-256 от строки (соль + пароль), результат — 64 hex-символа."""
        return hashlib.sha256((salt + password).encode("utf-8")).hexdigest()

    @staticmethod
    def verify_password(password: str, salt: str, stored_hash: str) -> bool:
        """Сравнение за постоянное время, чтобы не давать подсказок по таймингу."""
        candidate = PasswordHelper.hash_password(password, salt)
        return hmac.compare_digest(candidate, stored_hash)

    @staticmethod
    def check_strength(password: str) -> list:
        """Минимальные требования к паролю при регистрации."""
        problems = []
        if len(password) < 8:
            problems.append("не короче 8 символов")
        if not any(ch.isdigit() for ch in password):
            problems.append("хотя бы одна цифра")
        if password.lower() == password or password.upper() == password:
            problems.append("буквы в разном регистре")
        return problems
