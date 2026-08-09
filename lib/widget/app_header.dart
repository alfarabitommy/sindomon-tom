import 'package:flutter/material.dart';
import '../pages/pangaturan.dart';
import '../utils/session_util.dart';

/// Actions available from the profile dropdown (replaces the old
/// sidebar entries for Pengaturan / Logout).
enum _ProfileAction { pengaturan, logout }

class AppHeader extends StatelessWidget {
  final String breadcrumb;
  final String username;
  final String role;

  const AppHeader({
    super.key,
    required this.breadcrumb,
    required this.username,
    required this.role,
  });

  void _onProfileActionSelected(BuildContext context, _ProfileAction action) {
    switch (action) {
      case _ProfileAction.pengaturan:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AccountSettingPage()),
        );
        break;
      case _ProfileAction.logout:
        clearSessionAndLogout(context);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 65,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.home_rounded,
              color: Colors.amber,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              breadcrumb,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Spacer(),
          PopupMenuButton<_ProfileAction>(
            offset: const Offset(0, 50),
            tooltip: 'Menu Profil',
            onSelected: (action) => _onProfileActionSelected(context, action),
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _ProfileAction.pengaturan,
                child: _ProfileMenuItem(
                  icon: Icons.settings_rounded,
                  label: 'Pengaturan',
                ),
              ),
              PopupMenuDivider(),
              PopupMenuItem(
                value: _ProfileAction.logout,
                child: _ProfileMenuItem(
                  icon: Icons.logout_rounded,
                  label: 'Logout',
                ),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade300, width: 1.5),
                    ),
                    child: const CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.amber,
                      child: Icon(Icons.person, color: Colors.black, size: 18),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          height: 1.2,
                        ),
                      ),
                      Text(
                        role,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down, color: Colors.grey),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Single dropdown row: icon + label.
class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ProfileMenuItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.black87),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}
