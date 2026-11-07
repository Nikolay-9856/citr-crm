-- ============================================================
-- Триггеры БД citr_crm: аудит смены этапов, авто-timestamp
-- СУБД: MySQL 8.0
-- ============================================================
USE citr_crm;

DELIMITER $$

-- ---------- ТРИГГЕРЫ ----------

-- Аудит: запись в журнал при смене этапа сделки
DROP TRIGGER IF EXISTS trg_deals_stage_audit $$
CREATE TRIGGER trg_deals_stage_audit
AFTER UPDATE ON deals
FOR EACH ROW
BEGIN
    IF NOT (OLD.stage_id <=> NEW.stage_id) THEN
        INSERT INTO deal_stage_history (deal_id, old_stage_id, new_stage_id, changed_by)
        VALUES (NEW.deal_id, OLD.stage_id, NEW.stage_id, @app_user_id);
    END IF;
END $$

-- Журнал: фиксация первого этапа при создании сделки
DROP TRIGGER IF EXISTS trg_deals_insert_audit $$
CREATE TRIGGER trg_deals_insert_audit
AFTER INSERT ON deals
FOR EACH ROW
BEGIN
    INSERT INTO deal_stage_history (deal_id, old_stage_id, new_stage_id, changed_by)
    VALUES (NEW.deal_id, NULL, NEW.stage_id, COALESCE(@app_user_id, NEW.manager_id));
END $$

-- Авто-timestamp и дата закрытия для сделок
DROP TRIGGER IF EXISTS trg_deals_before_update $$
CREATE TRIGGER trg_deals_before_update
BEFORE UPDATE ON deals
FOR EACH ROW
BEGIN
    DECLARE v_final TINYINT;
    SET NEW.updated_at = NOW();
    IF NOT (OLD.stage_id <=> NEW.stage_id) THEN
        SELECT is_final INTO v_final FROM deal_stages WHERE stage_id = NEW.stage_id;
        SET NEW.closed_at = IF(v_final = 1, NOW(), NULL);
    END IF;
END $$

-- Авто-timestamp для карточки клиента
DROP TRIGGER IF EXISTS trg_clients_before_update $$
CREATE TRIGGER trg_clients_before_update
BEFORE UPDATE ON clients
FOR EACH ROW
BEGIN
    SET NEW.updated_at = NOW();
END $$

DELIMITER ;
