import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/pantry_provider.dart';
import '../models/pantry_item.dart';
import 'add_edit_item_screen.dart';

class PantryMapScreen extends StatelessWidget {
  const PantryMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PantryProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final locations = provider.locations;
        final itemsByLocation = provider.itemsByLocation;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Pantry map'),
            actions: [
              IconButton(
                icon: const Icon(Icons.help_outline),
                tooltip: 'Map help',
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Pantry map'),
                      content: const Text(
                        'This view shows your pantry locations as shelves.\n'
                        'Tap an item to edit it, or add items from Home.\n'
                        'Locations named "Freezer" will show three drawer sections.\n'
                        'Locations named "Fridge" will show five shelves, a door, and two drawers.',                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Got it'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: locations.isEmpty
                ? const Center(
                    child: Text(
                      'No shelf locations are configured yet. Add items from Home and set their location.',
                      textAlign: TextAlign.center,
                    ),
                  )
                : CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Text(
                          'Your pantry as a set of shelves. Tap a location to inspect its items.',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.only(top: 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final location = locations[index];
                              final locationItems = itemsByLocation[location] ?? [];
                              final rowCount = provider.getGridRows(location);
                              final columnCount = provider.getGridColumns(location);
                              return _ShelfCard(
                                location: location,
                                items: locationItems,
                                rowCount: rowCount,
                                columnCount: columnCount,
                              );
                            },
                            childCount: locations.length,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class _ShelfCard extends StatelessWidget {
  const _ShelfCard({required this.location, required this.items, required this.rowCount, required this.columnCount});

  final String location;
  final List<PantryItem> items;
  final int rowCount;
  final int columnCount;

  @override
  Widget build(BuildContext context) {
    final placedItems = <String, PantryItem>{};
    final overflowItems = <PantryItem>[];
    // use provided row/column counts for this location
    final rowCount = this.rowCount;
    final columnCount = this.columnCount;

    for (final item in items) {
      if (item.gridRow != null && item.gridColumn != null) {
        final row = item.gridRow!;
        final column = item.gridColumn!;
        if (row > 0 && row <= rowCount && column > 0 && column <= columnCount) {
          final key = '$row:$column';
          if (!placedItems.containsKey(key)) {
            placedItems[key] = item;
            continue;
          }
        }
      }
      overflowItems.add(item);
    }

    final lower = location.toLowerCase();
    final isFreezer = lower.contains('freezer');
    final isFridge = lower.contains('fridge');

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  location,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Chip(
                  label: Text('${items.length} item${items.length == 1 ? '' : 's'}'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (isFreezer)
              _FreezerDrawerView(location: location, items: items)
            else if (isFridge)
              _FridgeLayoutView(location: location, items: items)
            else ...[
              SizedBox(
                height: 260,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columnCount,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: rowCount * columnCount,
                  itemBuilder: (context, index) {
                    final row = index ~/ columnCount + 1;
                    final column = index % columnCount + 1;
                    final key = '$row:$column';
                    final item = placedItems[key];
                    return _GridCell(
                      location: location,
                      row: row,
                      column: column,
                      item: item,
                    );
                  },
                ),
              ),
              if (overflowItems.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Unplaced items',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: overflowItems.map((item) {
                    return _ShelfItemTile(item: item);
                  }).toList(),
                ),
              ]
              else if (items.isEmpty)
                Text(
                  'No items assigned to this shelf yet.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FreezerDrawerView extends StatelessWidget {
 const _FreezerDrawerView({required this.location, required this.items});

 final String location;
 final List<PantryItem> items;

 @override
 Widget build(BuildContext context) {
   final drawerItems = {
     for (var drawer = 1; drawer <= 3; drawer++)
       drawer: items.where((item) => item.gridRow == drawer).toList(),
   };
   final unplaced = items.where((item) => item.gridRow == null || item.gridRow! < 1 || item.gridRow! > 3).toList();

   return Column(
     crossAxisAlignment: CrossAxisAlignment.start,
     children: [
       ...drawerItems.entries.map((entry) {
         final drawer = entry.key;
         final drawerList = entry.value;
         return _DrawerSection(
           title: 'Drawer $drawer',
           items: drawerList,
           location: location,
           emptyLabel: 'No items in drawer $drawer.',
         );
       }),
       if (unplaced.isNotEmpty) ...[
         const SizedBox(height: 16),
         Text('Unassigned items', style: Theme.of(context).textTheme.bodyLarge),
         const SizedBox(height: 10),
         Wrap(
           spacing: 10,
           runSpacing: 10,
           children: unplaced.map((item) => _ShelfItemTile(item: item)).toList(),
         ),
       ],
     ],
   );
 }
}

class _FridgeLayoutView extends StatelessWidget {
 const _FridgeLayoutView({required this.location, required this.items});

 final String location;
 final List<PantryItem> items;

 Map<int, String> get _sections => const {
       1: 'Shelf 1',
       2: 'Shelf 2',
       3: 'Shelf 3',
       4: 'Shelf 4',
       5: 'Shelf 5',
       6: 'Door',
       7: 'Drawer 1',
       8: 'Drawer 2',
     };

 @override
 Widget build(BuildContext context) {
   final sectionItems = {
     for (final entry in _sections.entries)
       entry.key: items.where((item) => item.gridRow == entry.key).toList(),
   };
   final unplaced = items.where((item) => item.gridRow == null || !_sections.containsKey(item.gridRow)).toList();

   return Column(
     crossAxisAlignment: CrossAxisAlignment.start,
     children: [
       ..._sections.entries.map((entry) {
         final label = entry.value;
         final sectionList = sectionItems[entry.key]!;
         return _DrawerSection(
           title: label,
           items: sectionList,
           location: location,
           emptyLabel: 'No items in $label yet.',
         );
       }),
       if (unplaced.isNotEmpty) ...[
         const SizedBox(height: 16),
         Text('Unassigned items', style: Theme.of(context).textTheme.bodyLarge),
         const SizedBox(height: 10),
         Wrap(
           spacing: 10,
           runSpacing: 10,
           children: unplaced.map((item) => _ShelfItemTile(item: item)).toList(),
         ),
       ],
     ],
   );
 }
}

class _DrawerSection extends StatelessWidget {
 const _DrawerSection({required this.title, required this.items, required this.location, required this.emptyLabel});

 final String title;
 final List<PantryItem> items;
 final String location;
 final String emptyLabel;

 @override
 Widget build(BuildContext context) {
   return Card(
     margin: const EdgeInsets.only(bottom: 14),
     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
     child: Padding(
       padding: const EdgeInsets.all(12),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           Text(title, style: Theme.of(context).textTheme.titleMedium),
           const SizedBox(height: 10),
           if (items.isEmpty)
             Text(emptyLabel, style: Theme.of(context).textTheme.bodyMedium)
           else
             Column(
               children: items.map((item) {
                 return ListTile(
                   contentPadding: EdgeInsets.zero,
                   title: Text(item.name.isNotEmpty ? item.name : 'Unnamed'),
                   subtitle: Text('Expires ${item.expiryDate.toLocal().toIso8601String().split('T').first}'),
                   trailing: const Icon(Icons.chevron_right),
                   onTap: () async {
                     await Navigator.push<PantryItem?>(
                       context,
                       MaterialPageRoute(
                         builder: (context) => AddEditItemScreen(initialItem: item),
                       ),
                     );
                   },
                 );
               }).toList(),
             ),
         ],
       ),
     ),
   );
 }
}

class _GridCell extends StatelessWidget {
  const _GridCell({required this.location, required this.row, required this.column, this.item});

  final String location;
  final int row;
  final int column;
  final PantryItem? item;

  @override
  Widget build(BuildContext context) {
    final displayItem = item;
    return InkWell(
      onTap: () async {
        await Navigator.push<PantryItem?>(
          context,
          MaterialPageRoute(
            builder: (context) => displayItem != null
                ? AddEditItemScreen(initialItem: displayItem)
                : AddEditItemScreen(
                    initialLocation: location,
                    initialGridRow: row,
                    initialGridColumn: column,
                  ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: displayItem != null ? Colors.blue.shade50 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: displayItem != null ? Colors.blue.shade200 : Colors.grey.shade300,
          ),
        ),
        padding: const EdgeInsets.all(10),
        child: displayItem != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayItem.name.isNotEmpty ? displayItem.name : 'Unnamed',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  Text(
                    displayItem.brand.isNotEmpty ? displayItem.brand : 'Brand',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'R$row C$column',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                  ),
                ],
              )
            : Center(
                child: Text(
                  'Row $row\nCol $column',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ),
      ),
    );
  }
}

class _ShelfItemTile extends StatelessWidget {
  const _ShelfItemTile({required this.item});

  final PantryItem item;

  @override
  Widget build(BuildContext context) {
    final expired = item.isExpired;
    final warning = item.isExpiringSoon;
    final color = expired
        ? Colors.red.shade100
        : warning
            ? Colors.orange.shade100
            : Colors.green.shade100;

    return GestureDetector(
      onTap: () async {
        await Navigator.push<PantryItem?>(
          context,
          MaterialPageRoute(
            builder: (context) => AddEditItemScreen(initialItem: item),
          ),
        );
      },
      child: Container(
        constraints: const BoxConstraints(minWidth: 120, maxWidth: 180),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.name.isNotEmpty ? item.name : 'Unnamed',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(item.brand.isNotEmpty ? item.brand : 'Unknown brand'),
            const SizedBox(height: 6),
            Text(
              'Exp ${item.expiryDate.toLocal().toString().split(' ').first}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }
}
