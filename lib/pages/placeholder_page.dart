import 'package:flutter/material.dart';
import '../widget/app_scaffold.dart';

class PlaceholderPage extends StatelessWidget {
  final String title;
  final String routeName;

  const PlaceholderPage({
    super.key,
    required this.title,
    required this.routeName,
  });

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
  currentRoute: routeName,
  showHeaderFooter: false,
  child:       Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.construction_rounded,
                                size: 80, color: Colors.amber.shade700),
                            const SizedBox(height: 20),
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xff1E1B4B),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Fitur dalam pengembangan",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
);
  }
}
