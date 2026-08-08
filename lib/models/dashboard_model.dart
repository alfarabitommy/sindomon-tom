import 'package:latlong2/latlong.dart';

/// Dashboard data models for the Executive Command Center.
///
/// Parses the nested payloads produced by `Dashboard.php`:
///   - `GET /api/v1/dashboard/nasional`             → [DashboardNasional]
///   - `GET /api/v1/dashboard/drilldown?polda_id=`  → [DashboardDrilldown]
///
/// Defensive parsing contract (applies to every `fromJson` below):
///   - Integers: `_toInt(...)` — `(value as num?)?.toInt()` with String fallback
///   - Strings : `_toStr(...)` — `value?.toString() ?? ''`
///   - Booleans: `_toBool(...)` — `value as bool? ?? false` with 0/1/"true" fallback
///   - Lists   : `_mapList(...)` — null/non-map elements are skipped, never throws
///   - The `!` force-unwrap operator is NEVER used in this file.
///
/// Every factory is TOTAL: given any input (null, wrong type, missing keys) it
/// returns a fully-constructed instance with safe defaults (0 / '' / false /
/// empty list). A malformed payload can never crash the widget tree.
class DashboardNasional {
  final Ringkasan ringkasan;
  final List<PetaNode> peta;
  final List<SitkamtibmasTerkini> sitkamtibmasTerkini;

  const DashboardNasional({
    this.ringkasan = const Ringkasan(),
    this.peta = const [],
    this.sitkamtibmasTerkini = const [],
  });

  /// Parses the `data` object of the `/nasional` response envelope.
  factory DashboardNasional.fromJson(dynamic json) {
    final j = _asMap(json);
    if (j == null) return const DashboardNasional();
    return DashboardNasional(
      ringkasan: Ringkasan.fromJson(j['ringkasan']),
      peta: _mapList(j['peta'], PetaNode.fromJson),
      sitkamtibmasTerkini: _mapList(
        j['sitkamtibmas_terkini'],
        SitkamtibmasTerkini.fromJson,
      ),
    );
  }
}

/// National (or polda-scoped) summary card aggregates.
///
/// JSON keys (strict match with `Dashboard.php::_get_ringkasan()`):
/// `total_personil_aktif`, `total_formasi_ideal`, `total_jumlah_riil`,
/// `selisih_kekurangan`, `total_senjata`, `total_senjata_layak`,
/// `total_sarpras`, `total_sarpras_baik`, `total_satwa_k9`,
/// `total_amunisi_butir`, `amunisi_h90_alert`.
class Ringkasan {
  final int totalPersonilAktif;
  final int totalFormasiIdeal;
  final int totalJumlahRiil;
  final int selisihKekurangan;
  final int totalSenjata;
  final int totalSenjataLayak;
  final int totalSarpras;
  final int totalSarprasBaik;
  final int totalSatwaK9;
  final int totalAmunisiButir;
  final int amunisiH90Alert;

  const Ringkasan({
    this.totalPersonilAktif = 0,
    this.totalFormasiIdeal = 0,
    this.totalJumlahRiil = 0,
    this.selisihKekurangan = 0,
    this.totalSenjata = 0,
    this.totalSenjataLayak = 0,
    this.totalSarpras = 0,
    this.totalSarprasBaik = 0,
    this.totalSatwaK9 = 0,
    this.totalAmunisiButir = 0,
    this.amunisiH90Alert = 0,
  });

  factory Ringkasan.fromJson(dynamic json) {
    final j = _asMap(json);
    if (j == null) return const Ringkasan();
    return Ringkasan(
      totalPersonilAktif: _toInt(j['total_personil_aktif']),
      totalFormasiIdeal: _toInt(j['total_formasi_ideal']),
      totalJumlahRiil: _toInt(j['total_jumlah_riil']),
      selisihKekurangan: _toInt(j['selisih_kekurangan']),
      totalSenjata: _toInt(j['total_senjata']),
      totalSenjataLayak: _toInt(j['total_senjata_layak']),
      totalSarpras: _toInt(j['total_sarpras']),
      totalSarprasBaik: _toInt(j['total_sarpras_baik']),
      totalSatwaK9: _toInt(j['total_satwa_k9']),
      totalAmunisiButir: _toInt(j['total_amunisi_butir']),
      amunisiH90Alert: _toInt(j['amunisi_h90_alert']),
    );
  }
}

