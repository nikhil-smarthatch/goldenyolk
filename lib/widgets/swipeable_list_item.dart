import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class SwipeableListItem extends StatelessWidget {
  final Widget child;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final String? confirmDeleteMessage;

  const SwipeableListItem({
    super.key,
    required this.child,
    required this.onEdit,
    required this.onDelete,
    this.confirmDeleteMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Slidable(
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => onEdit(),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: 'Edit',
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
          ),
          SlidableAction(
            onPressed: (_) => _confirmDelete(context),
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Delete',
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
          ),
        ],
      ),
      child: child,
    );
  }

  void _confirmDelete(BuildContext context) {
    if (confirmDeleteMessage == null) {
      onDelete();
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text(confirmDeleteMessage!),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              onDelete();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
