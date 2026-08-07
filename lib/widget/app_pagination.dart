import 'package:flutter/material.dart';

/// Dynamic pagination strip.
///
/// All props are optional and default to the previous hardcoded values
/// ("Menampilkan 1 hingga 10 dari 50 data", page 1 active), so existing call
/// sites like `const AppPagination()` keep compiling and render the same
/// layout. Pages that opt in pass [currentPage], [totalPages], [totalItems],
/// [perPage] and [onPageChanged] to get a live, clickable widget.
class AppPagination extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int perPage;
  final ValueChanged<int>? onPageChanged;

  const AppPagination({
    super.key,
    this.currentPage = 1,
    this.totalPages = 1,
    this.totalItems = 50,
    this.perPage = 10,
    this.onPageChanged,
  });

  /// Page numbers to render, windowed with gaps when the range is large
  /// (first, last, and current ± 1).
  List<int> get _visiblePages {
    if (totalPages <= 7) {
      return List.generate(totalPages, (i) => i + 1);
    }
    return <int>{
      1,
      totalPages,
      currentPage - 1,
      currentPage,
      currentPage + 1,
    }
        .where((p) => p >= 1 && p <= totalPages)
        .toList()
      ..sort();
  }

  @override
  Widget build(BuildContext context) {
    final int start = totalItems == 0 ? 0 : (currentPage - 1) * perPage + 1;
    final int end = totalItems == 0
        ? 0
        : (currentPage * perPage < totalItems)
        ? currentPage * perPage
        : totalItems;

    final String displayText = totalItems == 0
        ? "Menampilkan 0 data"
        : "Menampilkan $start hingga $end dari $totalItems data";

    final pages = _visiblePages;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade200, width: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            displayText,
            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
          ),
          Row(
            children: [
              _pageButton(
                "<",
                onTap: onPageChanged != null && currentPage > 1
                    ? () => onPageChanged!(currentPage - 1)
                    : null,
              ),
              const SizedBox(width: 6),
              for (int i = 0; i < pages.length; i++) ...[
                if (i > 0 && pages[i] - pages[i - 1] > 1)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      "...",
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                _pageButton(
                  "${pages[i]}",
                  active: pages[i] == currentPage,
                  onTap: onPageChanged != null && pages[i] != currentPage
                      ? () => onPageChanged!(pages[i])
                      : null,
                ),
                const SizedBox(width: 6),
              ],
              _pageButton(
                ">",
                onTap: onPageChanged != null && currentPage < totalPages
                    ? () => onPageChanged!(currentPage + 1)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _pageButton(
    String label, {
    bool active = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? Colors.amber : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: active ? Colors.amber : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: active ? Colors.black : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}
