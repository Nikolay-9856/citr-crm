-- MySQL dump 10.13  Distrib 8.0.46, for Linux (x86_64)
--
-- Host: localhost    Database: citr_crm
-- ------------------------------------------------------
-- Server version	8.0.46-0ubuntu0.24.04.4

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Current Database: `citr_crm`
--

CREATE DATABASE /*!32312 IF NOT EXISTS*/ `citr_crm` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;

USE `citr_crm`;

--
-- Table structure for table `client_segments`
--

DROP TABLE IF EXISTS `client_segments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `client_segments` (
  `segment_id` tinyint unsigned NOT NULL AUTO_INCREMENT,
  `segment_name` varchar(60) NOT NULL,
  `description` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`segment_id`),
  UNIQUE KEY `segment_name` (`segment_name`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `client_segments`
--

LOCK TABLES `client_segments` WRITE;
/*!40000 ALTER TABLE `client_segments` DISABLE KEYS */;
INSERT INTO `client_segments` VALUES (1,'Промышленность','Производственные предприятия и технопарки'),(2,'Девелопмент и УК','Застройщики, управляющие и эксплуатирующие компании'),(3,'Бюджетный сектор','Государственные и муниципальные учреждения'),(4,'Малый бизнес','Небольшие компании и ИП'),(5,'Частные заказчики','Физические лица'),(6,'Медицина','Клиники и медицинские центры (новое направление)');
/*!40000 ALTER TABLE `client_segments` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `clients`
--

DROP TABLE IF EXISTS `clients`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `clients` (
  `client_id` int unsigned NOT NULL AUTO_INCREMENT,
  `client_type` enum('ЮЛ','ИП','ФЛ') NOT NULL DEFAULT 'ЮЛ',
  `client_name` varchar(150) NOT NULL,
  `inn` varchar(12) DEFAULT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `email` varchar(120) DEFAULT NULL,
  `city` varchar(60) DEFAULT NULL,
  `segment_id` tinyint unsigned DEFAULT NULL,
  `manager_id` int unsigned DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`client_id`),
  UNIQUE KEY `inn` (`inn`),
  KEY `fk_clients_segment` (`segment_id`),
  KEY `fk_clients_manager` (`manager_id`),
  KEY `ix_clients_name` (`client_name`),
  CONSTRAINT `fk_clients_manager` FOREIGN KEY (`manager_id`) REFERENCES `users` (`user_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_clients_segment` FOREIGN KEY (`segment_id`) REFERENCES `client_segments` (`segment_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `chk_clients_inn` CHECK (((`inn` is null) or regexp_like(`inn`,_utf8mb4'^[0-9]{10}([0-9]{2})?$')))
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `clients`
--

