import 'package:flutter/material.dart';
import '../pages/dashboard.dart';
import '../pages/report.dart';
import '../pages/personel.dart';
import '../pages/sarpras.dart';
import '../pages/senjata.dart';
import '../pages/satwa.dart';
import '../pages/inventaris.dart';
import '../pages/amunisi.dart';
import '../pages/user_page.dart';
import '../pages/placeholder_page.dart';
import '../pages/polda.dart';
import '../pages/polres.dart';

class LeafMenuItem {
  final String label;
  final IconData icon;
  final String routeName;
  final Widget Function() pageBuilder;

  const LeafMenuItem({
    required this.label,
    required this.icon,
    required this.routeName,
    required this.pageBuilder,
  });
}

class MenuGroup {
  final String label;
  final IconData icon;
  final List<LeafMenuItem> children;

  const MenuGroup({
    required this.label,
    required this.icon,
    required this.children,
  });
}

Widget _ph(String title, String route) =>
    PlaceholderPage(title: title, routeName: route);

/// Menu dasar yang tersedia untuk semua role (juga dipakai sebagai
/// fallback untuk role yang belum terdaftar di [roleMenus]).
const commonTopItems = [
  LeafMenuItem(
    label: "Dashboard",
    icon: Icons.dashboard_rounded,
    routeName: "dashboard",
    pageBuilder: _db,
  ),
  LeafMenuItem(
    label: "Laporan",
    icon: Icons.description_rounded,
    routeName: "report",
    pageBuilder: _rp,
  ),
];

Widget _db() => const DashboardPage();
Widget _rp() => const ReportPage();
Widget _pe() => const PersonelPage();
Widget _se() => const SenjataPage();
Widget _sa() => const SatwaPage();
Widget _in() => const InventarisPage();
Widget _us() => const UserPage();
Widget _po() => const PoldaPage();
Widget _pr() => const PolresPage();

const role1Menu = [
  commonTopItems,
  [
    MenuGroup(
      label: "Manajemen Keamanan & Akun",
      icon: Icons.admin_panel_settings,
      children: [
        LeafMenuItem(
          label: "Daftar Pengguna",
          icon: Icons.people_alt_rounded,
          routeName: "pengguna",
          pageBuilder: _us,
        ),
        LeafMenuItem(
          label: "Binding Perangkat",
          icon: Icons.phonelink_lock_rounded,
          routeName: "binding_device",
          pageBuilder: _bd,
        ),
      ],
    ),
    MenuGroup(
      label: "Master Data Sistem",
      icon: Icons.storage_rounded,
      children: [
        LeafMenuItem(
          label: "Master Wilayah",
          icon: Icons.map_rounded,
          routeName: "polda",
          pageBuilder: _po,
        ),
        LeafMenuItem(
          label: "Master Polres",
          icon: Icons.flag_rounded,
          routeName: "polres",
          pageBuilder: _pr,
        ),
        LeafMenuItem(
          label: "Master SDM & Organisasi",
          icon: Icons.account_tree_rounded,
          routeName: "org_tree",
          pageBuilder: _ot,
        ),
        LeafMenuItem(
          label: "Master Logistik",
          icon: Icons.warehouse_rounded,
          routeName: "inventaris",
          pageBuilder: _in,
        ),
      ],
    ),
  ],
];

