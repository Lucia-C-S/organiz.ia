import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/pantry_provider.dart';
import '../models/pantry_item.dart';
import 'add_edit_item_screen.dart';

class PantryMapScreen extends StatefulWidget {
  const PantryMapScreen({super.key});

  @override
  State<PantryMapScreen> createState() => _PantryMapScreenState();
}

class _PantryMapScreenState extends State<PantryMapScreen> {
  String _selectedPantryLocation = 'Cupboard 1';

  @override
  Widget build(BuildContext context) {
    return Consumer<PantryProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final itemsByLocation = provider.itemsByLocation;
        final allPantryLocations = ['Cupboard 1', 'Cupboard 2', 'Wine cellar'];
        final fridgeFreezerLocations = ['Fridge', 'Freezer'];

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
                        'This view shows your pantry locations.\n'
                        'Select a cupboard or location from the dropdown.\n'
                        'Cupboards show 5x5 grids.\n'
                        'Wine cellar shows categorized wines.\n'
                        'Fridge and Freezer show their sections.',
                      ),
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
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Pantry', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedPantryLocation,
                            decoration: const InputDecoration(
                              labelText: 'Select location',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            items: allPantryLocations.map((loc) {
                              return DropdownMenuItem<String>(
                                value: loc,
                                child: Text(loc),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedPantryLocation = value;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Display the selected pantry location
                  _ShelfCard(
                    location: _selectedPantryLocation,
                    items: itemsByLocation[_selectedPantryLocation] ?? [],
                    rowCount: provider.getGridRows(_selectedPantryLocation),
                    columnCount: provider.getGridColumns(_selectedPantryLocation),
                  ),
                  const SizedBox(height: 24),
                  // Fridge and Freezer
                  ...fridgeFreezerLocations.map((location) {
                    return Column(
                      children: [
                        _ShelfCard(
                          location: location,
                          items: itemsByLocation[location] ?? [],
                          rowCount: provider.getGridRows(location),
                          columnCount: provider.getGridColumns(location),
                        ),
                        const SizedBox(height: 24),
                      ],
                    );
                  }).toList(),
                ],
              ),
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
                      // If this location is the Wine cellar, show a categorized list instead of a grid
                      if (location.toLowerCase() == 'wine cellar')
                        _WineCellarView(location: location, items: items)
                      else
                        // Cupboards and other shelf-like locations: render a grid that sizes to content
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: columnCount > 0 ? columnCount : 1,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 1.1,
                          ),
                          itemCount: (rowCount > 0 && columnCount > 0) ? rowCount * columnCount : 0,
                          itemBuilder: (context, index) {
                            final row = index ~/ (columnCount > 0 ? columnCount : 1) + 1;
                            final column = index % (columnCount > 0 ? columnCount : 1) + 1;
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
                      if (items.isEmpty)
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
     ],
   );
 }
}

// New: Wine cellar list view with simple category grouping and optional user-added categories
class _WineCellarView extends StatefulWidget {
  const _WineCellarView({required this.location, required this.items});

  final String location;
  final List<PantryItem> items;

  @override
  State<_WineCellarView> createState() => _WineCellarViewState();
}

class _WineCellarViewState extends State<_WineCellarView> {
  String _selectedCategory = 'All';

  void _addCategory(PantryProvider provider) async {
    final controller = TextEditingController();
    final result = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add wine category'),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'Category name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      await provider.addWineCategory(result);
      if (mounted) {
        setState(() {
          _selectedCategory = result;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PantryProvider>(
      builder: (context, provider, child) {
        final items = widget.items;
        final categories = provider.wineCategories;
        final allCategories = ['All', ...categories];

        // Ensure selected category is still valid
        if (!allCategories.contains(_selectedCategory)) {
          _selectedCategory = 'All';
        }

        // derive category from locationDetail, fallback to 'Uncategorized'
        final grouped = <String, List<PantryItem>>{};
        for (final item in items) {
          final cat = (item.locationDetail.isNotEmpty ? item.locationDetail : 'Uncategorized');
          grouped.putIfAbsent(cat, () => []).add(item);
        }

        final displayGroups = Map.fromEntries(
          grouped.entries.where((e) => _selectedCategory == 'All' || e.key == _selectedCategory),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    items: allCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) => setState(() => _selectedCategory = v ?? 'All'),
                  ),
                ),
                IconButton(onPressed: () => _addCategory(provider), icon: const Icon(Icons.add)),
              ],
            ),
            const SizedBox(height: 12),
            if (displayGroups.isEmpty)
              Text('No wines in this category', style: Theme.of(context).textTheme.bodyMedium)
            else
              ...displayGroups.entries.map((entry) {
                final cat = entry.key;
                final list = entry.value;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cat, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Column(
                      children: list
                          .map(
                            (item) => ListTile(
                              title: Text(item.name.isNotEmpty ? item.name : 'Unnamed'),
                              subtitle: Text(item.brand.isNotEmpty ? item.brand : 'Unknown'),
                              trailing: Text(item.addedAt.toLocal().toString().split(' ').first),
                              onTap: () async {
                                await Navigator.push<PantryItem?>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AddEditItemScreen(initialItem: item),
                                  ),
                                );
                              },
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                  ],
                );
              }).toList(),
          ],
        );
      },
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
