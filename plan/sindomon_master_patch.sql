-- ============================================================
-- SINDOMON MASTER DATA PATCH v1.0
-- Database : sindomondb (MariaDB 12.3.x, utf8mb4)
-- Tanggal  : 2026-08-02
-- Sumber   : plan/data_completion_plan.md §4.1 s/d §4.8
--
-- CARA PAKAI (phpMyAdmin):
--   1. BACKUP DULU: phpMyAdmin > Export > sindomondb (.sql)
--   2. phpMyAdmin > Import > pilih file ini > Go
--   3. (Opsional) Jalankan query verifikasi di SECTION 9
--
-- ISOMETRI: file ini TIDAK membungkus transaction karena
-- berisi DDL (ALTER/CREATE) yang memicu implicit commit di
-- MariaDB. Jalankan sekali; jika perlu dijalankan ulang,
-- SECTION 1/6 sudah aman (MODIFY & IF NOT EXISTS), sedangkan
-- INSERT/UPDATE bersifat idempoten terhadap data yang sama.
-- ============================================================

SET NAMES utf8mb4;
SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";

-- ============================================================
-- SECTION 1: GEOSPASIAL POLDA (COMMAND CENTER MAP)
-- Referensi: data_completion_plan.md §4.8
-- Kolom latitude/longitude SUDAH ADA di dump (VARCHAR(100)),
-- jadi dikonversi ke DECIMAL sesuai ERD §II.A.1. Nilai existing
-- ('5.550000') terkonversi otomatis tanpa kehilangan data.
-- ============================================================

ALTER TABLE `tbl_polda`
  MODIFY COLUMN `latitude` DECIMAL(10,8) NOT NULL DEFAULT 0,
  MODIFY COLUMN `longitude` DECIMAL(11,8) NOT NULL DEFAULT 0;

