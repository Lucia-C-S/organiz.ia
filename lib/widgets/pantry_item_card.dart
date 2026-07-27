import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/pantry_item.dart';
import '../providers/pantry_provider.dart';
import '../screens/add_edit_item_screen.dart';

class PantryItemCard extends StatelessWidget {
  const PantryItemCard({super.key, required this.item});

  final PantryItem item;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<PantryProvider>();
    final expiryLabel = DateFormat.yMMMd().format(item.expiryDate);
    final statusText = item.isExpired
        ? 'Expired'
        : item.isExpiringSoon
            ? 'Expiring soon'
            : 'Fresh';

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _PhotoPreview(photoUrl: item.photoUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name.isNotEmpty ? item.name : 'Unnamed item',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(item.brand.isNotEmpty ? item.brand : 'No brand'),
                  const SizedBox(height: 4),
                  Text('Location: ${item.location}'),
                  const SizedBox(height: 2),
                  Text('Expiry: $expiryLabel • $statusText'),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'edit') {
                  await Navigator.push<PantryItem?>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddEditItemScreen(initialItem: item),
                    ),
                  );
                } else if (value == 'delete') {
                  await provider.removeItem(item.id);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({required this.photoUrl});

  final String photoUrl;

  @override
  Widget build(BuildContext context) {
    if (photoUrl.isEmpty) {
      return Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.photo, color: Colors.grey),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        photoUrl,
        width: 64,
        height: 64,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: 64,
          height: 64,
          color: Colors.grey.shade200,
          child: const Icon(Icons.broken_image, color: Colors.grey),
        ),
      ),
    );
  }
}
