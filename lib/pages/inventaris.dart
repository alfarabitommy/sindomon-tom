import 'package:flutter/material.dart';
import '../pages/add_inventaris_page.dart';
import '../widget/app_pagination.dart';
import '../widget/app_search_field.dart';
import '../widget/action_buttons.dart';
import '../widget/app_scaffold.dart';

class InventarisPage extends StatefulWidget {
  const InventarisPage({super.key});

  @override
  State<InventarisPage> createState() => _InventarisPageState();
}

class _InventarisPageState extends State<InventarisPage> {
  final List<Map<String, dynamic>> listinventaris = [
    {
      "foto": "",
      "nama": "APC Anoa-2 6x6",
      "kategori": "Rantis",
      "kondisi": "Baik",
    },
    {
      "foto": "",
      "nama": "APC Anoa-2 6x6",
      "kategori": "Rantis",
      "kondisi": "Baik",
    },
    {
      "foto": "",
      "nama": "APC Anoa-2 6x6",
      "kategori": "Rantis",
      "kondisi": "Baik",
    },
    {
      "foto": "",
      "nama": "APC Anoa-2 6x6",
      "kategori": "Rantis",
      "kondisi": "Baik",
    },
    {
      "foto": "",
      "nama": "APC Anoa-2 6x6",
      "kategori": "Rantis",
      "kondisi": "Baik",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
  currentRoute: "inventaris",
  breadcrumb: "Dashboard / Inventaris",
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 25),

      /// ============================
      /// TITLE
      /// ============================
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Manajemen Inventaris",
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),

          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddInventarisPage(),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text("Tambah Inventaris"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              elevation: 5,
              padding: const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 18,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),

      const SizedBox(height: 20),

      /// SEARCH
      AppSearchField(hintText: "Cari Inventaris..."),

      const SizedBox(height: 25),

      /// TABLE DATA
      Expanded(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: constraints.maxWidth,
                            ),
                            child: DataTable(
                              headingRowColor:
                                  WidgetStateProperty.all(
                                    Colors.grey.shade50,
                                  ),
                              headingTextStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF6B7280),
                              ),
                              dataTextStyle: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF374151),
                              ),
                              dividerThickness: 0.5,
                              border: const TableBorder(
                                horizontalInside: BorderSide(
                                  color: Color(0xFFE5E7EB),
                                  width: 0.5,
                                ),
                              ),
                              dataRowMinHeight: 60,
                              dataRowMaxHeight: 70,
                              columns: const [
                                DataColumn(label: Text("FOTO")),
                                DataColumn(label: Text("NAMA")),
                                DataColumn(
                                  label: Text("KATEGORI"),
                                ),
                                DataColumn(
                                  label: Text("KONDISI"),
                                ),
                                DataColumn(label: Text("AKSI")),
                              ],
                              rows:
                                  listinventaris
                                      .map(
                                        (e) => DataRow(
                                          cells: [
                                            DataCell(
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      8,
                                                    ),
                                                child: Image.asset(
                                                  "assets/images/rantis.jpg",
                                                  width: 80,
                                                  height: 50,
                                                  fit:
                                                      BoxFit
                                                          .cover,
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Text(e["nama"]),
                                            ),
                                            DataCell(
                                              Text(
                                                "${e["kategori"]}",
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                "${e["kondisi"]}",
                                              ),
                                            ),
                                            DataCell(
                                              ActionButtons(
                                                onEdit: () {},
                                                onDelete: () {},
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                      .toList(),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const AppPagination(),
            ],
          ),
        ),
      ),

      const SizedBox(height: 20),

    ],
  ),
);
  }

}
