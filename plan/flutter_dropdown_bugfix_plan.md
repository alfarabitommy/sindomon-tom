# Dropdown JSON Key Mapping Bugfix Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix the Polres dropdown crash caused by JSON key mismatch (`polres["id"]` → `polres["polres_id"]`), and address the disabled Pangkat/Jabatan dropdowns (missing backend endpoints).

**Architecture:** Two-phase fix — one frontend key correction in `form_input_personel.dart`, plus two new backend GET endpoints in `Master.php` and route registrations.

**Tech Stack:** Flutter 3.29.3 (Dart), CodeIgniter 3 (PHP), MySQL

---

## 1. Audit Findings

### Polres Dropdown — CONFIRMED JSON Key Bug ❌

**File:** `lib/widget/form_input_personel.dart`, line 408

```dart
value: int.tryParse(polres["id"].toString()) ?? -1,
```

The nested Polres array from `GET /api/v1/polda` returns records with key `polres_id` (the `tbl_polres` primary key), NOT `id`. Every `polres["id"]` evaluates to `null`, the `?? -1` fallback assigns `-1` to every single item, and Flutter's `DropdownButton` asserts because multiple `DropdownMenuItem`s share the same value `-1`:

> `There should be exactly one item with [DropdownButton]'s value: -1. Either zero or 2 or more [DropdownMenuItem]s were detected with the same value`

**Evidence:** The `getPolda()` method (line 55-70) extracts the nested polres from the polda API response:
```dart
daftarPolres = List<Map<String, dynamic>>.from(
    match.first["polres"] ?? [],
);
```
The `/api/v1/polda` endpoint returns polres with their native `tbl_polres` column names (`polres_id`, `nama_polres`, `polda_id`). No column alias `id` exists anywhere in the backend.

### Pangkat Dropdown — Endpoint Does Not Exist ⚠️

**File:** `lib/widget/form_input_personel.dart`, line 433

```dart
value: int.tryParse(pkt["pangkat_id"].toString()) ?? 0,
```

The Dart code already uses the correct DB key `pangkat_id`. However, the API endpoint `GET /api/v1/pangkat` **does not exist** in the backend — no route is registered and no controller method handles it. Every call to `getPangkat()` (line 86: `$apiBaseUrl/api/v1/pangkat`) 404s, leaving `daftarPangkat` eternally empty. With no items and a null value (create mode), the dropdown shows its hint "Pilih Pangkat" but has nothing to select.

**DB schema** (`tbl_pangkat`): `pangkat_id INT AUTO_INCREMENT PK`, `nama_pangkat VARCHAR(100)`

### Jabatan Dropdown — Endpoint Does Not Exist ⚠️

**File:** `lib/widget/form_input_personel.dart`, line 457

```dart
value: int.tryParse(jbt["jabatan_id"].toString()) ?? 0,
```

Same situation as Pangkat. The Dart code uses the correct key `jabatan_id`, but `GET /api/v1/jabatan` does not exist in the backend. `getJabatan()` (line 111: `$apiBaseUrl/api/v1/jabatan`) 404s, `daftarJabatan` stays empty.

**DB schema** (`tbl_jabatan`): `jabatan_id INT AUTO_INCREMENT PK`, `nama_jabatan VARCHAR(100)`, `formasi_ideal INT`, `parent_id INT`

### Polda Dropdown — Correct ✅

Line 365: `polda["id"]` — correct. `tbl_polda` PK is `id`, and the API `/api/v1/polda` returns it as `id`.

---

## 2. Fix Plan

### Task 1: Fix Polres JSON Key (Frontend)

**File:** `lib/widget/form_input_personel.dart`
**Change:** One line — line 408

**Before:**
```dart
value: int.tryParse(polres["id"].toString()) ?? -1,
```

**After:**
```dart
value: int.tryParse(polres["polres_id"].toString()) ?? -1,
```

This ensures each Polres `DropdownMenuItem` gets its actual `polres_id` value, eliminating the duplicate `-1` collision. The `-1` fallback is kept as collision prevention (a real polres_id will never be `-1`, so it remains safe).

### Task 2: Create `GET /api/v1/pangkat` Endpoint (Backend)

**File:** `/home/tommy/dev/sindomon-api-tom/application/controllers/Master.php`

**Add method:**
```php
/**
 * GET /api/v1/pangkat
 * Ambil daftar pangkat untuk dropdown
 */
public function pangkat_get()
{
    $payload = get_jwt_payload($this);
    if ($payload === null) {
        http_response_code(401);
        echo json_encode([
            'status' => 401,
            'message' => 'Token tidak ditemukan atau tidak valid.',
            'data' => (object)[]
        ]);
        return;
    }

    $this->db->select('pangkat_id, nama_pangkat');
    $this->db->from('tbl_pangkat');
    $this->db->order_by('pangkat_id', 'ASC');
    $query = $this->db->get();
    $rows = $query->result_array();

    foreach ($rows as &$row) {
        $row['pangkat_id'] = (int) $row['pangkat_id'];
    }
    unset($row);

    http_response_code(200);
    echo json_encode([
        'status' => 200,
        'message' => 'Daftar Pangkat berhasil dimuat.',
        'data' => $rows
    ]);
}
```

### Task 3: Create `GET /api/v1/jabatan` Endpoint (Backend)

**File:** `/home/tommy/dev/sindomon-api-tom/application/controllers/Master.php`

**Add method:**
```php
/**
 * GET /api/v1/jabatan
 * Ambil daftar jabatan untuk dropdown
 */
public function jabatan_get()
{
    $payload = get_jwt_payload($this);
    if ($payload === null) {
        http_response_code(401);
        echo json_encode([
            'status' => 401,
            'message' => 'Token tidak ditemukan atau tidak valid.',
            'data' => (object)[]
        ]);
        return;
    }

    $this->db->select('jabatan_id, nama_jabatan');
    $this->db->from('tbl_jabatan');
    $this->db->order_by('jabatan_id', 'ASC');
    $query = $this->db->get();
    $rows = $query->result_array();

    foreach ($rows as &$row) {
        $row['jabatan_id'] = (int) $row['jabatan_id'];
    }
    unset($row);

    http_response_code(200);
    echo json_encode([
        'status' => 200,
        'message' => 'Daftar Jabatan berhasil dimuat.',
        'data' => $rows
    ]);
}
```

### Task 4: Register Routes (Backend)

**File:** `/home/tommy/dev/sindomon-api-tom/application/config/routes.php`

**Add two routes:**
```php
$route['api/v1/pangkat']['GET'] = 'master/pangkat_get';
$route['api/v1/jabatan']['GET'] = 'master/jabatan_get';
```

The notation `'master/pangkat_get'` maps to `Master::pangkat_get()` in CodeIgniter 3.

---

## Verification Checklist

1. **Frontend:** Select a Polda with Polres data → dropdown shows polres names, no red screen crash
2. **Frontend:** `flutter analyze` — zero errors on `form_input_personel.dart`
3. **Backend:** `GET /api/v1/pangkat` returns `{"status":200, "data":[{"pangkat_id":1,"nama_pangkat":"..."},...]}`
4. **Backend:** `GET /api/v1/jabatan` returns `{"status":200, "data":[{"jabatan_id":1,"nama_jabatan":"..."},...]}`
5. **Integration:** Pangkat dropdown populates with options and is selectable
6. **Integration:** Jabatan dropdown populates with options and is selectable