LOCK TABLES `clients` WRITE;
/*!40000 ALTER TABLE `clients` DISABLE KEYS */;
INSERT INTO `clients` VALUES (1,'ЮЛ','АО «Микролит-Электроника»','7735600111','+7 495 531-10-20','zakupki@mikrolit.test','Зеленоград',1,2,'2026-11-06 19:19:49','2026-11-06 19:19:49'),(2,'ЮЛ','ООО «УК «Северный квартал»»','5044112233','+7 495 988-44-01','office@sevkvartal.test','Солнечногорск',2,3,'2026-11-06 19:19:49','2026-11-06 19:19:49'),(3,'ЮЛ','ООО «ТехноПарк-Сервис»','7735611987','+7 499 710-25-36','info@tp-service.test','Зеленоград',1,2,'2026-11-06 19:19:49','2026-11-06 19:19:49'),(4,'ЮЛ','ГБУ «Центр досуга «Крюково»»','7735005544','+7 499 735-12-12','cd-kryukovo@mos.test','Москва',3,4,'2026-11-06 19:19:49','2026-11-06 19:19:49'),(5,'ИП','ИП Сафонов Денис Петрович','773512345678','+7 916 204-55-71','safonov.dp@mail.test','Химки',4,3,'2026-11-06 19:19:49','2026-11-06 19:19:49'),(6,'ЮЛ','ООО «СтройИнвест-Лобня»','5025098765','+7 495 577-03-30','tender@si-lobnya.test','Лобня',2,4,'2026-11-06 19:19:49','2026-11-06 19:19:49'),(7,'ФЛ','Ермакова Наталья Юрьевна',NULL,'+7 925 330-18-42','ermakova.ny@mail.test','Зеленоград',5,2,'2026-11-06 19:19:49','2026-11-06 19:19:49'),(8,'ЮЛ','ООО «Логистик Парк Дурыкино»','5044223344','+7 495 640-90-90','it@lp-durykino.test','Солнечногорск',1,3,'2026-11-06 19:19:49','2026-11-06 19:19:49'),(9,'ЮЛ','ООО «Кофейня на Панфиловском»','7735699001','+7 903 111-22-33','boss@coffee-panf.test','Зеленоград',4,NULL,'2026-11-06 19:19:49','2026-11-06 19:19:49');
/*!40000 ALTER TABLE `clients` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_clients_before_update` BEFORE UPDATE ON `clients` FOR EACH ROW BEGIN
    SET NEW.updated_at = NOW();
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `contacts`
--

DROP TABLE IF EXISTS `contacts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `contacts` (
  `contact_id` int unsigned NOT NULL AUTO_INCREMENT,
  `client_id` int unsigned NOT NULL,
  `full_name` varchar(120) NOT NULL,
  `job_title` varchar(80) DEFAULT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `email` varchar(120) DEFAULT NULL,
  `is_primary` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`contact_id`),
  KEY `fk_contacts_client` (`client_id`),
  CONSTRAINT `fk_contacts_client` FOREIGN KEY (`client_id`) REFERENCES `clients` (`client_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `contacts`
--

LOCK TABLES `contacts` WRITE;
/*!40000 ALTER TABLE `contacts` DISABLE KEYS */;
INSERT INTO `contacts` VALUES (1,1,'Корнеев Алексей Дмитриевич','Главный инженер','+7 495 531-10-21','korneev@mikrolit.test',1),(2,1,'Шилова Марина Игоревна','Специалист по закупкам','+7 495 531-10-24','shilova@mikrolit.test',0),(3,2,'Панов Сергей Валерьевич','Директор','+7 495 988-44-02','panov@sevkvartal.test',1),(4,3,'Тарасова Екатерина Олеговна','Офис-менеджер','+7 499 710-25-37','tarasova@tp-service.test',1),(5,4,'Яковлев Роман Николаевич','Заместитель директора по АХЧ','+7 499 735-12-14','yakovlev@mos.test',1),(6,5,'Сафонов Денис Петрович','Индивидуальный предприниматель','+7 916 204-55-71','safonov.dp@mail.test',1),(7,6,'Голубев Артём Сергеевич','Руководитель службы эксплуатации','+7 495 577-03-31','golubev@si-lobnya.test',1),(8,6,'Нестерова Ирина Павловна','Инженер ПТО','+7 495 577-03-35','nesterova@si-lobnya.test',0),(9,8,'Фомин Владислав Игоревич','Начальник ИТ-службы','+7 495 640-90-91','fomin@lp-durykino.test',1);
/*!40000 ALTER TABLE `contacts` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `deal_stage_history`
--

DROP TABLE IF EXISTS `deal_stage_history`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `deal_stage_history` (
  `history_id` int unsigned NOT NULL AUTO_INCREMENT,
  `deal_id` int unsigned NOT NULL,
  `old_stage_id` tinyint unsigned DEFAULT NULL,
  `new_stage_id` tinyint unsigned NOT NULL,
  `changed_by` int unsigned DEFAULT NULL,
  `changed_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`history_id`),
  KEY `fk_hist_deal` (`deal_id`),
  KEY `fk_hist_old` (`old_stage_id`),
  KEY `fk_hist_new` (`new_stage_id`),
  KEY `fk_hist_user` (`changed_by`),
  CONSTRAINT `fk_hist_deal` FOREIGN KEY (`deal_id`) REFERENCES `deals` (`deal_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_hist_new` FOREIGN KEY (`new_stage_id`) REFERENCES `deal_stages` (`stage_id`),
  CONSTRAINT `fk_hist_old` FOREIGN KEY (`old_stage_id`) REFERENCES `deal_stages` (`stage_id`),
  CONSTRAINT `fk_hist_user` FOREIGN KEY (`changed_by`) REFERENCES `users` (`user_id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `deal_stage_history`
--

LOCK TABLES `deal_stage_history` WRITE;
/*!40000 ALTER TABLE `deal_stage_history` DISABLE KEYS */;
INSERT INTO `deal_stage_history` VALUES (1,1,3,4,2,'2026-10-21 16:40:00'),(2,3,4,5,3,'2026-10-09 15:20:00'),(3,6,3,6,3,'2026-09-26 11:30:00'),(4,11,NULL,1,2,'2026-11-06 19:19:49'),(5,4,2,3,2,'2026-11-06 19:19:49'),(6,9,4,5,3,'2026-11-06 19:19:50'),(8,2,3,4,1,'2026-11-06 19:19:55');
/*!40000 ALTER TABLE `deal_stage_history` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `deal_stages`
--

DROP TABLE IF EXISTS `deal_stages`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `deal_stages` (
  `stage_id` tinyint unsigned NOT NULL AUTO_INCREMENT,
  `stage_name` varchar(60) NOT NULL,
  `sort_order` tinyint unsigned NOT NULL,
  `probability` tinyint unsigned NOT NULL DEFAULT '0',
  `is_final` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`stage_id`),
  UNIQUE KEY `stage_name` (`stage_name`),
  CONSTRAINT `chk_stage_prob` CHECK ((`probability` between 0 and 100))
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `deal_stages`
--

LOCK TABLES `deal_stages` WRITE;
/*!40000 ALTER TABLE `deal_stages` DISABLE KEYS */;
INSERT INTO `deal_stages` VALUES (1,'Новый лид',1,10,0),(2,'Квалификация',2,25,0),(3,'Коммерческое предложение',3,45,0),(4,'Переговоры',4,70,0),(5,'Успешно закрыта',5,100,1),(6,'Проиграна',6,0,1);
/*!40000 ALTER TABLE `deal_stages` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `deals`
--

DROP TABLE IF EXISTS `deals`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `deals` (
  `deal_id` int unsigned NOT NULL AUTO_INCREMENT,
  `client_id` int unsigned NOT NULL,
  `manager_id` int unsigned NOT NULL,
  `stage_id` tinyint unsigned NOT NULL,
  `title` varchar(180) NOT NULL,
  `amount` decimal(12,2) NOT NULL DEFAULT '0.00',
  `expected_close` date DEFAULT NULL,
  `closed_at` datetime DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`deal_id`),
  KEY `fk_deals_client` (`client_id`),
  KEY `fk_deals_manager` (`manager_id`),
  KEY `ix_deals_stage` (`stage_id`),
  CONSTRAINT `fk_deals_client` FOREIGN KEY (`client_id`) REFERENCES `clients` (`client_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_deals_manager` FOREIGN KEY (`manager_id`) REFERENCES `users` (`user_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_deals_stage` FOREIGN KEY (`stage_id`) REFERENCES `deal_stages` (`stage_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `chk_deals_amount` CHECK ((`amount` >= 0))
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `deals`
--

LOCK TABLES `deals` WRITE;
/*!40000 ALTER TABLE `deals` DISABLE KEYS */;
INSERT INTO `deals` VALUES (1,1,2,4,'Модернизация СКС производственного корпуса №2',1850000.00,'2026-11-28',NULL,'2026-09-08 10:15:00','2026-10-21 16:40:00'),(2,1,2,4,'Сервисное обслуживание серверной, договор на 12 мес.',598000.00,'2026-12-15',NULL,'2026-10-02 11:00:00','2026-11-06 19:19:55'),(3,2,3,5,'Система видеонаблюдения ЖК (4 корпуса)',2390000.00,'2026-10-10','2026-10-09 15:20:00','2026-08-18 09:30:00','2026-10-09 15:20:00'),(4,3,2,3,'Wi-Fi покрытие бизнес-центра',418500.00,'2026-12-20',NULL,'2026-10-14 14:45:00','2026-11-06 19:19:49'),(5,4,4,3,'Обновление АРМ и сетевого оборудования',736200.00,'2026-12-05',NULL,'2026-09-29 13:10:00','2026-10-22 09:50:00'),(6,5,3,6,'Монтаж СКУД в магазине',142000.00,'2026-09-30','2026-09-26 11:30:00','2026-08-25 16:00:00','2026-09-26 11:30:00'),(7,6,4,1,'Диспетчеризация инженерных систем ТЦ',3120000.00,'2027-02-15',NULL,'2026-10-27 10:05:00','2026-10-27 10:05:00'),(8,7,2,5,'Умный дом: слаботочные сети квартиры',187400.00,'2026-10-01','2026-09-30 17:00:00','2026-09-02 12:20:00','2026-09-30 17:00:00'),(9,8,3,5,'Резервирование каналов связи складского комплекса',965000.00,'2026-11-30','2026-11-06 19:19:50','2026-09-15 15:00:00','2026-11-06 19:19:50'),(10,2,3,2,'Домофония и контроль доступа, корпус 5',540000.00,'2027-01-20',NULL,'2026-10-30 09:40:00','2026-10-30 09:40:00'),(11,9,2,1,'Видеонаблюдение зала и кассовой зоны',168000.00,'2026-12-25',NULL,'2026-11-06 19:19:49','2026-11-06 19:19:49');
/*!40000 ALTER TABLE `deals` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_deals_insert_audit` AFTER INSERT ON `deals` FOR EACH ROW BEGIN
    INSERT INTO deal_stage_history (deal_id, old_stage_id, new_stage_id, changed_by)
    VALUES (NEW.deal_id, NULL, NEW.stage_id, COALESCE(@app_user_id, NEW.manager_id));
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_deals_before_update` BEFORE UPDATE ON `deals` FOR EACH ROW BEGIN
    DECLARE v_final TINYINT;
    SET NEW.updated_at = NOW();
    IF NOT (OLD.stage_id <=> NEW.stage_id) THEN
        SELECT is_final INTO v_final FROM deal_stages WHERE stage_id = NEW.stage_id;
        SET NEW.closed_at = IF(v_final = 1, NOW(), NULL);
    END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_deals_stage_audit` AFTER UPDATE ON `deals` FOR EACH ROW BEGIN
    IF NOT (OLD.stage_id <=> NEW.stage_id) THEN
        INSERT INTO deal_stage_history (deal_id, old_stage_id, new_stage_id, changed_by)
        VALUES (NEW.deal_id, OLD.stage_id, NEW.stage_id, @app_user_id);
    END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `interactions`
--

DROP TABLE IF EXISTS `interactions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `interactions` (
  `interaction_id` int unsigned NOT NULL AUTO_INCREMENT,
  `client_id` int unsigned NOT NULL,
  `deal_id` int unsigned DEFAULT NULL,
  `user_id` int unsigned NOT NULL,
  `channel` enum('звонок','e-mail','встреча','мессенджер') NOT NULL,
  `subject` varchar(180) NOT NULL,
  `result_note` text,
  `happened_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`interaction_id`),
  KEY `fk_inter_client` (`client_id`),
  KEY `fk_inter_deal` (`deal_id`),
  KEY `fk_inter_user` (`user_id`),
  CONSTRAINT `fk_inter_client` FOREIGN KEY (`client_id`) REFERENCES `clients` (`client_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_inter_deal` FOREIGN KEY (`deal_id`) REFERENCES `deals` (`deal_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_inter_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `interactions`
--

LOCK TABLES `interactions` WRITE;
/*!40000 ALTER TABLE `interactions` DISABLE KEYS */;
INSERT INTO `interactions` VALUES (1,1,1,2,'встреча','Обследование корпуса №2','Сняты замеры трасс, согласован перечень помещений','2026-09-12 11:00:00'),(2,1,1,2,'e-mail','Направлено КП с двумя вариантами','Клиент выбрал вариант с категорией 6A','2026-10-03 15:30:00'),(3,1,2,2,'звонок','Уточнение SLA по выездам','Нужна реакция 4 часа в рабочее время','2026-10-17 10:20:00'),(4,2,3,3,'встреча','Подписание договора','Договор подписан, аванс 30%','2026-10-09 14:00:00'),(5,3,4,2,'звонок','Первичный контакт по Wi-Fi','Запрошены поэтажные планы','2026-10-14 14:45:00'),(6,4,5,4,'e-mail','Запрос спецификации АРМ','Получено ТЗ от заказчика','2026-10-01 09:15:00'),(7,5,6,3,'мессенджер','Отказ от проекта','Клиент выбрал более дешёвого подрядчика','2026-09-26 11:20:00'),(8,6,7,4,'звонок','Входящий запрос с сайта','Назначена встреча на объекте','2026-10-27 10:00:00'),(9,7,8,2,'встреча','Сдача работ','Подписан акт, претензий нет','2026-09-30 16:30:00'),(10,8,9,3,'встреча','Техническое совещание','Согласована схема с двумя провайдерами','2026-10-28 13:00:00'),(11,9,NULL,2,'звонок','Холодный звонок','Интерес к видеонаблюдению, перезвонить в декабре','2026-10-29 12:10:00'),(12,3,4,2,'e-mail','Отправлено КП на Wi-Fi','Клиент просит смету на 3 этажа','2026-11-06 19:19:50');
/*!40000 ALTER TABLE `interactions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `roles`
--

DROP TABLE IF EXISTS `roles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `roles` (
  `role_id` tinyint unsigned NOT NULL AUTO_INCREMENT,
  `role_code` varchar(20) NOT NULL,
  `role_name` varchar(60) NOT NULL,
  `description` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`role_id`),
  UNIQUE KEY `role_code` (`role_code`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `roles`
--

LOCK TABLES `roles` WRITE;
/*!40000 ALTER TABLE `roles` DISABLE KEYS */;
INSERT INTO `roles` VALUES (1,'admin','Администратор','Ведение справочников, пользователей, полный доступ'),(2,'manager','Менеджер по работе с клиентами','Ведение клиентов, сделок и коммуникаций'),(3,'analyst','Руководитель отдела продаж','Просмотр воронки и аналитических отчётов');
/*!40000 ALTER TABLE `roles` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `user_id` int unsigned NOT NULL AUTO_INCREMENT,
  `login` varchar(40) NOT NULL,
  `full_name` varchar(120) NOT NULL,
  `email` varchar(120) NOT NULL,
  `password_hash` char(64) NOT NULL,
  `password_salt` char(32) NOT NULL DEFAULT '',
  `role_id` tinyint unsigned NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `last_login_at` datetime DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`user_id`),
  UNIQUE KEY `login` (`login`),
  UNIQUE KEY `email` (`email`),
  KEY `fk_users_role` (`role_id`),
  CONSTRAINT `fk_users_role` FOREIGN KEY (`role_id`) REFERENCES `roles` (`role_id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES (1,'voronin','Воронин Игорь Сергеевич','voronin@citr.local','51b90ebae424aaa2866510e9afbe59fad07002daa9312d64b7b121209c1d1f92','291580f272a0cd4fc47d88969a35ae3a',1,1,'2026-11-06 19:19:54','2026-11-06 19:19:49'),(2,'belova','Белова Анна Викторовна','belova@citr.local','f2ee75e9ef2c8a1d6f7d856d272cbfd3a9264505c03fed8d1439cb2a253cd760','4a9ad2db871a5d141a29d41b95025f0d',2,1,NULL,'2026-11-06 19:19:49'),(3,'gusev','Гусев Павел Олегович','gusev@citr.local','347bf4da31fcf4de65c73def96a7f83a491b3889a155dfa4f7d6d661ddb48cd1','4b18bcddf3354f5dcb5a4229975aec7c',2,1,NULL,'2026-11-06 19:19:49'),(4,'litvinova','Литвинова Ольга Андреевна','litvinova@citr.local','31669036901ff611620aaf9f622553b2cbdafdeabf5f2f90ef50b159a9adc4ef','97e4ff7e916630a4b0e231c95ec811d1',2,1,NULL,'2026-11-06 19:19:49'),(5,'martynov','Мартынов Кирилл Евгеньевич','martynov@citr.local','6f80d444133883f148df83ed59eeab7ac04b5ae1b0e0267d62814ae172537300','a9144e684c8eb728cc8dbc8552c3a8ff',3,1,NULL,'2026-11-06 19:19:49'),(6,'orlova','Орлова Светлана Игоревна','orlova@citr.local','e44b561c7b61f2e33915030d758951b862510d212f66841e8376f63def780e55','c3b58af295c7447d4e7896b29f55d40b',2,1,'2026-11-06 19:19:57','2026-11-06 19:19:57');
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Temporary view structure for view `v_clients_overview`
--

DROP TABLE IF EXISTS `v_clients_overview`;
/*!50001 DROP VIEW IF EXISTS `v_clients_overview`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_clients_overview` AS SELECT 
 1 AS `client_id`,
 1 AS `client_type`,
 1 AS `client_name`,
 1 AS `inn`,
 1 AS `phone`,
 1 AS `city`,
 1 AS `segment_name`,
 1 AS `manager_name`,
 1 AS `main_contact`,
 1 AS `deals_cnt`,
 1 AS `last_touch`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_deals_full`
--

DROP TABLE IF EXISTS `v_deals_full`;
/*!50001 DROP VIEW IF EXISTS `v_deals_full`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_deals_full` AS SELECT 
 1 AS `deal_id`,
 1 AS `title`,
 1 AS `client_id`,
 1 AS `client_name`,
 1 AS `segment_name`,
 1 AS `manager_id`,
 1 AS `manager_name`,
 1 AS `stage_id`,
 1 AS `stage_name`,
 1 AS `probability`,
 1 AS `amount`,
 1 AS `weighted_amount`,
 1 AS `expected_close`,
 1 AS `closed_at`,
 1 AS `updated_at`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_manager_pipeline`
--

DROP TABLE IF EXISTS `v_manager_pipeline`;
/*!50001 DROP VIEW IF EXISTS `v_manager_pipeline`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_manager_pipeline` AS SELECT 
 1 AS `user_id`,
 1 AS `manager_name`,
 1 AS `deals_total`,
 1 AS `deals_open`,
 1 AS `open_amount`,
 1 AS `forecast`,
 1 AS `deals_won`,
 1 AS `won_amount`*/;
