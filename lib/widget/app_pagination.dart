import 'package:flutter/material.dart';

class AppPagination extends StatelessWidget {
  const AppPagination({super.key});

  @override
  Widget build(BuildContext context) {
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
          const Text(
            "Menampilkan 1 hingga 10 dari 50 data",
            style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
          ),
          Row(
            children: [
              _pageButton("<"),
              const SizedBox(width: 6),
              _pageButton("1", active: true),
              const SizedBox(width: 6),
              _pageButton("2"),
              const SizedBox(width: 6),
              _pageButton("3"),
              const SizedBox(width: 6),
              _pageButton(">"),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _pageButton(String label, {bool active = false}) {
    return Container(
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
    );
  }
}