/// One map node (Polda) with its per-polda counts.
///
/// JSON keys (strict match with `Dashboard.php::_get_peta_nodes()`):
/// `polda_id`, `nama_polda`, `latitude`, `longitude`, `total_personil`,
/// `total_senjata`, `total_sarpras`, `total_k9`.
class PetaNode {
  final int poldaId;
  final String namaPolda;
  final String latitude; // raw value from API — preserves exact precision
  final String longitude; // raw value from API — preserves exact precision
  final int totalPersonil;
  final int totalSenjata;
  final int totalSarpras;
  final int totalK9;

  const PetaNode({
    this.poldaId = 0,
    this.namaPolda = '',
    this.latitude = '',
    this.longitude = '',
    this.totalPersonil = 0,
    this.totalSenjata = 0,
    this.totalSarpras = 0,
    this.totalK9 = 0,
  });

  factory PetaNode.fromJson(dynamic json) {
    final j = _asMap(json);
    if (j == null) return const PetaNode();
    return PetaNode(
      poldaId: _toInt(j['polda_id']),
      namaPolda: _toStr(j['nama_polda']),
      latitude: _toStr(j['latitude']),
      longitude: _toStr(j['longitude']),
      totalPersonil: _toInt(j['total_personil']),
      totalSenjata: _toInt(j['total_senjata']),
      totalSarpras: _toInt(j['total_sarpras']),
      totalK9: _toInt(j['total_k9']),
    );
  }

  /// `true` when both coordinates parse to non-zero doubles (skips Null Island).
  bool get hasValidCoordinates {
    final lat = double.tryParse(latitude);
    final lng = double.tryParse(longitude);
    return lat != null && lng != null && lat != 0.0 && lng != 0.0;
  }

  /// `LatLng` ready for `flutter_map` `MarkerLayer` (mirrors `Polda.latLng`).
  LatLng get latLng => LatLng(_toDouble(latitude), _toDouble(longitude));
}

/// One SITKAMTIBMAS report (latest first).
///
/// JSON keys (strict match with `Dashboard.php::_get_sitkamtibmas_terkini()`):
/// `sitkamtibmas_id`, `polda_id`, `nama_polda` (nullable — LEFT JOIN),
/// `deskripsi_kejadian`, `level_kritis`, `foto_tkp_url` (nullable),
/// `created_at`.
class SitkamtibmasTerkini {
  final String sitkamtibmasId;
  final int poldaId;
  final String? namaPolda; // nullable: LEFT JOIN may yield no Polda row
  final String deskripsiKejadian;
  final String levelKritis; // enum: 'Aman' | 'Waspada' | 'Darurat'
  final String? fotoTkpUrl; // nullable: report may have no photo
  final String createdAt;

  const SitkamtibmasTerkini({
    this.sitkamtibmasId = '',
    this.poldaId = 0,
    this.namaPolda,
    this.deskripsiKejadian = '',
    this.levelKritis = '',
    this.fotoTkpUrl,
    this.createdAt = '',
  });

  factory SitkamtibmasTerkini.fromJson(dynamic json) {
    final j = _asMap(json);
    if (j == null) return const SitkamtibmasTerkini();
    return SitkamtibmasTerkini(
      sitkamtibmasId: _toStr(j['sitkamtibmas_id']),
      poldaId: _toInt(j['polda_id']),
      namaPolda: j['nama_polda']?.toString(),
      deskripsiKejadian: _toStr(j['deskripsi_kejadian']),
      levelKritis: _toStr(j['level_kritis']),
      fotoTkpUrl: j['foto_tkp_url']?.toString(),
      createdAt: _toStr(j['created_at']),
    );
  }
}

/// Per-polda detail payload for the drill-down popup.
///
/// Parses the `data` object of the `/drilldown?polda_id=X` response envelope.
/// JSON keys (strict match with `Dashboard.php::drilldown_get()`):
/// `polda`, `personil`, `vakansi`, `logistik`, `sitkamtibmas_terkini`.
class DashboardDrilldown {
  final PoldaInfo polda;
  final PersonilStats personil;
  final VakansiStats vakansi;
  final LogistikStats logistik;
  final List<SitkamtibmasTerkini> sitkamtibmasTerkini;

  const DashboardDrilldown({
    this.polda = const PoldaInfo(),
    this.personil = const PersonilStats(),
    this.vakansi = const VakansiStats(),
    this.logistik = const LogistikStats(),
    this.sitkamtibmasTerkini = const [],
  });

