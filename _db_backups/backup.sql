-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Anamakine: 127.0.0.1
-- Üretim Zamanı: 15 Ara 2025, 10:21:28
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
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `ibb_card_file` varchar(255) DEFAULT NULL,
  `driving_license_file` varchar(255) DEFAULT NULL,
  `identity_card_file` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Tablo döküm verisi `drivers`
--

INSERT INTO `drivers` (`user_id`, `driver_card_number`, `vehicle_plate`, `vehicle_type`, `vehicle_license_file`, `working_region`, `working_district`, `status`, `is_available`, `created_at`, `updated_at`, `ibb_card_file`, `driving_license_file`, `identity_card_file`) VALUES
(165, NULL, '34 TDN 39', 'sari', 'uploads/drivers/driver-1765647392979-898339093.jpg', 'Anadolu', 'Ataşehir', 'approved', 1, '2025-12-13 17:36:33', '2025-12-14 10:08:42', 'uploads/drivers/driver-1765647393013-52454665.jpg', 'uploads/drivers/driver-1765647393033-194223028.jpg', 'uploads/drivers/driver-1765647393051-722487511.jpg');

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
(287, 164, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 165).', '{\"ride_id\":259,\"driver_id\":165}', 0, '2025-12-13 17:44:16'),
(288, 165, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 259).', '{\"ride_id\":259,\"passenger_id\":164}', 0, '2025-12-13 17:44:16'),
(289, 164, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 165).', '{\"ride_id\":260,\"driver_id\":165}', 0, '2025-12-13 17:49:31'),
(290, 165, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 260).', '{\"ride_id\":260,\"passenger_id\":164}', 0, '2025-12-13 17:49:31'),
(291, 164, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 165).', '{\"ride_id\":261,\"driver_id\":165}', 0, '2025-12-13 17:55:02'),
(292, 165, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 261).', '{\"ride_id\":261,\"passenger_id\":164}', 0, '2025-12-13 17:55:02'),
(293, 164, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 165).', '{\"ride_id\":263,\"driver_id\":165}', 0, '2025-12-13 18:01:48'),
(294, 165, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 263).', '{\"ride_id\":263,\"passenger_id\":164}', 0, '2025-12-13 18:01:48'),
(295, 164, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 165).', '{\"ride_id\":264,\"driver_id\":165}', 0, '2025-12-13 18:08:11'),
(296, 165, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 264).', '{\"ride_id\":264,\"passenger_id\":164}', 0, '2025-12-13 18:08:11'),
(297, 164, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 165).', '{\"ride_id\":265,\"driver_id\":165}', 0, '2025-12-13 18:15:54'),
(298, 165, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 265).', '{\"ride_id\":265,\"passenger_id\":164}', 0, '2025-12-13 18:15:54'),
(299, 164, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 165).', '{\"ride_id\":266,\"driver_id\":165}', 0, '2025-12-13 18:19:50'),
(300, 165, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 266).', '{\"ride_id\":266,\"passenger_id\":164}', 0, '2025-12-13 18:19:50'),
(301, 164, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 165).', '{\"ride_id\":267,\"driver_id\":165}', 0, '2025-12-13 18:30:14'),
(302, 165, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 267).', '{\"ride_id\":267,\"passenger_id\":164}', 0, '2025-12-13 18:30:14'),
(303, 164, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 165).', '{\"ride_id\":268,\"driver_id\":165}', 0, '2025-12-13 18:39:32'),
(304, 165, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 268).', '{\"ride_id\":268,\"passenger_id\":164}', 0, '2025-12-13 18:39:32'),
(305, 164, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 165).', '{\"ride_id\":269,\"driver_id\":165}', 0, '2025-12-13 18:44:11'),
(306, 165, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 269).', '{\"ride_id\":269,\"passenger_id\":164}', 0, '2025-12-13 18:44:11'),
(307, 164, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 165).', '{\"ride_id\":270,\"driver_id\":165}', 0, '2025-12-13 18:49:31'),
(308, 165, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 270).', '{\"ride_id\":270,\"passenger_id\":164}', 0, '2025-12-13 18:49:31'),
(309, 164, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 165).', '{\"ride_id\":271,\"driver_id\":165}', 0, '2025-12-13 18:50:15'),
(310, 165, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 271).', '{\"ride_id\":271,\"passenger_id\":164}', 0, '2025-12-13 18:50:15'),
(311, 164, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 165).', '{\"ride_id\":272,\"driver_id\":165}', 0, '2025-12-13 18:52:06'),
(312, 165, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 272).', '{\"ride_id\":272,\"passenger_id\":164}', 0, '2025-12-13 18:52:06'),
(313, 164, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 165).', '{\"ride_id\":274,\"driver_id\":165}', 0, '2025-12-13 18:54:22'),
(314, 165, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 274).', '{\"ride_id\":274,\"passenger_id\":164}', 0, '2025-12-13 18:54:22'),
(315, 164, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 165).', '{\"ride_id\":275,\"driver_id\":165}', 0, '2025-12-13 19:26:38'),
(316, 165, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 275).', '{\"ride_id\":275,\"passenger_id\":164}', 0, '2025-12-13 19:26:38'),
(317, 164, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 165).', '{\"ride_id\":276,\"driver_id\":165}', 0, '2025-12-13 19:27:47'),
(318, 165, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 276).', '{\"ride_id\":276,\"passenger_id\":164}', 0, '2025-12-13 19:27:47'),
(319, 164, 'ride_auto_rejected', 'Çağrı reddedildi', 'Maalesef çağrınıza hiç sürücü cevap vermedi.', '{\"ride_id\":277}', 0, '2025-12-13 19:31:05'),
(320, 164, 'ride_auto_rejected', 'Çağrı reddedildi', 'Maalesef çağrınıza hiç sürücü cevap vermedi.', '{\"ride_id\":279}', 0, '2025-12-13 20:14:25'),
(321, 164, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 165).', '{\"ride_id\":280,\"driver_id\":165}', 0, '2025-12-13 20:17:14'),
(322, 165, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 280).', '{\"ride_id\":280,\"passenger_id\":164}', 0, '2025-12-13 20:17:14'),
(323, 164, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 165).', '{\"ride_id\":281,\"driver_id\":165}', 0, '2025-12-13 20:41:22'),
(324, 165, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 281).', '{\"ride_id\":281,\"passenger_id\":164}', 0, '2025-12-13 20:41:22'),
(325, 164, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 165).', '{\"ride_id\":282,\"driver_id\":165}', 0, '2025-12-13 20:47:17'),
(326, 165, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 282).', '{\"ride_id\":282,\"passenger_id\":164}', 0, '2025-12-13 20:47:17'),
(327, 164, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 165).', '{\"ride_id\":283,\"driver_id\":165}', 0, '2025-12-13 20:51:58'),
(328, 165, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 283).', '{\"ride_id\":283,\"passenger_id\":164}', 0, '2025-12-13 20:51:58'),
(329, 164, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 165).', '{\"ride_id\":284,\"driver_id\":165}', 0, '2025-12-14 06:48:39'),
(330, 165, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 284).', '{\"ride_id\":284,\"passenger_id\":164}', 0, '2025-12-14 06:48:39'),
(331, 164, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 165).', '{\"ride_id\":285,\"driver_id\":165}', 0, '2025-12-14 06:59:20'),
(332, 165, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 285).', '{\"ride_id\":285,\"passenger_id\":164}', 0, '2025-12-14 06:59:20'),
(333, 164, 'ride_auto_rejected', 'Çağrı reddedildi', 'Maalesef çağrınıza hiç sürücü cevap vermedi.', '{\"ride_id\":286}', 0, '2025-12-14 07:05:03'),
(334, 164, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 165).', '{\"ride_id\":287,\"driver_id\":165}', 0, '2025-12-14 07:07:52'),
(335, 165, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 287).', '{\"ride_id\":287,\"passenger_id\":164}', 0, '2025-12-14 07:07:52'),
(336, 164, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 165).', '{\"ride_id\":288,\"driver_id\":165}', 0, '2025-12-14 07:08:31'),
(337, 165, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 288).', '{\"ride_id\":288,\"passenger_id\":164}', 0, '2025-12-14 07:08:31'),
(338, 164, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 165).', '{\"ride_id\":290,\"driver_id\":165}', 0, '2025-12-14 07:13:47'),
(339, 165, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 290).', '{\"ride_id\":290,\"passenger_id\":164}', 0, '2025-12-14 07:13:47'),
(340, 164, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 165).', '{\"ride_id\":291,\"driver_id\":165}', 0, '2025-12-14 07:14:31'),
(341, 165, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 291).', '{\"ride_id\":291,\"passenger_id\":164}', 0, '2025-12-14 07:14:31'),
(342, 164, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 165).', '{\"ride_id\":293,\"driver_id\":165}', 0, '2025-12-14 07:19:20'),
(343, 165, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 293).', '{\"ride_id\":293,\"passenger_id\":164}', 0, '2025-12-14 07:19:20'),
(344, 164, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 165).', '{\"ride_id\":294,\"driver_id\":165}', 0, '2025-12-14 07:32:30'),
(345, 165, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 294).', '{\"ride_id\":294,\"passenger_id\":164}', 0, '2025-12-14 07:32:30'),
(346, 164, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 165).', '{\"ride_id\":295,\"driver_id\":165}', 0, '2025-12-14 07:44:14'),
(347, 165, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 295).', '{\"ride_id\":295,\"passenger_id\":164}', 0, '2025-12-14 07:44:14'),
(348, 164, 'ride_auto_rejected', 'Çağrı reddedildi', 'Maalesef çağrınıza hiç sürücü cevap vermedi.', '{\"ride_id\":297}', 0, '2025-12-14 07:48:48'),
(349, 164, 'ride_auto_rejected', 'Çağrı reddedildi', 'Maalesef çağrınıza hiç sürücü cevap vermedi.', '{\"ride_id\":298}', 0, '2025-12-14 07:49:25'),
(350, 164, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 165).', '{\"ride_id\":299,\"driver_id\":165}', 0, '2025-12-14 07:56:45'),
(351, 165, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 299).', '{\"ride_id\":299,\"passenger_id\":164}', 0, '2025-12-14 07:56:45'),
(352, 164, 'ride_auto_rejected', 'Çağrı reddedildi', 'Maalesef çağrınıza hiç sürücü cevap vermedi.', '{\"ride_id\":300}', 0, '2025-12-14 07:57:24'),
(353, 164, 'ride_auto_rejected', 'Çağrı reddedildi', 'Maalesef çağrınıza hiç sürücü cevap vermedi.', '{\"ride_id\":302}', 0, '2025-12-14 07:58:30'),
(354, 164, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 165).', '{\"ride_id\":303,\"driver_id\":165}', 0, '2025-12-14 08:02:49'),
(355, 165, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 303).', '{\"ride_id\":303,\"passenger_id\":164}', 0, '2025-12-14 08:02:49'),
(356, 164, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 165).', '{\"ride_id\":305,\"driver_id\":165}', 0, '2025-12-14 08:08:03'),
(357, 165, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 305).', '{\"ride_id\":305,\"passenger_id\":164}', 0, '2025-12-14 08:08:03'),
(358, 164, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 165).', '{\"ride_id\":307,\"driver_id\":165}', 0, '2025-12-14 08:08:52'),
(359, 165, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 307).', '{\"ride_id\":307,\"passenger_id\":164}', 0, '2025-12-14 08:08:52'),
(360, 164, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 165).', '{\"ride_id\":309,\"driver_id\":165}', 0, '2025-12-14 08:13:23'),
(361, 165, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 309).', '{\"ride_id\":309,\"passenger_id\":164}', 0, '2025-12-14 08:13:23'),
(362, 164, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 165).', '{\"ride_id\":311,\"driver_id\":165}', 0, '2025-12-14 08:20:48'),
(363, 165, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 311).', '{\"ride_id\":311,\"passenger_id\":164}', 0, '2025-12-14 08:20:48'),
(364, 164, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 165).', '{\"ride_id\":312,\"driver_id\":165}', 0, '2025-12-14 08:21:13'),
(365, 165, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 312).', '{\"ride_id\":312,\"passenger_id\":164}', 0, '2025-12-14 08:21:13'),
(366, 164, 'ride_auto_rejected', 'Çağrı reddedildi', 'Maalesef çağrınıza hiç sürücü cevap vermedi.', '{\"ride_id\":314}', 0, '2025-12-14 08:32:16'),
(367, 164, 'ride_auto_rejected', 'Çağrı reddedildi', 'Maalesef çağrınıza hiç sürücü cevap vermedi.', '{\"ride_id\":315}', 0, '2025-12-14 08:36:25'),
(368, 164, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 165).', '{\"ride_id\":316,\"driver_id\":165}', 0, '2025-12-14 08:37:36'),
(369, 165, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 316).', '{\"ride_id\":316,\"passenger_id\":164}', 0, '2025-12-14 08:37:36'),
(370, 164, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 165).', '{\"ride_id\":317,\"driver_id\":165}', 0, '2025-12-14 08:46:06'),
(371, 165, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 317).', '{\"ride_id\":317,\"passenger_id\":164}', 0, '2025-12-14 08:46:06'),
(372, 164, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 165).', '{\"ride_id\":318,\"driver_id\":165}', 0, '2025-12-14 08:46:40'),
(373, 165, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 318).', '{\"ride_id\":318,\"passenger_id\":164}', 0, '2025-12-14 08:46:40'),
(374, 164, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 165).', '{\"ride_id\":319,\"driver_id\":165}', 0, '2025-12-14 08:48:09'),
(375, 165, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 319).', '{\"ride_id\":319,\"passenger_id\":164}', 0, '2025-12-14 08:48:09'),
(376, 164, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 165).', '{\"ride_id\":320,\"driver_id\":165}', 0, '2025-12-14 08:56:55'),
(377, 165, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 320).', '{\"ride_id\":320,\"passenger_id\":164}', 0, '2025-12-14 08:56:55'),
(378, 164, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 165).', '{\"ride_id\":321,\"driver_id\":165}', 0, '2025-12-14 09:06:01'),
(379, 165, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 321).', '{\"ride_id\":321,\"passenger_id\":164}', 0, '2025-12-14 09:06:01'),
(380, 164, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 165).', '{\"ride_id\":322,\"driver_id\":165}', 0, '2025-12-14 09:15:00'),
(381, 165, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 322).', '{\"ride_id\":322,\"passenger_id\":164}', 0, '2025-12-14 09:15:00'),
(382, 164, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 165).', '{\"ride_id\":323,\"driver_id\":165}', 0, '2025-12-14 09:20:52'),
(383, 165, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 323).', '{\"ride_id\":323,\"passenger_id\":164}', 0, '2025-12-14 09:20:52'),
(384, 164, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 165).', '{\"ride_id\":324,\"driver_id\":165}', 0, '2025-12-14 09:26:48'),
(385, 165, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 324).', '{\"ride_id\":324,\"passenger_id\":164}', 0, '2025-12-14 09:26:48'),
(386, 164, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 165).', '{\"ride_id\":325,\"driver_id\":165}', 0, '2025-12-14 09:46:50'),
(387, 165, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 325).', '{\"ride_id\":325,\"passenger_id\":164}', 0, '2025-12-14 09:46:50'),
(388, 164, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 165).', '{\"ride_id\":326,\"driver_id\":165}', 0, '2025-12-14 09:47:59'),
(389, 165, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 326).', '{\"ride_id\":326,\"passenger_id\":164}', 0, '2025-12-14 09:47:59'),
(390, 164, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 165).', '{\"ride_id\":327,\"driver_id\":165}', 0, '2025-12-14 10:07:54'),
(391, 165, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 327).', '{\"ride_id\":327,\"passenger_id\":164}', 0, '2025-12-14 10:07:54');

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
(177, 260, 164, 165, 5, NULL, '2025-12-13 17:49:52'),
(178, 260, 165, 164, 5, NULL, '2025-12-13 17:49:53'),
(179, 261, 165, 164, 5, NULL, '2025-12-13 17:58:18'),
(180, 261, 164, 165, 5, NULL, '2025-12-13 17:58:18'),
(181, 263, 165, 164, 5, NULL, '2025-12-13 18:02:05'),
(182, 263, 164, 165, 5, NULL, '2025-12-13 18:02:06'),
(183, 264, 164, 165, 5, NULL, '2025-12-13 18:08:29'),
(184, 264, 165, 164, 5, NULL, '2025-12-13 18:08:30'),
(185, 265, 164, 165, 5, NULL, '2025-12-13 18:16:11'),
(186, 265, 165, 164, 5, NULL, '2025-12-13 18:16:11'),
(187, 266, 164, 165, 5, NULL, '2025-12-13 18:20:28'),
(188, 266, 165, 164, 5, NULL, '2025-12-13 18:20:29'),
(189, 267, 165, 164, 5, NULL, '2025-12-13 18:38:14'),
(190, 268, 164, 165, 5, NULL, '2025-12-13 18:40:40'),
(191, 268, 165, 164, 5, NULL, '2025-12-13 18:40:41'),
(192, 269, 165, 164, 5, NULL, '2025-12-13 18:45:07'),
(193, 269, 164, 165, 5, NULL, '2025-12-13 18:45:08'),
(194, 270, 164, 165, 5, NULL, '2025-12-13 18:50:01'),
(195, 270, 165, 164, 5, NULL, '2025-12-13 18:50:01'),
(196, 271, 164, 165, 5, NULL, '2025-12-13 18:51:48'),
(197, 271, 165, 164, 5, NULL, '2025-12-13 18:51:49'),
(198, 272, 165, 164, 5, NULL, '2025-12-13 18:52:28'),
(199, 272, 164, 165, 5, NULL, '2025-12-13 18:52:29'),
(200, 274, 165, 164, 5, NULL, '2025-12-13 18:57:24'),
(201, 275, 164, 165, 5, NULL, '2025-12-13 19:27:13'),
(202, 275, 165, 164, 5, NULL, '2025-12-13 19:27:14'),
(203, 276, 164, 165, 5, NULL, '2025-12-13 19:28:52'),
(204, 276, 165, 164, 5, NULL, '2025-12-13 19:28:55'),
(205, 280, 164, 165, 5, NULL, '2025-12-13 20:17:46'),
(206, 280, 165, 164, 5, NULL, '2025-12-13 20:17:47'),
(207, 281, 165, 164, 5, NULL, '2025-12-13 20:44:56'),
(208, 282, 164, 165, 5, NULL, '2025-12-13 20:47:52'),
(209, 282, 165, 164, 5, NULL, '2025-12-13 20:47:54'),
(210, 283, 165, 164, 5, NULL, '2025-12-13 20:52:23'),
(211, 283, 164, 165, 5, NULL, '2025-12-13 20:52:24'),
(212, 284, 164, 165, 5, NULL, '2025-12-14 06:48:57'),
(213, 284, 165, 164, 5, NULL, '2025-12-14 06:48:57'),
(214, 285, 164, 165, 5, NULL, '2025-12-14 06:59:43'),
(215, 285, 165, 164, 5, NULL, '2025-12-14 06:59:43'),
(216, 287, 164, 165, 5, NULL, '2025-12-14 07:08:14'),
(217, 287, 165, 164, 5, NULL, '2025-12-14 07:08:16'),
(218, 290, 164, 165, 5, NULL, '2025-12-14 07:14:06'),
(219, 290, 165, 164, 5, NULL, '2025-12-14 07:14:07'),
(220, 293, 164, 165, 5, NULL, '2025-12-14 07:21:31'),
(221, 293, 165, 164, 5, NULL, '2025-12-14 07:21:32'),
(222, 294, 164, 165, 5, NULL, '2025-12-14 07:32:56'),
(223, 294, 165, 164, 5, NULL, '2025-12-14 07:32:56'),
(224, 318, 164, 165, 5, NULL, '2025-12-14 08:47:10'),
(225, 318, 165, 164, 5, NULL, '2025-12-14 08:47:11'),
(226, 320, 164, 165, 5, NULL, '2025-12-14 08:57:16'),
(227, 320, 165, 164, 5, NULL, '2025-12-14 08:57:17'),
(228, 321, 164, 165, 5, NULL, '2025-12-14 09:06:25'),
(229, 321, 165, 164, 5, NULL, '2025-12-14 09:06:26'),
(230, 323, 165, 164, 5, NULL, '2025-12-14 09:21:48'),
(231, 323, 164, 165, 5, NULL, '2025-12-14 09:21:49'),
(232, 324, 165, 164, 5, NULL, '2025-12-14 09:37:38'),
(233, 325, 164, 165, 5, NULL, '2025-12-14 09:47:25'),
(234, 325, 165, 164, 5, NULL, '2025-12-14 09:47:26'),
(235, 326, 165, 164, 5, NULL, '2025-12-14 09:48:33'),
(236, 326, 164, 165, 5, NULL, '2025-12-14 09:48:34');

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
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `actual_route` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`actual_route`))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Tablo döküm verisi `rides`
--

INSERT INTO `rides` (`id`, `passenger_id`, `driver_id`, `start_lat`, `start_lng`, `start_address`, `end_lat`, `end_lng`, `end_address`, `vehicle_type`, `options`, `payment_method`, `fare_estimate`, `fare_actual`, `status`, `cancel_reason`, `code4`, `created_at`, `updated_at`, `actual_route`) VALUES
(259, 164, 165, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 41.0189417, 29.0576298, 'Üsküdar/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":false,\"has_pet\":false}', 'nakit', 438.66, NULL, 'cancelled', 'Aracım arıza yaptı', '8141', '2025-12-13 17:44:06', '2025-12-13 17:46:29', NULL),
(260, 164, 165, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 40.9498022, 29.1739513, 'Maltepe/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":false,\"has_pet\":false}', 'nakit', 634.36, 550.00, 'completed', NULL, '2090', '2025-12-13 17:49:25', '2025-12-13 17:49:50', '[{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765648172402},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765648177402},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765648182399},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765648187400}]'),
(261, 164, 165, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 41.0189417, 29.0576298, 'Üsküdar/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":false,\"has_pet\":false}', 'nakit', 438.66, 600.00, 'completed', NULL, '7691', '2025-12-13 17:54:53', '2025-12-13 17:58:09', '[{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765648503628},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765648508619},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765648513613},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765648518639},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765648523618},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765648528613},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765648533615},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765648538615},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765648543613},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765648548613},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765648553613},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765648558614},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765648563614},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765648568613},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765648573614},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765648578613},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765648583614},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765648588612},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765648593613},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765648661230},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765648663515},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765648668513},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765648673511},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765648678511},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765648683520},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765648688514}]'),
(262, 164, NULL, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 40.9583172, 29.0968982, 'Bostancı, 34744 Kadıköy/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":false,\"has_pet\":false}', 'nakit', 247.36, NULL, 'cancelled', 'Başka bir araç buldum', '1972', '2025-12-13 18:00:08', '2025-12-13 18:00:11', NULL),
(263, 164, 165, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 40.9583172, 29.0968982, 'Bostancı, 34744 Kadıköy/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":false,\"has_pet\":false}', 'nakit', 247.36, 250.00, 'completed', NULL, '8905', '2025-12-13 18:01:41', '2025-12-13 18:02:02', '[{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765648912494},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765648917404},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765648922404}]'),
(264, 164, 165, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 41.0189417, 29.0576298, 'Üsküdar/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":false,\"has_pet\":false}', 'nakit', 438.66, 550.00, 'completed', NULL, '8509', '2025-12-13 18:08:05', '2025-12-13 18:08:26', '[{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765649293333},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765649298321},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765649303324}]'),
(265, 164, 165, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 40.9583172, 29.0968982, 'Bostancı, 34744 Kadıköy/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":false,\"has_pet\":false}', 'nakit', 247.36, 275.00, 'completed', NULL, '1019', '2025-12-13 18:15:44', '2025-12-13 18:16:06', '[{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765649758907},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765649763871}]'),
(266, 164, 165, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 41.0189417, 29.0576298, 'Üsküdar/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":false,\"has_pet\":false}', 'nakit', 438.66, 500.00, 'completed', NULL, '8106', '2025-12-13 18:19:34', '2025-12-13 18:20:26', '[{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765649994043},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765649999041},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765650004039},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765650009043},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765650014060},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765650019039},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765650024125}]'),
(267, 164, 165, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 40.9498022, 29.1739513, 'Maltepe/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":false,\"has_pet\":false}', 'nakit', 634.36, 400.00, 'completed', NULL, '2743', '2025-12-13 18:30:09', '2025-12-13 18:38:00', '[{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765650619238},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765650624335},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765650629236},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765650634237},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765650639239},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765650644243},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765650649239},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765650654239},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765650659240},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765650664238},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765650669237},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765650674242},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765650679240},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765650684240},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765650689239},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765650694239},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765650699238},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765650704239},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765650709241},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765650714238},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765650719236},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765650724245},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765650729237},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765650734236},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765650739238},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765650744237},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765650749237},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765650754238},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765650759237},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765650764240},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765650769241},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765650774237},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765650779238},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765650784239},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765650789239},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765650794241},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765650799241},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765650804239},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765650809237},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765650814243},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765650819236},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765650824238},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765650829238},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765650834242},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765650839237},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765650844239},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765650849238},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765650854238},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765650859237},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765650864239},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765650869236},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765650874237},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765650879237},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765650884239},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765650889239},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765650894237},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765650899238},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765651048668},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765651051285},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765651056284},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765651061283},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765651066283},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765651071282},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765651076312}]'),
(268, 164, 165, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 41.0189417, 29.0576298, 'Üsküdar/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":false,\"has_pet\":false}', 'nakit', 438.66, 450.00, 'completed', NULL, '1293', '2025-12-13 18:39:26', '2025-12-13 18:40:37', '[{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765651175320},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765651180303},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765651185308},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765651190302},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765651195301},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765651200301},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765651205304},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765651210317},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765651215310},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765651220302},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765651225301},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765651230304},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765651235303}]'),
(269, 164, 165, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 41.0189417, 29.0576298, 'Üsküdar/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":false,\"has_pet\":false}', 'nakit', 438.66, 550.00, 'completed', NULL, '3626', '2025-12-13 18:44:03', '2025-12-13 18:45:03', '[{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765651455309},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765651460230},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765651465233},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765651470234},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765651475236},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765651480233},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765651485232},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765651490230},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765651495231},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765651500419}]'),
(270, 164, 165, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 40.9498022, 29.1739513, 'Maltepe/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":false,\"has_pet\":false}', 'nakit', 634.36, 550.00, 'completed', NULL, '3645', '2025-12-13 18:49:24', '2025-12-13 18:49:58', '[{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765651773681},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765651778652},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765651783631},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765651788628},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765651793627}]'),
(271, 164, 165, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 41.0189417, 29.0576298, 'Üsküdar/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":false,\"has_pet\":false}', 'nakit', 438.66, 550.00, 'completed', NULL, '3190', '2025-12-13 18:50:09', '2025-12-13 18:51:45', '[{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765651818642},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765651823630},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765651828627},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765651833626},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765651838627},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765651843625},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765651848628},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765651853627},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765651858628},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765651863629},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765651868625},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765651873628},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765651878627},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765651883628},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765651888627},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765651893627},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765651898627},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765651903626}]'),
(272, 164, 165, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 40.9498022, 29.1739513, 'Maltepe/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":false,\"has_pet\":false}', 'nakit', 634.36, 350.00, 'completed', NULL, '4412', '2025-12-13 18:52:00', '2025-12-13 18:52:25', '[{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765651928638},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765651933628},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765651938628},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765651943630}]'),
(273, 164, NULL, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 41.0189417, 29.0576298, 'Üsküdar/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":false,\"has_pet\":false}', 'nakit', 438.66, NULL, 'cancelled', 'Sürücü gelmiyor', '2389', '2025-12-13 18:54:02', '2025-12-13 18:54:05', NULL),
(274, 164, 165, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 41.0189417, 29.0576298, 'Üsküdar/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":false,\"has_pet\":false}', 'nakit', 438.66, 375.00, 'completed', NULL, '8539', '2025-12-13 18:54:15', '2025-12-13 18:57:09', '[{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765652062948},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765652067913},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765652072733},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765652077724},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765652082716},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765652087721},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765652092735},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765652097717},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765652102720},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765652107717},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765652112718},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765652117719},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765652184099},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765652186300},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765652191147},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765652196148},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765652201150},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765652206149},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765652211148},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765652216146},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765652221150},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765652226189}]'),
(275, 164, 165, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 40.9498022, 29.1739513, 'Maltepe/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":false,\"has_pet\":false}', 'nakit', 634.36, 350.00, 'completed', NULL, '2617', '2025-12-13 19:26:31', '2025-12-13 19:27:09', '[{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765654003436},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765654008436},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765654013432},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765654018436},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765654023431},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765654028432}]'),
(276, 164, 165, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 40.9583172, 29.0968982, 'Bostancı, 34744 Kadıköy/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":false,\"has_pet\":false}', 'nakit', 247.36, 375.00, 'completed', NULL, '4609', '2025-12-13 19:27:37', '2025-12-13 19:28:48', '[{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765654068568},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765654073434},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765654078433},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765654083433},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765654088433},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765654093437},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765654098432},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765654103433},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765654108434},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765654113434},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765654118437},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765654123431},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765654128432}]'),
(277, 164, NULL, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 41.0189417, 29.0576298, 'Üsküdar/İstanbul, Türkiye', 'turkuaz', '{\"open_taximeter\":false,\"has_pet\":false}', 'nakit', 504.34, NULL, 'auto_rejected', NULL, '1172', '2025-12-13 19:30:45', '2025-12-13 19:31:05', NULL),
(278, 164, NULL, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 41.0189417, 29.0576298, 'Üsküdar/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":false,\"has_pet\":false}', 'nakit', 438.66, NULL, 'cancelled', 'Başka bir araç buldum', '5864', '2025-12-13 19:46:14', '2025-12-13 19:46:27', NULL),
(279, 164, NULL, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 40.9498022, 29.1739513, 'Maltepe/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":false,\"has_pet\":false}', 'nakit', 634.36, NULL, 'auto_rejected', NULL, '7780', '2025-12-13 20:14:04', '2025-12-13 20:14:25', NULL),
(280, 164, 165, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 40.9498022, 29.1739513, 'Maltepe/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":false,\"has_pet\":false}', 'nakit', 634.36, 475.00, 'completed', NULL, '4173', '2025-12-13 20:17:03', '2025-12-13 20:17:37', '[{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765657035653},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765657040281},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765657045280},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765657050283},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765657055282}]'),
(281, 164, 165, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 40.99410929176251, 29.11404462531209, 'X4V7+JJ Ataşehir/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":false,\"has_pet\":false}', 'nakit', 191.64, 275.00, 'completed', NULL, '2170', '2025-12-13 20:41:10', '2025-12-13 20:44:46', '[{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765658488083},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765658491950},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765658496860},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765658501865},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765658506875},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765658511862},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765658516868},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765658521860},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765658526860},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765658531863},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765658536860},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765658541862},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765658546862},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765658551869},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765658556866},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765658561865},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765658566862},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765658571860},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765658576860},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765658581859},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765658676973},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765658678929},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765658684033}]'),
(282, 164, 165, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 41.052793927080984, 29.074330497533083, 'Güzeltepe, Çağdaş Sokağı 10 A, 34680 Üsküdar/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":false,\"has_pet\":false}', 'nakit', 571.09, 400.00, 'completed', NULL, '6935', '2025-12-13 20:47:11', '2025-12-13 20:47:47', '[{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765658838683},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765658843474},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765658848509},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765658853478},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765658858491},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765658863471}]'),
(283, 164, 165, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 40.99536283468261, 29.100699964910746, 'Barbaros, Mor Sumbul Sokagi no4, 34750 Ataşehir/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":false,\"has_pet\":false}', 'nakit', 175.00, 200.00, 'completed', NULL, '1557', '2025-12-13 20:51:51', '2025-12-13 20:52:19', '[{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765659118818},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765659123345},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765659128559},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765659133323},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765659138320}]'),
(284, 164, 165, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 41.0168639, 28.9470422, 'Fatih/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":true,\"has_pet\":true}', 'nakit', 732.11, 650.00, 'completed', NULL, '1838', '2025-12-14 06:48:30', '2025-12-14 06:48:53', '[{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765694921879},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765694926851},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765694931851}]'),
(285, 164, 165, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 40.9498022, 29.1739513, 'Maltepe/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":false,\"has_pet\":false}', 'nakit', 634.36, 450.00, 'completed', NULL, '6057', '2025-12-14 06:59:14', '2025-12-14 06:59:37', '[{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765695562056},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765695566987},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765695571996},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765695576991}]'),
(286, 164, NULL, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 41.1121881, 29.0199726, 'Maslak, Sarıyer/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":false,\"has_pet\":false}', 'nakit', 1006.87, NULL, 'auto_rejected', NULL, '9354', '2025-12-14 07:04:42', '2025-12-14 07:05:03', NULL),
(287, 164, 165, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 41.0189417, 29.0576298, 'Üsküdar/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":false,\"has_pet\":false}', 'nakit', 438.66, 425.00, 'completed', NULL, '4028', '2025-12-14 07:07:47', '2025-12-14 07:08:11', '[{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765696073334},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765696077769},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765696082765},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765696087766}]'),
(288, 164, 165, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 41.0287028, 29.2901829, 'Sancaktepe/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":false,\"has_pet\":false}', 'nakit', 1142.59, NULL, 'cancelled', 'Aracım arıza yaptı', '5878', '2025-12-14 07:08:25', '2025-12-14 07:11:13', NULL),
(289, 164, NULL, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 41.0189417, 29.0576298, 'Üsküdar/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":false,\"has_pet\":false}', 'nakit', 438.66, NULL, 'cancelled', 'Yanlış konum seçtim', '9738', '2025-12-14 07:13:24', '2025-12-14 07:13:32', NULL),
(290, 164, 165, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 40.879326, 29.258135, 'Pendik, Kaynarca, 34890 Pendik/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":false,\"has_pet\":false}', 'nakit', 880.11, 450.00, 'completed', NULL, '3418', '2025-12-14 07:13:40', '2025-12-14 07:14:03', '[{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765696429127},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765696434066},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765696439059}]'),
(291, 164, 165, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 40.9128704, 29.2988966, 'Kurtköy, Pendik/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":false,\"has_pet\":false}', 'nakit', 941.71, NULL, 'cancelled', 'Sürücü gelmiyor', '8553', '2025-12-14 07:14:24', '2025-12-14 07:16:02', NULL),
(292, 164, NULL, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 41.0189417, 29.0576298, 'Üsküdar/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":false,\"has_pet\":false}', 'nakit', 438.66, NULL, 'cancelled', 'Sürücü çok uzakta', '8633', '2025-12-14 07:18:51', '2025-12-14 07:18:58', NULL),
(293, 164, 165, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 41.0261264, 29.0954013, 'Atatürk, Fatih Sultan Mehmet Cd. No:31, 34764 Ümraniye/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":false,\"has_pet\":false}', 'nakit', 440.19, 450.00, 'completed', NULL, '1385', '2025-12-14 07:19:13', '2025-12-14 07:21:25', '[{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765696760123},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765696765064},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765696770062},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765696775065},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765696780070},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765696785064},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765696790063},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765696795064},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765696800063},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765696805062},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765696810063},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765696815061},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765696820065},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765696825065},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765696830071},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765696835066},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765696840065},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765696845062},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765696850065},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765696855065},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765696860065},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765696865065},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765696870064},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765696875064},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765696880066},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765696885064}]'),
(294, 164, 165, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 41.0189417, 29.0576298, 'Üsküdar/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":false,\"has_pet\":false}', 'nakit', 438.66, 386.00, 'completed', NULL, '4682', '2025-12-14 07:32:25', '2025-12-14 07:32:53', '[{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765697553357},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765697558357},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765697563356},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765697568357},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765697573360}]'),
(295, 164, 165, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 40.9817556, 29.146333, 'Kayışdağı, 34755 Ataşehir/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":true,\"has_pet\":true}', 'nakit', 175.00, NULL, 'cancelled', 'Acil durum', '7927', '2025-12-14 07:43:58', '2025-12-14 07:44:19', NULL),
(296, 164, NULL, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 40.9498022, 29.1739513, 'Maltepe/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":false,\"has_pet\":false}', 'nakit', 634.36, NULL, 'cancelled', 'Başka bir araç buldum', '1770', '2025-12-14 07:47:57', '2025-12-14 07:48:14', NULL),
(297, 164, NULL, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 40.9498022, 29.1739513, 'Maltepe/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":true,\"has_pet\":true}', 'nakit', 634.36, NULL, 'auto_rejected', NULL, '5106', '2025-12-14 07:48:27', '2025-12-14 07:48:48', NULL),
(298, 164, NULL, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 41.0189417, 29.0576298, 'Üsküdar/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":true,\"has_pet\":true}', 'nakit', 438.66, NULL, 'auto_rejected', NULL, '8209', '2025-12-14 07:49:04', '2025-12-14 07:49:25', NULL),
(299, 164, 165, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 40.9498022, 29.1739513, 'Maltepe/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":false,\"has_pet\":false}', 'nakit', 634.36, NULL, 'cancelled', 'Acil durum', '9061', '2025-12-14 07:56:36', '2025-12-14 07:56:51', NULL),
(300, 164, NULL, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 41.0189417, 29.0576298, 'Üsküdar/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":true,\"has_pet\":true}', 'nakit', 438.66, NULL, 'auto_rejected', NULL, '5123', '2025-12-14 07:57:04', '2025-12-14 07:57:24', NULL),
(301, 164, NULL, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 40.9498022, 29.1739513, 'Maltepe/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":false,\"has_pet\":false}', 'nakit', 634.36, NULL, 'cancelled', 'Fikir değiştirdim', '1211', '2025-12-14 07:57:36', '2025-12-14 07:57:51', NULL),
(302, 164, NULL, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 41.0189417, 29.0576298, 'Üsküdar/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":true,\"has_pet\":true}', 'nakit', 438.66, NULL, 'auto_rejected', NULL, '6799', '2025-12-14 07:58:10', '2025-12-14 07:58:30', NULL),
(303, 164, 165, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 40.9498022, 29.1739513, 'Maltepe/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":true,\"has_pet\":true}', 'nakit', 634.36, NULL, 'cancelled', 'Acil durum', '4851', '2025-12-14 08:02:39', '2025-12-14 08:02:54', NULL),
(304, 164, NULL, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 40.9818744, 29.0576298, 'Kadıköy/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":false,\"has_pet\":false}', 'nakit', 375.17, NULL, 'cancelled', 'Sürücü gelmiyor', '9260', '2025-12-14 08:03:05', '2025-12-14 08:03:22', NULL),
(305, 164, 165, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 41.0189417, 29.0576298, 'Üsküdar/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":false,\"has_pet\":false}', 'nakit', 438.66, NULL, 'cancelled', 'Acil durum', '2201', '2025-12-14 08:07:56', '2025-12-14 08:08:08', NULL),
(306, 164, NULL, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 40.9498022, 29.1739513, 'Maltepe/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":false,\"has_pet\":false}', 'nakit', 634.36, NULL, 'cancelled', 'Başka bir araç buldum', '3847', '2025-12-14 08:08:18', '2025-12-14 08:08:34', NULL),
(307, 164, 165, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 41.0189417, 29.0576298, 'Üsküdar/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":false,\"has_pet\":false}', 'nakit', 438.66, NULL, 'cancelled', 'Sürücü gelmiyor', '3775', '2025-12-14 08:08:44', '2025-12-14 08:08:55', NULL),
(308, 164, NULL, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 40.9818744, 29.0576298, 'Kadıköy/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":false,\"has_pet\":false}', 'nakit', 375.17, NULL, 'cancelled', 'Yanlış konum seçtim', '3448', '2025-12-14 08:09:07', '2025-12-14 08:09:16', NULL),
(309, 164, 165, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 40.9498022, 29.1739513, 'Maltepe/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":false,\"has_pet\":false}', 'nakit', 634.36, NULL, 'cancelled', 'Acil durum', '7888', '2025-12-14 08:13:08', '2025-12-14 08:13:29', NULL),
(310, 164, NULL, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 41.0189417, 29.0576298, 'Üsküdar/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":false,\"has_pet\":false}', 'nakit', 438.66, NULL, 'cancelled', 'Yanlış konum seçtim', '7953', '2025-12-14 08:13:40', '2025-12-14 08:14:00', NULL),
(311, 164, 165, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 41.0189417, 29.0576298, 'Üsküdar/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":false,\"has_pet\":false}', 'nakit', 438.66, NULL, 'cancelled', 'Acil durum', '6314', '2025-12-14 08:20:37', '2025-12-14 08:20:53', NULL),
(312, 164, 165, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 40.9498022, 29.1739513, 'Maltepe/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":false,\"has_pet\":false}', 'nakit', 634.36, NULL, 'cancelled', 'Aracım arıza yaptı', '5386', '2025-12-14 08:21:07', '2025-12-14 08:21:21', NULL),
(313, 164, NULL, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 41.1121881, 29.0199726, 'Maslak, Sarıyer/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":false,\"has_pet\":false}', 'nakit', 1006.87, NULL, 'cancelled', 'Yanlış konum seçtim', '3298', '2025-12-14 08:22:14', '2025-12-14 08:22:28', NULL),
(314, 164, NULL, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 41.0189417, 29.0576298, 'Üsküdar/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":false,\"has_pet\":false}', 'nakit', 438.66, NULL, 'auto_rejected', NULL, '8379', '2025-12-14 08:31:56', '2025-12-14 08:32:16', NULL),
(315, 164, NULL, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 41.0189417, 29.0576298, 'Üsküdar/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":false,\"has_pet\":false}', 'nakit', 438.66, NULL, 'auto_rejected', NULL, '1739', '2025-12-14 08:36:05', '2025-12-14 08:36:25', NULL),
(316, 164, 165, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 40.985665, 29.155087, 'Mevlana, Fatih Cd. No:9, 34779 Ataşehir/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":true,\"has_pet\":true}', 'nakit', 175.00, NULL, 'cancelled', 'Acil durum', '6998', '2025-12-14 08:37:25', '2025-12-14 08:37:40', NULL),
(317, 164, 165, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 40.9498022, 29.1739513, 'Maltepe/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":true,\"has_pet\":true}', 'pos', 634.36, NULL, 'cancelled', 'Acil durum', '9750', '2025-12-14 08:45:51', '2025-12-14 08:46:11', NULL),
(318, 164, 165, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 41.067751, 29.0433819, 'Arnavutköy, Satış Meydanı Sk. No:9, 34345 Beşiktaş/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":true,\"has_pet\":false}', 'nakit', 907.19, 786.00, 'completed', NULL, '9874', '2025-12-14 08:46:30', '2025-12-14 08:47:07', '[{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765702005299},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765702010297},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765702015295},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765702020294},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765702025308}]'),
(319, 164, 165, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 41.03930163987801, 29.080964773893356, 'Yavuztürk, Türkler Sk. 9-2, 34690 Üsküdar/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":false,\"has_pet\":false}', 'nakit', 496.67, NULL, 'cancelled', 'Sürücü gelmiyor', '9144', '2025-12-14 08:47:56', '2025-12-14 08:50:46', NULL),
(320, 164, 165, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 41.0266305, 28.92215749999999, 'Orta, Anıt Sokağı no:2 D:1, B Blok, 34040 Bayrampaşa/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":true,\"has_pet\":true}', 'nakit', 1611.30, 1611.00, 'completed', NULL, '4007', '2025-12-14 08:56:46', '2025-12-14 08:57:13', '[{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765702617757},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765702622700},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765702627698},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765702632697}]'),
(321, 164, 165, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 40.9895751, 29.1361718, 'Atatürk, 3. Cd. No:6, 34758 Ataşehir/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":false,\"has_pet\":true}', 'nakit', 175.00, 215.00, 'completed', NULL, '5530', '2025-12-14 09:05:53', '2025-12-14 09:06:21', '[{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765703165372},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765703170189},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765703175198},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765703180175}]'),
(322, 164, 165, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 41.104235, 29.3177272, 'Çekmeköy/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":true,\"has_pet\":true}', 'nakit', 1250.95, NULL, 'cancelled', 'Acil durum', '8163', '2025-12-14 09:14:51', '2025-12-14 09:17:24', NULL),
(323, 164, 165, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 40.880074, 29.231431, 'Batı, Hatboyu Cd. No:42 D:48, 34890 Pendik/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":true,\"has_pet\":true}', 'nakit', 884.64, 900.00, 'completed', NULL, '9964', '2025-12-14 09:20:43', '2025-12-14 09:21:42', '[{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704055919},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704060970},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704065915},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704070916},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704075919},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704080921},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704085924},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704090921},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704095918},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704100916}]'),
(324, 164, 165, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 40.9567576, 29.1013549, 'Bostancı, Mehmet Şevki Paşa Cd. No:8, 34744 Kadıköy/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":true,\"has_pet\":false}', 'nakit', 252.12, 250.00, 'completed', NULL, '1315', '2025-12-14 09:26:39', '2025-12-14 09:37:35', '[{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704411301},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704416242},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704421243},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704426242},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704431245},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704436246},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704441251},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704446245},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704451248},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704456246},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704461248},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704466250},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704471246},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704476242},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704481263},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704486254},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704491247},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704496257},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704501250},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704506259},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704511252},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704516245},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704521251},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704526247},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704531250},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704536247},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704541247},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704546246},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704551248},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704556246},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704561248},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704566246},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704571248},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704576248},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704581245},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704586245},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704591249},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704596246},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704601246},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704606248},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704611245},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704616246},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704621248},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704626249},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704631249},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704636247},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704641252},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704646246},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704651249},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704656242},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704661249},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704666249},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704671243},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704676248},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704681248},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704686247},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704691249},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704696245},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704701245},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704706246},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704711246},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704716251},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704721245},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704726246},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704731247},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704736245},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704741246},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704746249},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704751247},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704756245},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704761245},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704766247},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704771245},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704776247},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704781245},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704786254},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704791247},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704796248},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704801244},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704806252},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704811242},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704816252},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704821245},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704826247},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704831248},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704836243},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704841244},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704846242},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704851247},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704856253},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704861254},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704866292},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704959710},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704961544},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704966513},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704971512},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704976521},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704981514},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704986515},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704991513},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765704996514},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765705001514},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765705006513},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765705011515},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765705016513},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765705021514},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765705026522},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765705031515},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765705036515},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765705041513},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765705046514},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765705051513}]'),
(325, 164, 165, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 40.9498022, 29.1739513, 'Maltepe/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":true,\"has_pet\":true}', 'nakit', 634.36, 475.00, 'completed', NULL, '7693', '2025-12-14 09:46:38', '2025-12-14 09:47:21', '[{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765705615657},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765705620600},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765705625600},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765705630601},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765705635602},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765705640599}]'),
(326, 164, 165, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 41.0231235, 29.0674, 'Kısıklı, Turistik Çamlıca Cd. No:17, 34692 Üsküdar/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":false,\"has_pet\":false}', 'nakit', 444.73, 475.00, 'completed', NULL, '8567', '2025-12-14 09:47:50', '2025-12-14 09:48:30', '[{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765705680692},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765705685604},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765705690602},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765705695628},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765705700600},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765705705601},{\"lat\":40.9923,\"lng\":29.1276,\"ts\":1765705710601}]'),
(327, 164, 165, 40.9923, 29.1276, 'Atatürk, Ataşehir Blv. NO:20, 34758 Ataşehir/İstanbul, Türkiye', 40.9498022, 29.1739513, 'Maltepe/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":true,\"has_pet\":true}', 'pos', 634.36, NULL, 'cancelled', 'Yolcu yanlış konumda', '9854', '2025-12-14 10:07:43', '2025-12-14 10:08:42', NULL);

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

--
-- Tablo döküm verisi `ride_messages`
--

INSERT INTO `ride_messages` (`id`, `ride_id`, `sender_id`, `message`, `created_at`) VALUES
(51, 327, 165, 'Trafikteyim', '2025-12-14 10:08:36'),
(52, 327, 164, 'Neredesiniz?', '2025-12-14 10:08:37'),
(53, 326, 164, 'selamlar cantami unuttum', '2025-12-14 10:09:14');

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
(218, 259, 165, '2025-12-13 17:44:06', 'accepted', '2025-12-13 17:44:16', 0),
(219, 260, 165, '2025-12-13 17:49:25', 'accepted', '2025-12-13 17:49:30', 0),
(220, 261, 165, '2025-12-13 17:54:53', 'accepted', '2025-12-13 17:55:02', 0),
(221, 262, 165, '2025-12-13 18:00:08', 'no_response', NULL, 0),
(222, 263, 165, '2025-12-13 18:01:41', 'accepted', '2025-12-13 18:01:48', 0),
(223, 264, 165, '2025-12-13 18:08:05', 'accepted', '2025-12-13 18:08:11', 0),
(224, 265, 165, '2025-12-13 18:15:44', 'accepted', '2025-12-13 18:15:54', 0),
(225, 266, 165, '2025-12-13 18:19:34', 'accepted', '2025-12-13 18:19:50', 0),
(226, 267, 165, '2025-12-13 18:30:09', 'accepted', '2025-12-13 18:30:14', 0),
(227, 268, 165, '2025-12-13 18:39:26', 'accepted', '2025-12-13 18:39:32', 0),
(228, 269, 165, '2025-12-13 18:44:03', 'accepted', '2025-12-13 18:44:11', 0),
(229, 270, 165, '2025-12-13 18:49:24', 'accepted', '2025-12-13 18:49:31', 0),
(230, 271, 165, '2025-12-13 18:50:09', 'accepted', '2025-12-13 18:50:15', 0),
(231, 272, 165, '2025-12-13 18:52:00', 'accepted', '2025-12-13 18:52:06', 0),
(232, 273, 165, '2025-12-13 18:54:02', 'no_response', NULL, 0),
(233, 274, 165, '2025-12-13 18:54:15', 'accepted', '2025-12-13 18:54:22', 0),
(234, 275, 165, '2025-12-13 19:26:31', 'accepted', '2025-12-13 19:26:38', 0),
(235, 276, 165, '2025-12-13 19:27:37', 'accepted', '2025-12-13 19:27:47', 0),
(236, 280, 165, '2025-12-13 20:17:03', 'accepted', '2025-12-13 20:17:14', 0),
(237, 281, 165, '2025-12-13 20:41:10', 'accepted', '2025-12-13 20:41:22', 0),
(238, 282, 165, '2025-12-13 20:47:11', 'accepted', '2025-12-13 20:47:17', 0),
(239, 283, 165, '2025-12-13 20:51:51', 'accepted', '2025-12-13 20:51:58', 0),
(240, 284, 165, '2025-12-14 06:48:30', 'accepted', '2025-12-14 06:48:38', 0),
(241, 285, 165, '2025-12-14 06:59:14', 'accepted', '2025-12-14 06:59:20', 0),
(242, 286, 165, '2025-12-14 07:04:42', 'no_response', NULL, 1),
(243, 287, 165, '2025-12-14 07:07:47', 'accepted', '2025-12-14 07:07:52', 0),
(244, 288, 165, '2025-12-14 07:08:25', 'accepted', '2025-12-14 07:08:31', 0),
(245, 290, 165, '2025-12-14 07:13:40', 'accepted', '2025-12-14 07:13:47', 0),
(246, 291, 165, '2025-12-14 07:14:24', 'accepted', '2025-12-14 07:14:31', 0),
(247, 293, 165, '2025-12-14 07:19:13', 'accepted', '2025-12-14 07:19:20', 0),
(248, 294, 165, '2025-12-14 07:32:25', 'accepted', '2025-12-14 07:32:30', 0),
(249, 295, 165, '2025-12-14 07:43:58', 'accepted', '2025-12-14 07:44:14', 0),
(250, 296, 165, '2025-12-14 07:47:57', 'no_response', NULL, 0),
(251, 297, 165, '2025-12-14 07:48:27', 'no_response', NULL, 1),
(252, 298, 165, '2025-12-14 07:49:04', 'no_response', NULL, 1),
(253, 299, 165, '2025-12-14 07:56:36', 'accepted', '2025-12-14 07:56:45', 0),
(254, 303, 165, '2025-12-14 08:02:39', 'accepted', '2025-12-14 08:02:49', 0),
(255, 305, 165, '2025-12-14 08:07:56', 'accepted', '2025-12-14 08:08:03', 0),
(256, 307, 165, '2025-12-14 08:08:44', 'accepted', '2025-12-14 08:08:52', 0),
(257, 309, 165, '2025-12-14 08:13:08', 'accepted', '2025-12-14 08:13:23', 0),
(258, 311, 165, '2025-12-14 08:20:37', 'accepted', '2025-12-14 08:20:48', 0),
(259, 312, 165, '2025-12-14 08:21:07', 'accepted', '2025-12-14 08:21:13', 0),
(260, 313, 165, '2025-12-14 08:22:14', 'no_response', NULL, 0),
(261, 314, 165, '2025-12-14 08:31:56', 'no_response', NULL, 1),
(262, 315, 165, '2025-12-14 08:36:05', 'no_response', NULL, 1),
(263, 316, 165, '2025-12-14 08:37:25', 'accepted', '2025-12-14 08:37:36', 0),
(264, 317, 165, '2025-12-14 08:45:51', 'accepted', '2025-12-14 08:46:06', 0),
(265, 318, 165, '2025-12-14 08:46:30', 'accepted', '2025-12-14 08:46:40', 0),
(266, 319, 165, '2025-12-14 08:47:56', 'accepted', '2025-12-14 08:48:09', 0),
(267, 320, 165, '2025-12-14 08:56:46', 'accepted', '2025-12-14 08:56:55', 0),
(268, 321, 165, '2025-12-14 09:05:53', 'accepted', '2025-12-14 09:06:01', 0),
(269, 322, 165, '2025-12-14 09:14:51', 'accepted', '2025-12-14 09:15:00', 0),
(270, 323, 165, '2025-12-14 09:20:43', 'accepted', '2025-12-14 09:20:52', 0),
(271, 324, 165, '2025-12-14 09:26:39', 'accepted', '2025-12-14 09:26:48', 0),
(272, 325, 165, '2025-12-14 09:46:38', 'accepted', '2025-12-14 09:46:50', 0),
(273, 326, 165, '2025-12-14 09:47:50', 'accepted', '2025-12-14 09:47:59', 0),
(274, 327, 165, '2025-12-14 10:07:43', 'accepted', '2025-12-14 10:07:54', 0);

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
-- Tablo için tablo yapısı `support_messages`
--

CREATE TABLE `support_messages` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `ticket_id` bigint(20) UNSIGNED NOT NULL,
  `sender_id` bigint(20) UNSIGNED NOT NULL,
  `sender_type` enum('user','admin') NOT NULL,
  `message` text NOT NULL,
  `is_read` tinyint(1) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Tablo döküm verisi `support_messages`
--

INSERT INTO `support_messages` (`id`, `ticket_id`, `sender_id`, `sender_type`, `message`, `is_read`, `created_at`) VALUES
(3, 3, 165, 'user', 'selamlar', 0, '2025-12-14 08:56:30');

-- --------------------------------------------------------

--
-- Tablo için tablo yapısı `support_tickets`
--

CREATE TABLE `support_tickets` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `subject` varchar(255) NOT NULL,
  `status` enum('open','answered','closed') DEFAULT 'open',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Tablo döküm verisi `support_tickets`
--

INSERT INTO `support_tickets` (`id`, `user_id`, `subject`, `status`, `created_at`, `updated_at`) VALUES
(3, 165, 'merhaba', 'open', '2025-12-14 08:56:29', '2025-12-14 08:56:29');

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

INSERT INTO `users` (`id`, `role`, `first_name`, `last_name`, `phone`, `profile_photo`, `is_active`, `created_at`, `updated_at`, `ref_code`, `referrer_id`, `ref_count`, `level`, `fcm_token`) VALUES
(164, 'passenger', 'polat', 'gungor', '+905070181758', NULL, 1, '2025-12-13 17:31:15', '2025-12-14 09:49:31', 'TB164', NULL, 14, 'standard', NULL),
(165, 'driver', 'Dat', 'Gungor', '+905346884385', 'uploads/drivers/driver-1765647392955-468247445.jpg', 1, '2025-12-13 17:36:33', '2025-12-13 17:36:33', 'TB165', NULL, 0, 'standard', NULL);

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
(49, 164, 'fOnOB-yFSO-MlNgj4mB-iy:APA91bFNgaTEr8EJYstwNOVQHRSqSNQfcxc6FQjP-1ZFwEyj3L_pB0Vfyapc8PsYB1RAfiWGE9cBYSIAdlixy-KhSGvJqQQZYI-F5zAqgSmbddCxL4W6WIA', 'android', '2025-12-13 17:31:36'),
(50, 165, 'fTF0d9tzR-CoVJxq-mu6Ys:APA91bGaxYsgWySKJS8fiVwsNPfhX0315zjgbN8x4C4Q8RYqNDFtXaAQxbGiTbdrR_Rh2zRm2GOy-bCQaMuFQkBeHp6rAWt2Tf2x1ZI3Azi4fMtfRaNh7xI', 'android', '2025-12-13 17:38:02');

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
(6, 165, 15548.00, 15548.00, 'TRY', '2025-12-13 17:49:50', '2025-12-14 09:48:30');

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
(25, 6, 550.00, 'ride_earnings', 260, 'Yolculuk Kazancı - Ride #260', '2025-12-13 17:49:50'),
(26, 6, 600.00, 'ride_earnings', 261, 'Yolculuk Kazancı - Ride #261', '2025-12-13 17:58:09'),
(27, 6, 250.00, 'ride_earnings', 263, 'Yolculuk Kazancı - Ride #263', '2025-12-13 18:02:02'),
(28, 6, 550.00, 'ride_earnings', 264, 'Yolculuk Kazancı - Ride #264', '2025-12-13 18:08:26'),
(29, 6, 275.00, 'ride_earnings', 265, 'Yolculuk Kazancı - Ride #265', '2025-12-13 18:16:06'),
(30, 6, 500.00, 'ride_earnings', 266, 'Yolculuk Kazancı - Ride #266', '2025-12-13 18:20:26'),
(31, 6, 400.00, 'ride_earnings', 267, 'Yolculuk Kazancı - Ride #267', '2025-12-13 18:38:00'),
(32, 6, 450.00, 'ride_earnings', 268, 'Yolculuk Kazancı - Ride #268', '2025-12-13 18:40:37'),
(33, 6, 550.00, 'ride_earnings', 269, 'Yolculuk Kazancı - Ride #269', '2025-12-13 18:45:03'),
(34, 6, 550.00, 'ride_earnings', 270, 'Yolculuk Kazancı - Ride #270', '2025-12-13 18:49:58'),
(35, 6, 550.00, 'ride_earnings', 271, 'Yolculuk Kazancı - Ride #271', '2025-12-13 18:51:45'),
(36, 6, 350.00, 'ride_earnings', 272, 'Yolculuk Kazancı - Ride #272', '2025-12-13 18:52:25'),
(37, 6, 375.00, 'ride_earnings', 274, 'Yolculuk Kazancı - Ride #274', '2025-12-13 18:57:09'),
(38, 6, 350.00, 'ride_earnings', 275, 'Yolculuk Kazancı - Ride #275', '2025-12-13 19:27:09'),
(39, 6, 375.00, 'ride_earnings', 276, 'Yolculuk Kazancı - Ride #276', '2025-12-13 19:28:48'),
(40, 6, 475.00, 'ride_earnings', 280, 'Yolculuk Kazancı - Ride #280', '2025-12-13 20:17:37'),
(41, 6, 275.00, 'ride_earnings', 281, 'Yolculuk Kazancı - Ride #281', '2025-12-13 20:44:46'),
(42, 6, 400.00, 'ride_earnings', 282, 'Yolculuk Kazancı - Ride #282', '2025-12-13 20:47:47'),
(43, 6, 200.00, 'ride_earnings', 283, 'Yolculuk Kazancı - Ride #283', '2025-12-13 20:52:19'),
(44, 6, 650.00, 'ride_earnings', 284, 'Yolculuk Kazancı - Ride #284', '2025-12-14 06:48:53'),
(45, 6, 450.00, 'ride_earnings', 285, 'Yolculuk Kazancı - Ride #285', '2025-12-14 06:59:37'),
(46, 6, 425.00, 'ride_earnings', 287, 'Yolculuk Kazancı - Ride #287', '2025-12-14 07:08:11'),
(47, 6, 450.00, 'ride_earnings', 290, 'Yolculuk Kazancı - Ride #290', '2025-12-14 07:14:03'),
(48, 6, 450.00, 'ride_earnings', 293, 'Yolculuk Kazancı - Ride #293', '2025-12-14 07:21:25'),
(49, 6, 386.00, 'ride_earnings', 294, 'Yolculuk Kazancı - Ride #294', '2025-12-14 07:32:53'),
(50, 6, 786.00, 'ride_earnings', 318, 'Yolculuk Kazancı - Ride #318', '2025-12-14 08:47:07'),
(51, 6, 1611.00, 'ride_earnings', 320, 'Yolculuk Kazancı - Ride #320', '2025-12-14 08:57:13'),
(52, 6, 215.00, 'ride_earnings', 321, 'Yolculuk Kazancı - Ride #321', '2025-12-14 09:06:21'),
(53, 6, 900.00, 'ride_earnings', 323, 'Yolculuk Kazancı - Ride #323', '2025-12-14 09:21:42'),
(54, 6, 250.00, 'ride_earnings', 324, 'Yolculuk Kazancı - Ride #324', '2025-12-14 09:37:35'),
(55, 6, 475.00, 'ride_earnings', 325, 'Yolculuk Kazancı - Ride #325', '2025-12-14 09:47:21'),
(56, 6, 475.00, 'ride_earnings', 326, 'Yolculuk Kazancı - Ride #326', '2025-12-14 09:48:30');

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
-- Tablo için indeksler `support_messages`
--
ALTER TABLE `support_messages`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_support_messages_ticket` (`ticket_id`);

--
-- Tablo için indeksler `support_tickets`
--
ALTER TABLE `support_tickets`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_support_tickets_user` (`user_id`);

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
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=392;

--
-- Tablo için AUTO_INCREMENT değeri `ratings`
--
ALTER TABLE `ratings`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=237;

--
-- Tablo için AUTO_INCREMENT değeri `rides`
--
ALTER TABLE `rides`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=328;

--
-- Tablo için AUTO_INCREMENT değeri `ride_messages`
--
ALTER TABLE `ride_messages`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=54;

--
-- Tablo için AUTO_INCREMENT değeri `ride_requests`
--
ALTER TABLE `ride_requests`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=275;

--
-- Tablo için AUTO_INCREMENT değeri `saved_places`
--
ALTER TABLE `saved_places`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- Tablo için AUTO_INCREMENT değeri `support_messages`
--
ALTER TABLE `support_messages`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- Tablo için AUTO_INCREMENT değeri `support_tickets`
--
ALTER TABLE `support_tickets`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- Tablo için AUTO_INCREMENT değeri `users`
--
ALTER TABLE `users`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=166;

--
-- Tablo için AUTO_INCREMENT değeri `user_devices`
--
ALTER TABLE `user_devices`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=51;

--
-- Tablo için AUTO_INCREMENT değeri `wallets`
--
ALTER TABLE `wallets`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- Tablo için AUTO_INCREMENT değeri `wallet_transactions`
--
ALTER TABLE `wallet_transactions`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=57;

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
-- Tablo kısıtlamaları `support_messages`
--
ALTER TABLE `support_messages`
  ADD CONSTRAINT `support_messages_ibfk_1` FOREIGN KEY (`ticket_id`) REFERENCES `support_tickets` (`id`) ON DELETE CASCADE;

--
-- Tablo kısıtlamaları `support_tickets`
--
ALTER TABLE `support_tickets`
  ADD CONSTRAINT `support_tickets_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

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