const role2Menu = [
  commonTopItems,
  [
    MenuGroup(
      label: "Manajemen SDM",
      icon: Icons.group_rounded,
      children: [
        LeafMenuItem(
          label: "Bagan Organisasi (Org-Tree)",
          icon: Icons.account_tree_rounded,
          routeName: "org_tree",
          pageBuilder: _ot,
        ),
        LeafMenuItem(
          label: "Direktori Personel",
          icon: Icons.badge_rounded,
          routeName: "personel",
          pageBuilder: _pe,
        ),
        LeafMenuItem(
          label: "Pemantauan Proses Hukum",
          icon: Icons.gavel_rounded,
          routeName: "process_law",
          pageBuilder: _pl,
        ),
      ],
    ),
    MenuGroup(
      label: "Logistik & Aset",
      icon: Icons.inventory_rounded,
      children: [
        LeafMenuItem(
          label: "Inventaris Senjata",
          icon: Icons.shield_rounded,
          routeName: "senjata",
          pageBuilder: _se,
        ),
        LeafMenuItem(
          label: "Stok Amunisi",
          icon: Icons.archive_rounded,
          routeName: "ammo_stock",
          pageBuilder: _as,
        ),
        LeafMenuItem(
          label: "Sarpras & Altmatsus",
          icon: Icons.precision_manufacturing_rounded,
          routeName: "sarpras",
          pageBuilder: _sp,
        ),
        LeafMenuItem(
          label: "Satwa K9 & Turangga",
          icon: Icons.pets_rounded,
          routeName: "satwa",
          pageBuilder: _sa,
        ),
      ],
    ),
    MenuGroup(
      label: "Administrasi (DMS)",
      icon: Icons.description_rounded,
      children: [
        LeafMenuItem(
          label: "Kotak Masuk (Inbox)",
          icon: Icons.move_to_inbox_rounded,
          routeName: "dms_inbox",
          pageBuilder: _di,
        ),
        LeafMenuItem(
          label: "Kotak Keluar (Outbox)",
          icon: Icons.outbox_rounded,
          routeName: "dms_outbox",
          pageBuilder: _do,
        ),
      ],
    ),
    MenuGroup(
      label: "Operasional & Kamtibmas",
      icon: Icons.local_police_rounded,
      children: [
        LeafMenuItem(
          label: "Log Sitkamtibmas",
          icon: Icons.article_rounded,
          routeName: "sitkamtibmas",
          pageBuilder: _sk,
        ),
      ],
    ),
    MenuGroup(
      label: "Komunikasi Taktis",
      icon: Icons.chat_rounded,
      children: [
        LeafMenuItem(
          label: "Direktori Panggilan (VoIP)",
          icon: Icons.call_rounded,
          routeName: "voip_directory",
          pageBuilder: _vd,
        ),
        LeafMenuItem(
          label: "Ruang Konferensi",
          icon: Icons.videocam_rounded,
          routeName: "conference",
          pageBuilder: _cf,
        ),
      ],
    ),
    MenuGroup(
      label: "Hub Informasi Terpadu",
      icon: Icons.device_hub_rounded,
      children: [
        LeafMenuItem(
          label: "Perpustakaan Digital",
          icon: Icons.library_books_rounded,
          routeName: "digital_library",
          pageBuilder: _dl,
        ),
        LeafMenuItem(
          label: "Pengaduan Masyarakat",
          icon: Icons.report_problem_rounded,
          routeName: "public_complaint",
          pageBuilder: _pc,
        ),
      ],
    ),
    MenuGroup(
      label: "Mobile",
      icon: Icons.phone_android_rounded,
      children: [
        LeafMenuItem(
          label: "Status Patroli GPS",
          icon: Icons.gps_fixed_rounded,
          routeName: "patrol_gps",
          pageBuilder: _pg,
        ),
      ],
    ),
  ],
];

const role3Menu = [
  [
    LeafMenuItem(
      label: "Command Center Nasional",
      icon: Icons.monitor_heart_rounded,
      routeName: "dashboard",
      pageBuilder: _db,
    ),
  ],
];

const Map<String, List<List<dynamic>>> roleMenus = {
  "1": role1Menu,
  "2": role2Menu,
  "3": role3Menu,
};

Widget _ot() => _ph("Bagan Organisasi (Org-Tree)", "org_tree");
Widget _pl() => _ph("Pemantauan Proses Hukum", "process_law");
Widget _sp() => const SarprasPage();
Widget _as() => const AmunisiPage();
Widget _di() => _ph("Kotak Masuk (Inbox)", "dms_inbox");
Widget _do() => _ph("Kotak Keluar (Outbox)", "dms_outbox");
Widget _sk() => _ph("Log Sitkamtibmas", "sitkamtibmas");
Widget _vd() => _ph("Direktori Panggilan (VoIP)", "voip_directory");
Widget _cf() => _ph("Ruang Konferensi", "conference");
Widget _dl() => _ph("Perpustakaan Digital", "digital_library");
Widget _pc() => _ph("Pengaduan Masyarakat", "public_complaint");
Widget _pg() => _ph("Status Patroli GPS", "patrol_gps");
Widget _bd() => _ph("Binding Perangkat", "binding_device");