  factory DashboardDrilldown.fromJson(dynamic json) {
    final j = _asMap(json);
    if (j == null) return const DashboardDrilldown();
    return DashboardDrilldown(
      polda: PoldaInfo.fromJson(j['polda']),
      personil: PersonilStats.fromJson(j['personil']),
      vakansi: VakansiStats.fromJson(j['vakansi']),
      logistik: LogistikStats.fromJson(j['logistik']),
      sitkamtibmasTerkini: _mapList(
        j['sitkamtibmas_terkini'],
        SitkamtibmasTerkini.fromJson,
      ),
    );
  }
}

/// Polda master row for the drill-down header.
///
/// JSON keys: `id`, `nama_polda`, `latitude`, `longitude`.
class PoldaInfo {
  final int id;
  final String namaPolda;
  final String latitude; // raw value from API — preserves exact precision
  final String longitude; // raw value from API — preserves exact precision

  const PoldaInfo({
    this.id = 0,
    this.namaPolda = '',
    this.latitude = '',
    this.longitude = '',
  });

  factory PoldaInfo.fromJson(dynamic json) {
    final j = _asMap(json);
    if (j == null) return const PoldaInfo();
    return PoldaInfo(
      id: _toInt(j['id']),
      namaPolda: _toStr(j['nama_polda']),
      latitude: _toStr(j['latitude']),
      longitude: _toStr(j['longitude']),
    );
  }
}

/// Personil aggregate for one Polda (drill-down).
///
/// JSON keys: `total_aktif`, `total_mutasi`, `total_pensiun`.
class PersonilStats {
  final int totalAktif;
  final int totalMutasi;
  final int totalPensiun;

  const PersonilStats({
    this.totalAktif = 0,
    this.totalMutasi = 0,
    this.totalPensiun = 0,
  });

  factory PersonilStats.fromJson(dynamic json) {
    final j = _asMap(json);
    if (j == null) return const PersonilStats();
    return PersonilStats(
      totalAktif: _toInt(j['total_aktif']),
      totalMutasi: _toInt(j['total_mutasi']),
      totalPensiun: _toInt(j['total_pensiun']),
    );
  }
}

/// Vacancy (jabatan) aggregate for one Polda (drill-down).
///
/// JSON keys (strict match with `Dashboard.php::_get_vakansi()`):
/// `total_formasi_ideal`, `total_jumlah_riil`, `selisih`,
/// `detail_per_jabatan`.
class VakansiStats {
  final int totalFormasiIdeal;
  final int totalJumlahRiil;
  final int selisih;
  final List<DetailJabatan> detailPerJabatan;

  const VakansiStats({
    this.totalFormasiIdeal = 0,
    this.totalJumlahRiil = 0,
    this.selisih = 0,
    this.detailPerJabatan = const [],
  });

  factory VakansiStats.fromJson(dynamic json) {
    final j = _asMap(json);
    if (j == null) return const VakansiStats();
    return VakansiStats(
      totalFormasiIdeal: _toInt(j['total_formasi_ideal']),
      totalJumlahRiil: _toInt(j['total_jumlah_riil']),
      selisih: _toInt(j['selisih']),
      detailPerJabatan: _mapList(j['detail_per_jabatan'], DetailJabatan.fromJson),
    );
  }
}

/// One jabatan row of the vacancy detail (drill-down).
///
/// JSON keys: `jabatan_id`, `nama_jabatan`, `formasi_ideal`, `jumlah_riil`,
/// `is_alert`.
class DetailJabatan {
  final int jabatanId;
  final String namaJabatan;
  final int formasiIdeal;
  final int jumlahRiil;
  final bool isAlert;

  const DetailJabatan({
    this.jabatanId = 0,
    this.namaJabatan = '',
    this.formasiIdeal = 0,
    this.jumlahRiil = 0,
    this.isAlert = false,
  });

  factory DetailJabatan.fromJson(dynamic json) {
    final j = _asMap(json);
    if (j == null) return const DetailJabatan();
    return DetailJabatan(
      jabatanId: _toInt(j['jabatan_id']),
      namaJabatan: _toStr(j['nama_jabatan']),
      formasiIdeal: _toInt(j['formasi_ideal']),
      jumlahRiil: _toInt(j['jumlah_riil']),
      isAlert: _toBool(j['is_alert']),
    );
  }
}

