# Rencana Audit & Pelengkapan Data Master SINDOMON

> **Status: MENUNGGU PERSETUJUAN (APPROVAL REQUIRED)**
> Tidak ada eksekusi SQL atau modifikasi MCP Memory yang akan dilakukan sampai user memberikan persetujuan eksplisit.

---

## 1. DATA AUDIT REPORT

### Ringkasan Eksekutif

Database SINDOMON (`sindomondb`) memiliki **17 tabel** dengan seed data yang sudah diisi. Namun, hasil audit terhadap SQL dump (`sindomondb010826.sql`), dokumentasi ERD/PRD/API, dan source code Flutter mengungkapkan beberapa kesenjangan (gap) signifikan antara kondisi database saat ini dengan kebutuhan bisnis yang didefinisikan dalam dokumentasi resmi.

### 1.1 Tabel Master Data — Status Kelengkapan

| # | Tabel | Baris Saat Ini | Status | Masalah |
|---|-------|---------------|--------|---------|
| 1 | `tbl_polda` | 38 | ✅ LENGKAP | Mencakup seluruh 38 Polda Indonesia |
| 2 | `tbl_pangkat` | 13 | ✅ LENGKAP | Bripda s/d Irjen Pol (jenjang standar Polri) |
| 3 | `tbl_role` | 3 | ⚠️ FUNGSIONAL | Data lengkap, tapi terjadi inkonsistensi penamaan: role_id=3 bernama "Eksekutif" di DB, namun frontend Flutter (`menu_config.dart`, `app_sidebar.dart`) menyebutnya "Command Center". Form user (`form_input_user.dart`) juga menyebut "Operator Polres" yang tidak ada di DB. |
| 4 | `tbl_polres` | 76 | ❌ PLACEHOLDER | Ada 2 polres per polda, tapi nama bersifat generik/placeholder: `"Polrestabes N.1"` dan `"Polres N.2"`. ERD dan PRD mensyaratkan nama asli seperti `"Polrestabes Medan"` atau `"Polres Toba"`. |
| 5 | `tbl_jabatan` | 8 | ❌ TIDAK LENGKAP | Hanya 8 jabatan (semua dari Korps Sabhara). Tidak mencakup jabatan standar kepolisian lain seperti Kapolres, Wakapolres, Kasat Reskrim, Kasat Narkoba, Kasat Lantas, Kasat Intel, dll. ERD menyebutkan fitur "Dynamic Org-Tree" dan "Vacancy Alert" yang bergantung pada data jabatan yang komprehensif. |
| 6 | `tbl_kategori_senjata` | 2 | ❌ TIDAK LENGKAP | Hanya 2 kategori: 9mm Pendek dan 5.56mm Panjang. ERD menyebutkan contoh `"7.62mm"` sebagai kaliber yang valid. Inventaris senjata Polri mencakup lebih banyak kaliber dan tipe. |
| 7 | `tbl_satwa` | 25 | ✅ CUKUP (seed) | Data seed memadai untuk testing. Namun `kualifikasi` menggunakan VARCHAR bebas, bukan ENUM seperti yang direkomendasikan ERD (`'Narkotika', 'Handak', 'Dalmas', 'Kriminal Umum'`). |
| 8 | `tbl_senjata` | 35 | ✅ CUKUP (seed) | Data seed memadai untuk testing. |
| 9 | `tbl_sarpras` | 30 | ✅ CUKUP (seed) | Data seed memadai. ERD merekomendasikan ENUM `'Baik', 'Rusak', 'Perbaikan'` tapi DB sudah pakai `'Baik','Rusak Ringan','Rusak Berat'` (lebih granular — lebih baik). |

### 1.2 Tabel yang ADA di ERD tapi BELUM ADA di Database

| # | Tabel | Prioritas | Justifikasi |
|---|-------|-----------|-------------|
| 1 | `tbl_devices` | **HIGH** | Disebut di ERD §I.A.3, PRD AC-2.1, dan API Doc §1.1. Diperlukan untuk fitur Device Binding (Hardware Lock) yang mencegah aplikasi dibuka di perangkat tidak sah. Memiliki relasi ke `tbl_users`. |
| 2 | `tbl_gps_tracking` | **MEDIUM** | Disebut di ERD §V.A.3. Tabel temporal untuk menerima koordinat patroli setiap 10-30 detik. Disebutkan perlunya auto-pruning data >30 hari. |
| 3 | `tbl_altmatsus` | **LOW** | Disebut di ERD §IV.A.4. ERD sendiri menyarankan untuk digabung dengan `tbl_sarpras` karena struktur kolom identik. Bisa ditunda. |

### 1.3 Kolom yang ADA di ERD/PRD tapi BELUM ADA di Tabel Eksisting

