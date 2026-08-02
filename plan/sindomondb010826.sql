-- phpMyAdmin SQL Dump
-- version 5.2.3
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1:3306
-- Generation Time: Aug 01, 2026 at 01:00 PM
-- Server version: 12.3.2-MariaDB
-- PHP Version: 8.3.6

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `sindomondb`
--

-- --------------------------------------------------------

--
-- Table structure for table `tbl_amunisi_batch`
--

CREATE TABLE `tbl_amunisi_batch` (
  `batch_id` int(11) NOT NULL,
  `polda_id` int(11) DEFAULT NULL,
  `kode_batch` varchar(100) DEFAULT NULL,
  `kategori_id` int(11) DEFAULT NULL,
  `jumlah_butir` int(11) DEFAULT 0,
  `tanggal_masuk` date DEFAULT NULL,
  `tanggal_kedaluwarsa` date DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `tbl_amunisi_batch`
--

INSERT INTO `tbl_amunisi_batch` (`batch_id`, `polda_id`, `kode_batch`, `kategori_id`, `jumlah_butir`, `tanggal_masuk`, `tanggal_kedaluwarsa`, `created_at`, `updated_at`) VALUES
(1, 34, 'PROD-001/2026', 1, 927, '2025-10-16', '2026-10-27', '2026-07-30 20:35:13', NULL),
(2, 33, 'PROD-002/2026', 2, 9502, '2026-01-10', '2027-01-17', '2026-07-30 20:35:13', NULL),
(3, 11, 'LOT-003/2026', 2, 9497, '2026-04-28', '2026-08-29', '2026-07-30 20:35:13', NULL),
(4, 13, 'LOT-004/2026', 2, 9156, '2025-10-16', '2027-05-28', '2026-07-30 20:35:13', NULL),
(5, 36, 'PROD-005/2026', 2, 8068, '2025-12-08', '2027-01-28', '2026-07-30 20:35:13', NULL),
(6, 22, 'BATCH-006/2026', 2, 2947, '2025-12-16', '2027-04-19', '2026-07-30 20:35:13', NULL),
(7, 29, 'BATCH-007/2026', 2, 3186, '2026-05-30', '2027-07-25', '2026-07-30 20:35:13', NULL),
(8, 3, 'PROD-008/2026', 2, 4215, '2026-06-05', '2027-07-04', '2026-07-30 20:35:13', NULL),
(9, 30, 'BATCH-009/2026', 2, 7518, '2026-03-14', '2027-05-19', '2026-07-30 20:35:13', NULL),
(10, 24, 'BATCH-010/2026', 2, 8304, '2025-09-27', '2026-12-16', '2026-07-30 20:35:13', NULL),
(11, 24, 'BATCH-011/2026', 1, 3859, '2025-11-17', '2027-07-30', '2026-07-30 20:35:13', NULL),
(12, 38, 'PROD-012/2026', 2, 8472, '2025-09-30', '2027-04-12', '2026-07-30 20:35:13', NULL),
(13, 36, 'BATCH-013/2026', 1, 3774, '2025-10-02', '2026-12-24', '2026-07-30 20:35:13', NULL),
(14, 20, 'BATCH-014/2026', 1, 1292, '2025-08-26', '2027-07-05', '2026-07-30 20:35:13', NULL),
(15, 7, 'PROD-015/2026', 2, 7650, '2025-08-22', '2026-11-17', '2026-07-30 20:35:13', NULL),
(16, 35, 'LOT-016/2026', 1, 7803, '2026-05-30', '2027-07-28', '2026-07-30 20:35:13', NULL),
(17, 4, 'LOT-017/2026', 1, 2855, '2026-02-17', '2027-06-13', '2026-07-30 20:35:13', NULL),
(18, 13, 'PROD-018/2026', 1, 8696, '2025-12-04', '2027-04-10', '2026-07-30 20:35:13', NULL),
(19, 9, 'PROD-019/2026', 1, 683, '2026-05-15', '2026-10-11', '2026-07-30 20:35:13', NULL),
(20, 36, 'BATCH-020/2026', 2, 9224, '2026-03-24', '2027-02-04', '2026-07-30 20:35:13', NULL),
(21, 25, 'LOT-021/2026', 2, 8507, '2025-10-06', '2027-07-24', '2026-07-30 20:35:13', NULL),
(22, 7, 'PROD-022/2026', 2, 1444, '2025-07-30', '2027-05-17', '2026-07-30 20:35:13', NULL),
(23, 34, 'PROD-023/2026', 2, 9179, '2026-04-03', '2027-03-11', '2026-07-30 20:35:13', NULL),
(24, 23, 'LOT-024/2026', 1, 5569, '2025-12-04', '2027-04-16', '2026-07-30 20:35:13', NULL),
(25, 11, 'BATCH-025/2026', 2, 7384, '2025-12-19', '2026-11-23', '2026-07-30 20:35:13', NULL),
(26, 32, 'LOT-026/2026', 2, 6469, '2026-01-15', '2027-07-26', '2026-07-30 20:35:13', NULL),
(27, 25, 'BATCH-027/2026', 1, 9348, '2025-09-24', '2027-04-19', '2026-07-30 20:35:13', NULL),
(28, 1, 'LOT-028/2026', 1, 5173, '2026-05-19', '2026-08-30', '2026-07-30 20:35:13', NULL),
(29, 13, 'BATCH-029/2026', 2, 1059, '2026-04-09', '2027-08-09', '2026-07-30 20:35:13', NULL),
(30, 38, 'LOT-030/2026', 1, 1360, '2026-01-21', '2026-10-23', '2026-07-30 20:35:13', NULL),
(31, 1, 'BATCH-H90-TRIGGER', 1, 5000, '2026-04-21', '2026-09-13', '2026-07-30 20:35:13', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `tbl_dms_surat`
--

CREATE TABLE `tbl_dms_surat` (
  `surat_id` varchar(36) NOT NULL,
  `pengirim_polda_id` int(11) DEFAULT NULL,
  `penerima_polda_id` int(11) DEFAULT NULL,
  `judul_surat` varchar(255) NOT NULL,
  `nomor_surat` varchar(100) NOT NULL,
  `file_pdf_url` varchar(500) DEFAULT NULL,
  `status_tracking` enum('Terkirim','Dibaca') DEFAULT 'Terkirim',
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `tbl_dms_surat`
--

INSERT INTO `tbl_dms_surat` (`surat_id`, `pengirim_polda_id`, `penerima_polda_id`, `judul_surat`, `nomor_surat`, `file_pdf_url`, `status_tracking`, `created_at`) VALUES
('0204ba63-6280-4b98-b69b-1d060d6dd9f1', NULL, 32, 'Koordinasi Pengamanan Pilkada Serentak', 'R/OPS.1/88/VII/2026', 'https://placehold.co/400x600?text=Surat+3', 'Terkirim', '2026-07-30 20:35:13'),
('03c89998-7449-4ecc-a08f-7bd3cfb0d3c3', 32, 26, 'Permintaan Data Satwa dan Sarpras Polda Jajaran', 'R/SAT.1/08/VII/2026', 'https://placehold.co/400x600?text=Surat+21', 'Terkirim', '2026-07-30 20:35:13'),
('03d95b3f-cc2e-4224-9b38-55cde3f697fa', 36, 14, 'Pengajuan Pengadaan Senjata Api Tahun 2026', 'R/LOG.1/12/VI/2026', 'https://placehold.co/400x600?text=Surat+7', 'Terkirim', '2026-07-30 20:35:13'),
('249a04db-1c46-4558-af9d-e183aa4bd3dc', NULL, 14, 'Laporan Pelayanan Publik dan Pengaduan Masyarakat', 'B/YAN.1/09/VII/2026', 'https://placehold.co/400x600?text=Surat+10', 'Terkirim', '2026-07-30 20:35:13'),
('294b7fc0-4ea1-48d3-8a77-c8f48f42ef6f', 2, NULL, 'Laporan Realisasi Anggaran Triwulan II', 'B/KEU.1/22/VI/2026', 'https://placehold.co/400x600?text=Surat+24', 'Dibaca', '2026-07-30 20:35:13'),
('29739403-94c9-448d-a8d4-3274ed3822f9', 30, 22, 'Laporan Pengungkapan Jaringan Narkoba Antar Provinsi', 'B/NARK.1/44/VI/2026', 'https://placehold.co/400x600?text=Surat+12', 'Terkirim', '2026-07-30 20:35:13'),
('3673b97e-e22e-4415-b334-c0d359c1e0a1', 22, 28, 'Permohonan Mutasi Personil Antar Polda', 'B/SDM.1/56/VII/2026', 'https://placehold.co/400x600?text=Surat+6', 'Dibaca', '2026-07-30 20:35:13'),
('4e0d2b89-5cb4-4250-a20e-d71884586c48', 4, 18, 'Permintaan Pendampingan Hukum Sidang Etik', 'R/HUK.1/33/VI/2026', 'https://placehold.co/400x600?text=Surat+9', 'Terkirim', '2026-07-30 20:35:13'),
('613a63d1-6225-4ce8-a16d-fa51fde9c978', NULL, 29, 'Laporan Kerusakan Sarana dan Prasarana Akibat Bencana', 'B/BEN.1/47/VI/2026', 'https://placehold.co/400x600?text=Surat+22', 'Terkirim', '2026-07-30 20:35:13'),
('72dd5d57-2d76-431f-8d8b-0d2f39021799', NULL, 18, 'Laporan Akhir Operasi Ketupat 2026', 'R/LAP.1/73/VII/2026', 'https://placehold.co/400x600?text=Surat+19', 'Dibaca', '2026-07-30 20:35:13'),
('818ccda7-1622-425a-a905-bdfea557e4cf', 20, NULL, 'Laporan Situasi Kamtibmas Bulanan', 'B/KAMT.1/78/VII/2026', 'https://placehold.co/400x600?text=Surat+8', 'Dibaca', '2026-07-30 20:35:13'),
('8373ca73-a493-445e-870e-71fa872ad5fa', NULL, 16, 'Laporan Intelijen Mingguan Wilayah Perbatasan', 'B/INTEL.1/15/VII/2026', 'https://placehold.co/400x600?text=Surat+2', 'Terkirim', '2026-07-30 20:35:13'),
('8f215688-7f38-4819-98a0-b49fe9699197', 20, 18, 'Laporan Penyelidikan Tindak Pidana Siber', 'B/TIP.1/18/VI/2026', 'https://placehold.co/400x600?text=Surat+14', 'Dibaca', '2026-07-30 20:35:13'),
('953203d5-3625-41c2-9016-51bd8f63ceb4', 25, 31, 'Rencana Pengamanan Kunjungan Pejabat Negara', 'R/PAM.1/27/VII/2026', 'https://placehold.co/400x600?text=Surat+13', 'Terkirim', '2026-07-30 20:35:13'),
('9e52a65e-1313-459e-8ef6-7bbd2523f581', NULL, 30, 'Usulan Diklat Pengembangan Spesialisasi Anggota', 'R/DIK.1/14/VII/2026', 'https://placehold.co/400x600?text=Surat+23', 'Dibaca', '2026-07-30 20:35:13'),
('a458ca0f-01d0-4d8d-a506-14713d5c6eb3', NULL, 8, 'Undangan Rapat Koordinasi Pimpinan Polda', 'B/HUB.1/29/VI/2026', 'https://placehold.co/400x600?text=Surat+20', 'Dibaca', '2026-07-30 20:35:13'),
('b20c4500-3082-4759-bab8-74201057ace5', 23, 19, 'Rekomendasi Sanksi Pelanggaran Disiplin Anggota', 'R/PROP.1/21/VI/2026', 'https://placehold.co/400x600?text=Surat+5', 'Terkirim', '2026-07-30 20:35:13'),
('c059a479-355a-44ed-b654-a791b145b554', 15, 21, 'Permintaan Bantuan Dalmas Pengamanan Unjuk Rasa', 'R/DAL.1/65/VII/2026', 'https://placehold.co/400x600?text=Surat+11', 'Dibaca', '2026-07-30 20:35:13'),
('cb7982d2-4b83-4890-a7ba-06e30b2c7689', 22, 4, 'Permintaan Bantuan Hukum Kasus Narkotika', 'R/KUM.1/42/VI/2026', 'https://placehold.co/400x600?text=Surat+1', 'Terkirim', '2026-07-30 20:35:13'),
('d30ea5d4-c3df-48f7-8aed-146519755f01', NULL, 6, 'Kerjasama Patroli Perbatasan Antar Polda', 'R/KER.1/51/VII/2026', 'https://placehold.co/400x600?text=Surat+15', 'Terkirim', '2026-07-30 20:35:13'),
('d5e3a2f5-2f42-46b0-bf28-9fe80998d83f', NULL, 27, 'Surat Perintah Penyelidikan Kasus Korupsi', 'B/SPK.1/03/VII/2026', 'https://placehold.co/400x600?text=Surat+4', 'Terkirim', '2026-07-30 20:35:13'),
('d91ac00f-0866-469b-b2dd-350e34946544', 8, 30, 'Permohonan Data Dukung Siaran Pers Pengungkapan Kasus', 'R/KOM.1/05/VII/2026', 'https://placehold.co/400x600?text=Surat+25', 'Terkirim', '2026-07-30 20:35:13'),
('e435751f-c03c-4c34-9a37-e410977f58a8', NULL, 17, 'Laporan Kesehatan Personil Satuan Brimob', 'B/KES.1/11/VI/2026', 'https://placehold.co/400x600?text=Surat+18', 'Terkirim', '2026-07-30 20:35:13'),
('ea29b8b3-dcd4-4751-a0c9-cd6155bc9281', NULL, 35, 'Informasi Intelejen Gangguan Keamanan Terkini', 'B/INT.1/06/VI/2026', 'https://placehold.co/400x600?text=Surat+16', 'Dibaca', '2026-07-30 20:35:13'),
('f17c8148-44e1-4465-8d4c-79190da7a8b3', 2, 14, 'Rekomendasi Kenaikan Pangkat Anggota Berprestasi', 'R/PEG.1/39/VII/2026', 'https://placehold.co/400x600?text=Surat+17', 'Terkirim', '2026-07-30 20:35:13');

-- --------------------------------------------------------

--
-- Table structure for table `tbl_dokumen_hukum`
--

CREATE TABLE `tbl_dokumen_hukum` (
  `dokumen_id` int(11) NOT NULL,
  `kategori` enum('Perkap','Perpol','SOP','Juknis') NOT NULL,
  `judul_dokumen` varchar(255) NOT NULL,
  `file_url` varchar(500) DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `tbl_dokumen_hukum`
--

INSERT INTO `tbl_dokumen_hukum` (`dokumen_id`, `kategori`, `judul_dokumen`, `file_url`, `created_at`) VALUES
(1, 'Perkap', 'Peraturan Kapolri No 1 Tahun 2024 tentang Pelayanan Publik', '/uploads/dokumen/perkap_1_2024.pdf', '2024-10-15 08:00:00'),
(2, 'Perpol', 'Peraturan Polisi No 3 Tahun 2024 tentang Patroli', '/uploads/dokumen/perpol_3_2024.pdf', '2024-09-20 10:30:00'),
(3, 'SOP', 'SOP Penanganan Pengaduan Masyarakat', '/uploads/dokumen/sop_pengaduan.pdf', '2024-08-01 14:00:00'),
(4, 'Juknis', 'Juknis Aplikasi e-Complaint 2024', '/uploads/dokumen/juknis_ecomplaint.pdf', '2024-07-10 09:15:00'),
(5, 'Perkap', 'Peraturan Kapolri No 5 Tahun 2023 tentang IT', '/uploads/dokumen/perkap_5_2023.pdf', '2023-12-01 11:00:00');

-- --------------------------------------------------------

--
-- Table structure for table `tbl_hub_pengaduan`
--

CREATE TABLE `tbl_hub_pengaduan` (
  `pengaduan_id` int(11) NOT NULL,
  `polda_id` int(11) DEFAULT NULL,
  `sumber` enum('Email','Hotline') NOT NULL,
  `deskripsi` text DEFAULT NULL,
  `status` enum('Open','In Progress','Resolved','Closed') DEFAULT 'Open',
  `created_at` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `tbl_hub_pengaduan`
--

INSERT INTO `tbl_hub_pengaduan` (`pengaduan_id`, `polda_id`, `sumber`, `deskripsi`, `status`, `created_at`) VALUES
(1, 33, 'Hotline', 'Laporan pencurian kendaraan bermotor di Jalan Sudirman', 'Open', '2026-07-30 13:35:13'),
(2, 21, 'Email', 'Pengaduan pungutan liar oknum Polantas di Terminal Bus', 'In Progress', '2026-07-30 13:35:13'),
(3, 20, 'Hotline', 'Laporan balapan liar mengganggu ketertiban umum malam hari', 'Resolved', '2026-07-30 13:35:13'),
(4, 34, 'Email', 'Aduan pelayanan lambat pembuatan SKCK di Polres setempat', 'Closed', '2026-07-30 13:35:13'),
(5, 14, 'Hotline', 'Laporan penganiayaan oleh sekelompok orang tidak dikenal', 'Open', '2026-07-30 13:35:13'),
(6, 34, 'Email', 'Kritik terhadap penanganan kasus penggusuran lahan', 'In Progress', '2026-07-30 13:35:13'),
(7, 28, 'Hotline', 'Laporan peredaran narkoba di lingkungan perumahan', 'Open', '2026-07-30 13:35:13'),
(8, 21, 'Email', 'Pengaduan suara bising di atas batas wajar', 'Resolved', '2026-07-30 13:35:13'),
(9, 3, 'Hotline', 'Laporan penipuan online melalui media sosial', 'In Progress', '2026-07-30 13:35:13'),
(10, 16, 'Email', 'Pengaduan KDRT yang diabaikan oleh pihak kepolisian setempat', 'Open', '2026-07-30 13:35:13'),
(11, 23, 'Hotline', 'Laporan penemuan mayat tanpa identitas di pinggir sungai', 'In Progress', '2026-07-30 13:35:13'),
(12, 14, 'Email', 'Pengaduan marka jalan rusak dan tidak jelas', 'Resolved', '2026-07-30 13:35:13'),
(13, 9, 'Hotline', 'Laporan tawuran antar pelajar di jalan raya', 'Closed', '2026-07-30 13:35:13'),
(14, 37, 'Email', 'Pengaduan pencemaran lingkungan oleh pabrik', 'Open', '2026-07-30 13:35:13'),
(15, 6, 'Hotline', 'Laporan perampokan bersenjata di minimarket', 'In Progress', '2026-07-30 13:35:13'),
(16, 19, 'Email', 'Kritik tentang respon lambat piket Polsek dalam menangani kecelakaan', 'Open', '2026-07-30 13:35:13'),
(17, 23, 'Hotline', 'Laporan penculikan anak di lingkungan sekolah', 'Resolved', '2026-07-30 13:35:13'),
(18, 31, 'Email', 'Pengaduan parkir liar di pusat perbelanjaan', 'Resolved', '2026-07-30 13:35:13'),
(19, 30, 'Hotline', 'Laporan pembakaran lahan pertanian merambat ke pemukiman', 'In Progress', '2026-07-30 13:35:13'),
(20, 8, 'Email', 'Usulan perbaikan layanan pengaduan 24 jam', 'Closed', '2026-07-30 13:35:13'),
(21, 15, 'Hotline', 'Laporan kekerasan terhadap anak di bawah umur', 'Open', '2026-07-30 13:35:13'),
(22, 32, 'Email', 'Pengaduan anggota polisi tidak dinas melakukan pemukulan', 'In Progress', '2026-07-30 13:35:13'),
(23, 15, 'Hotline', 'Laporan penyalahgunaan wewenang oleh oknum kepala desa', 'Open', '2026-07-30 13:35:13'),
(24, 31, 'Email', 'Pengaduan rusaknya penerangan jalan umum', 'Closed', '2026-07-30 13:35:13'),
(25, 19, 'Hotline', 'Laporan kericuhan di pasar tradisional, butuh pengamanan', 'In Progress', '2026-07-30 13:35:13');

-- --------------------------------------------------------

--
-- Table structure for table `tbl_jabatan`
--

CREATE TABLE `tbl_jabatan` (
  `jabatan_id` int(11) NOT NULL,
  `nama_jabatan` varchar(100) NOT NULL,
  `formasi_ideal` int(11) NOT NULL DEFAULT 0,
  `parent_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `tbl_jabatan`
--

INSERT INTO `tbl_jabatan` (`jabatan_id`, `nama_jabatan`, `formasi_ideal`, `parent_id`) VALUES
(1, 'Dirsamapta', 1, NULL),
(2, 'Wadirsamapta', 1, NULL),
(3, 'Kasat Sabhara', 1, NULL),
(4, 'Komandan Peleton', 4, NULL),
(5, 'Anggota Dalmas', 20, NULL),
(6, 'Kasi Propam', 1, NULL),
(7, 'Anggota Samapta', 15, NULL),
(8, 'Paur Humas', 2, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `tbl_kategori_senjata`
--

CREATE TABLE `tbl_kategori_senjata` (
  `kategori_id` int(11) NOT NULL,
  `tipe_laras` enum('Panjang','Pendek') NOT NULL,
  `kaliber` varchar(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `tbl_kategori_senjata`
--

INSERT INTO `tbl_kategori_senjata` (`kategori_id`, `tipe_laras`, `kaliber`) VALUES
(1, 'Pendek', '9mm'),
(2, 'Panjang', '5.56mm');

-- --------------------------------------------------------

--
-- Table structure for table `tbl_pangkat`
--

CREATE TABLE `tbl_pangkat` (
  `pangkat_id` int(11) NOT NULL,
  `nama_pangkat` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `tbl_pangkat`
--

INSERT INTO `tbl_pangkat` (`pangkat_id`, `nama_pangkat`) VALUES
(1, 'Bripda'),
(2, 'Briptu'),
(3, 'Brigpol'),
(4, 'Bripka'),
(5, 'Aipda'),
(6, 'Aiptu'),
(7, 'Ipda'),
(8, 'Iptu'),
(9, 'AKP'),
(10, 'Kompol'),
(11, 'AKBP'),
(12, 'Kombes Pol'),
(13, 'Irjen Pol');

-- --------------------------------------------------------

--
-- Table structure for table `tbl_personil`
--

CREATE TABLE `tbl_personil` (
  `personil_id` varchar(36) NOT NULL,
  `nrp` varchar(20) NOT NULL,
  `nama_lengkap` varchar(255) NOT NULL,
  `pangkat_id` int(11) DEFAULT NULL,
  `jabatan_id` int(11) DEFAULT NULL,
  `status_aktif` varchar(50) DEFAULT NULL,
  `polda_id` int(11) DEFAULT NULL,
  `polres_id` int(11) DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `tbl_personil`
--

INSERT INTO `tbl_personil` (`personil_id`, `nrp`, `nama_lengkap`, `pangkat_id`, `jabatan_id`, `status_aktif`, `polda_id`, `polres_id`, `created_at`) VALUES
('020f7943-3741-48a4-ae0b-5b48107c87e6', '81003295', 'Iptu Murni Handayani', 1, 5, 'Aktif', 34, 67, '2026-07-30 20:35:13'),
('0544d7e5-cf32-4359-a575-d89925318ae3', '81002717', 'Brigpol Ari Wibisono', 9, 8, 'Aktif', 3, 5, '2026-07-30 20:35:13'),
('066747a2-48d2-43a0-99ed-8520c9f81115', '81000689', 'Brigpol Eko Prasetyo', 13, 3, 'Aktif', 32, 64, '2026-07-30 20:35:13'),
('07034c14-75fc-4606-b025-4791e98d87cc', '81003058', 'Bripka Dwi Santosa', 10, 5, 'Aktif', 32, 63, '2026-07-30 20:35:13'),
('102c55ce-a624-4041-a463-ef5ab2598769', '81003830', 'Briptu Didi Kurniawan', 11, 5, 'Aktif', 14, 28, '2026-07-30 20:35:13'),
('106f2d88-3f60-4b4c-bbb5-d593186b58a7', '81001107', 'Iptu Mega Lestari', 7, 4, 'Pensiun', 2, 4, '2026-07-30 20:35:13'),
('1e9ca0d2-7c00-4250-9b1e-980c7ebc499b', '81004236', 'Kompol Hartono', 3, 5, 'Mutasi', 25, 49, '2026-07-30 20:35:13'),
('2198e0cd-4ab8-468d-b834-f99d06ac139c', '81002484', 'Aiptu Slamet Riyadi', 9, 7, 'Aktif', 14, 27, '2026-07-30 20:35:13'),
('278fcde7-ef07-41e3-8054-42b79ff5955a', '81002348', 'Briptu Indah Permata', 8, 7, 'Aktif', 17, 34, '2026-07-30 20:35:13'),
('27d36970-5e40-4057-9550-ceba0196cec9', '81004718', 'Brigpol Reza Maulana', 2, 5, 'Mutasi', 21, 41, '2026-07-30 20:35:13'),
('2c3d1650-fffa-414f-9052-35a6469d60b1', '81003689', 'Bripka Catur Prasetyo', 1, 5, 'Aktif', 35, 70, '2026-07-30 20:35:13'),
('2c852efd-4126-46ee-8bf4-f949f1e2c71f', '81004343', 'Aipda I Made Sudarma', 7, 5, 'Aktif', 19, 38, '2026-07-30 20:35:13'),
('36527f64-685d-40a1-a46c-362aafa21c73', '81004693', 'Briptu Yogi Pratama', 2, 5, 'Aktif', 24, 47, '2026-07-30 20:35:13'),
('39e846b5-3ccf-4d91-b24e-4b756cb77ab4', '81001261', 'Kompol Agung Prabowo', 8, 4, 'Mutasi', 8, 16, '2026-07-30 20:35:13'),
('40358e30-f973-4da1-a491-6e30493aed3c', '81001868', 'Bripka Fitri Handayani', 10, 6, 'Pensiun', 28, 56, '2026-07-30 20:35:13'),
('410746cc-b5c2-475b-9782-bb19f74e9d1f', '81002949', 'Bripda Nilam Sari', 3, 5, 'Aktif', 21, 41, '2026-07-30 20:35:13'),
('4476e98e-094a-438b-8769-b3955a4c4ca9', '81000751', 'Ipda Agus Suprayitno', 10, 3, 'Aktif', 30, 60, '2026-07-30 20:35:13'),
('44830573-beac-431c-906c-fcfbf5876c26', '81000226', 'Bripka Hendra Gunawan', 7, 2, 'Aktif', 33, 66, '2026-07-30 20:35:13'),
('496b9036-e15f-4173-a32c-c106eb044816', '81004176', 'Brigpol Yuniarti', 8, 5, 'Aktif', 13, 25, '2026-07-30 20:35:13'),
('4a823912-b2f2-4493-962e-16cee8e656b0', '81001919', 'Aipda Danang Wibowo', 7, 6, 'Aktif', 12, 24, '2026-07-30 20:35:13'),
('4b4d73dd-fa88-4ab2-bc10-bfa0a8955818', '81003196', 'Aipda Tri Nugroho', 10, 5, 'Mutasi', 9, 17, '2026-07-30 20:35:13'),
('51bd8d15-990d-4cbe-9a02-1f8af4dcf7db', '81003762', 'Ipda Susi Rahmawati', 6, 5, 'Aktif', 22, 44, '2026-07-30 20:35:13'),
('5c7774e1-57cf-4157-b85f-d11af86fc1ed', '81001521', 'Aiptu Suryadi Putra', 12, 6, 'Mutasi', 3, 6, '2026-07-30 20:35:13'),
('60e705a9-07d6-4552-8e0d-9f6eaf078f9c', '81002261', 'Kompol Joko Susilo', 9, 7, 'Aktif', 36, 72, '2026-07-30 20:35:13'),
('63baa8b2-f05b-4bda-9efa-327ff826f302', '81002191', 'Bripda Wahyu Nugroho', 4, 7, 'Mutasi', 35, 69, '2026-07-30 20:35:13'),
('6803fc1f-273d-424e-9eb8-6f702ec5d1d8', '81003383', 'Briptu Adi Prakoso', 4, 5, 'Pensiun', 20, 39, '2026-07-30 20:35:13'),
('76c11e7f-cbef-4e89-a46a-7321d146add2', '81002038', 'Iptu Titis Rahayu', 12, 7, 'Aktif', 3, 6, '2026-07-30 20:35:13'),
('7af297f3-97eb-403d-8e07-4d7766e246f4', '81004454', 'Bripda Putu Ayu', 11, 5, 'Aktif', 26, 52, '2026-07-30 20:35:13'),
('7ce9d9ed-9db6-4f7f-8aa7-bba18e58e664', '81001370', 'Briptu Wulan Rahmawati', 11, 4, 'Aktif', 4, 7, '2026-07-30 20:35:13'),
('88cc5753-76ac-41f3-9443-ba72270fce62', '81002615', 'AKP Gunawan Setiawan', 4, 8, 'Aktif', 37, 74, '2026-07-30 20:35:13'),
('8cba0007-d4be-45a2-8176-0d3088f48807', '81001727', 'Ipda Hadi Kusuma', 1, 6, 'Aktif', 36, 71, '2026-07-30 20:35:13'),
('9011f6cc-94f2-4d20-bb60-726c4875e2ff', '81004521', 'Iptu Laila Khairunnisa', 9, 5, 'Aktif', 37, 74, '2026-07-30 20:35:13'),
('97719f82-b4e0-4fcd-b04d-47cfc4bc8136', '81004064', 'AKP Bagus Purnomo', 11, 5, 'Mutasi', 22, 43, '2026-07-30 20:35:13'),
('9d9f689d-7cc8-4e81-b562-2b782a8e2a14', '81000371', 'Briptu Andi Prasetyo', 3, 2, 'Aktif', 25, 49, '2026-07-30 20:35:13'),
('a4d83e83-8ed2-47f1-8282-935386517410', '81001611', 'Brigpol Ratna Dewi', 7, 6, 'Aktif', 5, 10, '2026-07-30 20:35:13'),
('a673fc57-7522-41a8-bf32-e8d0a2264d62', '81001029', 'Aipda Dani Ramdani', 8, 4, 'Mutasi', 4, 7, '2026-07-30 20:35:13'),
('a67d8aad-20a2-46af-b1b2-ecfd9b460ad1', '81002811', 'Ipda Iwan Kurniawan', 7, 5, 'Mutasi', 22, 43, '2026-07-30 20:35:13'),
('aee119b1-0809-4272-b4ce-7a45e1e386cf', '81000188', 'Iptu Rina Marlina', 12, 1, 'Aktif', 29, 58, '2026-07-30 20:35:13'),
('af15f0b2-1285-4f7f-81e1-ed77a1612839', '81000047', 'AKBP Budi Santoso, S.I.K.', 12, 1, 'Mutasi', 15, 29, '2026-07-30 20:35:13'),
('b986a28b-2605-408f-ae50-f4e3bb803222', '81002515', 'Bripka Retno Puspita', 4, 8, 'Aktif', 29, 58, '2026-07-30 20:35:13'),
('c1fb3a64-6513-470d-86fa-1d6b446773de', '81004920', 'Ipda Donny Lesmana, S.T.', 3, 5, 'Aktif', 13, 25, '2026-07-30 20:35:13'),
('cce2aef4-610d-462d-bc21-df45c7e635db', '81003403', 'Brigpol Heru Susanto', 2, 5, 'Aktif', 26, 52, '2026-07-30 20:35:13'),
('e1ae762e-16d9-4d62-8310-bbf34da87d67', '81000490', 'Kompol Ahmad Fauzi, S.H.', 4, 2, 'Aktif', 33, 65, '2026-07-30 20:35:13'),
('e22f73d2-2f8e-44a9-a3d3-41405925c8ba', '81000918', 'Bripda Sari Wijaya', 1, 4, 'Aktif', 6, 12, '2026-07-30 20:35:13'),
('e77022c1-3e34-4749-b49e-25bc0715dc61', '81001438', 'Bripka Yulianto Saputra', 8, 4, 'Aktif', 9, 17, '2026-07-30 20:35:13'),
('eb43ab87-4d6e-4c6f-8a85-ade29f3257b1', '81000544', 'Aiptu Dewi Sartika', 7, 3, 'Mutasi', 15, 30, '2026-07-30 20:35:13'),
('eb7a89ca-74de-45c9-87e7-366fe2cec3f4', '81003583', 'Aiptu Agung Wijaya', 5, 5, 'Pensiun', 18, 35, '2026-07-30 20:35:13'),
('ed56670a-cccc-488c-9f30-d4439a67871f', '81003911', 'Bripda Dian Pertiwi', 5, 5, 'Aktif', 2, 3, '2026-07-30 20:35:13'),
('ed8ef224-8a92-48b0-bab7-22d049916aa7', '81004872', 'Aiptu Suprapti', 8, 5, 'Mutasi', 25, 50, '2026-07-30 20:35:13'),
('f4bce7a0-1af2-4c16-b6a2-d58397f791ab', '81000822', 'AKP Bambang Hartono', 11, 4, 'Aktif', 6, 12, '2026-07-30 20:35:13');

-- --------------------------------------------------------

--
-- Table structure for table `tbl_polda`
--

CREATE TABLE `tbl_polda` (
  `id` int(11) NOT NULL,
  `nama_polda` varchar(100) DEFAULT NULL,
  `latitude` varchar(100) DEFAULT NULL,
  `longitude` varchar(100) DEFAULT NULL,
  `created_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `tbl_polda`
--

INSERT INTO `tbl_polda` (`id`, `nama_polda`, `latitude`, `longitude`, `created_at`) VALUES
(1, 'Polda Aceh', '5.550000', '95.316666', '0000-00-00 00:00:00'),
(2, 'Polda Sumatera Utara', '3.583333', '98.666667', '0000-00-00 00:00:00'),
(3, 'Polda Sumatera Barat', '-0.916667', '100.366667', '0000-00-00 00:00:00'),
(4, 'Polda Riau', '0.533333', '101.450000', '0000-00-00 00:00:00'),
(5, 'Polda Kepulauan Riau', '0.916667', '104.450000', '0000-00-00 00:00:00'),
(6, 'Polda Jambi', '-1.583333', '103.616667', '0000-00-00 00:00:00'),
(7, 'Polda Sumatera Selatan', '-2.983333', '104.750000', '0000-00-00 00:00:00'),
(8, 'Polda Bangka Belitung', '-2.133333', '106.116667', '0000-00-00 00:00:00'),
(9, 'Polda Bengkulu', '-3.800000', '102.266667', '0000-00-00 00:00:00'),
(10, 'Polda Lampung', '-5.416667', '105.250000', '0000-00-00 00:00:00'),
(11, 'Polda Metro Jaya', '-6.200000', '106.816666', '0000-00-00 00:00:00'),
(12, 'Polda Banten', '-6.116667', '106.150000', '0000-00-00 00:00:00'),
(13, 'Polda Jawa Barat', '-6.914744', '107.609810', '0000-00-00 00:00:00'),
(14, 'Polda Jawa Tengah', '-6.983333', '110.366667', '0000-00-00 00:00:00'),
(15, 'Polda D.I. Yogyakarta', '-7.800000', '110.366667', '0000-00-00 00:00:00'),
(16, 'Polda Jawa Timur', '-7.250000', '112.750000', '0000-00-00 00:00:00'),
(17, 'Polda Kalimantan Barat', '-0.016667', '109.350000', '0000-00-00 00:00:00'),
(18, 'Polda Kalimantan Tengah', '-2.216667', '113.916667', '0000-00-00 00:00:00'),
(19, 'Polda Kalimantan Selatan', '-3.316667', '114.583333', '0000-00-00 00:00:00'),
(20, 'Polda Kalimantan Timur', '-0.500000', '117.150000', '0000-00-00 00:00:00'),
(21, 'Polda Kalimantan Utara', '3.000000', '116.533333', '0000-00-00 00:00:00'),
(22, 'Polda Bali', '-8.550000', '115.266667', '0000-00-00 00:00:00'),
(23, 'Polda Nusa Tenggara Barat', '-8.583333', '116.116667', '0000-00-00 00:00:00'),
(24, 'Polda Nusa Tenggara Timur', '-10.166667', '123.583333', '0000-00-00 00:00:00'),
(25, 'Polda Sulawesi Utara', '1.483333', '124.850000', '0000-00-00 00:00:00'),
(26, 'Polda Gorontalo', '0.533333', '123.066667', '0000-00-00 00:00:00'),
(27, 'Polda Sulawesi Tengah', '-0.900000', '119.850000', '0000-00-00 00:00:00'),
(28, 'Polda Sulawesi Selatan', '-5.133333', '119.416667', '0000-00-00 00:00:00'),
(29, 'Polda Sulawesi Tenggara', '-3.966667', '122.516667', '0000-00-00 00:00:00'),
(30, 'Polda Sulawesi Barat', '-2.683333', '118.900000', '0000-00-00 00:00:00'),
(31, 'Polda Maluku', '-3.700000', '128.166667', '0000-00-00 00:00:00'),
(32, 'Polda Maluku Utara', '0.783333', '127.366667', '0000-00-00 00:00:00'),
(33, 'Polda Papua', '-2.533333', '140.716667', '0000-00-00 00:00:00'),
(34, 'Polda Papua Barat', '-0.866667', '134.083333', '0000-00-00 00:00:00'),
(35, 'Polda Papua Selatan', '-8.500000', '140.400000', '0000-00-00 00:00:00'),
(36, 'Polda Papua Tengah', '-3.350000', '135.500000', '0000-00-00 00:00:00'),
(37, 'Polda Papua Pegunungan', '-4.100000', '138.950000', '0000-00-00 00:00:00'),
(38, 'Polda Papua Barat Daya', '-0.866667', '131.250000', '0000-00-00 00:00:00');

-- --------------------------------------------------------

--
-- Table structure for table `tbl_polres`
--

CREATE TABLE `tbl_polres` (
  `polres_id` int(11) NOT NULL,
  `polda_id` int(11) NOT NULL DEFAULT 0,
  `nama_polres` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `tbl_polres`
--

INSERT INTO `tbl_polres` (`polres_id`, `polda_id`, `nama_polres`) VALUES
(1, 1, 'Polrestabes 1.1'),
(2, 1, 'Polres 1.2'),
(3, 2, 'Polrestabes 2.1'),
(4, 2, 'Polres 2.2'),
(5, 3, 'Polrestabes 3.1'),
(6, 3, 'Polres 3.2'),
(7, 4, 'Polrestabes 4.1'),
(8, 4, 'Polres 4.2'),
(9, 5, 'Polrestabes 5.1'),
(10, 5, 'Polres 5.2'),
(11, 6, 'Polrestabes 6.1'),
(12, 6, 'Polres 6.2'),
(13, 7, 'Polrestabes 7.1'),
(14, 7, 'Polres 7.2'),
(15, 8, 'Polrestabes 8.1'),
(16, 8, 'Polres 8.2'),
(17, 9, 'Polrestabes 9.1'),
(18, 9, 'Polres 9.2'),
(19, 10, 'Polrestabes 10.1'),
(20, 10, 'Polres 10.2'),
(21, 11, 'Polrestabes 11.1'),
(22, 11, 'Polres 11.2'),
(23, 12, 'Polrestabes 12.1'),
(24, 12, 'Polres 12.2'),
(25, 13, 'Polrestabes 13.1'),
(26, 13, 'Polres 13.2'),
(27, 14, 'Polrestabes 14.1'),
(28, 14, 'Polres 14.2'),
(29, 15, 'Polrestabes 15.1'),
(30, 15, 'Polres 15.2'),
(31, 16, 'Polrestabes 16.1'),
(32, 16, 'Polres 16.2'),
(33, 17, 'Polrestabes 17.1'),
(34, 17, 'Polres 17.2'),
(35, 18, 'Polrestabes 18.1'),
(36, 18, 'Polres 18.2'),
(37, 19, 'Polrestabes 19.1'),
(38, 19, 'Polres 19.2'),
(39, 20, 'Polrestabes 20.1'),
(40, 20, 'Polres 20.2'),
(41, 21, 'Polrestabes 21.1'),
(42, 21, 'Polres 21.2'),
(43, 22, 'Polrestabes 22.1'),
(44, 22, 'Polres 22.2'),
(45, 23, 'Polrestabes 23.1'),
(46, 23, 'Polres 23.2'),
(47, 24, 'Polrestabes 24.1'),
(48, 24, 'Polres 24.2'),
(49, 25, 'Polrestabes 25.1'),
(50, 25, 'Polres 25.2'),
(51, 26, 'Polrestabes 26.1'),
(52, 26, 'Polres 26.2'),
(53, 27, 'Polrestabes 27.1'),
(54, 27, 'Polres 27.2'),
(55, 28, 'Polrestabes 28.1'),
(56, 28, 'Polres 28.2'),
(57, 29, 'Polrestabes 29.1'),
(58, 29, 'Polres 29.2'),
(59, 30, 'Polrestabes 30.1'),
(60, 30, 'Polres 30.2'),
(61, 31, 'Polrestabes 31.1'),
(62, 31, 'Polres 31.2'),
(63, 32, 'Polrestabes 32.1'),
(64, 32, 'Polres 32.2'),
(65, 33, 'Polrestabes 33.1'),
(66, 33, 'Polres 33.2'),
(67, 34, 'Polrestabes 34.1'),
(68, 34, 'Polres 34.2'),
(69, 35, 'Polrestabes 35.1'),
(70, 35, 'Polres 35.2'),
(71, 36, 'Polrestabes 36.1'),
(72, 36, 'Polres 36.2'),
(73, 37, 'Polrestabes 37.1'),
(74, 37, 'Polres 37.2'),
(75, 38, 'Polrestabes 38.1'),
(76, 38, 'Polres 38.2');

-- --------------------------------------------------------

--
-- Table structure for table `tbl_proses_hukum`
--

CREATE TABLE `tbl_proses_hukum` (
  `hukum_id` int(11) NOT NULL,
  `personil_id` varchar(36) NOT NULL,
  `klasifikasi` enum('Pemeriksaan Propam','Sidang Kode Etik','Sidang Disiplin','Pidana Umum') NOT NULL,
  `status_hukum` varchar(100) NOT NULL,
  `tanggal_mulai` date NOT NULL,
  `deskripsi_kasus` text DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `tbl_proses_hukum`
--

INSERT INTO `tbl_proses_hukum` (`hukum_id`, `personil_id`, `klasifikasi`, `status_hukum`, `tanggal_mulai`, `deskripsi_kasus`, `created_at`) VALUES
(1, 'af15f0b2-1285-4f7f-81e1-ed77a1612839', 'Pemeriksaan Propam', 'Dalam Penyelidikan', '2026-07-23', 'Kasus disiplin simulasi seeder — 1', '2026-07-30 20:35:13'),
(2, 'aee119b1-0809-4272-b4ce-7a45e1e386cf', 'Sidang Kode Etik', 'Proses Sidang', '2026-07-16', 'Kasus disiplin simulasi seeder — 2', '2026-07-30 20:35:13'),
(3, '44830573-beac-431c-906c-fcfbf5876c26', 'Sidang Disiplin', 'Putusan', '2026-07-09', 'Kasus disiplin simulasi seeder — 3', '2026-07-30 20:35:13'),
(4, '9d9f689d-7cc8-4e81-b562-2b782a8e2a14', 'Pidana Umum', 'Banding', '2026-07-02', 'Kasus disiplin simulasi seeder — 4', '2026-07-30 20:35:13'),
(5, 'e1ae762e-16d9-4d62-8310-bbf34da87d67', 'Pemeriksaan Propam', 'Dalam Penyelidikan', '2026-06-25', 'Kasus disiplin simulasi seeder — 5', '2026-07-30 20:35:13'),
(6, 'eb43ab87-4d6e-4c6f-8a85-ade29f3257b1', 'Sidang Kode Etik', 'Proses Sidang', '2026-06-18', 'Kasus disiplin simulasi seeder — 6', '2026-07-30 20:35:13'),
(7, '066747a2-48d2-43a0-99ed-8520c9f81115', 'Sidang Disiplin', 'Putusan', '2026-06-11', 'Kasus disiplin simulasi seeder — 7', '2026-07-30 20:35:13'),
(8, '4476e98e-094a-438b-8769-b3955a4c4ca9', 'Pidana Umum', 'Banding', '2026-06-04', 'Kasus disiplin simulasi seeder — 8', '2026-07-30 20:35:13');

-- --------------------------------------------------------

--
-- Table structure for table `tbl_role`
--

CREATE TABLE `tbl_role` (
  `id` int(11) NOT NULL,
  `roles` varchar(100) NOT NULL,
  `created_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `tbl_role`
--

INSERT INTO `tbl_role` (`id`, `roles`, `created_at`) VALUES
(1, 'Super Admin', '2026-07-11 00:00:00'),
(2, 'Operator Polda', '2026-07-12 00:00:00'),
(3, 'Eksekutif', '2026-07-14 11:25:28');

-- --------------------------------------------------------

--
-- Table structure for table `tbl_sarpras`
--

CREATE TABLE `tbl_sarpras` (
  `sarpras_id` varchar(36) NOT NULL,
  `polda_id` int(11) DEFAULT NULL,
  `kode_barang` varchar(100) NOT NULL,
  `nama_barang` varchar(255) NOT NULL,
  `kategori` varchar(50) DEFAULT NULL,
  `kondisi` enum('Baik','Rusak Ringan','Rusak Berat') DEFAULT 'Baik',
  `tahun_pengadaan` varchar(10) DEFAULT NULL,
  `foto_url` varchar(500) DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `tbl_sarpras`
--

INSERT INTO `tbl_sarpras` (`sarpras_id`, `polda_id`, `kode_barang`, `nama_barang`, `kategori`, `kondisi`, `tahun_pengadaan`, `foto_url`, `created_at`, `updated_at`) VALUES
('013a7793-8d0a-4119-ab64-d79214836bcb', 24, 'SPR-KEND-004', 'Motor Trail Kawasaki KLX250', 'Kendaraan', 'Baik', '2021', 'https://placehold.co/400x300?text=Sarpras+4', '2026-07-30 20:35:13', NULL),
('02c7b012-ac82-4acf-972e-afc46bad3fbf', 13, 'SPR-PERL-028', 'Kursi Kantor Eksklusif', 'Perlengkapan Kantor', 'Baik', '2021', 'https://placehold.co/400x300?text=Sarpras+28', '2026-07-30 20:35:13', NULL),
('13ddb030-a91c-4335-a13b-256393eec2f0', 31, 'SPR-PERL-013', 'Laptop Lenovo ThinkPad', 'Perlengkapan Kantor', 'Baik', '2023', 'https://placehold.co/400x300?text=Sarpras+13', '2026-07-30 20:35:13', NULL),
('181c959f-2a2d-4b0f-a6e4-f9fcc69566e5', 22, 'SPR-PERL-030', 'Dispenser Air', 'Perlengkapan Kantor', 'Baik', '2023', 'https://placehold.co/400x300?text=Sarpras+30', '2026-07-30 20:35:13', NULL),
('2dd359fc-b304-4b0e-9e50-8ec3c11c6e10', 4, 'SPR-PERL-007', 'Tameng Dalmas', 'Perlengkapan Dalmas', 'Baik', '2021', 'https://placehold.co/400x300?text=Sarpras+7', '2026-07-30 20:35:13', NULL),
('2ea2ce58-1ce7-4563-ba22-24b017bb775d', 23, 'SPR-PERL-008', 'Helm Anti-Rusuh', 'Perlengkapan Dalmas', 'Baik', '2021', 'https://placehold.co/400x300?text=Sarpras+8', '2026-07-30 20:35:13', NULL),
('37e96229-a6c6-4604-b93a-ad0faa7dd4ce', 12, 'SPR-PERL-027', 'Meja Rapat Kayu Jati', 'Perlengkapan Kantor', 'Baik', '2024', 'https://placehold.co/400x300?text=Sarpras+27', '2026-07-30 20:35:13', NULL),
('45497086-9856-4cb9-9fc6-a1d20df90094', 28, 'SPR-ALAT-019', 'GPS Tracker Garmin', 'Alat Komunikasi', 'Baik', '2021', 'https://placehold.co/400x300?text=Sarpras+19', '2026-07-30 20:35:13', NULL),
('4d0e222b-3b56-445c-96a6-1236b2d189e3', 37, 'SPR-KEND-003', 'Rantis Tambun', 'Kendaraan Taktis', 'Rusak Ringan', '2020', 'https://placehold.co/400x300?text=Sarpras+3', '2026-07-30 20:35:13', NULL),
('519b7f9a-b7ad-4fd4-97c6-95f80e9a75ca', 31, 'SPR-PERL-006', 'Borgol Standar Polri', 'Perlengkapan Dalmas', 'Baik', '2021', 'https://placehold.co/400x300?text=Sarpras+6', '2026-07-30 20:35:13', NULL),
('604b332b-dbd7-48cd-a470-eb830825c275', 28, 'SPR-PERL-020', 'Tenda Pos PAM Dalmas', 'Perlengkapan Dalmas', 'Baik', '2022', 'https://placehold.co/400x300?text=Sarpras+20', '2026-07-30 20:35:13', NULL),
('6052f48f-df8a-45d9-a564-1557858b3c7a', 22, 'SPR-ALAT-021', 'Sound System Portable', 'Alat Komunikasi', 'Baik', '2022', 'https://placehold.co/400x300?text=Sarpras+21', '2026-07-30 20:35:13', NULL),
('62312006-83c0-4688-8b35-579ab4a7dde9', 21, 'SPR-PERL-029', 'Lemari Arsip Besi', 'Perlengkapan Kantor', 'Rusak Ringan', '2024', 'https://placehold.co/400x300?text=Sarpras+29', '2026-07-30 20:35:13', NULL),
('7a9348d9-c703-4a94-9aac-a4e13b18c441', 25, 'SPR-ALAT-005', 'HT Motorola GP380', 'Alat Komunikasi', 'Baik', '2024', 'https://placehold.co/400x300?text=Sarpras+5', '2026-07-30 20:35:13', NULL),
('82e5c644-229e-463f-bb39-fe6a074f17ed', 1, 'SPR-PERL-026', 'AC Split 2 PK', 'Perlengkapan Kantor', 'Rusak Berat', '2022', 'https://placehold.co/400x300?text=Sarpras+26', '2026-07-30 20:35:13', NULL),
('85c6ab83-4f15-4314-abc4-42756f82af44', 14, 'SPR-ALAT-011', 'Kamera Bodycam', 'Alat Komunikasi', 'Baik', '2022', 'https://placehold.co/400x300?text=Sarpras+11', '2026-07-30 20:35:13', NULL),
('9427e97f-8954-4a0b-bea7-acd36b888976', 20, 'SPR-PERL-010', 'Rompi Anti Peluru IIIA', 'Perlengkapan Dalmas', 'Rusak Ringan', '2024', 'https://placehold.co/400x300?text=Sarpras+10', '2026-07-30 20:35:13', NULL),
('95201fa6-326e-4eae-b04c-0b2aa5c9b594', 18, 'SPR-PERL-014', 'Printer Epson L3210', 'Perlengkapan Kantor', 'Rusak Ringan', '2023', 'https://placehold.co/400x300?text=Sarpras+14', '2026-07-30 20:35:13', NULL),
('96e29441-3dfb-48f3-8a92-5b70dd6315ba', 36, 'SPR-KEND-016', 'Mobil Tahanan Isuzu Elf', 'Kendaraan', 'Baik', '2024', 'https://placehold.co/400x300?text=Sarpras+16', '2026-07-30 20:35:13', NULL),
('9882edaa-614e-42a7-ba65-d96d7cfa04bc', 19, 'SPR-KEND-002', 'Water Cannon Barracuda', 'Kendaraan Taktis', 'Baik', '2024', 'https://placehold.co/400x300?text=Sarpras+2', '2026-07-30 20:35:13', NULL),
('a231bc45-c0d7-4f79-8156-291fe5aba9ba', 4, 'SPR-ALAT-012', 'Drone DJI Matrice', 'Alat Komunikasi', 'Baik', '2021', 'https://placehold.co/400x300?text=Sarpras+12', '2026-07-30 20:35:13', NULL),
('a5b96c83-6cca-469c-8f92-a479c4c1b7ae', 5, 'SPR-KEND-015', 'Mobil Patroli Toyota Innova', 'Kendaraan', 'Baik', '2024', 'https://placehold.co/400x300?text=Sarpras+15', '2026-07-30 20:35:13', NULL),
('aee3150c-28fe-43d4-a531-c0b6029c97d3', 13, 'SPR-PERL-009', 'Pentungan Polri', 'Perlengkapan Dalmas', 'Baik', '2024', 'https://placehold.co/400x300?text=Sarpras+9', '2026-07-30 20:35:13', NULL),
('cd5af831-bc63-4413-a98f-373f51c05437', 17, 'SPR-PERL-025', 'Generator Listrik 5kVA', 'Perlengkapan Kantor', 'Baik', '2021', 'https://placehold.co/400x300?text=Sarpras+25', '2026-07-30 20:35:13', NULL),
('d50ab97d-98c9-4e1e-832f-abfb95674910', 22, 'SPR-KEND-001', 'APC Anoa 6x6', 'Kendaraan Taktis', 'Baik', '2022', 'https://placehold.co/400x300?text=Sarpras+1', '2026-07-30 20:35:13', NULL),
('e3127d0c-06b2-41d4-9c80-5ef7e1c3544e', 29, 'SPR-PERL-022', 'Metal Detector Garett', 'Perlengkapan Dalmas', 'Baik', '2020', 'https://placehold.co/400x300?text=Sarpras+22', '2026-07-30 20:35:13', NULL),
('e8e87951-154d-4bc7-9a55-33949a8c085e', 31, 'SPR-PERL-024', 'Kursi Roda Evakuasi', 'Perlengkapan Dalmas', 'Rusak Ringan', '2020', 'https://placehold.co/400x300?text=Sarpras+24', '2026-07-30 20:35:13', NULL),
('ef5d9524-5c5b-4885-9ed8-e9e919de5236', 4, 'SPR-KEND-023', 'Kendaraan Rantis Maung', 'Kendaraan Taktis', 'Baik', '2022', 'https://placehold.co/400x300?text=Sarpras+23', '2026-07-30 20:35:13', NULL),
('fbfcae01-ffc3-4b60-b05a-54e2e66cb608', 27, 'SPR-ALAT-018', 'Radio Rig Yaesu FT-991', 'Alat Komunikasi', 'Baik', '2022', 'https://placehold.co/400x300?text=Sarpras+18', '2026-07-30 20:35:13', NULL),
('fc29917f-abf2-4fea-b368-99cd220f99c9', 3, 'SPR-KEND-017', 'Sepeda Motor Honda CB150R', 'Kendaraan', 'Rusak Berat', '2022', 'https://placehold.co/400x300?text=Sarpras+17', '2026-07-30 20:35:13', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `tbl_satwa`
--

CREATE TABLE `tbl_satwa` (
  `satwa_id` varchar(36) NOT NULL,
  `polda_id` int(11) DEFAULT NULL,
  `nomor_registrasi` varchar(100) NOT NULL,
  `jenis_satwa` varchar(50) DEFAULT NULL,
  `nama_satwa` varchar(255) DEFAULT NULL,
  `nama_handler` varchar(255) DEFAULT NULL,
  `kualifikasi` varchar(100) DEFAULT NULL,
  `jadwal_vaksin` date DEFAULT NULL,
  `foto_url` varchar(500) DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `tbl_satwa`
--

INSERT INTO `tbl_satwa` (`satwa_id`, `polda_id`, `nomor_registrasi`, `jenis_satwa`, `nama_satwa`, `nama_handler`, `kualifikasi`, `jadwal_vaksin`, `foto_url`, `created_at`) VALUES
('0c5375cf-1350-4d79-a1e4-ae0f51405bdd', 4, 'TRG-P04-009', 'Turangga', 'Panji Asmoro', 'Brigpol Ratna Dewi', 'Patroli', '2027-01-27', 'https://placehold.co/400x300?text=Turangga-Panji+Asmoro', '2026-07-30 20:35:13'),
('183186fb-9d54-4821-8c9a-08400da854f8', 2, 'TRG-P02-002', 'Turangga', 'Bima Sakti', 'Briptu Wulan Rahmawati', 'Patroli', '2026-12-31', 'https://placehold.co/400x300?text=Turangga-Bima+Sakti', '2026-07-30 20:35:13'),
('378bdd6b-2b06-4115-9b81-0580d97de3ef', 37, 'K9-P37-004', 'K9', 'Rex', 'Aipda Suryadi', 'Pelacak', '2027-01-10', 'https://placehold.co/400x300?text=K9-Rex', '2026-07-30 20:35:13'),
('3ea973bf-6ee5-4caf-b9a8-1fced0e43939', 23, 'TRG-P23-006', 'Turangga', 'Roro Mendut', 'Aipda Danang Wibowo', 'Dalmas', '2027-05-14', 'https://placehold.co/400x300?text=Turangga-Roro+Mendut', '2026-07-30 20:35:13'),
('4244627d-b08d-4f01-92ed-c5ce51e92093', 18, 'TRG-P18-010', 'Turangga', 'Cakra Buana', 'Bripka Yulianto Saputra', 'Patroli', '2026-08-26', 'https://placehold.co/400x300?text=Turangga-Cakra+Buana', '2026-07-30 20:35:13'),
('44b4a5a6-0df1-4d30-bdf7-d70916d005f6', 5, 'K9-P05-009', 'K9', 'Grom', 'Ipda Hadi Kusuma', 'Pelacak', '2027-03-07', 'https://placehold.co/400x300?text=K9-Grom', '2026-07-30 20:35:13'),
('499659b6-ab10-495a-85df-4c7d797935bb', 26, 'TRG-P26-007', 'Turangga', 'Sembada', 'Briptu Indah Permata', 'Patroli', '2026-09-09', 'https://placehold.co/400x300?text=Turangga-Sembada', '2026-07-30 20:35:13'),
('59bb10f7-d98b-4ef0-badc-f0fc5b4e97c7', 18, 'K9-P18-002', 'K9', 'Bruno', 'Bripka Rudi Hartono', 'Narkotika', '2026-10-31', 'https://placehold.co/400x300?text=K9-Bruno', '2026-07-30 20:35:13'),
('5dd8ee81-e01a-4d95-b25a-a49eb483dbc8', 18, 'TRG-P18-003', 'Turangga', 'Singa Barong', 'Bripka Hendra Gunawan', 'Dalmas', '2026-11-24', 'https://placehold.co/400x300?text=Turangga-Singa+Barong', '2026-07-30 20:35:13'),
('691fc1b1-8178-452d-85ee-9844fcc55d85', 20, 'K9-P20-010', 'K9', 'Hulk', 'Bripka Dwi Santosa', 'Narkotika', '2026-12-08', 'https://placehold.co/400x300?text=K9-Hulk', '2026-07-30 20:35:13'),
('72448c62-69c8-4c2f-879a-af1b7dc6ead0', 21, 'TRG-P21-008', 'Turangga', 'Wahyu Kliyu', 'Ipda Titis Rahayu', 'Dalmas', '2026-08-09', 'https://placehold.co/400x300?text=Turangga-Wahyu+Kliyu', '2026-07-30 20:35:13'),
('8a097e6a-2455-4153-a0cb-a76029f6bef7', 12, 'TRG-P12-004', 'Turangga', 'Kyai Slamet', 'Brigpol Eko Prasetyo', 'Patroli', '2026-09-19', 'https://placehold.co/400x300?text=Turangga-Kyai+Slamet', '2026-07-30 20:35:13'),
('95a6d0e5-558f-4acd-ae37-7b4b590c0b6c', 11, 'K9-P11-003', 'K9', 'Rocky', 'Brigpol Eko Prasetyo', 'Patroli', '2026-12-29', 'https://placehold.co/400x300?text=K9-Rocky', '2026-07-30 20:35:13'),
('acf8cc00-ba4e-41fc-83a3-33c7f77d9420', 5, 'K9-P05-011', 'K9', 'Ivan', 'Briptu Yogi Pratama', 'Pelacak', '2026-08-07', 'https://placehold.co/400x300?text=K9-Ivan', '2026-07-30 20:35:13'),
('b0f97a20-9a77-4659-8233-5b466fbca2e3', 18, 'K9-P18-008', 'K9', 'Django', 'Brigpol Ari Wibisono', 'Patroli', '2027-01-06', 'https://placehold.co/400x300?text=K9-Django', '2026-07-30 20:35:13'),
('b2e18dc8-964a-4cca-a10e-b1f7d232db20', 11, 'K9-P11-001', 'K9', 'Helder', 'Briptu Doni Kusuma', 'Pelacak', '2027-05-10', 'https://placehold.co/400x300?text=K9-Helder', '2026-07-30 20:35:13'),
('b43a1922-d496-451f-aa50-335af3514458', 1, 'K9-P01-005', 'K9', 'Argo', 'Briptu Adi Prakoso', 'Narkotika', '2027-03-23', 'https://placehold.co/400x300?text=K9-Argo', '2026-07-30 20:35:13'),
('dde62bc4-2f4d-4e13-bfff-f5e6ff7ffe3c', 15, 'K9-P15-012', 'K9', 'Loki', 'Aiptu Agung Wijaya', 'Narkotika', '2027-05-21', 'https://placehold.co/400x300?text=K9-Loki', '2026-07-30 20:35:13'),
('de46b61e-3b31-444f-bac7-f69e47145bfc', 4, 'K9-P04-015', 'K9', 'Thor', 'Aipda Dani Ramdani', 'Narkotika', '2027-01-13', 'https://placehold.co/400x300?text=K9-Thor', '2026-07-30 20:35:13'),
('e3a12e2f-5c47-4e6c-bf97-57401536af2f', 22, 'K9-P22-007', 'K9', 'Cesar', 'Aiptu Slamet Riyadi', 'Narkotika', '2027-01-08', 'https://placehold.co/400x300?text=K9-Cesar', '2026-07-30 20:35:13'),
('e4c4ad13-ca6e-43d6-8914-39cf5c8e2221', 7, 'K9-P07-006', 'K9', 'Boris', 'Bripda Wahyu Nugroho', 'Pelacak', '2026-10-13', 'https://placehold.co/400x300?text=K9-Boris', '2026-07-30 20:35:13'),
('f253a4d5-4816-45bf-af16-d664174f01d6', 25, 'K9-P25-013', 'K9', 'Max', 'Brigpol Reza Maulana', 'Patroli', '2026-12-31', 'https://placehold.co/400x300?text=K9-Max', '2026-07-30 20:35:13'),
('f4801cb3-9492-4f48-a20c-4942a5e3bed9', 9, 'TRG-P09-005', 'Turangga', 'Puspo Negoro', 'Bripda Sari Wijaya', 'Patroli', '2027-01-13', 'https://placehold.co/400x300?text=Turangga-Puspo+Negoro', '2026-07-30 20:35:13'),
('f6a4cf93-2956-44ea-859b-a2225bd01b4b', 36, 'K9-P36-014', 'K9', 'Odin', 'Bripda Dian Pertiwi', 'Pelacak', '2027-01-12', 'https://placehold.co/400x300?text=K9-Odin', '2026-07-30 20:35:13'),
('ff1d516c-a516-4035-9f45-7ba5711bcb17', 2, 'TRG-P02-001', 'Turangga', 'Gagak Rimang', 'Aiptu Suryadi', 'Dalmas', '2027-04-22', 'https://placehold.co/400x300?text=Turangga-Gagak+Rimang', '2026-07-30 20:35:13');

-- --------------------------------------------------------

--
-- Table structure for table `tbl_senjata`
--

CREATE TABLE `tbl_senjata` (
  `senjata_id` varchar(36) NOT NULL,
  `nomor_seri` varchar(100) DEFAULT NULL,
  `kategori_id` int(11) DEFAULT NULL,
  `polda_id` int(11) DEFAULT NULL,
  `tahun_pengadaan` varchar(10) DEFAULT NULL,
  `status_kelayakan` varchar(50) DEFAULT NULL,
  `foto_url` varchar(500) DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `tbl_senjata`
--

INSERT INTO `tbl_senjata` (`senjata_id`, `nomor_seri`, `kategori_id`, `polda_id`, `tahun_pengadaan`, `status_kelayakan`, `foto_url`, `created_at`) VALUES
('002a983d-3434-4f22-9687-9bbccfe3a62e', 'SNJ-0001-2026', 1, 11, '2024', 'Laik', 'https://placehold.co/400x300?text=Senjata+1', '2026-07-30 20:35:13'),
('050c54f7-0784-4bd0-8bd1-c1ed4aed8e3b', 'SS2-0002-2024', 1, 34, '2024', 'Laik', 'https://placehold.co/400x300?text=Senjata+2', '2026-07-30 20:35:13'),
('0c2e816e-a0cb-4ebb-b6a9-a63270d327bd', 'HNZ-0013-2021', 1, 10, '2023', 'Laik', 'https://placehold.co/400x300?text=Senjata+13', '2026-07-30 20:35:13'),
('1aa02216-50ff-44b2-8216-08f69d16b4d5', 'HNZ-0010-2024', 1, 10, '2023', 'Laik', 'https://placehold.co/400x300?text=Senjata+10', '2026-07-30 20:35:13'),
('1be60c5b-5b9c-422f-bdb3-68f7deea73ea', 'G2-0018-2025', 1, 21, '2022', 'Rusak Ringan', 'https://placehold.co/400x300?text=Senjata+18', '2026-07-30 20:35:13'),
('1d808535-bd13-4d91-9855-d68ab76e4c0b', 'SNJ-0016-2021', 1, 5, '2020', 'Laik', 'https://placehold.co/400x300?text=Senjata+16', '2026-07-30 20:35:13'),
('29c8daa4-7079-4062-883c-0abcfa2f5095', 'SS2-0019-2021', 1, 36, '2020', 'Laik', 'https://placehold.co/400x300?text=Senjata+19', '2026-07-30 20:35:13'),
('2f0d3e3c-03f0-4672-b5a7-e4305590984e', 'P1-0023-2024', 2, 27, '2023', 'Laik', 'https://placehold.co/400x300?text=Senjata+23', '2026-07-30 20:35:13'),
('303a1c89-c6db-4cdb-a4f1-d604320a0d1e', 'HNZ-0022-2022', 2, 35, '2024', 'Laik', 'https://placehold.co/400x300?text=Senjata+22', '2026-07-30 20:35:13'),
('3b7b6688-a66d-4893-a3af-7fd04897fbd2', 'P1-0024-2021', 2, 31, '2021', 'Laik', 'https://placehold.co/400x300?text=Senjata+24', '2026-07-30 20:35:13'),
('4b8f2565-6909-4b49-be55-9103c94993a2', 'G2-0014-2020', 1, 25, '2024', 'Laik', 'https://placehold.co/400x300?text=Senjata+14', '2026-07-30 20:35:13'),
('519325f2-e065-4d47-b3b3-d8985d65d15d', 'SS2-0029-2021', 2, 32, '2022', 'Laik', 'https://placehold.co/400x300?text=Senjata+29', '2026-07-30 20:35:13'),
('5662410b-d413-4591-91f5-073f352a0f49', 'G2-0005-2022', 1, 14, '2023', 'Rusak Ringan', 'https://placehold.co/400x300?text=Senjata+5', '2026-07-30 20:35:13'),
('571d9741-8472-4b4f-b07f-3c4b5f65a4cf', 'SS2-0015-2023', 1, 6, '2024', 'Laik', 'https://placehold.co/400x300?text=Senjata+15', '2026-07-30 20:35:13'),
('57561524-7cf1-4aaa-9ee2-a89de73120cd', 'SS2-0025-2021', 2, 29, '2023', 'Laik', 'https://placehold.co/400x300?text=Senjata+25', '2026-07-30 20:35:13'),
('583c80c1-8cad-416e-9f25-d1d2c0a960f1', 'SNJ-0009-2023', 1, 25, '2022', 'Laik', 'https://placehold.co/400x300?text=Senjata+9', '2026-07-30 20:35:13'),
('6467bc4d-83f8-482f-bdb6-25234b015495', 'SS2-0011-2025', 1, 27, '2020', 'Laik', 'https://placehold.co/400x300?text=Senjata+11', '2026-07-30 20:35:13'),
('67949d84-bdb4-4f96-bdd4-42565360957b', 'SNJ-0020-2020', 1, 9, '2023', 'Rusak Ringan', 'https://placehold.co/400x300?text=Senjata+20', '2026-07-30 20:35:13'),
('69cf67fe-a55a-4c22-9a8b-2d43ff52ab1e', 'HNZ-0004-2023', 1, 9, '2023', 'Laik', 'https://placehold.co/400x300?text=Senjata+4', '2026-07-30 20:35:13'),
('6d2f0d5e-dfc8-4f6f-af64-f9deacb7331a', 'SS2-0034-2024', 2, 9, '2020', 'Rusak Ringan', 'https://placehold.co/400x300?text=Senjata+34', '2026-07-30 20:35:13'),
('71536dad-fbec-44d0-9d0e-0cf4000c22ae', 'SNJ-0012-2023', 1, 8, '2020', 'Laik', 'https://placehold.co/400x300?text=Senjata+12', '2026-07-30 20:35:13'),
('82734721-b69d-4001-b4d3-eddd46db5590', 'P1-0027-2021', 2, 29, '2023', 'Laik', 'https://placehold.co/400x300?text=Senjata+27', '2026-07-30 20:35:13'),
('8f9e2d8d-6e2c-452e-8960-9cf2b0bd883d', 'G2-0008-2022', 1, 27, '2021', 'Laik', 'https://placehold.co/400x300?text=Senjata+8', '2026-07-30 20:35:13'),
('9cc8e25c-4427-472e-b019-137a5202ece2', 'P1-0028-2022', 2, 31, '2020', 'Laik', 'https://placehold.co/400x300?text=Senjata+28', '2026-07-30 20:35:13'),
('a80b4c38-f7d6-43e3-b783-959b60790833', 'HNZ-0033-2025', 2, 21, '2024', 'Rusak Ringan', 'https://placehold.co/400x300?text=Senjata+33', '2026-07-30 20:35:13'),
('a9b8ee21-cc17-4723-8e95-82904f4ae550', 'G2-0026-2023', 2, 33, '2022', 'Rusak Berat', 'https://placehold.co/400x300?text=Senjata+26', '2026-07-30 20:35:13'),
('afad8359-6c43-4209-9cf8-3336edf30b59', 'SS2-0017-2025', 1, 23, '2023', 'Laik', 'https://placehold.co/400x300?text=Senjata+17', '2026-07-30 20:35:13'),
('bb30c8ad-5e13-4cd2-accf-73199fb921f0', 'HNZ-0007-2023', 1, 13, '2023', 'Laik', 'https://placehold.co/400x300?text=Senjata+7', '2026-07-30 20:35:13'),
('c7e1ff84-6eae-4084-887e-336954dfb894', 'P1-0003-2026', 1, 26, '2024', 'Laik', 'https://placehold.co/400x300?text=Senjata+3', '2026-07-30 20:35:13'),
('cfdb1740-3154-467e-89d7-7fbbfee773bc', 'SNJ-0035-2020', 2, 19, '2024', 'Laik', 'https://placehold.co/400x300?text=Senjata+35', '2026-07-30 20:35:13'),
('cfdc6048-e522-42b4-b5ef-84e225be586a', 'G2-0032-2021', 2, 4, '2023', 'Laik', 'https://placehold.co/400x300?text=Senjata+32', '2026-07-30 20:35:13'),
('d1138381-11cb-47d1-8621-010f20f1daa2', 'G2-0030-2024', 2, 17, '2024', 'Laik', 'https://placehold.co/400x300?text=Senjata+30', '2026-07-30 20:35:13'),
('dc0e1ba2-aff5-43e9-bc1c-2134f9f399b1', 'G2-0031-2023', 2, 32, '2022', 'Laik', 'https://placehold.co/400x300?text=Senjata+31', '2026-07-30 20:35:13'),
('ee0a72ad-6f15-4441-84cb-3ef9347dfa4d', 'G2-0021-2022', 2, 12, '2023', 'Laik', 'https://placehold.co/400x300?text=Senjata+21', '2026-07-30 20:35:13'),
('f069f365-9d90-465f-b1cc-6898e78a68c6', 'HNZ-0006-2026', 1, 15, '2024', 'Laik', 'https://placehold.co/400x300?text=Senjata+6', '2026-07-30 20:35:13');

-- --------------------------------------------------------

--
-- Table structure for table `tbl_sitkamtibmas`
--

CREATE TABLE `tbl_sitkamtibmas` (
  `sitkamtibmas_id` varchar(36) NOT NULL,
  `polda_id` int(11) DEFAULT NULL,
  `deskripsi_kejadian` text DEFAULT NULL,
  `level_kritis` enum('Aman','Waspada','Darurat') DEFAULT NULL,
  `foto_tkp_url` varchar(500) DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `tbl_sitkamtibmas`
--

INSERT INTO `tbl_sitkamtibmas` (`sitkamtibmas_id`, `polda_id`, `deskripsi_kejadian`, `level_kritis`, `foto_tkp_url`, `created_at`) VALUES
('03a15980-0f5a-4af3-8ac5-c1edca0e561a', 21, 'Ledakan bahan peledak di area pemukiman warga.', 'Darurat', 'https://placehold.co/400x300?text=Darurat', '2026-07-30 20:35:13'),
('104fa056-a438-4fac-8a7b-454a865db8f5', 18, 'Penambahan personil di lokasi rawan tawuran.', 'Waspada', 'https://placehold.co/400x300?text=Waspada', '2026-07-30 20:35:13'),
('1362afb4-7e60-4ab0-8efa-65d7f7095d31', 26, 'Terdeteksi kerumunan massa di pusat kota, patroli ditingkatkan.', 'Waspada', 'https://placehold.co/400x300?text=Waspada', '2026-07-30 20:35:13'),
('15f2b298-9676-4abb-9658-b1e6992d9930', 21, 'Tidak ditemukan aktivitas mencurigakan di wilayah hukum.', 'Aman', 'https://placehold.co/400x300?text=Aman', '2026-07-30 20:35:13'),
('25d4dafe-2ceb-41b1-9fc3-78f31c48590f', 32, 'Bentrokan antar kelompok di wilayah perbatasan, backup diperlukan.', 'Darurat', 'https://placehold.co/400x300?text=Darurat', '2026-07-30 20:35:13'),
('26db3e96-3ebc-456a-8ee0-8b97105b5e55', 1, 'Situasi kondusif, patroli rutin berjalan normal.', 'Aman', 'https://placehold.co/400x300?text=Aman', '2026-07-30 20:35:13'),
('2bcdd45f-78ed-46da-926b-a4dd5c8d01b0', 28, 'Objek vital negara dalam pengamanan maksimal.', 'Aman', 'https://placehold.co/400x300?text=Aman', '2026-07-30 20:35:13'),
('3019dea5-1c79-4f69-b88b-04ac96212677', 31, 'Kerusuhan massa meluas, situasi genting memerlukan bantuan.', 'Darurat', 'https://placehold.co/400x300?text=Darurat', '2026-07-30 20:35:13'),
('416b0217-63eb-48e1-9a9e-f8db926f22e3', 5, 'Wilayah perbatasan dalam keadaan aman terkendali.', 'Aman', 'https://placehold.co/400x300?text=Aman', '2026-07-30 20:35:13'),
('4631f656-05e6-4882-b368-4b5b54cca621', 6, 'Koordinator keamanan lingkungan aktif melapor.', 'Aman', 'https://placehold.co/400x300?text=Aman', '2026-07-30 20:35:13'),
('5b4065bd-f1bb-4dbf-8245-dd2b43cb52f2', 36, 'Jalur wisata dalam pengamanan optimal.', 'Aman', 'https://placehold.co/400x300?text=Aman', '2026-07-30 20:35:13'),
('6534bf6d-d8d9-4bbc-a4c7-9a7d3411c723', 32, 'Situasi arus mudik lancar terkendali.', 'Aman', 'https://placehold.co/400x300?text=Aman', '2026-07-30 20:35:13'),
('6655a9b0-c58d-4fa5-8269-ad3dabd01069', 29, 'Kegiatan masyarakat berjalan aman dan tertib.', 'Aman', 'https://placehold.co/400x300?text=Aman', '2026-07-30 20:35:13'),
('671bf10b-2320-4ddf-a441-de36622a6002', 3, 'Potensi gesekan antar kelompok warga dilaporkan.', 'Waspada', 'https://placehold.co/400x300?text=Waspada', '2026-07-30 20:35:13'),
('7317fb00-428c-45e9-ae1c-77beab920f09', 8, 'Lonjakan arus kendaraan di titik rawan macet.', 'Waspada', 'https://placehold.co/400x300?text=Waspada', '2026-07-30 20:35:13'),
('7782d359-4ca6-4898-9376-0ff847952b97', 6, 'Patroli dialogis bersama warga berjalan lancar.', 'Aman', 'https://placehold.co/400x300?text=Aman', '2026-07-30 20:35:13'),
('799fb84a-36ca-489b-b39c-cc5a0f70eb95', 12, 'Kegiatan ibadah berlangsung aman dan tertib.', 'Aman', 'https://placehold.co/400x300?text=Aman', '2026-07-30 20:35:13'),
('8681afe6-720a-46a3-8904-2e1ca8de3556', 8, 'Aksi premanisme terpantau di terminal bus.', 'Waspada', 'https://placehold.co/400x300?text=Waspada', '2026-07-30 20:35:13'),
('8a910b63-3255-49a3-9fc9-a58f9c9e22ef', 15, 'Konflik bersenjata melibatkan kelompok bersenjata.', 'Darurat', 'https://placehold.co/400x300?text=Darurat', '2026-07-30 20:35:13'),
('90bd37ca-c922-444f-947f-6445c9154c5b', 25, 'Pos pengamanan berfungsi normal, situasi terkendali.', 'Aman', 'https://placehold.co/400x300?text=Aman', '2026-07-30 20:35:13'),
('98095dc6-27f7-4b8c-878d-44a54adad843', 1, 'Cuaca ekstrem berpotensi longsor di jalur utama.', 'Waspada', 'https://placehold.co/400x300?text=Waspada', '2026-07-30 20:35:13'),
('9b0759f7-be88-4c01-bad3-d9fd1b979593', 17, 'Laporan peredaran narkoba di lingkungan sekolah.', 'Waspada', 'https://placehold.co/400x300?text=Waspada', '2026-07-30 20:35:13'),
('a3f64d31-0976-408a-9795-3e158b31849d', 34, 'Kegiatan pasar tradisional berlangsung aman.', 'Aman', 'https://placehold.co/400x300?text=Aman', '2026-07-30 20:35:13'),
('af8d0fd5-c136-47fd-99dd-c09290a542b9', 8, 'Tidak ada laporan gangguan kamtibmas.', 'Aman', 'https://placehold.co/400x300?text=Aman', '2026-07-30 20:35:13'),
('b7cff3e7-ca60-4491-b18f-1c64332fcebb', 21, 'Peningkatan aktivitas ormas di wilayah hukum.', 'Waspada', 'https://placehold.co/400x300?text=Waspada', '2026-07-30 20:35:13'),
('d171bc8d-b9c1-49df-a501-e8660bc1f57c', 3, 'Lalu lintas lancar, tidak ada gangguan keamanan.', 'Aman', 'https://placehold.co/400x300?text=Aman', '2026-07-30 20:35:13'),
('db8690ca-aaba-4ca0-bc49-15d90bfb1b79', 34, 'Bencana alam mengakibatkan korban jiwa dan kerusakan luas.', 'Darurat', 'https://placehold.co/400x300?text=Darurat', '2026-07-30 20:35:13'),
('e49fe2b0-9ac5-4c6a-805a-bf038f197a86', 24, 'Pemantauan ketat di lokasi bekas konflik.', 'Waspada', 'https://placehold.co/400x300?text=Waspada', '2026-07-30 20:35:13'),
('ea174521-7e5f-4148-b174-c0739505953e', 23, 'Situasi perkantoran dan perbankan aman.', 'Aman', 'https://placehold.co/400x300?text=Aman', '2026-07-30 20:35:13'),
('f257d546-5d97-43ef-840c-a5dc84c5b006', 31, 'Evakuasi korban bencana alam masih berlangsung.', 'Waspada', 'https://placehold.co/400x300?text=Waspada', '2026-07-30 20:35:13');

-- --------------------------------------------------------

--
-- Table structure for table `tbl_users`
--

CREATE TABLE `tbl_users` (
  `id` int(11) NOT NULL,
  `username` varchar(255) DEFAULT NULL,
  `password` varchar(255) DEFAULT NULL,
  `roles_id` int(11) DEFAULT NULL,
  `polda_id` int(11) DEFAULT NULL,
  `uuid` varchar(100) DEFAULT NULL,
  `token` varchar(100) DEFAULT NULL,
  `expired` varchar(50) DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `tbl_users`
--

INSERT INTO `tbl_users` (`id`, `username`, `password`, `roles_id`, `polda_id`, `uuid`, `token`, `expired`, `created_at`) VALUES
(4, 'admin', '$2y$10$IDgbgGycDFkbdsJ/SZYLge.jo/0lWOHR0RINxo5.tptPAKzRuAWwW', 1, NULL, '7997324a-bce7-48b1-bfad-3008068d7ebe', '3b9ecb26465fada071efba2eab80da00', '30', '2026-07-11 16:07:10'),
(12, 'operator_test', '$2y$10$Z/0yPPYhOLTCuP691LoUj.Aj6Wq9d5apL56axRJoa1ekT4gvqwtjC', 2, 12, 'f3327d78-8381-11f1-a8a0-60f81db0df76', 'testtoken', '30', '2026-07-19 21:55:56');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `tbl_amunisi_batch`
--
ALTER TABLE `tbl_amunisi_batch`
  ADD PRIMARY KEY (`batch_id`);

--
-- Indexes for table `tbl_dms_surat`
--
ALTER TABLE `tbl_dms_surat`
  ADD PRIMARY KEY (`surat_id`);

--
-- Indexes for table `tbl_dokumen_hukum`
--
ALTER TABLE `tbl_dokumen_hukum`
  ADD PRIMARY KEY (`dokumen_id`);

--
-- Indexes for table `tbl_hub_pengaduan`
--
ALTER TABLE `tbl_hub_pengaduan`
  ADD PRIMARY KEY (`pengaduan_id`),
  ADD KEY `idx_polda_id` (`polda_id`);

--
-- Indexes for table `tbl_jabatan`
--
ALTER TABLE `tbl_jabatan`
  ADD PRIMARY KEY (`jabatan_id`);

--
-- Indexes for table `tbl_kategori_senjata`
--
ALTER TABLE `tbl_kategori_senjata`
  ADD PRIMARY KEY (`kategori_id`);

--
-- Indexes for table `tbl_pangkat`
--
ALTER TABLE `tbl_pangkat`
  ADD PRIMARY KEY (`pangkat_id`);

--
-- Indexes for table `tbl_personil`
--
ALTER TABLE `tbl_personil`
  ADD PRIMARY KEY (`personil_id`),
  ADD KEY `fk_personil_polres` (`polres_id`);

--
-- Indexes for table `tbl_polda`
--
ALTER TABLE `tbl_polda`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `tbl_polres`
--
ALTER TABLE `tbl_polres`
  ADD PRIMARY KEY (`polres_id`),
  ADD KEY `fk_polres_polda` (`polda_id`);

--
-- Indexes for table `tbl_proses_hukum`
--
ALTER TABLE `tbl_proses_hukum`
  ADD PRIMARY KEY (`hukum_id`),
  ADD KEY `idx_personil_id` (`personil_id`);

--
-- Indexes for table `tbl_role`
--
ALTER TABLE `tbl_role`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `tbl_sarpras`
--
ALTER TABLE `tbl_sarpras`
  ADD PRIMARY KEY (`sarpras_id`),
  ADD UNIQUE KEY `uq_kode_barang` (`kode_barang`);

--
-- Indexes for table `tbl_satwa`
--
ALTER TABLE `tbl_satwa`
  ADD PRIMARY KEY (`satwa_id`),
  ADD UNIQUE KEY `uq_nomor_registrasi` (`nomor_registrasi`);

--
-- Indexes for table `tbl_senjata`
--
ALTER TABLE `tbl_senjata`
  ADD PRIMARY KEY (`senjata_id`);

--
-- Indexes for table `tbl_sitkamtibmas`
--
ALTER TABLE `tbl_sitkamtibmas`
  ADD PRIMARY KEY (`sitkamtibmas_id`);

--
-- Indexes for table `tbl_users`
--
ALTER TABLE `tbl_users`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_polda_id` (`polda_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `tbl_amunisi_batch`
--
ALTER TABLE `tbl_amunisi_batch`
  MODIFY `batch_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=32;

--
-- AUTO_INCREMENT for table `tbl_dokumen_hukum`
--
ALTER TABLE `tbl_dokumen_hukum`
  MODIFY `dokumen_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `tbl_hub_pengaduan`
--
ALTER TABLE `tbl_hub_pengaduan`
  MODIFY `pengaduan_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=26;

--
-- AUTO_INCREMENT for table `tbl_jabatan`
--
ALTER TABLE `tbl_jabatan`
  MODIFY `jabatan_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `tbl_kategori_senjata`
--
ALTER TABLE `tbl_kategori_senjata`
  MODIFY `kategori_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `tbl_pangkat`
--
ALTER TABLE `tbl_pangkat`
  MODIFY `pangkat_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=14;

--
-- AUTO_INCREMENT for table `tbl_polda`
--
ALTER TABLE `tbl_polda`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=39;

--
-- AUTO_INCREMENT for table `tbl_polres`
--
ALTER TABLE `tbl_polres`
  MODIFY `polres_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=77;

--
-- AUTO_INCREMENT for table `tbl_proses_hukum`
--
ALTER TABLE `tbl_proses_hukum`
  MODIFY `hukum_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `tbl_role`
--
ALTER TABLE `tbl_role`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `tbl_users`
--
ALTER TABLE `tbl_users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=13;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `tbl_personil`
--
ALTER TABLE `tbl_personil`
  ADD CONSTRAINT `fk_personil_polres` FOREIGN KEY (`polres_id`) REFERENCES `tbl_polres` (`polres_id`);

--
-- Constraints for table `tbl_polres`
--
ALTER TABLE `tbl_polres`
  ADD CONSTRAINT `fk_polres_polda` FOREIGN KEY (`polda_id`) REFERENCES `tbl_polda` (`id`);

--
-- Constraints for table `tbl_proses_hukum`
--
ALTER TABLE `tbl_proses_hukum`
  ADD CONSTRAINT `fk_proses_hukum_personil` FOREIGN KEY (`personil_id`) REFERENCES `tbl_personil` (`personil_id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
