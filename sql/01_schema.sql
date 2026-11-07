-- ============================================================
-- База данных: citr_crm
-- СУБД: MySQL 8.0 (InnoDB, utf8mb4)
-- Назначение: учёт клиентов, контактов, сделок и коммуникаций ООО «ЦИТР»
-- ============================================================
DROP DATABASE IF EXISTS citr_crm;
CREATE DATABASE citr_crm CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE citr_crm;

-- 1. Роли пользователей приложения
CREATE TABLE roles (
    role_id      TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    role_code    VARCHAR(20)  NOT NULL UNIQUE,
    role_name    VARCHAR(60)  NOT NULL,
    description  VARCHAR(255) NULL
) ENGINE=InnoDB;

-- 2. Пользователи приложения (сотрудники ЦИТР)
CREATE TABLE users (
    user_id        INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    login          VARCHAR(40)  NOT NULL UNIQUE,
    full_name      VARCHAR(120) NOT NULL,
    email          VARCHAR(120) NOT NULL UNIQUE,
    password_hash  CHAR(64)     NOT NULL,
    role_id        TINYINT UNSIGNED NOT NULL,
    is_active      TINYINT(1)   NOT NULL DEFAULT 1,
    last_login_at  DATETIME     NULL,
    created_at     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_users_role FOREIGN KEY (role_id) REFERENCES roles(role_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- 3. Сегменты клиентской базы (справочник)
CREATE TABLE client_segments (
    segment_id   TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    segment_name VARCHAR(60)  NOT NULL UNIQUE,
    description  VARCHAR(255) NULL
) ENGINE=InnoDB;

-- 4. Клиенты (организации и частные заказчики)
CREATE TABLE clients (
    client_id    INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    client_type  ENUM('ЮЛ','ИП','ФЛ') NOT NULL DEFAULT 'ЮЛ',
    client_name  VARCHAR(150) NOT NULL,
    inn          VARCHAR(12)  NULL UNIQUE,
    phone        VARCHAR(20)  NULL,
    email        VARCHAR(120) NULL,
    city         VARCHAR(60)  NULL,
    segment_id   TINYINT UNSIGNED NULL,
    manager_id   INT UNSIGNED NULL,
    created_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_clients_segment FOREIGN KEY (segment_id) REFERENCES client_segments(segment_id)
        ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT fk_clients_manager FOREIGN KEY (manager_id) REFERENCES users(user_id)
        ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT chk_clients_inn CHECK (inn IS NULL OR inn REGEXP '^[0-9]{10}([0-9]{2})?$')
) ENGINE=InnoDB;
CREATE INDEX ix_clients_name ON clients(client_name);

-- 5. Контактные лица клиентов
CREATE TABLE contacts (
    contact_id   INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    client_id    INT UNSIGNED NOT NULL,
    full_name    VARCHAR(120) NOT NULL,
    job_title    VARCHAR(80)  NULL,
    phone        VARCHAR(20)  NULL,
    email        VARCHAR(120) NULL,
    is_primary   TINYINT(1)   NOT NULL DEFAULT 0,
    CONSTRAINT fk_contacts_client FOREIGN KEY (client_id) REFERENCES clients(client_id)
        ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- 6. Этапы воронки продаж (справочник)
CREATE TABLE deal_stages (
    stage_id     TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    stage_name   VARCHAR(60) NOT NULL UNIQUE,
    sort_order   TINYINT UNSIGNED NOT NULL,
    probability  TINYINT UNSIGNED NOT NULL DEFAULT 0,
    is_final     TINYINT(1) NOT NULL DEFAULT 0,
    CONSTRAINT chk_stage_prob CHECK (probability BETWEEN 0 AND 100)
) ENGINE=InnoDB;

-- 7. Сделки
CREATE TABLE deals (
    deal_id        INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    client_id      INT UNSIGNED NOT NULL,
    manager_id     INT UNSIGNED NOT NULL,
    stage_id       TINYINT UNSIGNED NOT NULL,
    title          VARCHAR(180) NOT NULL,
    amount         DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    expected_close DATE NULL,
    closed_at      DATETIME NULL,
    created_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_deals_client  FOREIGN KEY (client_id)  REFERENCES clients(client_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_deals_manager FOREIGN KEY (manager_id) REFERENCES users(user_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_deals_stage   FOREIGN KEY (stage_id)   REFERENCES deal_stages(stage_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_deals_amount CHECK (amount >= 0)
) ENGINE=InnoDB;
CREATE INDEX ix_deals_stage ON deals(stage_id);

-- 8. Взаимодействия с клиентом (звонки, письма, встречи)
CREATE TABLE interactions (
    interaction_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    client_id      INT UNSIGNED NOT NULL,
    deal_id        INT UNSIGNED NULL,
    user_id        INT UNSIGNED NOT NULL,
    channel        ENUM('звонок','e-mail','встреча','мессенджер') NOT NULL,
    subject        VARCHAR(180) NOT NULL,
    result_note    TEXT NULL,
    happened_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_inter_client FOREIGN KEY (client_id) REFERENCES clients(client_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_inter_deal   FOREIGN KEY (deal_id)   REFERENCES deals(deal_id)
        ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT fk_inter_user   FOREIGN KEY (user_id)   REFERENCES users(user_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- 9. Журнал смены этапов сделки (заполняется триггером)
CREATE TABLE deal_stage_history (
    history_id    INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    deal_id       INT UNSIGNED NOT NULL,
    old_stage_id  TINYINT UNSIGNED NULL,
    new_stage_id  TINYINT UNSIGNED NOT NULL,
    changed_by    INT UNSIGNED NULL,
    changed_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_hist_deal FOREIGN KEY (deal_id) REFERENCES deals(deal_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_hist_old  FOREIGN KEY (old_stage_id) REFERENCES deal_stages(stage_id),
    CONSTRAINT fk_hist_new  FOREIGN KEY (new_stage_id) REFERENCES deal_stages(stage_id),
    CONSTRAINT fk_hist_user FOREIGN KEY (changed_by) REFERENCES users(user_id)
        ON DELETE SET NULL
) ENGINE=InnoDB;
