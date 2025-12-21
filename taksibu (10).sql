-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Anamakine: 127.0.0.1
-- Üretim Zamanı: 02 Ara 2025, 11:45:12
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
  `status` enum('pending','approved','rejected','banned') DEFAULT 'pending',
  `is_available` tinyint(1) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Tablo döküm verisi `drivers`
--

INSERT INTO `drivers` (`user_id`, `driver_card_number`, `vehicle_plate`, `vehicle_type`, `vehicle_license_file`, `status`, `is_available`, `created_at`, `updated_at`) VALUES
(139, NULL, NULL, 'sari', NULL, 'approved', 1, '2025-11-20 07:33:47', '2025-11-20 12:24:29');

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
(86, 138, 'ride_auto_rejected', 'Çağrı reddedildi', 'Maalesef çağrınıza hiç sürücü cevap vermedi.', '{\"ride_id\":65}', 0, '2025-11-17 18:11:32'),
(87, 138, 'ride_auto_rejected', 'Çağrı reddedildi', 'Maalesef çağrınıza hiç sürücü cevap vermedi.', '{\"ride_id\":66}', 0, '2025-11-17 18:11:37'),
(88, 138, 'ride_auto_rejected', 'Çağrı reddedildi', 'Maalesef çağrınıza hiç sürücü cevap vermedi.', '{\"ride_id\":67}', 0, '2025-11-17 18:15:03'),
(89, 138, 'ride_auto_rejected', 'Çağrı reddedildi', 'Maalesef çağrınıza hiç sürücü cevap vermedi.', '{\"ride_id\":68}', 0, '2025-11-17 18:28:56'),
(90, 138, 'ride_auto_rejected', 'Çağrı reddedildi', 'Maalesef çağrınıza hiç sürücü cevap vermedi.', '{\"ride_id\":69}', 0, '2025-11-17 18:33:11'),
(91, 138, 'ride_auto_rejected', 'Çağrı reddedildi', 'Maalesef çağrınıza hiç sürücü cevap vermedi.', '{\"ride_id\":70}', 0, '2025-11-17 18:36:37'),
(92, 138, 'ride_auto_rejected', 'Çağrı reddedildi', 'Maalesef çağrınıza hiç sürücü cevap vermedi.', '{\"ride_id\":71}', 0, '2025-11-17 18:38:18'),
(93, 138, 'ride_auto_rejected', 'Çağrı reddedildi', 'Maalesef çağrınıza hiç sürücü cevap vermedi.', '{\"ride_id\":72}', 0, '2025-11-17 18:40:28'),
(94, 138, 'ride_auto_rejected', 'Çağrı reddedildi', 'Maalesef çağrınıza hiç sürücü cevap vermedi.', '{\"ride_id\":73}', 0, '2025-11-17 18:42:50'),
(95, 138, 'ride_auto_rejected', 'Çağrı reddedildi', 'Maalesef çağrınıza hiç sürücü cevap vermedi.', '{\"ride_id\":74}', 0, '2025-11-19 20:24:01'),
(96, 138, 'ride_auto_rejected', 'Çağrı reddedildi', 'Maalesef çağrınıza hiç sürücü cevap vermedi.', '{\"ride_id\":75}', 0, '2025-11-19 20:30:11'),
(97, 138, 'ride_auto_rejected', 'Çağrı reddedildi', 'Maalesef çağrınıza hiç sürücü cevap vermedi.', '{\"ride_id\":76}', 0, '2025-11-19 20:30:24'),
(98, 138, 'ride_auto_rejected', 'Çağrı reddedildi', 'Maalesef çağrınıza hiç sürücü cevap vermedi.', '{\"ride_id\":77}', 0, '2025-11-19 20:33:27'),
(99, 138, 'ride_auto_rejected', 'Çağrı reddedildi', 'Maalesef çağrınıza hiç sürücü cevap vermedi.', '{\"ride_id\":78}', 0, '2025-11-19 20:33:30'),
(100, 138, 'ride_auto_rejected', 'Çağrı reddedildi', 'Maalesef çağrınıza hiç sürücü cevap vermedi.', '{\"ride_id\":79}', 0, '2025-11-19 20:39:50'),
(101, 138, 'ride_auto_rejected', 'Çağrı reddedildi', 'Maalesef çağrınıza hiç sürücü cevap vermedi.', '{\"ride_id\":80}', 0, '2025-11-19 20:39:53'),
(102, 138, 'ride_auto_rejected', 'Çağrı reddedildi', 'Maalesef çağrınıza hiç sürücü cevap vermedi.', '{\"ride_id\":81}', 0, '2025-11-19 20:43:06'),
(103, 138, 'ride_auto_rejected', 'Çağrı reddedildi', 'Maalesef çağrınıza hiç sürücü cevap vermedi.', '{\"ride_id\":82}', 0, '2025-11-19 20:43:08'),
(104, 138, 'ride_auto_rejected', 'Çağrı reddedildi', 'Maalesef çağrınıza hiç sürücü cevap vermedi.', '{\"ride_id\":83}', 0, '2025-11-19 20:43:08'),
(105, 138, 'ride_auto_rejected', 'Çağrı reddedildi', 'Maalesef çağrınıza hiç sürücü cevap vermedi.', '{\"ride_id\":84}', 0, '2025-11-19 20:46:37'),
(106, 138, 'ride_auto_rejected', 'Çağrı reddedildi', 'Maalesef çağrınıza hiç sürücü cevap vermedi.', '{\"ride_id\":85}', 0, '2025-11-19 20:46:38'),
(107, 138, 'ride_auto_rejected', 'Çağrı reddedildi', 'Maalesef çağrınıza hiç sürücü cevap vermedi.', '{\"ride_id\":86}', 0, '2025-11-19 20:46:39'),
(108, 138, 'ride_auto_rejected', 'Çağrı reddedildi', 'Maalesef çağrınıza hiç sürücü cevap vermedi.', '{\"ride_id\":87}', 0, '2025-11-19 20:46:40'),
(109, 138, 'ride_auto_rejected', 'Çağrı reddedildi', 'Maalesef çağrınıza hiç sürücü cevap vermedi.', '{\"ride_id\":88}', 0, '2025-11-19 20:53:15'),
(110, 138, 'ride_auto_rejected', 'Çağrı reddedildi', 'Maalesef çağrınıza hiç sürücü cevap vermedi.', '{\"ride_id\":89}', 0, '2025-11-19 20:53:17'),
(111, 138, 'ride_auto_rejected', 'Çağrı reddedildi', 'Maalesef çağrınıza hiç sürücü cevap vermedi.', '{\"ride_id\":90}', 0, '2025-11-19 20:53:31'),
(112, 138, 'ride_auto_rejected', 'Çağrı reddedildi', 'Maalesef çağrınıza hiç sürücü cevap vermedi.', '{\"ride_id\":91}', 0, '2025-11-19 20:53:31'),
(113, 138, 'ride_auto_rejected', 'Çağrı reddedildi', 'Maalesef çağrınıza hiç sürücü cevap vermedi.', '{\"ride_id\":92}', 0, '2025-11-19 20:53:35'),
(114, 138, 'ride_auto_rejected', 'Çağrı reddedildi', 'Maalesef çağrınıza hiç sürücü cevap vermedi.', '{\"ride_id\":94}', 0, '2025-11-20 06:52:27'),
(115, 138, 'ride_auto_rejected', 'Çağrı reddedildi', 'Maalesef çağrınıza hiç sürücü cevap vermedi.', '{\"ride_id\":96}', 0, '2025-11-20 07:04:06'),
(116, 138, 'ride_auto_rejected', 'Çağrı reddedildi', 'Maalesef çağrınıza hiç sürücü cevap vermedi.', '{\"ride_id\":97}', 0, '2025-11-20 07:10:07'),
(117, 138, 'ride_auto_rejected', 'Çağrı reddedildi', 'Maalesef çağrınıza hiç sürücü cevap vermedi.', '{\"ride_id\":98}', 0, '2025-11-20 07:14:25'),
(118, 138, 'ride_auto_rejected', 'Çağrı reddedildi', 'Maalesef çağrınıza hiç sürücü cevap vermedi.', '{\"ride_id\":99}', 0, '2025-11-20 07:22:08'),
(119, 138, 'ride_auto_rejected', 'Çağrı reddedildi', 'Maalesef çağrınıza hiç sürücü cevap vermedi.', '{\"ride_id\":100}', 0, '2025-11-20 13:06:46'),
(120, 138, 'ride_auto_rejected', 'Çağrı reddedildi', 'Maalesef çağrınıza hiç sürücü cevap vermedi.', '{\"ride_id\":101}', 0, '2025-11-20 13:14:29'),
(121, 138, 'ride_auto_rejected', 'Çağrı reddedildi', 'Maalesef çağrınıza hiç sürücü cevap vermedi.', '{\"ride_id\":103}', 0, '2025-11-20 13:32:25'),
(122, 138, 'ride_auto_rejected', 'Çağrı reddedildi', 'Maalesef çağrınıza hiç sürücü cevap vermedi.', '{\"ride_id\":104}', 0, '2025-11-20 13:42:01'),
(123, 138, 'ride_auto_rejected', 'Çağrı reddedildi', 'Maalesef çağrınıza hiç sürücü cevap vermedi.', '{\"ride_id\":105}', 0, '2025-11-20 13:48:08'),
(124, 138, 'ride_auto_rejected', 'Çağrı reddedildi', 'Maalesef çağrınıza hiç sürücü cevap vermedi.', '{\"ride_id\":106}', 0, '2025-11-20 13:51:37'),
(125, 138, 'ride_auto_rejected', 'Çağrı reddedildi', 'Maalesef çağrınıza hiç sürücü cevap vermedi.', '{\"ride_id\":107}', 0, '2025-11-20 13:55:33'),
(126, 138, 'ride_auto_rejected', 'Çağrı reddedildi', 'Maalesef çağrınıza hiç sürücü cevap vermedi.', '{\"ride_id\":108}', 0, '2025-11-20 14:04:56'),
(127, 138, 'ride_auto_rejected', 'Çağrı reddedildi', 'Maalesef çağrınıza hiç sürücü cevap vermedi.', '{\"ride_id\":110}', 0, '2025-11-20 14:21:17'),
(128, 138, 'ride_auto_rejected', 'Çağrı reddedildi', 'Maalesef çağrınıza hiç sürücü cevap vermedi.', '{\"ride_id\":111}', 0, '2025-11-20 14:28:51'),
(129, 138, 'ride_auto_rejected', 'Çağrı reddedildi', 'Maalesef çağrınıza hiç sürücü cevap vermedi.', '{\"ride_id\":112}', 0, '2025-11-29 18:44:19'),
(130, 138, 'ride_auto_rejected', 'Çağrı reddedildi', 'Maalesef çağrınıza hiç sürücü cevap vermedi.', '{\"ride_id\":113}', 0, '2025-11-29 18:45:42'),
(131, 138, 'ride_auto_rejected', 'Çağrı reddedildi', 'Maalesef çağrınıza hiç sürücü cevap vermedi.', '{\"ride_id\":114}', 0, '2025-11-29 18:50:03'),
(132, 138, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 139).', '{\"ride_id\":115,\"driver_id\":139}', 0, '2025-11-29 18:52:43'),
(133, 139, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 115).', '{\"ride_id\":115,\"passenger_id\":138}', 0, '2025-11-29 18:52:43'),
(134, 138, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 139).', '{\"ride_id\":116,\"driver_id\":139}', 0, '2025-11-29 19:07:58'),
(135, 139, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 116).', '{\"ride_id\":116,\"passenger_id\":138}', 0, '2025-11-29 19:07:58'),
(136, 138, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 139).', '{\"ride_id\":117,\"driver_id\":139}', 0, '2025-11-29 19:20:06'),
(137, 139, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 117).', '{\"ride_id\":117,\"passenger_id\":138}', 0, '2025-11-29 19:20:06'),
(138, 138, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 139).', '{\"ride_id\":118,\"driver_id\":139}', 0, '2025-11-29 19:30:31'),
(139, 139, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 118).', '{\"ride_id\":118,\"passenger_id\":138}', 0, '2025-11-29 19:30:31'),
(140, 138, 'ride_auto_rejected', 'Çağrı reddedildi', 'Maalesef çağrınıza hiç sürücü cevap vermedi.', '{\"ride_id\":121}', 0, '2025-11-29 19:49:58'),
(141, 138, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 139).', '{\"ride_id\":122,\"driver_id\":139}', 0, '2025-11-29 19:52:41'),
(142, 139, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 122).', '{\"ride_id\":122,\"passenger_id\":138}', 0, '2025-11-29 19:52:41'),
(143, 138, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 139).', '{\"ride_id\":123,\"driver_id\":139}', 0, '2025-11-29 20:01:53'),
(144, 139, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 123).', '{\"ride_id\":123,\"passenger_id\":138}', 0, '2025-11-29 20:01:53'),
(145, 138, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 139).', '{\"ride_id\":124,\"driver_id\":139}', 0, '2025-11-29 20:06:23'),
(146, 139, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 124).', '{\"ride_id\":124,\"passenger_id\":138}', 0, '2025-11-29 20:06:23'),
(147, 138, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 139).', '{\"ride_id\":125,\"driver_id\":139}', 0, '2025-12-01 16:16:56'),
(148, 139, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 125).', '{\"ride_id\":125,\"passenger_id\":138}', 0, '2025-12-01 16:16:56'),
(149, 138, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 139).', '{\"ride_id\":126,\"driver_id\":139}', 0, '2025-12-01 16:24:37'),
(150, 139, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 126).', '{\"ride_id\":126,\"passenger_id\":138}', 0, '2025-12-01 16:24:37'),
(151, 138, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 139).', '{\"ride_id\":127,\"driver_id\":139}', 0, '2025-12-01 16:31:00'),
(152, 139, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 127).', '{\"ride_id\":127,\"passenger_id\":138}', 0, '2025-12-01 16:31:00'),
(153, 138, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 139).', '{\"ride_id\":128,\"driver_id\":139}', 0, '2025-12-01 16:31:31'),
(154, 139, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 128).', '{\"ride_id\":128,\"passenger_id\":138}', 0, '2025-12-01 16:31:31'),
(155, 138, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 139).', '{\"ride_id\":129,\"driver_id\":139}', 0, '2025-12-01 16:37:57'),
(156, 139, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 129).', '{\"ride_id\":129,\"passenger_id\":138}', 0, '2025-12-01 16:37:57'),
(157, 138, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 139).', '{\"ride_id\":130,\"driver_id\":139}', 0, '2025-12-01 16:42:01'),
(158, 139, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 130).', '{\"ride_id\":130,\"passenger_id\":138}', 0, '2025-12-01 16:42:01'),
(159, 138, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 139).', '{\"ride_id\":131,\"driver_id\":139}', 0, '2025-12-01 16:46:02'),
(160, 139, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 131).', '{\"ride_id\":131,\"passenger_id\":138}', 0, '2025-12-01 16:46:02'),
(161, 138, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 139).', '{\"ride_id\":132,\"driver_id\":139}', 0, '2025-12-01 16:50:56'),
(162, 139, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 132).', '{\"ride_id\":132,\"passenger_id\":138}', 0, '2025-12-01 16:50:56'),
(163, 138, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 139).', '{\"ride_id\":133,\"driver_id\":139}', 0, '2025-12-01 16:55:23'),
(164, 139, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 133).', '{\"ride_id\":133,\"passenger_id\":138}', 0, '2025-12-01 16:55:23'),
(165, 138, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 139).', '{\"ride_id\":134,\"driver_id\":139}', 0, '2025-12-01 17:17:03'),
(166, 139, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 134).', '{\"ride_id\":134,\"passenger_id\":138}', 0, '2025-12-01 17:17:03'),
(167, 138, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 139).', '{\"ride_id\":135,\"driver_id\":139}', 0, '2025-12-01 17:23:33'),
(168, 139, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 135).', '{\"ride_id\":135,\"passenger_id\":138}', 0, '2025-12-01 17:23:33'),
(169, 138, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 139).', '{\"ride_id\":136,\"driver_id\":139}', 0, '2025-12-01 17:32:24'),
(170, 139, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 136).', '{\"ride_id\":136,\"passenger_id\":138}', 0, '2025-12-01 17:32:24'),
(171, 138, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 139).', '{\"ride_id\":137,\"driver_id\":139}', 0, '2025-12-01 17:37:43'),
(172, 139, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 137).', '{\"ride_id\":137,\"passenger_id\":138}', 0, '2025-12-01 17:37:43'),
(173, 138, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 139).', '{\"ride_id\":138,\"driver_id\":139}', 0, '2025-12-01 17:39:23'),
(174, 139, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 138).', '{\"ride_id\":138,\"passenger_id\":138}', 0, '2025-12-01 17:39:23'),
(175, 138, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 139).', '{\"ride_id\":139,\"driver_id\":139}', 0, '2025-12-01 18:01:37'),
(176, 139, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 139).', '{\"ride_id\":139,\"passenger_id\":138}', 0, '2025-12-01 18:01:37'),
(177, 138, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 139).', '{\"ride_id\":140,\"driver_id\":139}', 0, '2025-12-01 18:17:20'),
(178, 139, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 140).', '{\"ride_id\":140,\"passenger_id\":138}', 0, '2025-12-01 18:17:20'),
(179, 138, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 139).', '{\"ride_id\":141,\"driver_id\":139}', 0, '2025-12-01 18:28:32'),
(180, 139, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 141).', '{\"ride_id\":141,\"passenger_id\":138}', 0, '2025-12-01 18:28:32'),
(181, 138, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 139).', '{\"ride_id\":142,\"driver_id\":139}', 0, '2025-12-01 18:32:58'),
(182, 139, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 142).', '{\"ride_id\":142,\"passenger_id\":138}', 0, '2025-12-01 18:32:58'),
(183, 138, 'ride_auto_rejected', 'Çağrı reddedildi', 'Maalesef çağrınıza hiç sürücü cevap vermedi.', '{\"ride_id\":144}', 0, '2025-12-01 18:42:00'),
(184, 138, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 139).', '{\"ride_id\":146,\"driver_id\":139}', 0, '2025-12-01 18:44:02'),
(185, 139, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 146).', '{\"ride_id\":146,\"passenger_id\":138}', 0, '2025-12-01 18:44:02'),
(186, 138, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 139).', '{\"ride_id\":147,\"driver_id\":139}', 0, '2025-12-01 18:47:31'),
(187, 139, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 147).', '{\"ride_id\":147,\"passenger_id\":138}', 0, '2025-12-01 18:47:31'),
(188, 138, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 139).', '{\"ride_id\":148,\"driver_id\":139}', 0, '2025-12-01 19:05:32'),
(189, 139, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 148).', '{\"ride_id\":148,\"passenger_id\":138}', 0, '2025-12-01 19:05:32'),
(190, 138, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 139).', '{\"ride_id\":149,\"driver_id\":139}', 0, '2025-12-01 19:16:35'),
(191, 139, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 149).', '{\"ride_id\":149,\"passenger_id\":138}', 0, '2025-12-01 19:16:35'),
(192, 138, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 139).', '{\"ride_id\":150,\"driver_id\":139}', 0, '2025-12-01 19:26:49'),
(193, 139, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 150).', '{\"ride_id\":150,\"passenger_id\":138}', 0, '2025-12-01 19:26:49'),
(194, 138, 'ride_auto_rejected', 'Çağrı reddedildi', 'Maalesef çağrınıza hiç sürücü cevap vermedi.', '{\"ride_id\":151}', 0, '2025-12-01 20:28:28'),
(195, 138, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 139).', '{\"ride_id\":153,\"driver_id\":139}', 0, '2025-12-01 20:40:54'),
(196, 139, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 153).', '{\"ride_id\":153,\"passenger_id\":138}', 0, '2025-12-01 20:40:54'),
(197, 138, 'ride_auto_rejected', 'Çağrı reddedildi', 'Maalesef çağrınıza hiç sürücü cevap vermedi.', '{\"ride_id\":152}', 0, '2025-12-01 20:40:58'),
(198, 138, 'ride_assigned', 'Sürücü atandı', 'Sürücünüz atandı (ID: 139).', '{\"ride_id\":155,\"driver_id\":139}', 0, '2025-12-01 20:43:36'),
(199, 139, 'ride_assigned_driver', 'Yolculuk atandı', 'Yolculuk atandı (ride: 155).', '{\"ride_id\":155,\"passenger_id\":138}', 0, '2025-12-01 20:43:36'),
(200, 138, 'ride_auto_rejected', 'Çağrı reddedildi', 'Maalesef çağrınıza hiç sürücü cevap vermedi.', '{\"ride_id\":156}', 0, '2025-12-01 20:56:48'),
(201, 138, 'ride_auto_rejected', 'Çağrı reddedildi', 'Maalesef çağrınıza hiç sürücü cevap vermedi.', '{\"ride_id\":157}', 0, '2025-12-01 20:57:50'),
(202, 138, 'ride_auto_rejected', 'Çağrı reddedildi', 'Maalesef çağrınıza hiç sürücü cevap vermedi.', '{\"ride_id\":158}', 0, '2025-12-01 20:59:44');

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
(36, 148, 139, 138, 5, 'zupa!', '2025-12-01 19:06:11'),
(37, 148, 138, 139, 5, 'harika', '2025-12-01 19:06:12'),
(38, 149, 138, 139, 4, NULL, '2025-12-01 19:16:59'),
(39, 149, 139, 138, 3, NULL, '2025-12-01 19:17:00'),
(40, 150, 139, 138, 5, NULL, '2025-12-01 19:27:43'),
(41, 150, 138, 139, 4, NULL, '2025-12-01 19:27:43');

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
  `code4` char(4) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Tablo döküm verisi `rides`
--

INSERT INTO `rides` (`id`, `passenger_id`, `driver_id`, `start_lat`, `start_lng`, `start_address`, `end_lat`, `end_lng`, `end_address`, `vehicle_type`, `options`, `payment_method`, `fare_estimate`, `fare_actual`, `status`, `code4`, `created_at`, `updated_at`) VALUES
(148, 138, 139, 40.9819983, 29.1239983, 'Küçükbakkalköy, Alyakut Sk. No:6, 34750 Ataşehir/İstanbul, Türkiye', 41.104235, 29.3177272, 'Çekmeköy/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":false,\"has_pet\":false}', 'nakit', 1255.56, 1225.00, 'completed', '1497', '2025-12-01 19:05:27', '2025-12-01 19:05:56'),
(149, 138, 139, 40.9819983, 29.1239983, 'Küçükbakkalköy, Alyakut Sk. No:6, 34750 Ataşehir/İstanbul, Türkiye', 41.104235, 29.3177272, 'Çekmeköy/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":false,\"has_pet\":false}', 'nakit', 1255.56, 123.00, 'completed', '8502', '2025-12-01 19:16:30', '2025-12-01 19:16:54'),
(150, 138, 139, 40.9819983, 29.1239983, 'Küçükbakkalköy, Alyakut Sk. No:6, 34750 Ataşehir/İstanbul, Türkiye', 41.0267886, 29.0148969, 'Mimar Sinan, 34672 Üsküdar/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":false,\"has_pet\":false}', 'nakit', 572.39, 340.00, 'completed', '2699', '2025-12-01 19:26:43', '2025-12-01 19:27:34'),
(151, 138, NULL, 40.9819983, 29.1239983, 'Küçükbakkalköy, Alyakut Sk. No:6, 34750 Ataşehir/İstanbul, Türkiye', 41.104235, 29.3177272, 'Çekmeköy/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":false,\"has_pet\":false}', 'nakit', 1255.56, NULL, 'auto_rejected', '6178', '2025-12-01 20:28:08', '2025-12-01 20:28:28'),
(152, 138, NULL, 40.9819983, 29.1239983, 'Küçükbakkalköy, Alyakut Sk. No:6, 34750 Ataşehir/İstanbul, Türkiye', 41.03332899999999, 29.10136, 'Ümraniye, Elmalıkent, 34764 Ümraniye/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":false,\"has_pet\":false}', 'nakit', 452.86, NULL, 'auto_rejected', '4301', '2025-12-01 20:40:38', '2025-12-01 20:40:58'),
(153, 138, 139, 40.9819983, 29.1239983, 'Küçükbakkalköy, Alyakut Sk. No:6, 34750 Ataşehir/İstanbul, Türkiye', 41.03332899999999, 29.10136, 'Ümraniye, Elmalıkent, 34764 Ümraniye/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":false,\"has_pet\":false}', 'nakit', 452.86, NULL, 'cancelled', '2178', '2025-12-01 20:40:38', '2025-12-01 20:53:32'),
(154, 138, NULL, 40.9819983, 29.1239983, 'Küçükbakkalköy, Alyakut Sk. No:6, 34750 Ataşehir/İstanbul, Türkiye', 41.0189417, 29.0576298, 'Üsküdar/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":false,\"has_pet\":false}', 'nakit', 536.02, NULL, 'cancelled', '7427', '2025-12-01 20:41:12', '2025-12-01 20:41:28'),
(155, 138, 139, 40.9819983, 29.1239983, 'Küçükbakkalköy, Alyakut Sk. No:6, 34750 Ataşehir/İstanbul, Türkiye', 40.9710668, 29.1347028, 'Fındıklı, 34854 Maltepe/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":false,\"has_pet\":false}', 'nakit', 175.00, NULL, 'cancelled', '5171', '2025-12-01 20:43:30', '2025-12-01 20:43:49'),
(156, 138, NULL, 40.9819983, 29.1239983, 'Küçükbakkalköy, Alyakut Sk. No:6, 34750 Ataşehir/İstanbul, Türkiye', 41.0189417, 29.0576298, 'Üsküdar/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":false,\"has_pet\":false}', 'nakit', 536.02, NULL, 'auto_rejected', '6955', '2025-12-01 20:56:27', '2025-12-01 20:56:48'),
(157, 138, NULL, 40.9819983, 29.1239983, 'Küçükbakkalköy, Alyakut Sk. No:6, 34750 Ataşehir/İstanbul, Türkiye', 41.0189417, 29.0576298, 'Üsküdar/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":false,\"has_pet\":false}', 'nakit', 536.02, NULL, 'auto_rejected', '9586', '2025-12-01 20:57:29', '2025-12-01 20:57:50'),
(158, 138, NULL, 40.9819983, 29.1239983, 'Küçükbakkalköy, Alyakut Sk. No:6, 34750 Ataşehir/İstanbul, Türkiye', 41.025532, 29.0132718, 'Üsküdar Meydanı, Mimar Sinan, 34672 Üsküdar/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":false,\"has_pet\":false}', 'nakit', 565.79, NULL, 'auto_rejected', '5631', '2025-12-01 20:59:24', '2025-12-01 20:59:44'),
(159, 138, NULL, 40.9819983, 29.1239983, 'Küçükbakkalköy, Alyakut Sk. No:6, 34750 Ataşehir/İstanbul, Türkiye', 41.032236, 29.031938, 'Üsküdar, Kuzguncuk, 34674 Üsküdar/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":false,\"has_pet\":false}', 'nakit', 560.45, NULL, 'cancelled', '2239', '2025-12-01 21:00:04', '2025-12-01 21:00:23'),
(160, 138, NULL, 40.9819983, 29.1239983, 'Küçükbakkalköy, Alyakut Sk. No:6, 34750 Ataşehir/İstanbul, Türkiye', 41.0189417, 29.0576298, 'Üsküdar/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":false,\"has_pet\":false}', 'nakit', 536.02, NULL, 'cancelled', '8653', '2025-12-01 21:01:20', '2025-12-01 21:01:28'),
(161, 138, NULL, 40.9819983, 29.1239983, 'Küçükbakkalköy, Alyakut Sk. No:6, 34750 Ataşehir/İstanbul, Türkiye', 41.0189417, 29.0576298, 'Üsküdar/İstanbul, Türkiye', 'sari', '{\"open_taximeter\":false,\"has_pet\":false}', 'nakit', 536.02, NULL, 'cancelled', '6950', '2025-12-01 21:01:48', '2025-12-01 21:02:04');

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
(138, 'passenger', 'Naci', 'Polat', '5070181758', '$2b$10$dK9o2UelDR2WVjqu.bTHq.eoWeLlrBq3NMMEihWRzG/6iXCsMd5Xq', NULL, 1, '2025-11-17 17:46:36', '2025-12-01 20:54:43', 'TB138', NULL, 0, 'standard', 'dJOcxKN2S0mP7MNmLwhAkD:APA91bGup0Z3Ch6ZcUsQy9yVHWBqK_t8C7XwmJZJDpFawToKrs0jwnqyVxBsvnix-jm0fW7qsKY6fUtZJ9I6SuIZAX6nF_X7inxkm2jF-45zv1jrpO7zmgA'),
(139, 'driver', 'Murat', 'Gungor', '5327365892', '$2b$10$Zpb8eLSa64TrOZKUNK59gev.rU3rN93/zF4Lvf5ShbPBhe2GjHLxe', NULL, 1, '2025-11-20 07:33:47', '2025-12-02 10:36:49', 'TB139', NULL, 0, 'standard', 'eb-Ktfe1TzSt9Qlq_R8fwi:APA91bGikqLvxr7wUo0yGJoLoeT6kNuoS_a_oNlqnkG9CjrAJzoLWHOlST6vDV8SF7CVQK98e1QKZ0imuAUVv4DWVvhK6p92rVSfoLTE4VuJesjOjtNLGYU');

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
-- Dökümü yapılmış tablolar için indeksler
--

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
-- Dökümü yapılmış tablolar için AUTO_INCREMENT değeri
--

--
-- Tablo için AUTO_INCREMENT değeri `complaints`
--
ALTER TABLE `complaints`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=15;

--
-- Tablo için AUTO_INCREMENT değeri `notifications`
--
ALTER TABLE `notifications`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=203;

--
-- Tablo için AUTO_INCREMENT değeri `ratings`
--
ALTER TABLE `ratings`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=42;

--
-- Tablo için AUTO_INCREMENT değeri `rides`
--
ALTER TABLE `rides`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=162;

--
-- Tablo için AUTO_INCREMENT değeri `ride_messages`
--
ALTER TABLE `ride_messages`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=36;

--
-- Tablo için AUTO_INCREMENT değeri `ride_requests`
--
ALTER TABLE `ride_requests`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=22;

--
-- Tablo için AUTO_INCREMENT değeri `users`
--
ALTER TABLE `users`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=140;

--
-- Tablo için AUTO_INCREMENT değeri `user_devices`
--
ALTER TABLE `user_devices`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=20;

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
-- Tablo kısıtlamaları `users`
--
ALTER TABLE `users`
  ADD CONSTRAINT `fk_users_referrer` FOREIGN KEY (`referrer_id`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Tablo kısıtlamaları `user_devices`
--
ALTER TABLE `user_devices`
  ADD CONSTRAINT `fk_user_devices_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
