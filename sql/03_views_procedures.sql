-- ============================================================
-- Объекты БД citr_crm: представления и хранимые процедуры
-- СУБД: MySQL 8.0
-- ============================================================
USE citr_crm;

-- ---------- ПРЕДСТАВЛЕНИЯ ----------

-- Сделки в развёрнутом виде (JOIN пяти таблиц)
CREATE OR REPLACE VIEW v_deals_full AS
SELECT d.deal_id,
       d.title,
       c.client_id,
       c.client_name,
       seg.segment_name,
       u.user_id                       AS manager_id,
       u.full_name                     AS manager_name,
       s.stage_id,
       s.stage_name,
       s.probability,
       d.amount,
       ROUND(d.amount * s.probability / 100, 2) AS weighted_amount,
       d.expected_close,
       d.closed_at,
       d.updated_at
FROM deals d
JOIN clients     c ON c.client_id  = d.client_id
JOIN deal_stages s ON s.stage_id   = d.stage_id
JOIN users       u ON u.user_id    = d.manager_id
LEFT JOIN client_segments seg ON seg.segment_id = c.segment_id;

-- Воронка по менеджерам (агрегаты COUNT / SUM)
CREATE OR REPLACE VIEW v_manager_pipeline AS
SELECT u.user_id,
       u.full_name                                                AS manager_name,
       COUNT(d.deal_id)                                           AS deals_total,
       SUM(CASE WHEN s.is_final = 0 THEN 1 ELSE 0 END)            AS deals_open,
       COALESCE(SUM(CASE WHEN s.is_final = 0 THEN d.amount END),0) AS open_amount,
       ROUND(COALESCE(SUM(CASE WHEN s.is_final = 0
                         THEN d.amount * s.probability / 100 END),0), 2) AS forecast,
       SUM(CASE WHEN s.stage_name = 'Успешно закрыта' THEN 1 ELSE 0 END) AS deals_won,
       COALESCE(SUM(CASE WHEN s.stage_name = 'Успешно закрыта' THEN d.amount END),0) AS won_amount
FROM users u
JOIN roles r            ON r.role_id = u.role_id AND r.role_code = 'manager'
LEFT JOIN deals d       ON d.manager_id = u.user_id
LEFT JOIN deal_stages s ON s.stage_id = d.stage_id
GROUP BY u.user_id, u.full_name;

-- Карточка клиента для списка: основной контакт, число сделок, последний контакт
CREATE OR REPLACE VIEW v_clients_overview AS
SELECT c.client_id,
       c.client_type,
       c.client_name,
       c.inn,
       c.phone,
       c.city,
       seg.segment_name,
       u.full_name AS manager_name,
       (SELECT ct.full_name FROM contacts ct
         WHERE ct.client_id = c.client_id AND ct.is_primary = 1 LIMIT 1) AS main_contact,
       (SELECT COUNT(*) FROM deals d WHERE d.client_id = c.client_id)    AS deals_cnt,
       (SELECT MAX(i.happened_at) FROM interactions i
         WHERE i.client_id = c.client_id)                                AS last_touch
FROM clients c
LEFT JOIN client_segments seg ON seg.segment_id = c.segment_id
LEFT JOIN users u             ON u.user_id      = c.manager_id;

-- ---------- ХРАНИМЫЕ ПРОЦЕДУРЫ ----------
DELIMITER $$

-- 1. Создание сделки на первом этапе воронки
DROP PROCEDURE IF EXISTS sp_create_deal $$
CREATE PROCEDURE sp_create_deal(
    IN  p_client_id  INT UNSIGNED,
    IN  p_manager_id INT UNSIGNED,
    IN  p_title      VARCHAR(180),
    IN  p_amount     DECIMAL(12,2),
    IN  p_close_date DATE,
    OUT p_deal_id    INT UNSIGNED
)
BEGIN
    DECLARE v_first_stage TINYINT UNSIGNED;

    IF p_amount < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Сумма сделки не может быть отрицательной';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM clients WHERE client_id = p_client_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Клиент не найден';
    END IF;

    SELECT stage_id INTO v_first_stage FROM deal_stages ORDER BY sort_order LIMIT 1;

    SET @app_user_id = p_manager_id;
    INSERT INTO deals (client_id, manager_id, stage_id, title, amount, expected_close)
    VALUES (p_client_id, p_manager_id, v_first_stage, p_title, p_amount, p_close_date);
    SET p_deal_id = LAST_INSERT_ID();
END $$

-- 2. Перевод сделки на другой этап с проверками
DROP PROCEDURE IF EXISTS sp_change_deal_stage $$
CREATE PROCEDURE sp_change_deal_stage(
    IN p_deal_id   INT UNSIGNED,
    IN p_new_stage TINYINT UNSIGNED,
    IN p_user_id   INT UNSIGNED
)
BEGIN
    DECLARE v_is_final TINYINT DEFAULT NULL;
    DECLARE v_cur      TINYINT UNSIGNED;

    SELECT s.is_final, d.stage_id INTO v_is_final, v_cur
      FROM deals d JOIN deal_stages s ON s.stage_id = d.stage_id
     WHERE d.deal_id = p_deal_id;

    IF v_is_final IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Сделка не найдена';
    ELSEIF v_is_final = 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Сделка уже закрыта, смена этапа запрещена';
    ELSEIF NOT EXISTS (SELECT 1 FROM deal_stages WHERE stage_id = p_new_stage) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Указан несуществующий этап';
    ELSEIF v_cur = p_new_stage THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Сделка уже находится на этом этапе';
    END IF;

    SET @app_user_id = p_user_id;
    UPDATE deals SET stage_id = p_new_stage WHERE deal_id = p_deal_id;

    SELECT deal_id, title, stage_name, closed_at FROM v_deals_full WHERE deal_id = p_deal_id;
END $$

-- 3. Регистрация взаимодействия с клиентом
DROP PROCEDURE IF EXISTS sp_log_interaction $$
CREATE PROCEDURE sp_log_interaction(
    IN p_client_id INT UNSIGNED,
    IN p_deal_id   INT UNSIGNED,
    IN p_user_id   INT UNSIGNED,
    IN p_channel   VARCHAR(20),
    IN p_subject   VARCHAR(180),
    IN p_note      TEXT
)
BEGIN
    IF p_deal_id IS NOT NULL AND NOT EXISTS
       (SELECT 1 FROM deals WHERE deal_id = p_deal_id AND client_id = p_client_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Сделка не относится к указанному клиенту';
    END IF;

    INSERT INTO interactions (client_id, deal_id, user_id, channel, subject, result_note)
    VALUES (p_client_id, p_deal_id, p_user_id, p_channel, p_subject, p_note);

    SELECT LAST_INSERT_ID() AS interaction_id;
END $$

-- 4. Отчёт: движение сделок по этапам за период
DROP PROCEDURE IF EXISTS sp_stage_report $$
CREATE PROCEDURE sp_stage_report(IN p_from DATE, IN p_to DATE)
BEGIN
    SELECT s.stage_name,
           COUNT(h.history_id)              AS transitions,
           COUNT(DISTINCT h.deal_id)        AS deals,
           COALESCE(SUM(d.amount), 0)       AS amount
    FROM deal_stages s
    LEFT JOIN deal_stage_history h
           ON h.new_stage_id = s.stage_id
          AND h.changed_at >= p_from AND h.changed_at < p_to + INTERVAL 1 DAY
    LEFT JOIN deals d ON d.deal_id = h.deal_id
    GROUP BY s.stage_id, s.stage_name, s.sort_order
    ORDER BY s.sort_order;
END $$

DELIMITER ;
