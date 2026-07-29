import 'package:flutter/material.dart';

class ActionButtons extends StatefulWidget {
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ActionButtons({
    super.key,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<ActionButtons> createState() => _ActionButtonsState();
}

class _ActionButtonsState extends State<ActionButtons> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ghostIconButton(
            icon: Icons.edit_outlined,
            defaultColor: Colors.grey.shade400,
            hoverColor: Colors.blue,
            hoverBg: Colors.blue.withValues(alpha: 0.08),
            onPressed: widget.onEdit,
          ),
          const SizedBox(width: 4),
          _ghostIconButton(
            icon: Icons.delete_outlined,
            defaultColor: Colors.grey.shade400,
            hoverColor: Colors.red,
            hoverBg: Colors.red.withValues(alpha: 0.08),
            onPressed: widget.onDelete,
          ),
        ],
      ),
    );
  }

  Widget _ghostIconButton({
    required IconData icon,
    required Color defaultColor,
    required Color hoverColor,
    required Color hoverBg,
    required VoidCallback? onPressed,
  }) {
    return IconButton(
      icon: Icon(icon, color: _isHovered ? hoverColor : defaultColor, size: 20),
      onPressed: onPressed,
      splashRadius: 18,
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(
        backgroundColor: _isHovered ? hoverBg : Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