/// Logistik aggregate group for one Polda (drill-down).
///
/// JSON keys: `senjata`, `sarpras`, `satwa_k9`, `amunisi`.
class LogistikStats {
  final SenjataStats senjata;
  final SarprasStats sarpras;
  final SatwaStats satwaK9;
  final AmunisiStats amunisi;

  const LogistikStats({
    this.senjata = const SenjataStats(),
    this.sarpras = const SarprasStats(),
    this.satwaK9 = const SatwaStats(),
    this.amunisi = const AmunisiStats(),
  });

  factory LogistikStats.fromJson(dynamic json) {
    final j = _asMap(json);
    if (j == null) return const LogistikStats();
    return LogistikStats(
      senjata: SenjataStats.fromJson(j['senjata']),
      sarpras: SarprasStats.fromJson(j['sarpras']),
      satwaK9: SatwaStats.fromJson(j['satwa_k9']),
      amunisi: AmunisiStats.fromJson(j['amunisi']),
    );
  }
}

/// Senjata aggregate (drill-down).
///
/// JSON keys: `total`, `layak`, `tidak_layak`.
class SenjataStats {
  final int total;
  final int layak;
  final int tidakLayak;

  const SenjataStats({this.total = 0, this.layak = 0, this.tidakLayak = 0});

  factory SenjataStats.fromJson(dynamic json) {
    final j = _asMap(json);
    if (j == null) return const SenjataStats();
    return SenjataStats(
      total: _toInt(j['total']),
      layak: _toInt(j['layak']),
      tidakLayak: _toInt(j['tidak_layak']),
    );
  }
}

/// Sarpras aggregate (drill-down).
///
/// JSON keys: `total`, `baik`, `rusak_ringan`, `rusak_berat`.
class SarprasStats {
  final int total;
  final int baik;
  final int rusakRingan;
  final int rusakBerat;

  const SarprasStats({
    this.total = 0,
    this.baik = 0,
    this.rusakRingan = 0,
    this.rusakBerat = 0,
  });

  factory SarprasStats.fromJson(dynamic json) {
    final j = _asMap(json);
    if (j == null) return const SarprasStats();
    return SarprasStats(
      total: _toInt(j['total']),
      baik: _toInt(j['baik']),
      rusakRingan: _toInt(j['rusak_ringan']),
      rusakBerat: _toInt(j['rusak_berat']),
    );
  }
}

/// Satwa K9 aggregate (drill-down).
///
/// JSON keys: `total`.
class SatwaStats {
  final int total;

  const SatwaStats({this.total = 0});

  factory SatwaStats.fromJson(dynamic json) {
    final j = _asMap(json);
    if (j == null) return const SatwaStats();
    return SatwaStats(total: _toInt(j['total']));
  }
}

/// Amunisi aggregate (drill-down).
///
/// JSON keys: `total_butir`, `total_batch`, `h90_alert`.
class AmunisiStats {
  final int totalButir;
  final int totalBatch;
  final int h90Alert;

  const AmunisiStats({
    this.totalButir = 0,
    this.totalBatch = 0,
    this.h90Alert = 0,
  });

  factory AmunisiStats.fromJson(dynamic json) {
    final j = _asMap(json);
    if (j == null) return const AmunisiStats();
    return AmunisiStats(
      totalButir: _toInt(j['total_butir']),
      totalBatch: _toInt(j['total_batch']),
      h90Alert: _toInt(j['h90_alert']),
    );
  }
}

/* ══════════════════════════════════════════════════════════════════════════
 *  PRIVATE DEFENSIVE PARSING HELPERS — total functions, never throw.
 *  A `Map` value may arrive as `Map<String, dynamic>` (jsonDecode) or as any
 *  other `Map` subtype; `_asMap` normalizes both. `_mapList` skips null and
 *  non-map elements so one malformed row cannot sink the whole payload.
 * ══════════════════════════════════════════════════════════════════════════ */

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

int _toInt(dynamic value) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim()) ?? 0;
  if (value is bool) return value ? 1 : 0;
  return 0;
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim()) ?? 0.0;
  return 0.0;
}

String _toStr(dynamic value) => value?.toString() ?? '';

bool _toBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final t = value.trim().toLowerCase();
    return t == 'true' || t == '1';
  }
  return false;
}

List<T> _mapList<T>(
  dynamic value,
  T Function(Map<String, dynamic>) fromJson,
) {
  if (value is! List) return const [];
  final result = <T>[];
  for (final element in value) {
    final map = _asMap(element);
    if (map != null) {
      result.add(fromJson(map));
    }
  }
  return result;
}
