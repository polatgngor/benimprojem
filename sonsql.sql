-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Anamakine: 127.0.0.1
-- Üretim Zamanı: 12 Ara 2025, 14:07:41
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
  `cancel_reason` varchar(255) DEFAULT NULL,
  `code4` char(4) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

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
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=281;

--
-- Tablo için AUTO_INCREMENT değeri `ratings`
--
ALTER TABLE `ratings`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=171;

--
-- Tablo için AUTO_INCREMENT değeri `rides`
--
ALTER TABLE `rides`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=256;

--
-- Tablo için AUTO_INCREMENT değeri `ride_messages`
--
ALTER TABLE `ride_messages`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=48;

--
-- Tablo için AUTO_INCREMENT değeri `ride_requests`
--
ALTER TABLE `ride_requests`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=205;

--
-- Tablo için AUTO_INCREMENT değeri `saved_places`
--
ALTER TABLE `saved_places`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- Tablo için AUTO_INCREMENT değeri `support_messages`
--
ALTER TABLE `support_messages`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- Tablo için AUTO_INCREMENT değeri `support_tickets`
--
ALTER TABLE `support_tickets`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- Tablo için AUTO_INCREMENT değeri `users`
--
ALTER TABLE `users`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=149;

--
-- Tablo için AUTO_INCREMENT değeri `user_devices`
--
ALTER TABLE `user_devices`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=30;

--
-- Tablo için AUTO_INCREMENT değeri `wallets`
--
ALTER TABLE `wallets`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- Tablo için AUTO_INCREMENT değeri `wallet_transactions`
--
ALTER TABLE `wallet_transactions`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=22;

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
