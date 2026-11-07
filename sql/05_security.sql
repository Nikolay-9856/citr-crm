-- ============================================================
-- Безопасность citr_crm: соль пароля, процедуры аутентификации,
-- роли СУБД и пользователи БД. СУБД: MySQL 8.0
-- ============================================================
USE citr_crm;

-- Поле для соли (16 случайных байт в hex = 32 символа)
ALTER TABLE users
    ADD COLUMN password_salt CHAR(32) NOT NULL DEFAULT '' AFTER password_hash;

DELIMITER $$

-- Регистрация пользователя приложения: соль и хэш вычисляются в Python
DROP PROCEDURE IF EXISTS sp_register_user $$
CREATE PROCEDURE sp_register_user(
    IN p_login     VARCHAR(40),
    IN p_full_name VARCHAR(120),
    IN p_email     VARCHAR(120),
    IN p_salt      CHAR(32),
    IN p_hash      CHAR(64),
    IN p_role_code VARCHAR(20)
)
BEGIN
    DECLARE v_role TINYINT UNSIGNED;

    IF EXISTS (SELECT 1 FROM users WHERE login = p_login) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Пользователь с таким логином уже существует';
    END IF;
    IF CHAR_LENGTH(p_hash) <> 64 OR CHAR_LENGTH(p_salt) <> 32 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Неверный формат хэша или соли';
    END IF;

    SELECT role_id INTO v_role FROM roles WHERE role_code = p_role_code;
    IF v_role IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Роль не найдена';
    END IF;

    INSERT INTO users (login, full_name, email, password_hash, password_salt, role_id)
    VALUES (p_login, p_full_name, p_email, p_hash, p_salt, v_role);
    SELECT LAST_INSERT_ID() AS user_id;
END $$

-- Данные для проверки пароля при входе
DROP PROCEDURE IF EXISTS sp_get_auth_data $$
CREATE PROCEDURE sp_get_auth_data(IN p_login VARCHAR(40))
BEGIN
    SELECT u.user_id, u.full_name, u.password_hash, u.password_salt,
           u.is_active, r.role_code, r.role_name
      FROM users u JOIN roles r ON r.role_id = u.role_id
     WHERE u.login = p_login;
END $$

DELIMITER ;

-- ---------- Роли СУБД ----------
DROP ROLE IF EXISTS 'crm_reader', 'crm_operator', 'crm_admin';
CREATE ROLE 'crm_reader', 'crm_operator', 'crm_admin';

-- Только чтение: справочники, рабочие таблицы и представления (без users)
GRANT SELECT ON citr_crm.clients            TO 'crm_reader';
GRANT SELECT ON citr_crm.contacts           TO 'crm_reader';
GRANT SELECT ON citr_crm.deals              TO 'crm_reader';
GRANT SELECT ON citr_crm.deal_stages        TO 'crm_reader';
GRANT SELECT ON citr_crm.client_segments    TO 'crm_reader';
GRANT SELECT ON citr_crm.interactions       TO 'crm_reader';
GRANT SELECT ON citr_crm.deal_stage_history TO 'crm_reader';
GRANT SELECT ON citr_crm.v_deals_full       TO 'crm_reader';
GRANT SELECT ON citr_crm.v_manager_pipeline TO 'crm_reader';
GRANT SELECT ON citr_crm.v_clients_overview TO 'crm_reader';
GRANT EXECUTE ON PROCEDURE citr_crm.sp_stage_report TO 'crm_reader';

-- Оператор (учётная запись приложения): чтение + запись рабочих таблиц
GRANT 'crm_reader' TO 'crm_operator';
GRANT SELECT, INSERT, UPDATE, DELETE ON citr_crm.clients      TO 'crm_operator';
GRANT SELECT, INSERT, UPDATE, DELETE ON citr_crm.contacts     TO 'crm_operator';
GRANT SELECT, INSERT, UPDATE, DELETE ON citr_crm.deals        TO 'crm_operator';
GRANT SELECT, INSERT, UPDATE         ON citr_crm.interactions TO 'crm_operator';
GRANT SELECT                         ON citr_crm.roles        TO 'crm_operator';
GRANT SELECT, INSERT, UPDATE         ON citr_crm.users        TO 'crm_operator';
GRANT EXECUTE ON PROCEDURE citr_crm.sp_create_deal       TO 'crm_operator';
GRANT EXECUTE ON PROCEDURE citr_crm.sp_change_deal_stage TO 'crm_operator';
GRANT EXECUTE ON PROCEDURE citr_crm.sp_log_interaction   TO 'crm_operator';
GRANT EXECUTE ON PROCEDURE citr_crm.sp_register_user     TO 'crm_operator';
GRANT EXECUTE ON PROCEDURE citr_crm.sp_get_auth_data     TO 'crm_operator';

-- Администратор БД: полный доступ к схеме
GRANT ALL PRIVILEGES ON citr_crm.* TO 'crm_admin' WITH GRANT OPTION;

-- ---------- Пользователи СУБД ----------
DROP USER IF EXISTS 'crm_report'@'localhost', 'crm_app'@'localhost', 'crm_dba'@'localhost';
CREATE USER 'crm_report'@'localhost' IDENTIFIED BY 'Rep0rt_2026!';
CREATE USER 'crm_app'@'localhost'    IDENTIFIED BY 'AppCrm_2026!';
CREATE USER 'crm_dba'@'localhost'    IDENTIFIED BY 'DbaCrm_2026!';

GRANT 'crm_reader'   TO 'crm_report'@'localhost';
GRANT 'crm_operator' TO 'crm_app'@'localhost';
GRANT 'crm_admin'    TO 'crm_dba'@'localhost';

SET DEFAULT ROLE ALL TO 'crm_report'@'localhost', 'crm_app'@'localhost', 'crm_dba'@'localhost';
FLUSH PRIVILEGES;