| Tabel | Kolom yang Hilang | Sumber | Dampak |
|-------|-------------------|--------|--------|
| `tbl_users` | `is_2fa_enabled` (BOOLEAN) | ERD §I.A.2 | Fitur Two-Factor Authentication (PRD US-2.8, AC-2.1) |
| `tbl_users` | `two_factor_secret` (VARCHAR) | ERD §I.A.2 | Penyimpanan TOTP secret key |
| `tbl_users` | `is_active` (BOOLEAN) | ERD §I.A.2 | Soft-disable akun tanpa hapus riwayat |
| `tbl_users` | `password_hash` — DB sudah pakai `password` (VARCHAR) | ERD §I.A.2 | Naming convention: ERD menyebut `password_hash` |
| `tbl_personil` | `status_aktif` sebagai ENUM('Aktif','Mutasi','Pensiun') | ERD §III.A.1 | DB saat ini pakai VARCHAR(50), bukan ENUM |
| `tbl_satwa` | `kualifikasi` sebagai ENUM | ERD §IV.A.5 | DB saat ini pakai VARCHAR(50) |
| `tbl_dms_surat` | Value ENUM `'Diarsipkan'` pada `status_tracking` | ERD §V.A.1 | DB hanya punya 'Terkirim','Dibaca' |

### 1.4 Inkonsistensi Penamaan Terminologi

| Konteks | DB (`tbl_role`) | Frontend Flutter | Masalah |
|---------|-----------------|------------------|---------|
| Role ID 3 | `"Eksekutif"` | `"Command Center"` (`app_sidebar.dart:205`) | Membingungkan — perlu diselaraskan |
| Role ID 4 | Tidak ada | `"Operator Polres"` (`form_input_user.dart`) | Role tidak terdefinisi di database |
| API endpoint | `/api/v1/personel` | `tbl_personil` | ejaan "personel" vs "personil" (frontend ikut API) |

---

## 2. DOCUMENT INSIGHTS

### Ringkasan Temuan dari .docs

Empat dokumen PDF dianalisis dari folder `.docs/`:

#### 2.1 ERD (`Detailed Entity Relationship Diagram v1.0.pdf` — 20 halaman)

Dokumen ini adalah cetak biru database paling komprehensif. Temuan kunci:

- **6 Modul Sistem**: (I) RBAC & Device Binding, (II) Master Data Wilayah, (III) Manajemen Personil, (IV) Logistik & Alutsista, (V) Administrasi & Kamtibmas, (VI) Knowledge Hub
- **Data Dictionary Lengkap**: Setiap tabel memiliki spesifikasi kolom, tipe data, constraint, dan aturan bisnis eksplisit
- **Relasi Crow's Foot**: Diagram Mermaid lengkap dengan kardinalitas One-to-Many di seluruh modul
- **Aturan Bisnis Kunci**:
  - `tbl_users.polda_id = NULL` → akses nasional (Mabes), jika terisi → filter yurisdiksi
  - `tbl_polres` wajib ON DELETE RESTRICT ke `tbl_polda`
  - `tbl_proses_hukum` wajib ON DELETE CASCADE ke `tbl_personil`
  - Semua Foreign Key `polda_id` di entitas logistik wajib ON UPDATE CASCADE
- **Tabel Mandatory Photo**: `tbl_senjata`, `tbl_sarpras`, `tbl_satwa` wajib memiliki `foto_url` NOT NULL

#### 2.2 PRD (`Detailed Product Requirement Document v1.0.pdf` — 26 halaman)