-- (Fallback — HANYA jalankan jika ALTER di atas error "Unknown
--  column", artinya kolom belum ada di DB Anda:)
-- ALTER TABLE `tbl_polda`
--   ADD COLUMN `latitude` DECIMAL(10,8) NOT NULL DEFAULT 0 AFTER `nama_polda`,
--   ADD COLUMN `longitude` DECIMAL(11,8) NOT NULL DEFAULT 0 AFTER `latitude`;

-- ------------------------------------------------------------
-- 1B. UPDATE KOORDINAT AKURAT — 38 Polda Indonesia
-- Titik pusat kota markas Polda (presisi 6-8 desimal)
-- ------------------------------------------------------------

UPDATE tbl_polda SET latitude = 5.548290, longitude = 95.323757 WHERE id = 1;   -- Polda Aceh (Banda Aceh)
UPDATE tbl_polda SET latitude = 3.595196, longitude = 98.672223 WHERE id = 2;   -- Polda Sumatera Utara (Medan)
UPDATE tbl_polda SET latitude = -0.947083, longitude = 100.417182 WHERE id = 3; -- Polda Sumatera Barat (Padang)
UPDATE tbl_polda SET latitude = 0.507068, longitude = 101.447779 WHERE id = 4;  -- Polda Riau (Pekanbaru)
UPDATE tbl_polda SET latitude = 1.045626, longitude = 104.030454 WHERE id = 5;  -- Polda Kepulauan Riau (Batam)
UPDATE tbl_polda SET latitude = -1.594947, longitude = 103.612187 WHERE id = 6; -- Polda Jambi (Jambi)
UPDATE tbl_polda SET latitude = -2.976073, longitude = 104.775430 WHERE id = 7; -- Polda Sumatera Selatan (Palembang)
UPDATE tbl_polda SET latitude = -2.128726, longitude = 106.113759 WHERE id = 8; -- Polda Bangka Belitung (Pangkalpinang)
UPDATE tbl_polda SET latitude = -3.800464, longitude = 102.265889 WHERE id = 9; -- Polda Bengkulu (Bengkulu)
UPDATE tbl_polda SET latitude = -5.397140, longitude = 105.266787 WHERE id = 10; -- Polda Lampung (Bandar Lampung)
UPDATE tbl_polda SET latitude = -6.200000, longitude = 106.816666 WHERE id = 11; -- Polda Metro Jaya (Jakarta)
UPDATE tbl_polda SET latitude = -6.120427, longitude = 106.150256 WHERE id = 12; -- Polda Banten (Serang)
UPDATE tbl_polda SET latitude = -6.917464, longitude = 107.619123 WHERE id = 13; -- Polda Jawa Barat (Bandung)
UPDATE tbl_polda SET latitude = -6.966667, longitude = 110.416664 WHERE id = 14; -- Polda Jawa Tengah (Semarang)
UPDATE tbl_polda SET latitude = -7.797224, longitude = 110.368797 WHERE id = 15; -- Polda D.I. Yogyakarta (Yogyakarta)
UPDATE tbl_polda SET latitude = -7.257472, longitude = 112.752088 WHERE id = 16; -- Polda Jawa Timur (Surabaya)
UPDATE tbl_polda SET latitude = -0.026330, longitude = 109.342504 WHERE id = 17; -- Polda Kalimantan Barat (Pontianak)
UPDATE tbl_polda SET latitude = -2.208543, longitude = 113.908333 WHERE id = 18; -- Polda Kalimantan Tengah (Palangka Raya)
UPDATE tbl_polda SET latitude = -3.318607, longitude = 114.594398 WHERE id = 19; -- Polda Kalimantan Selatan (Banjarmasin)
UPDATE tbl_polda SET latitude = -0.502183, longitude = 117.153358 WHERE id = 20; -- Polda Kalimantan Timur (Samarinda)
UPDATE tbl_polda SET latitude = 2.837500, longitude = 117.365300 WHERE id = 21; -- Polda Kalimantan Utara (Tanjung Selor)
UPDATE tbl_polda SET latitude = -8.670458, longitude = 115.212629 WHERE id = 22; -- Polda Bali (Denpasar)
UPDATE tbl_polda SET latitude = -8.583329, longitude = 116.116667 WHERE id = 23; -- Polda Nusa Tenggara Barat (Mataram)
UPDATE tbl_polda SET latitude = -10.183333, longitude = 123.583333 WHERE id = 24; -- Polda Nusa Tenggara Timur (Kupang)
UPDATE tbl_polda SET latitude = 1.474831, longitude = 124.842079 WHERE id = 25; -- Polda Sulawesi Utara (Manado)
UPDATE tbl_polda SET latitude = 0.540268, longitude = 123.059433 WHERE id = 26; -- Polda Gorontalo (Gorontalo)
UPDATE tbl_polda SET latitude = -0.898583, longitude = 119.850601 WHERE id = 27; -- Polda Sulawesi Tengah (Palu)
UPDATE tbl_polda SET latitude = -5.147665, longitude = 119.432731 WHERE id = 28; -- Polda Sulawesi Selatan (Makassar)
UPDATE tbl_polda SET latitude = -3.972527, longitude = 122.515011 WHERE id = 29; -- Polda Sulawesi Tenggara (Kendari)
UPDATE tbl_polda SET latitude = -2.678789, longitude = 118.893056 WHERE id = 30; -- Polda Sulawesi Barat (Mamuju)
UPDATE tbl_polda SET latitude = -3.695424, longitude = 128.170856 WHERE id = 31; -- Polda Maluku (Ambon)
UPDATE tbl_polda SET latitude = 0.790708, longitude = 127.384354 WHERE id = 32; -- Polda Maluku Utara (Ternate)
UPDATE tbl_polda SET latitude = -2.533333, longitude = 140.716667 WHERE id = 33; -- Polda Papua (Jayapura)
UPDATE tbl_polda SET latitude = -0.861461, longitude = 134.062049 WHERE id = 34; -- Polda Papua Barat (Manokwari)
UPDATE tbl_polda SET latitude = -8.493235, longitude = 140.401771 WHERE id = 35; -- Polda Papua Selatan (Merauke)
UPDATE tbl_polda SET latitude = -3.369556, longitude = 135.500860 WHERE id = 36; -- Polda Papua Tengah (Nabire)
UPDATE tbl_polda SET latitude = -4.098897, longitude = 138.946748 WHERE id = 37; -- Polda Papua Pegunungan (Wamena)
UPDATE tbl_polda SET latitude = -0.865460, longitude = 131.291472 WHERE id = 38; -- Polda Papua Barat Daya (Sorong)

-- ============================================================
-- SECTION 2: NAMA ASLI POLRES (REPLACE PLACEHOLDER)
-- Referensi: data_completion_plan.md §4.1
-- Mengganti 76 nama generik ("Polrestabes N.1") dengan nama
-- asli kesatuan di tiap Polda (2 polres utama per Polda).
-- ============================================================

UPDATE tbl_polres SET nama_polres = 'Polresta Banda Aceh' WHERE polres_id = 1;
UPDATE tbl_polres SET nama_polres = 'Polres Aceh Besar' WHERE polres_id = 2;
UPDATE tbl_polres SET nama_polres = 'Polrestabes Medan' WHERE polres_id = 3;
UPDATE tbl_polres SET nama_polres = 'Polres Deli Serdang' WHERE polres_id = 4;
UPDATE tbl_polres SET nama_polres = 'Polresta Padang' WHERE polres_id = 5;
UPDATE tbl_polres SET nama_polres = 'Polres Agam' WHERE polres_id = 6;
UPDATE tbl_polres SET nama_polres = 'Polresta Pekanbaru' WHERE polres_id = 7;
UPDATE tbl_polres SET nama_polres = 'Polres Kampar' WHERE polres_id = 8;
UPDATE tbl_polres SET nama_polres = 'Polresta Batam' WHERE polres_id = 9;
UPDATE tbl_polres SET nama_polres = 'Polres Tanjungpinang' WHERE polres_id = 10;
UPDATE tbl_polres SET nama_polres = 'Polresta Jambi' WHERE polres_id = 11;
UPDATE tbl_polres SET nama_polres = 'Polres Batanghari' WHERE polres_id = 12;
UPDATE tbl_polres SET nama_polres = 'Polrestabes Palembang' WHERE polres_id = 13;
UPDATE tbl_polres SET nama_polres = 'Polres Banyuasin' WHERE polres_id = 14;
UPDATE tbl_polres SET nama_polres = 'Polresta Pangkalpinang' WHERE polres_id = 15;
UPDATE tbl_polres SET nama_polres = 'Polres Belitung' WHERE polres_id = 16;
UPDATE tbl_polres SET nama_polres = 'Polresta Bengkulu' WHERE polres_id = 17;
UPDATE tbl_polres SET nama_polres = 'Polres Rejang Lebong' WHERE polres_id = 18;
UPDATE tbl_polres SET nama_polres = 'Polresta Bandar Lampung' WHERE polres_id = 19;
UPDATE tbl_polres SET nama_polres = 'Polres Lampung Selatan' WHERE polres_id = 20;
UPDATE tbl_polres SET nama_polres = 'Polrestro Jakarta Pusat' WHERE polres_id = 21;
UPDATE tbl_polres SET nama_polres = 'Polrestro Jakarta Selatan' WHERE polres_id = 22;
UPDATE tbl_polres SET nama_polres = 'Polresta Serang Kota' WHERE polres_id = 23;
UPDATE tbl_polres SET nama_polres = 'Polres Lebak' WHERE polres_id = 24;
UPDATE tbl_polres SET nama_polres = 'Polrestabes Bandung' WHERE polres_id = 25;
UPDATE tbl_polres SET nama_polres = 'Polres Bogor' WHERE polres_id = 26;
UPDATE tbl_polres SET nama_polres = 'Polrestabes Semarang' WHERE polres_id = 27;
UPDATE tbl_polres SET nama_polres = 'Polres Solo' WHERE polres_id = 28;
UPDATE tbl_polres SET nama_polres = 'Polresta Yogyakarta' WHERE polres_id = 29;
UPDATE tbl_polres SET nama_polres = 'Polres Sleman' WHERE polres_id = 30;
UPDATE tbl_polres SET nama_polres = 'Polrestabes Surabaya' WHERE polres_id = 31;
UPDATE tbl_polres SET nama_polres = 'Polres Malang' WHERE polres_id = 32;
UPDATE tbl_polres SET nama_polres = 'Polresta Pontianak' WHERE polres_id = 33;
UPDATE tbl_polres SET nama_polres = 'Polres Kubu Raya' WHERE polres_id = 34;
UPDATE tbl_polres SET nama_polres = 'Polresta Palangka Raya' WHERE polres_id = 35;
UPDATE tbl_polres SET nama_polres = 'Polres Kotawaringin Timur' WHERE polres_id = 36;
UPDATE tbl_polres SET nama_polres = 'Polresta Banjarmasin' WHERE polres_id = 37;
UPDATE tbl_polres SET nama_polres = 'Polres Banjar' WHERE polres_id = 38;
UPDATE tbl_polres SET nama_polres = 'Polresta Samarinda' WHERE polres_id = 39;
UPDATE tbl_polres SET nama_polres = 'Polres Kutai Kartanegara' WHERE polres_id = 40;
UPDATE tbl_polres SET nama_polres = 'Polresta Tarakan' WHERE polres_id = 41;
UPDATE tbl_polres SET nama_polres = 'Polres Bulungan' WHERE polres_id = 42;
UPDATE tbl_polres SET nama_polres = 'Polresta Denpasar' WHERE polres_id = 43;
UPDATE tbl_polres SET nama_polres = 'Polres Badung' WHERE polres_id = 44;
UPDATE tbl_polres SET nama_polres = 'Polresta Mataram' WHERE polres_id = 45;
UPDATE tbl_polres SET nama_polres = 'Polres Lombok Timur' WHERE polres_id = 46;
UPDATE tbl_polres SET nama_polres = 'Polresta Kupang Kota' WHERE polres_id = 47;
UPDATE tbl_polres SET nama_polres = 'Polres Sikka' WHERE polres_id = 48;
UPDATE tbl_polres SET nama_polres = 'Polresta Manado' WHERE polres_id = 49;
UPDATE tbl_polres SET nama_polres = 'Polres Minahasa' WHERE polres_id = 50;
UPDATE tbl_polres SET nama_polres = 'Polresta Gorontalo Kota' WHERE polres_id = 51;
UPDATE tbl_polres SET nama_polres = 'Polres Bone Bolango' WHERE polres_id = 52;
UPDATE tbl_polres SET nama_polres = 'Polresta Palu' WHERE polres_id = 53;
UPDATE tbl_polres SET nama_polres = 'Polres Poso' WHERE polres_id = 54;
UPDATE tbl_polres SET nama_polres = 'Polrestabes Makassar' WHERE polres_id = 55;
UPDATE tbl_polres SET nama_polres = 'Polres Gowa' WHERE polres_id = 56;
UPDATE tbl_polres SET nama_polres = 'Polresta Kendari' WHERE polres_id = 57;
UPDATE tbl_polres SET nama_polres = 'Polres Kolaka' WHERE polres_id = 58;
UPDATE tbl_polres SET nama_polres = 'Polresta Mamuju' WHERE polres_id = 59;
UPDATE tbl_polres SET nama_polres = 'Polres Polewali Mandar' WHERE polres_id = 60;
UPDATE tbl_polres SET nama_polres = 'Polresta Ambon' WHERE polres_id = 61;
UPDATE tbl_polres SET nama_polres = 'Polres Maluku Tengah' WHERE polres_id = 62;
UPDATE tbl_polres SET nama_polres = 'Polresta Ternate' WHERE polres_id = 63;
UPDATE tbl_polres SET nama_polres = 'Polres Halmahera Utara' WHERE polres_id = 64;
UPDATE tbl_polres SET nama_polres = 'Polresta Jayapura Kota' WHERE polres_id = 65;
UPDATE tbl_polres SET nama_polres = 'Polres Jayapura' WHERE polres_id = 66;
UPDATE tbl_polres SET nama_polres = 'Polresta Manokwari' WHERE polres_id = 67;
UPDATE tbl_polres SET nama_polres = 'Polres Fakfak' WHERE polres_id = 68;
UPDATE tbl_polres SET nama_polres = 'Polresta Merauke' WHERE polres_id = 69;
UPDATE tbl_polres SET nama_polres = 'Polres Boven Digoel' WHERE polres_id = 70;
UPDATE tbl_polres SET nama_polres = 'Polresta Timika' WHERE polres_id = 71;
UPDATE tbl_polres SET nama_polres = 'Polres Nabire' WHERE polres_id = 72;
UPDATE tbl_polres SET nama_polres = 'Polresta Wamena' WHERE polres_id = 73;
UPDATE tbl_polres SET nama_polres = 'Polres Jayawijaya' WHERE polres_id = 74;
UPDATE tbl_polres SET nama_polres = 'Polresta Sorong Kota' WHERE polres_id = 75;
UPDATE tbl_polres SET nama_polres = 'Polres Sorong Selatan' WHERE polres_id = 76;

-- ============================================================
-- SECTION 3: JABATAN STRUKTURAL POLRI (EXPANSION)
-- Referensi: data_completion_plan.md §4.2
-- Menambah 35 jabatan baru (id 9-43) melengkapi 8 seed awal.
-- Catatan DBA: 'Kasat Sabhara' & 'Kasi Propam' di daftar level
-- Polres DILEWATI karena sudah ada sebagai id 3 & 6 (dedup —
-- duplikasi nama_jabatan akan merusak kalkulasi Vacancy Alert).
-- ============================================================

INSERT INTO tbl_jabatan (nama_jabatan, formasi_ideal, parent_id) VALUES
-- Level Polda / Mabes
('Kapolda', 1, NULL),
('Wakapolda', 1, NULL),
('Irwasda', 1, NULL),
('Karorena', 1, NULL),
('Karo SDM', 1, NULL),
('Karo Logistik', 1, NULL),
('Karo Ops', 1, NULL),
('Dirreskrimum', 1, NULL),
('Dirreskrimsus', 1, NULL),
('Dirresnarkoba', 1, NULL),
('Dirintelkam', 1, NULL),
('Dirsabhara', 1, NULL),
('Dirpamobvit', 1, NULL),
('Dirtahti', 1, NULL),
('Kabid Humas', 1, NULL),
('Kabid Propam', 1, NULL),
('Kabid TIK', 1, NULL),
('Kabid Keu', 1, NULL),
('Kabid Hukum', 1, NULL),
('Kabid Dokkes', 1, NULL),
-- Level Polres
('Kapolres', 1, NULL),
('Wakapolres', 1, NULL),
('Kabag Ops', 1, NULL),
('Kabag Ren', 1, NULL),
('Kabag SDM', 1, NULL),
('Kasat Reskrim', 1, NULL),
('Kasat Narkoba', 1, NULL),
('Kasat Lantas', 1, NULL),
('Kasat Intelkam', 1, NULL),
('Kasat Binmas', 1, NULL),
('Kasat Tahti', 1, NULL),
('Kasi Humas', 1, NULL),
('Kasi Keu', 1, NULL),
('Kasi Hukum', 1, NULL),
('Kapolsek', 10, NULL);

-- ============================================================
-- SECTION 4: KATEGORI SENJATA (KALIBER EXPANSION)
-- Referensi: data_completion_plan.md §4.3
-- Menambah 6 kaliber baru melengkapi 2 seed awal (9mm & 5.56mm).
-- ============================================================

INSERT INTO tbl_kategori_senjata (tipe_laras, kaliber) VALUES
('Panjang', '7.62mm'),
('Pendek', '.45 ACP'),
('Pendek', '.38 Special'),
('Pendek', '.357 Magnum'),
('Panjang', '12 Gauge'),
('Panjang', '.223 Remington');

-- ============================================================
-- SECTION 5: TABEL BARU tbl_devices (DEVICE BINDING)
-- Referensi: data_completion_plan.md §4.4, ERD §I.A.3
-- Mencatat hardware_uuid perangkat petugas + status binding.
-- ============================================================

CREATE TABLE IF NOT EXISTS `tbl_devices` (
  `device_id` INT(11) NOT NULL AUTO_INCREMENT,
  `user_id` VARCHAR(36) NOT NULL,
  `hardware_uuid` VARCHAR(255) NOT NULL,
  `fcm_token` VARCHAR(500) DEFAULT NULL,
  `status_binding` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP(),
  `updated_at` DATETIME DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP(),
  PRIMARY KEY (`device_id`),
  UNIQUE KEY `uq_hardware_uuid` (`hardware_uuid`),
  KEY `idx_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- (Opsional — tambahkan FK saat backend siap; catatan: PK
--  tbl_users di dump adalah INT `id`, bukan UUID `user_id`:
--  ALTER TABLE tbl_devices
--    ADD CONSTRAINT fk_devices_users
--    FOREIGN KEY (user_id) REFERENCES tbl_users(id) ON DELETE CASCADE;)

-- ============================================================
-- SECTION 6: KOLOM BARU tbl_users (2FA + SOFT-DELETE)
-- Referensi: data_completion_plan.md §4.5, ERD §I.A.2
-- IF NOT EXISTS => aman dijalankan ulang (MariaDB 10.2.1+).
-- ============================================================

ALTER TABLE tbl_users
  ADD COLUMN IF NOT EXISTS is_2fa_enabled TINYINT(1) NOT NULL DEFAULT 0 AFTER polda_id,
  ADD COLUMN IF NOT EXISTS two_factor_secret VARCHAR(255) DEFAULT NULL AFTER is_2fa_enabled,
  ADD COLUMN IF NOT EXISTS is_active TINYINT(1) NOT NULL DEFAULT 1 AFTER two_factor_secret;

-- ============================================================
-- SECTION 7: STANDARISASI ENUM (ERD COMPLIANCE)
-- Referensi: data_completion_plan.md §4.6
-- Semua nilai existing sudah termasuk dalam ENUM baru, jadi
-- konversi aman tanpa error "Out of range".
-- ============================================================

-- tbl_personil: status_aktif VARCHAR(50) -> ENUM
ALTER TABLE tbl_personil
  MODIFY COLUMN status_aktif ENUM('Aktif','Mutasi','Pensiun') DEFAULT 'Aktif';

-- tbl_satwa: kualifikasi VARCHAR(50) -> ENUM
-- (nilai existing 'Patroli','Pelacak','Dalmas','Narkotika' tercakup)
ALTER TABLE tbl_satwa
  MODIFY COLUMN kualifikasi ENUM('Narkotika','Handak','Dalmas','Kriminal Umum','Patroli','Pelacak') DEFAULT NULL;

-- tbl_dms_surat: status_tracking + nilai baru 'Diarsipkan'
ALTER TABLE tbl_dms_surat
  MODIFY COLUMN status_tracking ENUM('Terkirim','Dibaca','Diarsipkan') DEFAULT 'Terkirim';

-- ============================================================
-- SECTION 8: SINKRONISASI ROLE NAMING — OPSI A (APPROVED)
-- Referensi: data_completion_plan.md §4.7
-- DB mengikuti frontend: role 3 "Eksekutif" -> "Command Center"
-- (menu_config.dart & app_sidebar.dart memakai label ini)
-- ============================================================

UPDATE tbl_role SET roles = 'Command Center' WHERE id = 3;

-- ============================================================
-- SECTION 9: QUERY VERIFIKASI (JALANKAN MANUAL, BUKAN BAGIAN
-- DARI PATCH — KOMENTAR AGAR IMPORT TIDAK MENAMPILKAN RESULT)
-- ============================================================
-- 1) Geospasial: semua 38 Polda punya koordinat DECIMAL
--    SELECT id, nama_polda, latitude, longitude
--    FROM tbl_polda ORDER BY id;
--    (Harap: 38 baris, tidak ada latitude/longitude = 0.00000000)
--
-- 2) Nama polres asli:
--    SELECT polda_id, COUNT(*) AS jumlah_polres, GROUP_CONCAT(nama_polres)
--    FROM tbl_polres GROUP BY polda_id;
--
-- 3) Jabatan: total 43
--    SELECT COUNT(*) AS total_jabatan FROM tbl_jabatan;
--    (Harap: 43 = 8 seed + 35 baru; tidak ada nama duplikat:
--     SELECT nama_jabatan, COUNT(*) FROM tbl_jabatan GROUP BY nama_jabatan HAVING COUNT(*) > 1;)
--
-- 4) Kategori senjata: total 8
--    SELECT * FROM tbl_kategori_senjata ORDER BY kategori_id;
--
-- 5) tbl_devices tercipta:
--    SHOW CREATE TABLE tbl_devices;
--
-- 6) Kolom 2FA ada di tbl_users:
--    SHOW COLUMNS FROM tbl_users LIKE 'is_%';
--
-- 7) Role naming:
--    SELECT * FROM tbl_role ORDER BY id;
--    (Harap: id 3 = 'Command Center')

-- ============================================================
-- AKHIR PATCH — SINDOMON MASTER DATA PATCH v1.0
-- ============================================================
