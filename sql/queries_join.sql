-- ============================================================
-- Запросы с JOIN для БД citr_crm (MySQL 8.0)
-- ============================================================
USE citr_crm;

-- 1. INNER JOIN: сделки с наименованием клиента
SELECT d.deal_id, LEFT(d.title, 40) AS deal, c.client_name, d.amount
FROM deals d
INNER JOIN clients c ON c.client_id = d.client_id
ORDER BY d.amount DESC;

-- 2. JOIN из четырёх таблиц: журнал взаимодействий
SELECT i.happened_at, c.client_name, u.full_name AS employee,
       i.channel, COALESCE(d.deal_id, '—') AS deal
FROM interactions i
JOIN clients c ON c.client_id = i.client_id
JOIN users   u ON u.user_id   = i.user_id
LEFT JOIN deals d ON d.deal_id = i.deal_id
ORDER BY i.happened_at DESC LIMIT 8;

-- 3. LEFT JOIN: все клиенты, включая клиентов без сделок
SELECT c.client_id, c.client_name, COUNT(d.deal_id) AS deals_cnt,
       COALESCE(SUM(d.amount), 0) AS total
FROM clients c
LEFT JOIN deals d ON d.client_id = c.client_id
GROUP BY c.client_id, c.client_name ORDER BY total;

-- 3a. LEFT JOIN + IS NULL: клиенты без контактных лиц
SELECT c.client_name, c.city
FROM clients c LEFT JOIN contacts ct ON ct.client_id = c.client_id
WHERE ct.contact_id IS NULL;

-- 4. RIGHT JOIN: все сегменты, включая пустые
SELECT seg.segment_name, COUNT(c.client_id) AS clients_cnt
FROM clients c
RIGHT JOIN client_segments seg ON seg.segment_id = c.segment_id
GROUP BY seg.segment_id, seg.segment_name
ORDER BY clients_cnt DESC;

-- 4a. RIGHT JOIN: все этапы воронки, включая этапы без сделок
SELECT s.stage_name, COUNT(d.deal_id) AS deals_cnt, COALESCE(SUM(d.amount), 0) AS amount
FROM deals d
RIGHT JOIN deal_stages s ON s.stage_id = d.stage_id
GROUP BY s.stage_id, s.stage_name ORDER BY s.stage_id;

-- 5. GROUP BY + HAVING: менеджеры, у которых больше двух сделок
SELECT u.full_name AS manager, COUNT(*) AS deals_cnt,
       ROUND(AVG(d.amount), 2) AS avg_amount, SUM(d.amount) AS total
FROM deals d
JOIN users u ON u.user_id = d.manager_id
GROUP BY u.user_id, u.full_name
HAVING COUNT(*) > 2
ORDER BY deals_cnt DESC;