- **Tema Ganda UI**: Dashboard Command Center bertema Sci-Fi Dark (#0B0F19), halaman operator bertema "playful developer-tools system" (cream #eeefe9)
- **3 Role Statis**: Super Admin, Operator Polda, Eksekutif — tidak boleh ada dynamic role creation
- **Decentralized Input Engine**: Backend wajib menginjeksi `WHERE polda_id = X` otomatis berdasarkan JWT operator
- **Vacancy Alert**: Perbandingan `formasi_ideal` vs COUNT personil riil untuk deteksi jabatan kosong
- **H-90 Expiry Alert**: Notifikasi otomatis saat amunisi mendekati kedaluwarsa 90 hari
- **Device Binding**: UUID perangkat keras wajib cocok, proses unbinding harus manual via Super Admin
- **2FA (Two-Factor Authentication)**: Menggunakan TOTP authenticator app
- **Out of Scope**: Self-service password reset, dynamic role creation, LDAP/AD integration, CCTV streaming, 3D maps, data cuaca eksternal

#### 2.3 API Documentation (`Detailed API Documentation v1.0.pdf` — 53 halaman)

- **Standard JSON Envelope**: Setiap response memiliki `status`, `message`, dan `data` (data kosong wajib `{}`, bukan `[]` atau `null`)
- **Smart Token Extraction**: Backend menerima `Authorization: Bearer <token>` maupun token raw
- **12+ Endpoint Groups**: Auth (3 endpoint), Master Data (6+ endpoint), Personil, Logistik, dll
- **Endpoint yang relevan dengan master data**:
  - `GET /api/v1/master/wilayah` — mengembalikan polda dengan nested `polres_jajaran[]`
  - `POST /api/v1/master/polda` — hanya Super Admin
  - `POST /api/v1/master/polres` — hanya Super Admin
  - `POST /api/v1/master/jabatan` — hanya Super Admin, `formasi_ideal >= 1`
  - `DELETE /api/v1/master/polda/{id}` — ditolak (409) jika masih ada polres

#### 2.4 UI/UX Specification (`Detailed UI_UX Specification Document v1.0.pdf` — 91 halaman)

- **Design Token**: Font IBM Plex Sans Variable, warna olive-gray (#4d4f46), CTA yellow-orange (#f7a501), card putih dengan border olive (#bfc1b7)
- **Tablet-like Desktop Experience**: Tidak boleh ada scrollbar jadul, harus smooth scrolling
- **Mode Offline**: Badge "Mode Offline" untuk wilayah dengan koneksi tidak stabil
- **Form Validation**: Error state dengan border merah dan focus ring biru

---

## 3. MCP MEMORY INJECTION PLAN

### Tujuan

Menyimpan ringkasan arsitektur database, aturan bisnis, dan konvensi penamaan ke dalam MCP Codebase Memory agar seluruh agent AI yang bekerja di proyek ini memiliki konteks yang selaras dengan dokumentasi resmi.

### 3.1 Memory Files yang Akan Dibuat

#### Memory #1: `database-schema-core`
```yaml
---
name: database-schema-core
description: Core database schema — 17 tables with master data, RBAC, and logistics
metadata:
  type: reference
---

Database SINDOMON menggunakan MariaDB dengan 17 tabel. Tabel master: tbl_polda (38 Polda Indonesia), tbl_polres (76 baris — NAMA MASIH PLACEHOLDER), tbl_pangkat (13 jenjang), tbl_jabatan (8 jabatan — PERLU DIPERLUAS), tbl_kategori_senjata (2 kategori — PERLU DIPERLUAS), tbl_role (3 role). Tabel transaksional: tbl_personil, tbl_senjata, tbl_satwa, tbl_sarpras, tbl_amunisi_batch, tbl_dms_surat, tbl_dokumen_hukum, tbl_hub_pengaduan, tbl_sitkamtibmas, tbl_proses_hukum, tbl_users. Lihat ERD di .docs/Detailed Entity Relationship Diagram (ERD) v1.0.pdf untuk diagram relasi lengkap.
```

#### Memory #2: `rbac-and-jurisdiction-rules`
```yaml
---
name: rbac-and-jurisdiction-rules
description: Role-Based Access Control rules — 3 roles, jurisdiction-based data isolation
metadata:
  type: reference
---

Tiga role statis: 1=Super Admin (Mabes, akses global, kelola master data & device binding), 2=Operator Polda (akses terbatas ke polda_id-nya sendiri via Decentralized Input Engine), 3=Eksekutif (view-only Command Center). polda_id=NULL pada tbl_users berarti akses tingkat nasional. Backend WAJIB menginjeksi WHERE polda_id=X otomatis dari JWT untuk Operator Polda. Role 3 (Eksekutif) tidak boleh memiliki tombol CRUD — backend wajib menolak dengan 401 Unauthorized. Dynamic role creation TIDAK DIIZINKAN (out of scope per PRD §2.D.2). Frontend Flutter menyebut role 3 sebagai "Command Center" — waspadai inkonsistensi penamaan dengan DB.
```

#### Memory #3: `api-standards-and-conventions`
```yaml
---
name: api-standards-and-conventions
description: API response standards — JSON envelope, auth headers, endpoint naming
metadata:
  type: reference
---

Standard JSON Envelope: {"status": <http_code>, "message": "<deskripsi>", "data": <payload>}. Data kosong WAJIB berupa {} (object kosong), BUKAN [] atau null. Authorization header mendukung "Bearer <token>" maupun token raw. Token disimpan di SharedPreferences dengan key 'token', dikirim sebagai header 'authorization' (tanpa prefix "Bearer" di frontend Flutter saat ini — tidak sesuai API spec). Base URL: https://sindomon.cml-indonesia.com. Semua endpoint: /api/v1/<resource>. Ejaan API: "personel" (bukan "personil"). Endpoint master: GET /api/v1/master/wilayah (nested polda+polres), POST /api/v1/master/polda, POST /api/v1/master/polres, POST /api/v1/master/jabatan.
```

#### Memory #4: `device-binding-and-2fa`
```yaml
---
name: device-binding-and-2fa
description: Hardware UUID device binding and Two-Factor Authentication requirements
metadata:
  type: reference
---

Device Binding: hardware_uuid perangkat wajib terdaftar di tbl_devices (TABEL BELUM ADA) dengan status_binding=TRUE. Login dari perangkat tidak dikenal → 403 Forbidden. Unbinding hanya bisa dilakukan Super Admin. 2FA menggunakan TOTP authenticator app: two_factor_secret disimpan di tbl_users (KOLOM BELUM ADA), validasi via library TOTP PHP. Alur login 2-tahap: (1) POST /api/v1/auth/login → temp_token, (2) POST /api/v1/auth/verify-2fa → access_token JWT. Fitur self-service password reset dan self-unbinding TIDAK DIIZINKAN.
```

#### Memory #5: `master-data-gaps`
```yaml
---
name: master-data-gaps
description: Known gaps in master data — placeholder polres names, incomplete jabatan and kategori
metadata:
  type: project
---

KETIGA tabel master berikut memiliki data tidak lengkap dan perlu diisi sebelum rilis produksi:
1. tbl_polres: 76 baris ada tapi nama generik ("Polrestabes N.1"). Perlu diganti dengan nama asli seperti "Polrestabes Medan", "Polres Toba", dll.
2. tbl_jabatan: Hanya 8 jabatan (semua Sabhara). Perlu ditambah: Kapolres, Wakapolres, Kasat Reskrim, Kasat Narkoba, Kasat Lantas, Kasat Intel, Kasat Binmas, Kabag Ops, Kabag Ren, Kabag SDM, Kasubag, Kanit, dan jabatan struktural lainnya.
3. tbl_kategori_senjata: Hanya 2 kategori. Perlu ditambah: 7.62mm Panjang, .45 ACP Pendek, 12 Gauge, 5.56mm Pendek, 9mm Panjang (SMG), dll.

**Why:** Dokumentasi ERD dan PRD mensyaratkan data master yang komprehensif untuk fitur Dynamic Org-Tree, Vacancy Alert, Dropdown Form, dan Dashboard Command Center.

**How to apply:** Jalankan SQL INSERT di data_completion_plan.md §4 setelah APPROVAL.
```

### 3.2 Metode Injeksi

MCP Codebase Memory akan diinjeksi menggunakan tool `Write` untuk membuat file markdown di direktori `/home/tommy/.claude/projects/-home-tommy-dev-sindomon-tom/memory/`. Setiap file akan diregistrasi di `MEMORY.md`.

**Tidak ada tool MCP khusus** — MCP `codebase-memory-mcp` yang tersedia berfungsi untuk indexing code graph (LSP-based), bukan untuk menyimpan konteks bisnis. Konteks bisnis akan disimpan sebagai file memory markdown.

---

## 4. SQL INJECTION PLAN

### 4.1 Perbaikan Data `tbl_polres` — Nama Asli Polres per Polda

Data `tbl_polres` saat ini memiliki nama generik. Berikut adalah SQL UPDATE untuk mengganti 76 baris dengan nama polres asli Indonesia.

**Catatan Penting**: Karena kompleksitas data polres Indonesia (setiap Polda memiliki jumlah dan nama polres yang berbeda-beda), SQL di bawah ini mencakup **perkiraan 2-4 polres utama** per polda. Untuk data yang benar-benar akurat dan lengkap, diperlukan referensi resmi dari Mabes Polri. Data ini cukup untuk development dan testing.

```sql
-- ============================================================
-- PERBAIKAN NAMA POLRES (UPDATE tbl_polres)
-- Mengganti nama placeholder dengan nama asli
-- ============================================================

-- Polda Aceh (id=1)
UPDATE tbl_polres SET nama_polres = 'Polresta Banda Aceh' WHERE polres_id = 1;
UPDATE tbl_polres SET nama_polres = 'Polres Aceh Besar' WHERE polres_id = 2;

-- Polda Sumatera Utara (id=2)
UPDATE tbl_polres SET nama_polres = 'Polrestabes Medan' WHERE polres_id = 3;
UPDATE tbl_polres SET nama_polres = 'Polres Deli Serdang' WHERE polres_id = 4;

-- Polda Sumatera Barat (id=3)
UPDATE tbl_polres SET nama_polres = 'Polresta Padang' WHERE polres_id = 5;
UPDATE tbl_polres SET nama_polres = 'Polres Agam' WHERE polres_id = 6;

-- Polda Riau (id=4)
UPDATE tbl_polres SET nama_polres = 'Polresta Pekanbaru' WHERE polres_id = 7;
UPDATE tbl_polres SET nama_polres = 'Polres Kampar' WHERE polres_id = 8;

-- Polda Kepulauan Riau (id=5)
UPDATE tbl_polres SET nama_polres = 'Polresta Batam' WHERE polres_id = 9;
UPDATE tbl_polres SET nama_polres = 'Polres Tanjungpinang' WHERE polres_id = 10;

-- Polda Jambi (id=6)
UPDATE tbl_polres SET nama_polres = 'Polresta Jambi' WHERE polres_id = 11;
UPDATE tbl_polres SET nama_polres = 'Polres Batanghari' WHERE polres_id = 12;

-- Polda Sumatera Selatan (id=7)
UPDATE tbl_polres SET nama_polres = 'Polrestabes Palembang' WHERE polres_id = 13;
UPDATE tbl_polres SET nama_polres = 'Polres Banyuasin' WHERE polres_id = 14;

-- Polda Bangka Belitung (id=8)
UPDATE tbl_polres SET nama_polres = 'Polresta Pangkalpinang' WHERE polres_id = 15;
UPDATE tbl_polres SET nama_polres = 'Polres Belitung' WHERE polres_id = 16;

-- Polda Bengkulu (id=9)
UPDATE tbl_polres SET nama_polres = 'Polresta Bengkulu' WHERE polres_id = 17;
UPDATE tbl_polres SET nama_polres = 'Polres Rejang Lebong' WHERE polres_id = 18;

-- Polda Lampung (id=10)
UPDATE tbl_polres SET nama_polres = 'Polresta Bandar Lampung' WHERE polres_id = 19;
UPDATE tbl_polres SET nama_polres = 'Polres Lampung Selatan' WHERE polres_id = 20;

-- Polda Metro Jaya (id=11)
UPDATE tbl_polres SET nama_polres = 'Polrestro Jakarta Pusat' WHERE polres_id = 21;
UPDATE tbl_polres SET nama_polres = 'Polrestro Jakarta Selatan' WHERE polres_id = 22;

-- Polda Banten (id=12)
UPDATE tbl_polres SET nama_polres = 'Polresta Serang Kota' WHERE polres_id = 23;
UPDATE tbl_polres SET nama_polres = 'Polres Lebak' WHERE polres_id = 24;

-- Polda Jawa Barat (id=13)
UPDATE tbl_polres SET nama_polres = 'Polrestabes Bandung' WHERE polres_id = 25;
UPDATE tbl_polres SET nama_polres = 'Polres Bogor' WHERE polres_id = 26;

-- Polda Jawa Tengah (id=14)
UPDATE tbl_polres SET nama_polres = 'Polrestabes Semarang' WHERE polres_id = 27;
UPDATE tbl_polres SET nama_polres = 'Polres Solo' WHERE polres_id = 28;

-- Polda D.I. Yogyakarta (id=15)
UPDATE tbl_polres SET nama_polres = 'Polresta Yogyakarta' WHERE polres_id = 29;
UPDATE tbl_polres SET nama_polres = 'Polres Sleman' WHERE polres_id = 30;

-- Polda Jawa Timur (id=16)
UPDATE tbl_polres SET nama_polres = 'Polrestabes Surabaya' WHERE polres_id = 31;
UPDATE tbl_polres SET nama_polres = 'Polres Malang' WHERE polres_id = 32;

-- Polda Kalimantan Barat (id=17)
UPDATE tbl_polres SET nama_polres = 'Polresta Pontianak' WHERE polres_id = 33;
UPDATE tbl_polres SET nama_polres = 'Polres Kubu Raya' WHERE polres_id = 34;

-- Polda Kalimantan Tengah (id=18)
UPDATE tbl_polres SET nama_polres = 'Polresta Palangka Raya' WHERE polres_id = 35;
UPDATE tbl_polres SET nama_polres = 'Polres Kotawaringin Timur' WHERE polres_id = 36;

-- Polda Kalimantan Selatan (id=19)
UPDATE tbl_polres SET nama_polres = 'Polresta Banjarmasin' WHERE polres_id = 37;
UPDATE tbl_polres SET nama_polres = 'Polres Banjar' WHERE polres_id = 38;

-- Polda Kalimantan Timur (id=20)
UPDATE tbl_polres SET nama_polres = 'Polresta Samarinda' WHERE polres_id = 39;
UPDATE tbl_polres SET nama_polres = 'Polres Kutai Kartanegara' WHERE polres_id = 40;

-- Polda Kalimantan Utara (id=21)
UPDATE tbl_polres SET nama_polres = 'Polresta Tarakan' WHERE polres_id = 41;
UPDATE tbl_polres SET nama_polres = 'Polres Bulungan' WHERE polres_id = 42;

-- Polda Bali (id=22)
UPDATE tbl_polres SET nama_polres = 'Polresta Denpasar' WHERE polres_id = 43;
UPDATE tbl_polres SET nama_polres = 'Polres Badung' WHERE polres_id = 44;

-- Polda Nusa Tenggara Barat (id=23)
UPDATE tbl_polres SET nama_polres = 'Polresta Mataram' WHERE polres_id = 45;
UPDATE tbl_polres SET nama_polres = 'Polres Lombok Timur' WHERE polres_id = 46;

-- Polda Nusa Tenggara Timur (id=24)
UPDATE tbl_polres SET nama_polres = 'Polresta Kupang Kota' WHERE polres_id = 47;
UPDATE tbl_polres SET nama_polres = 'Polres Sikka' WHERE polres_id = 48;

-- Polda Sulawesi Utara (id=25)
UPDATE tbl_polres SET nama_polres = 'Polresta Manado' WHERE polres_id = 49;
UPDATE tbl_polres SET nama_polres = 'Polres Minahasa' WHERE polres_id = 50;

-- Polda Gorontalo (id=26)
UPDATE tbl_polres SET nama_polres = 'Polresta Gorontalo Kota' WHERE polres_id = 51;
UPDATE tbl_polres SET nama_polres = 'Polres Bone Bolango' WHERE polres_id = 52;

-- Polda Sulawesi Tengah (id=27)
UPDATE tbl_polres SET nama_polres = 'Polresta Palu' WHERE polres_id = 53;
UPDATE tbl_polres SET nama_polres = 'Polres Poso' WHERE polres_id = 54;

-- Polda Sulawesi Selatan (id=28)
UPDATE tbl_polres SET nama_polres = 'Polrestabes Makassar' WHERE polres_id = 55;
UPDATE tbl_polres SET nama_polres = 'Polres Gowa' WHERE polres_id = 56;

-- Polda Sulawesi Tenggara (id=29)
UPDATE tbl_polres SET nama_polres = 'Polresta Kendari' WHERE polres_id = 57;
UPDATE tbl_polres SET nama_polres = 'Polres Kolaka' WHERE polres_id = 58;

-- Polda Sulawesi Barat (id=30)
UPDATE tbl_polres SET nama_polres = 'Polresta Mamuju' WHERE polres_id = 59;
UPDATE tbl_polres SET nama_polres = 'Polres Polewali Mandar' WHERE polres_id = 60;

-- Polda Maluku (id=31)
UPDATE tbl_polres SET nama_polres = 'Polresta Ambon' WHERE polres_id = 61;
UPDATE tbl_polres SET nama_polres = 'Polres Maluku Tengah' WHERE polres_id = 62;

-- Polda Maluku Utara (id=32)
UPDATE tbl_polres SET nama_polres = 'Polresta Ternate' WHERE polres_id = 63;
UPDATE tbl_polres SET nama_polres = 'Polres Halmahera Utara' WHERE polres_id = 64;

-- Polda Papua (id=33)
UPDATE tbl_polres SET nama_polres = 'Polresta Jayapura Kota' WHERE polres_id = 65;
UPDATE tbl_polres SET nama_polres = 'Polres Jayapura' WHERE polres_id = 66;

-- Polda Papua Barat (id=34)
UPDATE tbl_polres SET nama_polres = 'Polresta Manokwari' WHERE polres_id = 67;
UPDATE tbl_polres SET nama_polres = 'Polres Fakfak' WHERE polres_id = 68;

-- Polda Papua Selatan (id=35)
UPDATE tbl_polres SET nama_polres = 'Polresta Merauke' WHERE polres_id = 69;
UPDATE tbl_polres SET nama_polres = 'Polres Boven Digoel' WHERE polres_id = 70;

-- Polda Papua Tengah (id=36)
UPDATE tbl_polres SET nama_polres = 'Polresta Timika' WHERE polres_id = 71;
UPDATE tbl_polres SET nama_polres = 'Polres Nabire' WHERE polres_id = 72;

-- Polda Papua Pegunungan (id=37)
UPDATE tbl_polres SET nama_polres = 'Polresta Wamena' WHERE polres_id = 73;
UPDATE tbl_polres SET nama_polres = 'Polres Jayawijaya' WHERE polres_id = 74;

-- Polda Papua Barat Daya (id=38)
UPDATE tbl_polres SET nama_polres = 'Polresta Sorong Kota' WHERE polres_id = 75;
UPDATE tbl_polres SET nama_polres = 'Polres Sorong Selatan' WHERE polres_id = 76;
```

### 4.2 Penambahan Data `tbl_jabatan` — Jabatan Struktural Polri

```sql
-- ============================================================
-- PENAMBAHAN JABATAN STRUKTURAL (INSERT tbl_jabatan)
-- Melengkapi dari 8 menjadi ~40+ jabatan standar kepolisian
-- ============================================================

-- Level Polda / Mabes
INSERT INTO tbl_jabatan (nama_jabatan, formasi_ideal, parent_id) VALUES
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
('Kabid Dokkes', 1, NULL);

-- Level Polres
INSERT INTO tbl_jabatan (nama_jabatan, formasi_ideal, parent_id) VALUES
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
('Kasat Sabhara', 1, NULL),
('Kasat Tahti', 1, NULL),
('Kasi Propam', 1, NULL),
('Kasi Humas', 1, NULL),
('Kasi Keu', 1, NULL),
('Kasi Hukum', 1, NULL),
('Kapolsek', 10, NULL);
```

### 4.3 Penambahan Data `tbl_kategori_senjata` — Kaliber Senjata Api

```sql
-- ============================================================
-- PENAMBAHAN KATEGORI SENJATA (INSERT tbl_kategori_senjata)
-- Melengkapi dari 2 menjadi 8+ kategori
-- ============================================================

INSERT INTO tbl_kategori_senjata (tipe_laras, kaliber) VALUES
('Panjang', '7.62mm'),
('Pendek', '.45 ACP'),
('Pendek', '.38 Special'),
('Pendek', '.357 Magnum'),
('Panjang', '12 Gauge'),
('Panjang', '.223 Remington');
```

### 4.4 Pembuatan Tabel `tbl_devices` (Device Binding)

```sql
-- ============================================================
-- TABEL BARU: tbl_devices (Device Binding Security)
-- Sesuai ERD §I.A.3 dan PRD AC-2.1
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
```

### 4.5 Penambahan Kolom pada `tbl_users` (2FA + Soft-Delete)

```sql
-- ============================================================
-- ALTER TABLE: tbl_users — menambah kolom 2FA dan soft-delete
-- Sesuai ERD §I.A.2
-- ============================================================

ALTER TABLE tbl_users
  ADD COLUMN is_2fa_enabled TINYINT(1) NOT NULL DEFAULT 0 AFTER polda_id,
  ADD COLUMN two_factor_secret VARCHAR(255) DEFAULT NULL AFTER is_2fa_enabled,
  ADD COLUMN is_active TINYINT(1) NOT NULL DEFAULT 1 AFTER two_factor_secret;
```

### 4.6 Perbaikan Kolom ENUM pada Tabel Eksisting

```sql
-- ============================================================
-- ALTER TABLE: Standarisasi ENUM sesuai ERD
-- ============================================================

-- tbl_personil: ubah status_aktif dari VARCHAR ke ENUM
ALTER TABLE tbl_personil
  MODIFY COLUMN status_aktif ENUM('Aktif','Mutasi','Pensiun') DEFAULT 'Aktif';

-- tbl_satwa: ubah kualifikasi dari VARCHAR ke ENUM
ALTER TABLE tbl_satwa
  MODIFY COLUMN kualifikasi ENUM('Narkotika','Handak','Dalmas','Kriminal Umum','Patroli','Pelacak') DEFAULT NULL;

-- tbl_dms_surat: tambah nilai ENUM 'Diarsipkan'
ALTER TABLE tbl_dms_surat
  MODIFY COLUMN status_tracking ENUM('Terkirim','Dibaca','Diarsipkan') DEFAULT 'Terkirim';
```

### 4.7 Sinkronisasi Role Naming — OPSI A DIPILIH ✅

**Keputusan user (APPROVE):** DB mengikuti frontend — role 3 di database diubah menjadi "Command Center".

```sql
-- ============================================================
-- UPDATE: Selaraskan nama role di DB dengan frontend
-- Keputusan: Opsi A — DB mengikuti frontend (APPROVED)
-- ============================================================

UPDATE tbl_role SET roles = 'Command Center' WHERE id = 3;
```

### 4.8 Koordinat Spasial Map Command Center (tbl_polda) — TAMBAHAN DARI ARCHITECT REVIEW ✅

**Konteks:** Dashboard Command Center (Role 3) merender 38 titik Polda pada peta interaktif. Kolom `latitude` dan `longitude` sudah ADA di `tbl_polda` (SQL dump `sindomondb010826.sql`), namun bertipe `VARCHAR(100)` — bukan `DECIMAL` seperti yang disyaratkan ERD §II.A.1. Oleh karena itu langkahnya adalah **MODIFY** (konversi tipe), bukan ADD. Nilai koordinat di-refine ke presisi titik pusat kota markas masing-masing Polda.

```sql
-- ============================================================
-- A) KONVERSI TIPE KOLOM: VARCHAR(100) -> DECIMAL sesuai ERD §II.A.1
-- ============================================================
-- Catatan: Kolom sudah ada sebagai VARCHAR(100) di dump saat ini,
-- jadi gunakan MODIFY (bukan ADD). Data existing ('5.550000') akan
-- dikonversi otomatis tanpa kehilangan nilai.

ALTER TABLE `tbl_polda`
  MODIFY COLUMN `latitude` DECIMAL(10,8) NOT NULL DEFAULT 0,
  MODIFY COLUMN `longitude` DECIMAL(11,8) NOT NULL DEFAULT 0;

-- (Fallback jika di DB lain kolom belum ada sama sekali — jalankan
--  hanya jika ALTER di atas error "Unknown column"):
-- ALTER TABLE `tbl_polda`
--   ADD COLUMN `latitude` DECIMAL(10,8) NOT NULL DEFAULT 0 AFTER `nama_polda`,
--   ADD COLUMN `longitude` DECIMAL(11,8) NOT NULL DEFAULT 0 AFTER `latitude`;

-- ============================================================
-- B) UPDATE KOORDINAT AKURAT — 38 Polda Indonesia
-- Titik pusat kota markas Polda (presisi 6-8 desimal)
-- ============================================================

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
```

> **Verifikasi setelah eksekusi:** `SELECT id, nama_polda, latitude, longitude FROM tbl_polda ORDER BY id;` — pastikan 38 baris dengan nilai DECIMAL, tidak ada yang 0.00000000. Dashboard Command Center (FlutterMap di `lib/pages/dashboard.dart`) membaca `nama_polda`, `latitude`, `longitude` dari `GET /api/v1/polda` untuk merender marker — nilai ini sekarang siap render.

---

## 5. RINGKASAN EKSEKUSI

### Urutan Eksekusi yang Direkomendasikan

| Langkah | Aksi | Dampak | Risiko |
|---------|------|--------|--------|
| 1 | Jalankan **SQL §4.1** — UPDATE nama polres | UI menampilkan nama polres asli | LOW — hanya UPDATE data |
| 2 | Jalankan **SQL §4.2** — INSERT jabatan | Dropdown form dan Org-Tree lengkap | LOW — hanya INSERT |
| 3 | Jalankan **SQL §4.3** — INSERT kategori senjata | Dropdown form senjata komprehensif | LOW — hanya INSERT |
| 4 | Jalankan **SQL §4.6** — ALTER TABLE ENUM | Standarisasi constraint database | MEDIUM — pastikan data existing kompatibel dengan ENUM baru |
| 5 | Jalankan **SQL §4.4** — CREATE TABLE devices | Dukungan Device Binding | LOW — tabel baru |
| 6 | Jalankan **SQL §4.5** — ALTER TABLE users | Dukungan 2FA dan soft-delete | MEDIUM — kolom baru, aplikasi belum support |
| 7 | Jalankan **SQL §4.7** — UPDATE role name (Opsi A: "Command Center") | Konsistensi penamaan role DB ↔ frontend | LOW — hanya UPDATE 1 baris |
| 8 | Jalankan **SQL §4.8** — konversi DECIMAL + UPDATE koordinat 38 Polda | Marker peta Command Center akurat (DECIMAL sesuai ERD) | MEDIUM — pastikan `created_at` tidak ikut terubah; backup dulu |
| 9 | Injeksi **MCP Memory §3** | Konteks AI selaras dengan dokumen | NONE — readonly (✅ SELESAI) |

### Rekomendasi Tambahan (Non-SQL)

1. **tbl_gps_tracking**: Buat setelah modul GPS siap dikembangkan. Perlu event scheduler MariaDB untuk auto-pruning data >30 hari.
2. **tbl_altmatsus**: Gabungkan dengan `tbl_sarpras` seperti yang direkomendasikan ERD — tambahkan kolom `jenis_aset` ENUM('Sarpras','Altmatsus') jika diperlukan.
3. **Foreign Key Constraints**: Tambahkan FK constraint untuk `polda_id` di seluruh tabel logistik dengan ON UPDATE CASCADE sesuai rekomendasi ERD §IV.B.2.
4. **Backend API**: Update endpoint `/api/v1/master/wilayah` untuk mengembalikan nested `polres_jajaran[]` sesuai API Doc §2.1.

---

**⚠️ PERHATIAN: Jangan jalankan SQL apapun atau modifikasi MCP Memory sebelum user memberikan persetujuan "APPROVE".**
