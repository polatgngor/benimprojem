-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Anamakine: 127.0.0.1
-- Üretim Zamanı: 09 Ara 2025, 21:30:49
-- Sunucu sürümü: 10.4.32-MariaDB
-- PHP Sürümü: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Veritabanı: `taksibu`
--

-- --------------------------------------------------------

--
-- Tablo için tablo yapısı `announcements`
--

CREATE TABLE `announcements` (
  `id` int(11) NOT NULL,
  `title` varchar(255) NOT NULL,
  `content` text DEFAULT NULL,
  `image_url` varchar(500) DEFAULT NULL,
  `type` enum('announcement','campaign') DEFAULT 'announcement',
  `target_app` enum('driver','customer','both') DEFAULT 'both',
  `is_active` tinyint(1) DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `expires_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Tablo döküm verisi `announcements`
--

INSERT INTO `announcements` (`id`, `title`, `content`, `image_url`, `type`, `target_app`, `is_active`, `created_at`, `expires_at`) VALUES
(3, 'Hoş Geldiniz!', 'Taksibu ailesine hoş geldiniz. İlk yolculuğunuzda başarılar!', NULL, 'announcement', 'driver', 1, '2025-12-09 13:47:29', '2026-01-08 13:47:29'),
(4, 'Yakıt Kampanyası', 'Anlaşmalı istasyonlarda %5 indirim!', NULL, 'campaign', 'driver', 1, '2025-12-09 13:47:29', '2025-12-16 13:47:29'),
(5, 'Hoş Geldiniz!', 'Taksibu ailesine hoş geldiniz. İlk yolculuğunuzda başarılar!', NULL, 'announcement', 'driver', 1, '2025-12-09 13:47:40', '2026-01-08 13:47:40'),
(6, 'Yakıt Kampanyası', 'Anlaşmalı istasyonlarda %5 indirim!', NULL, 'campaign', 'driver', 1, '2025-12-09 13:47:40', '2025-12-16 13:47:40');

-- --------------------------------------------------------

--
-- Tablo için tablo yapısı `complaints`
--

CREATE TABLE `complaints` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `ride_id` bigint(20) UNSIGNED DEFAULT NULL,
  `complainer_id` bigint(20) UNSIGNED NOT NULL,
  `accused_id` bigint(20) UNSIGNED DEFAULT NULL,
  `type` varchar(100) DEFAULT NULL,
  `description` text DEFAULT NULL,
  `status` enum('open','reviewing','closed') DEFAULT 'open',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Tablo için tablo yapısı `drivers`
--

CREATE TABLE `drivers` (
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `driver_card_number` varchar(100) DEFAULT NULL,
  `vehicle_plate` varchar(20) DEFAULT NULL,
  `vehicle_type` enum('sari','turkuaz','vip','8+1') NOT NULL,
  `vehicle_license_file` varchar(255) DEFAULT NULL,
  `working_region` enum('Anadolu','Avrupa') DEFAULT NULL,
  `working_district` varchar(100) DEFAULT NULL,
  `status` enum('pending','approved','rejected','banned') DEFAULT 'pending',
  `is_available` tinyint(1) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Tablo döküm verisi `drivers`
--

INSERT INTO `drivers` (`user_id`, `driver_card_number`, `vehicle_plate`, `vehicle_type`, `vehicle_license_file`, `working_region`, `working_district`, `status`, `is_available`, `created_at`, `updated_at`) VALUES
(146, '5812358', '34 TDN 39', 'sari', NULL, 'Anadolu', 'Ataşehir', 'approved', 1, '2025-12-09 08:31:15', '2025-12-09 20:15:44');

-- --------------------------------------------------------

--
-- Tablo için tablo yapısı `notifications`
--

CREATE TABLE `notifications` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `type` varchar(100) NOT NULL,
  `title` varchar(255) DEFAULT NULL,
  `body` text DEFAULT NULL,
  `data` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`data`)),
  `is_read` tinyint(1) DEFAULT 0,
  `created_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Tablo döküm verisi `notifications`
--

INSERT INTO `notifications` (`id`, `user_id`, `type`, `title`, `body`, `data`, `is_read`, `created_at`) VALUES
(233, 145, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 146).', '{\"ride_id\":227,\"driver_id\":146}', 0, '2025-12-09 08:32:41'),
(234, 146, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 227).', '{\"ride_id\":227,\"passenger_id\":145}', 0, '2025-12-09 08:32:41'),
(235, 145, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 146).', '{\"ride_id\":228,\"driver_id\":146}', 0, '2025-12-09 08:44:32'),
(236, 146, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 228).', '{\"ride_id\":228,\"passenger_id\":145}', 0, '2025-12-09 08:44:32'),
(237, 145, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 146).', '{\"ride_id\":229,\"driver_id\":146}', 0, '2025-12-09 09:10:08'),
(238, 146, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 229).', '{\"ride_id\":229,\"passenger_id\":145}', 0, '2025-12-09 09:10:08'),
(239, 145, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 146).', '{\"ride_id\":230,\"driver_id\":146}', 0, '2025-12-09 09:13:06'),
(240, 146, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 230).', '{\"ride_id\":230,\"passenger_id\":145}', 0, '2025-12-09 09:13:06'),
(241, 145, 'ride_auto_rejected', 'Çağrı reddedildi', 'Maalesef çağrınıza hiç sürücü cevap vermedi.', '{\"ride_id\":231}', 0, '2025-12-09 09:16:29'),
(242, 145, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 146).', '{\"ride_id\":232,\"driver_id\":146}', 0, '2025-12-09 11:41:44'),
(243, 146, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 232).', '{\"ride_id\":232,\"passenger_id\":145}', 0, '2025-12-09 11:41:44'),
(244, 145, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 146).', '{\"ride_id\":233,\"driver_id\":146}', 0, '2025-12-09 11:42:31'),
(245, 146, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 233).', '{\"ride_id\":233,\"passenger_id\":145}', 0, '2025-12-09 11:42:31'),
(246, 145, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 146).', '{\"ride_id\":234,\"driver_id\":146}', 0, '2025-12-09 11:55:27'),
(247, 146, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 234).', '{\"ride_id\":234,\"passenger_id\":145}', 0, '2025-12-09 11:55:27'),
(248, 145, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 146).', '{\"ride_id\":235,\"driver_id\":146}', 0, '2025-12-09 12:01:51'),
(249, 146, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 235).', '{\"ride_id\":235,\"passenger_id\":145}', 0, '2025-12-09 12:01:51'),
(250, 145, 'ride_auto_rejected', 'Çağrı reddedildi', 'Maalesef çağrınıza hiç sürücü cevap vermedi.', '{\"ride_id\":236}', 0, '2025-12-09 12:02:07'),
(251, 145, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 146).', '{\"ride_id\":237,\"driver_id\":146}', 0, '2025-12-09 12:03:02'),
(252, 146, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 237).', '{\"ride_id\":237,\"passenger_id\":145}', 0, '2025-12-09 12:03:02'),
(253, 145, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 146).', '{\"ride_id\":241,\"driver_id\":146}', 0, '2025-12-09 12:15:46'),
(254, 146, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 241).', '{\"ride_id\":241,\"passenger_id\":145}', 0, '2025-12-09 12:15:46'),
(255, 145, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 146).', '{\"ride_id\":242,\"driver_id\":146}', 0, '2025-12-09 12:22:53'),
(256, 146, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 242).', '{\"ride_id\":242,\"passenger_id\":145}', 0, '2025-12-09 12:22:53'),
(257, 145, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 146).', '{\"ride_id\":243,\"driver_id\":146}', 0, '2025-12-09 12:29:28'),
(258, 146, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 243).', '{\"ride_id\":243,\"passenger_id\":145}', 0, '2025-12-09 12:29:28'),
(259, 145, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 146).', '{\"ride_id\":244,\"driver_id\":146}', 0, '2025-12-09 13:26:46'),
(260, 146, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 244).', '{\"ride_id\":244,\"passenger_id\":145}', 0, '2025-12-09 13:26:46'),
(261, 145, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 146).', '{\"ride_id\":245,\"driver_id\":146}', 0, '2025-12-09 20:16:32'),
(262, 146, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 245).', '{\"ride_id\":245,\"passenger_id\":145}', 0, '2025-12-09 20:16:32');

-- --------------------------------------------------------

--
-- Tablo için tablo yapısı `ratings`
--

CREATE TABLE `ratings` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `ride_id` bigint(20) UNSIGNED NOT NULL,
  `rater_id` bigint(20) UNSIGNED NOT NULL,
  `rated_id` bigint(20) UNSIGNED NOT NULL,
  `stars` tinyint(3) UNSIGNED NOT NULL CHECK (`stars` >= 1 and `stars` <= 5),
  `comment` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Tablo döküm verisi `ratings`
--

INSERT INTO `ratings` (`id`, `ride_id`, `rater_id`, `rated_id`, `stars`, `comment`, `created_at`) VALUES
(138, 227, 145, 146, 5, NULL, '2025-12-09 08:32:57'),
(139, 227, 146, 145, 5, NULL, '2025-12-09 08:32:58'),
(140, 228, 145, 146, 5, NULL, '2025-12-09 08:44:51'),
(141, 228, 146, 145, 5, NULL, '2025-12-09 08:44:51'),
(142, 229, 145, 146, 5, NULL, '2025-12-09 09:10:25'),
(143, 229, 146, 145, 5, NULL, '2025-12-09 09:10:25'),
(144, 230, 146, 145, 5, NULL, '2025-12-09 09:13:22'),
(145, 230, 145, 146, 5, NULL, '2025-12-09 09:13:23'),
(146, 232, 145, 146, 5, NULL, '2025-12-09 11:42:16'),
(147, 232, 146, 145, 5, NULL, '2025-12-09 11:42:16'),
(148, 233, 145, 146, 5, NULL, '2025-12-09 11:42:48'),
(149, 233, 146, 145, 5, NULL, '2025-12-09 11:42:48'),
(150, 241, 146, 145, 5, NULL, '2025-12-09 12:22:44'),
(151, 242, 145, 146, 5, NULL, '2025-12-09 12:23:09'),
(152, 242, 146, 145, 5, NULL, '2025-12-09 12:23:10'),
(153, 244, 145, 146, 5, NULL, '2025-12-09 13:27:10'),
(154, 244, 146, 145, 5, NULL, '2025-12-09 13:27:10'),
(155, 245, 145, 146, 5, NULL, '2025-12-09 20:17:11'),
(156, 245, 146, 145, 5, NULL, '2025-12-09 20:17:12');

-- --------------------------------------------------------

--
-- Tablo için tablo yapısı `rides`
--

CREATE TABLE `rides` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `passenger_id` bigint(20) UNSIGNED NOT NULL,
  `driver_id` bigint(20) UNSIGNED DEFAULT NULL,
  `start_lat` double NOT NULL,
  `start_lng` double NOT NULL,
  `start_address` varchar(255) DEFAULT NULL,
  `end_lat` double DEFAULT NULL,
  `end_lng` double DEFAULT NULL,
  `end_address` varchar(255) DEFAULT NULL,
  `vehicle_type` enum('sari','turkuaz','vip','8+1') NOT NULL,
  `options` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`options`)),
  `payment_method` enum('pos','nakit') NOT NULL,
  `fare_estimate` decimal(10,2) DEFAULT NULL,
  `fare_actual` decimal(10,2) DEFAULT NULL,
  `status` enum('requested','assigned','started','completed','cancelled','auto_rejected') DEFAULT 'requested',
  `cancel_reason` varchar(255) DEFAULT NULL,
  `code4` char(4) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Tablo döküm verisi `rides`
--

INSERT INTO `rides` (`id`, `passenger_id`, `driver_id`, `start_lat`, `start_lng`, `start_address`, `end_lat`, `end_lng`, `end_address`, `vehicle_type`, `options`, `payment_method`, `fare_estimate`, `fare_actual`, `status`, `cancel_reason`, `code4`, `created_at`, `updated_at`) VALUES
(227, 145, 146, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 41.0189417, 29.0576298, 'Üsküdar/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":false,\"has_pet\":false}', 'nakit', 438.66, 400.00, 'completed', NULL, '6761', '2025-12-09 08:32:36', '2025-12-09 08:32:54'),
(228, 145, 146, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 40.9498022, 29.1739513, 'Maltepe/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":false,\"has_pet\":false}', 'nakit', 634.36, 400.00, 'completed', NULL, '4550', '2025-12-09 08:44:27', '2025-12-09 08:44:47'),
(229, 145, 146, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 40.9498022, 29.1739513, 'Maltepe/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":false,\"has_pet\":false}', 'nakit', 634.36, 400.00, 'completed', NULL, '1245', '2025-12-09 09:09:57', '2025-12-09 09:10:22'),
(230, 145, 146, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 41.0456474, 28.82472199999999, 'Bağcılar/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":false,\"has_pet\":false}', 'nakit', 1590.79, 1500.00, 'completed', NULL, '8046', '2025-12-09 09:13:00', '2025-12-09 09:13:19'),
(231, 145, NULL, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 40.879326, 29.258135, 'Pendik, Kaynarca, 34890 Pendik/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":true,\"has_pet\":true}', 'nakit', 880.11, NULL, 'auto_rejected', NULL, '5345', '2025-12-09 09:16:08', '2025-12-09 09:16:29'),
(232, 145, 146, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 40.879326, 29.258135, 'Pendik, Kaynarca, 34890 Pendik/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":false,\"has_pet\":false}', 'nakit', 880.11, 600.00, 'completed', NULL, '8378', '2025-12-09 11:41:39', '2025-12-09 11:42:12'),
(233, 145, 146, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 40.879326, 29.258135, 'Pendik, Kaynarca, 34890 Pendik/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":false,\"has_pet\":false}', 'nakit', 880.11, 500.00, 'completed', NULL, '3394', '2025-12-09 11:42:27', '2025-12-09 11:42:44'),
(234, 145, 146, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 40.879326, 29.258135, 'Pendik, Kaynarca, 34890 Pendik/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":false,\"has_pet\":false}', 'nakit', 880.11, NULL, 'cancelled', 'Diğer', '9771', '2025-12-09 11:55:21', '2025-12-09 11:55:32'),
(235, 145, 146, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 40.879326, 29.258135, 'Pendik, Kaynarca, 34890 Pendik/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":false,\"has_pet\":false}', 'nakit', 880.11, NULL, 'cancelled', 'Acil durum', '6778', '2025-12-09 12:01:44', '2025-12-09 12:01:59'),
(236, 145, NULL, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 40.879326, 29.258135, 'Pendik, Kaynarca, 34890 Pendik/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":false,\"has_pet\":false}', 'nakit', 880.11, NULL, 'auto_rejected', NULL, '1149', '2025-12-09 12:01:47', '2025-12-09 12:02:07'),
(237, 145, 146, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 40.879326, 29.258135, 'Pendik, Kaynarca, 34890 Pendik/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":false,\"has_pet\":false}', 'nakit', 880.11, NULL, 'cancelled', 'Acil durum', '3089', '2025-12-09 12:02:56', '2025-12-09 12:03:13'),
(238, 145, NULL, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 40.879326, 29.258135, 'Pendik, Kaynarca, 34890 Pendik/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":false,\"has_pet\":false}', 'nakit', 880.11, NULL, 'cancelled', 'Fikir değiştirdim', '6238', '2025-12-09 12:03:00', '2025-12-09 12:03:16'),
(239, 145, NULL, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 40.9498022, 29.1739513, 'Maltepe/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":false,\"has_pet\":false}', 'nakit', 634.36, NULL, 'cancelled', 'Fikir değiştirdim', '4275', '2025-12-09 12:03:28', '2025-12-09 12:03:44'),
(240, 145, NULL, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 40.879326, 29.258135, 'Pendik, Kaynarca, 34890 Pendik/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":false,\"has_pet\":false}', 'nakit', 880.11, NULL, 'cancelled', 'Başka bir araç buldum', '1362', '2025-12-09 12:15:28', '2025-12-09 12:15:32'),
(241, 145, 146, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 40.9498022, 29.1739513, 'Maltepe/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":false,\"has_pet\":false}', 'nakit', 634.36, 400.00, 'completed', NULL, '7688', '2025-12-09 12:15:40', '2025-12-09 12:22:37'),
(242, 145, 146, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 40.879326, 29.258135, 'Pendik, Kaynarca, 34890 Pendik/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":false,\"has_pet\":false}', 'nakit', 880.11, 500.00, 'completed', NULL, '2774', '2025-12-09 12:22:48', '2025-12-09 12:23:06'),
(243, 145, 146, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 41.0189417, 29.0576298, 'Üsküdar/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":false,\"has_pet\":false}', 'nakit', 438.66, NULL, 'cancelled', 'Aracım arıza yaptı', '1112', '2025-12-09 12:29:22', '2025-12-09 12:29:46'),
(244, 145, 146, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 40.879326, 29.258135, 'Pendik, Kaynarca, 34890 Pendik/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":false,\"has_pet\":false}', 'nakit', 880.11, 500.00, 'completed', NULL, '2914', '2025-12-09 13:26:41', '2025-12-09 13:27:07'),
(245, 145, 146, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 40.879326, 29.258135, 'Pendik, Kaynarca, 34890 Pendik/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":false,\"has_pet\":false}', 'nakit', 880.11, 500.00, 'completed', NULL, '7250', '2025-12-09 20:16:27', '2025-12-09 20:17:06');

-- --------------------------------------------------------

--
-- Tablo için tablo yapısı `ride_messages`
--

CREATE TABLE `ride_messages` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `ride_id` bigint(20) UNSIGNED NOT NULL,
  `sender_id` bigint(20) UNSIGNED DEFAULT NULL,
  `message` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Tablo için tablo yapısı `ride_requests`
--

CREATE TABLE `ride_requests` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `ride_id` bigint(20) UNSIGNED NOT NULL,
  `driver_id` bigint(20) UNSIGNED NOT NULL,
  `sent_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `driver_response` enum('no_response','accepted','rejected') DEFAULT 'no_response',
  `response_at` timestamp NULL DEFAULT NULL,
  `timeout` tinyint(1) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Tablo döküm verisi `ride_requests`
--

INSERT INTO `ride_requests` (`id`, `ride_id`, `driver_id`, `sent_at`, `driver_response`, `response_at`, `timeout`) VALUES
(147, 227, 146, '2025-12-09 08:32:36', 'accepted', '2025-12-09 08:32:41', 0),
(149, 228, 146, '2025-12-09 08:44:27', 'accepted', '2025-12-09 08:44:32', 0),
(151, 229, 146, '2025-12-09 09:09:57', 'accepted', '2025-12-09 09:10:08', 0),
(153, 230, 146, '2025-12-09 09:13:00', 'accepted', '2025-12-09 09:13:06', 0),
(155, 231, 146, '2025-12-09 09:16:08', 'no_response', NULL, 1),
(157, 232, 146, '2025-12-09 11:41:39', 'accepted', '2025-12-09 11:41:44', 0),
(159, 233, 146, '2025-12-09 11:42:27', 'accepted', '2025-12-09 11:42:31', 0),
(161, 234, 146, '2025-12-09 11:55:21', 'accepted', '2025-12-09 11:55:27', 0),
(163, 235, 146, '2025-12-09 12:01:44', 'accepted', '2025-12-09 12:01:51', 0),
(165, 236, 146, '2025-12-09 12:01:47', 'no_response', NULL, 1),
(167, 237, 146, '2025-12-09 12:02:56', 'accepted', '2025-12-09 12:03:02', 0),
(169, 238, 146, '2025-12-09 12:03:00', 'no_response', NULL, 0),
(171, 239, 146, '2025-12-09 12:03:28', 'no_response', NULL, 0),
(173, 240, 146, '2025-12-09 12:15:28', 'no_response', NULL, 0),
(175, 241, 146, '2025-12-09 12:15:40', 'accepted', '2025-12-09 12:15:46', 0),
(177, 242, 146, '2025-12-09 12:22:48', 'accepted', '2025-12-09 12:22:53', 0),
(179, 243, 146, '2025-12-09 12:29:22', 'accepted', '2025-12-09 12:29:28', 0),
(181, 244, 146, '2025-12-09 13:26:41', 'accepted', '2025-12-09 13:26:46', 0),
(183, 245, 146, '2025-12-09 20:16:27', 'accepted', '2025-12-09 20:16:32', 0);

-- --------------------------------------------------------

--
-- Tablo için tablo yapısı `saved_places`
--

CREATE TABLE `saved_places` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `title` varchar(64) NOT NULL,
  `address` varchar(255) NOT NULL,
  `lat` double NOT NULL,
  `lng` double NOT NULL,
  `icon` varchar(32) DEFAULT 'place',
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Tablo için tablo yapısı `users`
--

CREATE TABLE `users` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `role` enum('passenger','driver','admin') NOT NULL DEFAULT 'passenger',
  `first_name` varchar(100) NOT NULL,
  `last_name` varchar(100) NOT NULL,
  `phone` varchar(30) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `profile_photo` varchar(255) DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `ref_code` varchar(32) DEFAULT NULL,
  `referrer_id` bigint(20) UNSIGNED DEFAULT NULL,
  `ref_count` int(11) NOT NULL DEFAULT 0,
  `level` enum('standard','silver','gold','platinum') NOT NULL DEFAULT 'standard',
  `fcm_token` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Tablo döküm verisi `users`
--

INSERT INTO `users` (`id`, `role`, `first_name`, `last_name`, `phone`, `password_hash`, `profile_photo`, `is_active`, `created_at`, `updated_at`, `ref_code`, `referrer_id`, `ref_count`, `level`, `fcm_token`) VALUES
(145, 'passenger', 'Nur', 'Dokuz', '5070181758', '$2b$10$2Q8dvkUKXmn75T/JqF2DSOV0zczW/G7Xcm1D7gt8rMO7aIEJBx2GW', NULL, 1, '2025-12-09 08:29:53', '2025-12-09 08:29:53', 'TB145', NULL, 0, 'standard', NULL),
(146, 'driver', 'Murat', 'Gungor', '5327365892', '$2b$10$tlZ7W6Frf1/T1wjGJYCp/OvWlsr2eJcGCFme3FGPzPlsjyQjjUdda', NULL, 1, '2025-12-09 08:31:15', '2025-12-09 08:31:15', 'TB146', NULL, 0, 'standard', NULL);

-- --------------------------------------------------------

--
-- Tablo için tablo yapısı `user_devices`
--

CREATE TABLE `user_devices` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `device_token` varchar(255) NOT NULL,
  `platform` enum('android','ios','web') DEFAULT 'android',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Tablo döküm verisi `user_devices`
--

INSERT INTO `user_devices` (`id`, `user_id`, `device_token`, `platform`, `created_at`) VALUES
(24, 145, 'cCE-_08HTzSXuy1XUJygd4:APA91bGPQRAAh8-vG2MEqyHNMX2ITZ5FTp3_ok5yTF2u-Z1YKyCPkXKNuu6WBlAe0mWlOmgH_FQt-nZ4GbhMUEuAEBLj-PhYwxfsiubogScZ61aVJF6I3DY', 'android', '2025-12-09 08:30:05'),
(25, 146, 'cmDpNa9nSsGY6e2OS1RqZm:APA91bFKAQQUd7sacSqDXQrS5p6VZQ7tDMM4RkB9ocs034y2vSLFy64zjzjSJ8yFdOxKiqOmZWxwaAjwxtkt7cVlD9S0yRS23a4ip1lOaOAEendyn0y83iY', 'android', '2025-12-09 08:31:51');

-- --------------------------------------------------------

--
-- Tablo için tablo yapısı `wallets`
--

CREATE TABLE `wallets` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `balance` decimal(10,2) NOT NULL DEFAULT 0.00,
  `total_earnings` decimal(10,2) NOT NULL DEFAULT 0.00,
  `currency` varchar(3) NOT NULL DEFAULT 'TRY',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Tablo döküm verisi `wallets`
--

INSERT INTO `wallets` (`id`, `user_id`, `balance`, `total_earnings`, `currency`, `created_at`, `updated_at`) VALUES
(2, 146, 5700.00, 5700.00, 'TRY', '2025-12-09 08:32:54', '2025-12-09 20:17:06');

-- --------------------------------------------------------

--
-- Tablo için tablo yapısı `wallet_transactions`
--

CREATE TABLE `wallet_transactions` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `wallet_id` bigint(20) UNSIGNED NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `type` enum('ride_earnings','withdrawal','correction','other') NOT NULL,
  `reference_id` bigint(20) UNSIGNED DEFAULT NULL,
  `description` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Tablo döküm verisi `wallet_transactions`
--

INSERT INTO `wallet_transactions` (`id`, `wallet_id`, `amount`, `type`, `reference_id`, `description`, `created_at`) VALUES
(5, 2, 400.00, 'ride_earnings', 227, 'Yolculuk Kazancı - Ride #227', '2025-12-09 08:32:54'),
(6, 2, 400.00, 'ride_earnings', 228, 'Yolculuk Kazancı - Ride #228', '2025-12-09 08:44:47'),
(7, 2, 400.00, 'ride_earnings', 229, 'Yolculuk Kazancı - Ride #229', '2025-12-09 09:10:22'),
(8, 2, 1500.00, 'ride_earnings', 230, 'Yolculuk Kazancı - Ride #230', '2025-12-09 09:13:19'),
(9, 2, 600.00, 'ride_earnings', 232, 'Yolculuk Kazancı - Ride #232', '2025-12-09 11:42:12'),
(10, 2, 500.00, 'ride_earnings', 233, 'Yolculuk Kazancı - Ride #233', '2025-12-09 11:42:44'),
(11, 2, 400.00, 'ride_earnings', 241, 'Yolculuk Kazancı - Ride #241', '2025-12-09 12:22:37'),
(12, 2, 500.00, 'ride_earnings', 242, 'Yolculuk Kazancı - Ride #242', '2025-12-09 12:23:06'),
(13, 2, 500.00, 'ride_earnings', 244, 'Yolculuk Kazancı - Ride #244', '2025-12-09 13:27:07'),
(14, 2, 500.00, 'ride_earnings', 245, 'Yolculuk Kazancı - Ride #245', '2025-12-09 20:17:06');

--
-- Dökümü yapılmış tablolar için indeksler
--

--
-- Tablo için indeksler `announcements`
--
ALTER TABLE `announcements`
  ADD PRIMARY KEY (`id`);

--
-- Tablo için indeksler `complaints`
--
ALTER TABLE `complaints`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_complaints_complainer` (`complainer_id`),
  ADD KEY `idx_complaints_accused` (`accused_id`),
  ADD KEY `fk_complaints_ride` (`ride_id`);

--
-- Tablo için indeksler `drivers`
--
ALTER TABLE `drivers`
  ADD PRIMARY KEY (`user_id`);

--
-- Tablo için indeksler `notifications`
--
ALTER TABLE `notifications`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`);

--
-- Tablo için indeksler `ratings`
--
ALTER TABLE `ratings`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_ratings_rated` (`rated_id`),
  ADD KEY `fk_ratings_ride` (`ride_id`),
  ADD KEY `fk_ratings_rater` (`rater_id`);

--
-- Tablo için indeksler `rides`
--
ALTER TABLE `rides`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_rides_passenger` (`passenger_id`),
  ADD KEY `idx_rides_driver` (`driver_id`),
  ADD KEY `idx_rides_status_created` (`status`,`created_at`);

--
-- Tablo için indeksler `ride_messages`
--
ALTER TABLE `ride_messages`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_rm_ride` (`ride_id`),
  ADD KEY `fk_rm_sender` (`sender_id`);

--
-- Tablo için indeksler `ride_requests`
--
ALTER TABLE `ride_requests`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_rr_ride_id` (`ride_id`),
  ADD KEY `idx_rr_driver_id` (`driver_id`);

--
-- Tablo için indeksler `saved_places`
--
ALTER TABLE `saved_places`
  ADD PRIMARY KEY (`id`),
  ADD KEY `saved_places_user_id_foreign` (`user_id`);

--
-- Tablo için indeksler `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `phone` (`phone`),
  ADD UNIQUE KEY `uq_users_ref_code` (`ref_code`),
  ADD KEY `idx_users_phone` (`phone`),
  ADD KEY `fk_users_referrer` (`referrer_id`);

--
-- Tablo için indeksler `user_devices`
--
ALTER TABLE `user_devices`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_user_devices_user` (`user_id`);

--
-- Tablo için indeksler `wallets`
--
ALTER TABLE `wallets`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `user_id` (`user_id`);

--
-- Tablo için indeksler `wallet_transactions`
--
ALTER TABLE `wallet_transactions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_wallet_transactions_wallet_id` (`wallet_id`);

--
-- Dökümü yapılmış tablolar için AUTO_INCREMENT değeri
--

--
-- Tablo için AUTO_INCREMENT değeri `announcements`
--
ALTER TABLE `announcements`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- Tablo için AUTO_INCREMENT değeri `complaints`
--
ALTER TABLE `complaints`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=15;

--
-- Tablo için AUTO_INCREMENT değeri `notifications`
--
ALTER TABLE `notifications`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=263;

--
-- Tablo için AUTO_INCREMENT değeri `ratings`
--
ALTER TABLE `ratings`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=157;

--
-- Tablo için AUTO_INCREMENT değeri `rides`
--
ALTER TABLE `rides`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=246;

--
-- Tablo için AUTO_INCREMENT değeri `ride_messages`
--
ALTER TABLE `ride_messages`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=42;

--
-- Tablo için AUTO_INCREMENT değeri `ride_requests`
--
ALTER TABLE `ride_requests`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=185;

--
-- Tablo için AUTO_INCREMENT değeri `saved_places`
--
ALTER TABLE `saved_places`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- Tablo için AUTO_INCREMENT değeri `users`
--
ALTER TABLE `users`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=147;

--
-- Tablo için AUTO_INCREMENT değeri `user_devices`
--
ALTER TABLE `user_devices`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=26;

--
-- Tablo için AUTO_INCREMENT değeri `wallets`
--
ALTER TABLE `wallets`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- Tablo için AUTO_INCREMENT değeri `wallet_transactions`
--
ALTER TABLE `wallet_transactions`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=15;

--
-- Dökümü yapılmış tablolar için kısıtlamalar
--

--
-- Tablo kısıtlamaları `complaints`
--
ALTER TABLE `complaints`
  ADD CONSTRAINT `fk_complaints_accused` FOREIGN KEY (`accused_id`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_complaints_complainer` FOREIGN KEY (`complainer_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_complaints_ride` FOREIGN KEY (`ride_id`) REFERENCES `rides` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Tablo kısıtlamaları `drivers`
--
ALTER TABLE `drivers`
  ADD CONSTRAINT `fk_drivers_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Tablo kısıtlamaları `notifications`
--
ALTER TABLE `notifications`
  ADD CONSTRAINT `notifications_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE NO ACTION ON UPDATE CASCADE;

--
-- Tablo kısıtlamaları `ratings`
--
ALTER TABLE `ratings`
  ADD CONSTRAINT `fk_ratings_rated_user` FOREIGN KEY (`rated_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_ratings_rater` FOREIGN KEY (`rater_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_ratings_ride` FOREIGN KEY (`ride_id`) REFERENCES `rides` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Tablo kısıtlamaları `rides`
--
ALTER TABLE `rides`
  ADD CONSTRAINT `fk_rides_driver` FOREIGN KEY (`driver_id`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_rides_passenger` FOREIGN KEY (`passenger_id`) REFERENCES `users` (`id`) ON UPDATE CASCADE;

--
-- Tablo kısıtlamaları `ride_messages`
--
ALTER TABLE `ride_messages`
  ADD CONSTRAINT `fk_rm_ride` FOREIGN KEY (`ride_id`) REFERENCES `rides` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_rm_sender` FOREIGN KEY (`sender_id`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Tablo kısıtlamaları `ride_requests`
--
ALTER TABLE `ride_requests`
  ADD CONSTRAINT `fk_rr_driver` FOREIGN KEY (`driver_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_rr_ride` FOREIGN KEY (`ride_id`) REFERENCES `rides` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Tablo kısıtlamaları `saved_places`
--
ALTER TABLE `saved_places`
  ADD CONSTRAINT `saved_places_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Tablo kısıtlamaları `users`
--
ALTER TABLE `users`
  ADD CONSTRAINT `fk_users_referrer` FOREIGN KEY (`referrer_id`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Tablo kısıtlamaları `user_devices`
--
ALTER TABLE `user_devices`
  ADD CONSTRAINT `fk_user_devices_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Tablo kısıtlamaları `wallets`
--
ALTER TABLE `wallets`
  ADD CONSTRAINT `wallets_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Tablo kısıtlamaları `wallet_transactions`
--
ALTER TABLE `wallet_transactions`
  ADD CONSTRAINT `wallet_transactions_ibfk_1` FOREIGN KEY (`wallet_id`) REFERENCES `wallets` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