SET character_set_client = @saved_cs_client;

--
-- Dumping routines for database 'citr_crm'
--
/*!50003 DROP PROCEDURE IF EXISTS `sp_change_deal_stage` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_change_deal_stage`(
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
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_create_deal` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_create_deal`(
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
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_get_auth_data` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_get_auth_data`(IN p_login VARCHAR(40))
BEGIN
    SELECT u.user_id, u.full_name, u.password_hash, u.password_salt,
           u.is_active, r.role_code, r.role_name
      FROM users u JOIN roles r ON r.role_id = u.role_id
     WHERE u.login = p_login;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_log_interaction` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_log_interaction`(
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
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_register_user` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_register_user`(
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
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_stage_report` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_stage_report`(IN p_from DATE, IN p_to DATE)
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
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Current Database: `citr_crm`
--

USE `citr_crm`;

--
-- Final view structure for view `v_clients_overview`
--

/*!50001 DROP VIEW IF EXISTS `v_clients_overview`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_clients_overview` AS select `c`.`client_id` AS `client_id`,`c`.`client_type` AS `client_type`,`c`.`client_name` AS `client_name`,`c`.`inn` AS `inn`,`c`.`phone` AS `phone`,`c`.`city` AS `city`,`seg`.`segment_name` AS `segment_name`,`u`.`full_name` AS `manager_name`,(select `ct`.`full_name` from `contacts` `ct` where ((`ct`.`client_id` = `c`.`client_id`) and (`ct`.`is_primary` = 1)) limit 1) AS `main_contact`,(select count(0) from `deals` `d` where (`d`.`client_id` = `c`.`client_id`)) AS `deals_cnt`,(select max(`i`.`happened_at`) from `interactions` `i` where (`i`.`client_id` = `c`.`client_id`)) AS `last_touch` from ((`clients` `c` left join `client_segments` `seg` on((`seg`.`segment_id` = `c`.`segment_id`))) left join `users` `u` on((`u`.`user_id` = `c`.`manager_id`))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_deals_full`
--

/*!50001 DROP VIEW IF EXISTS `v_deals_full`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_deals_full` AS select `d`.`deal_id` AS `deal_id`,`d`.`title` AS `title`,`c`.`client_id` AS `client_id`,`c`.`client_name` AS `client_name`,`seg`.`segment_name` AS `segment_name`,`u`.`user_id` AS `manager_id`,`u`.`full_name` AS `manager_name`,`s`.`stage_id` AS `stage_id`,`s`.`stage_name` AS `stage_name`,`s`.`probability` AS `probability`,`d`.`amount` AS `amount`,round(((`d`.`amount` * `s`.`probability`) / 100),2) AS `weighted_amount`,`d`.`expected_close` AS `expected_close`,`d`.`closed_at` AS `closed_at`,`d`.`updated_at` AS `updated_at` from ((((`deals` `d` join `clients` `c` on((`c`.`client_id` = `d`.`client_id`))) join `deal_stages` `s` on((`s`.`stage_id` = `d`.`stage_id`))) join `users` `u` on((`u`.`user_id` = `d`.`manager_id`))) left join `client_segments` `seg` on((`seg`.`segment_id` = `c`.`segment_id`))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_manager_pipeline`
--

/*!50001 DROP VIEW IF EXISTS `v_manager_pipeline`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_manager_pipeline` AS select `u`.`user_id` AS `user_id`,`u`.`full_name` AS `manager_name`,count(`d`.`deal_id`) AS `deals_total`,sum((case when (`s`.`is_final` = 0) then 1 else 0 end)) AS `deals_open`,coalesce(sum((case when (`s`.`is_final` = 0) then `d`.`amount` end)),0) AS `open_amount`,round(coalesce(sum((case when (`s`.`is_final` = 0) then ((`d`.`amount` * `s`.`probability`) / 100) end)),0),2) AS `forecast`,sum((case when (`s`.`stage_name` = 'Успешно закрыта') then 1 else 0 end)) AS `deals_won`,coalesce(sum((case when (`s`.`stage_name` = 'Успешно закрыта') then `d`.`amount` end)),0) AS `won_amount` from (((`users` `u` join `roles` `r` on(((`r`.`role_id` = `u`.`role_id`) and (`r`.`role_code` = 'manager')))) left join `deals` `d` on((`d`.`manager_id` = `u`.`user_id`))) left join `deal_stages` `s` on((`s`.`stage_id` = `d`.`stage_id`))) group by `u`.`user_id`,`u`.`full_name` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-11-06 19:21:06
