-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Anamakine: 127.0.0.1
-- Üretim Zamanı: 19 Kas 2025, 17:46:19
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
(94, 138, 'ride_auto_rejected', 'Çağrı reddedildi', 'Maalesef çağrınıza hiç sürücü cevap vermedi.', '{\"ride_id\":73}', 0, '2025-11-17 18:42:50');

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
(65, 138, NULL, 37.4219983, -122.084, NULL, 37.4319983, -122.074, NULL, '', '{}', '', NULL, NULL, 'auto_rejected', '8870', '2025-11-17 18:11:11', '2025-11-17 18:11:32'),
(66, 138, NULL, 37.4219983, -122.084, NULL, 37.4319983, -122.074, NULL, '', '{}', '', NULL, NULL, 'auto_rejected', '5707', '2025-11-17 18:11:17', '2025-11-17 18:11:37'),
(67, 138, NULL, 37.4219983, -122.084, NULL, 37.4319983, -122.074, NULL, '', '{}', '', NULL, NULL, 'auto_rejected', '7557', '2025-11-17 18:14:43', '2025-11-17 18:15:03'),
(68, 138, NULL, 37.4219983, -122.084, NULL, 41.0189417, 29.0576298, NULL, '', '{}', '', NULL, NULL, 'auto_rejected', '1588', '2025-11-17 18:28:35', '2025-11-17 18:28:56'),
(69, 138, NULL, 37.4219983, -122.084, NULL, 41.0182327, 29.1274334, NULL, '', '{}', '', NULL, NULL, 'auto_rejected', '2958', '2025-11-17 18:32:50', '2025-11-17 18:33:11'),
(70, 138, NULL, 37.4219983, -122.084, NULL, 41.0625272, 28.8075256, NULL, '', '{}', '', NULL, NULL, 'auto_rejected', '1099', '2025-11-17 18:36:17', '2025-11-17 18:36:37'),
(71, 138, NULL, 37.4219983, -122.084, NULL, 40.9874178, 29.1216176, NULL, '', '{}', '', NULL, NULL, 'auto_rejected', '5917', '2025-11-17 18:37:58', '2025-11-17 18:38:18'),
(72, 138, NULL, 37.4219983, -122.084, NULL, 41.104235, 29.3177272, NULL, '', '{}', '', NULL, NULL, 'auto_rejected', '2899', '2025-11-17 18:40:07', '2025-11-17 18:40:28'),
(73, 138, NULL, 37.4219983, -122.084, NULL, 41.0168639, 28.9470422, NULL, '', '{}', '', NULL, NULL, 'auto_rejected', '3335', '2025-11-17 18:42:29', '2025-11-17 18:42:50');

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
  `level` enum('standard','silver','gold','platinum') NOT NULL DEFAULT 'standard'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Tablo döküm verisi `users`
--

INSERT INTO `users` (`id`, `role`, `first_name`, `last_name`, `phone`, `password_hash`, `profile_photo`, `is_active`, `created_at`, `updated_at`, `ref_code`, `referrer_id`, `ref_count`, `level`) VALUES
(138, 'passenger', 'Naci', 'Polat', '5070181758', '$2b$10$dK9o2UelDR2WVjqu.bTHq.eoWeLlrBq3NMMEihWRzG/6iXCsMd5Xq', NULL, 1, '2025-11-17 17:46:36', '2025-11-17 17:46:36', 'TB138', NULL, 0, 'standard');

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
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=95;

--
-- Tablo için AUTO_INCREMENT değeri `ratings`
--
ALTER TABLE `ratings`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=29;

--
-- Tablo için AUTO_INCREMENT değeri `rides`
--
ALTER TABLE `rides`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=74;

--
-- Tablo için AUTO_INCREMENT değeri `ride_messages`
--
ALTER TABLE `ride_messages`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=23;

--
-- Tablo için AUTO_INCREMENT değeri `ride_requests`
--
ALTER TABLE `ride_requests`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=22;

--
-- Tablo için AUTO_INCREMENT değeri `users`
--
ALTER TABLE `users`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=139;

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
