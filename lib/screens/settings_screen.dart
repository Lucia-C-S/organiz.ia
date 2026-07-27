import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/pantry_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Consumer<PantryProvider>(
          builder: (context, provider, child) {
            return ListView(
              children: [
                Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('My Pantry settings', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 12),
                        TextField(
                          decoration: InputDecoration(
                            labelText: 'Pantry display name',
                            hintText: 'My Kitchen Pantry',
                            suffixIcon: const Icon(Icons.edit_note),
                          ),
                          controller: TextEditingController(text: provider.profileName),
                          onSubmitted: (value) => provider.setProfileName(value),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Default expiry days',
                            helperText: 'Suggested days for new pantry items',
                          ),
                          controller: TextEditingController(text: provider.defaultExpiryDays.toString()),
                          onSubmitted: (value) {
                            final days = int.tryParse(value) ?? provider.defaultExpiryDays;
                            provider.setDefaultExpiryDays(days.clamp(1, 365));
                          },
                        ),
                        const SizedBox(height: 8),
                        Text('Personalize your map by editing shelf locations and their grid sizes.', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ),
                Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Shelf locations', style: Theme.of(context).textTheme.titleMedium),
                            TextButton.icon(
                              onPressed: () async {
                                final newName = await showDialog<String>(
                                  context: context,
                                  builder: (context) {
                                    final controller = TextEditingController();
                                    int rows = PantryProvider.gridRowCount;
                                    int cols = PantryProvider.gridColumnCount;
                                    return AlertDialog(
                                      title: const Text('Add location'),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          TextField(
                                            controller: controller,
                                            decoration: const InputDecoration(labelText: 'Location name'),
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: DropdownButtonFormField<int>(
                                                  initialValue: rows,
                                                  decoration: const InputDecoration(labelText: 'Rows'),
                                                  items: List.generate(6, (i) => i + 1).map((v) => DropdownMenuItem(value: v, child: Text('$v'))).toList(),
                                                  onChanged: (v) => rows = v ?? rows,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: DropdownButtonFormField<int>(
                                                  initialValue: cols,
                                                  decoration: const InputDecoration(labelText: 'Columns'),
                                                  items: List.generate(6, (i) => i + 1).map((v) => DropdownMenuItem(value: v, child: Text('$v'))).toList(),
                                                  onChanged: (v) => cols = v ?? cols,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                                        ElevatedButton(
                                          onPressed: () {
                                            final name = controller.text.trim();
                                            if (name.isEmpty) return;
                                            Navigator.pop(context, jsonEncode({'name': name, 'rows': rows, 'columns': cols}));
                                          },
                                          child: const Text('Add'),
                                        ),
                                      ],
                                    );
                                  },
                                );

                                if (newName != null) {
                                  try {
                                    final parsed = json.decode(newName) as Map<String, dynamic>;
                                    final name = parsed['name'] as String? ?? '';
                                    final rows = (parsed['rows'] as num?)?.toInt() ?? PantryProvider.gridRowCount;
                                    final cols = (parsed['columns'] as num?)?.toInt() ?? PantryProvider.gridColumnCount;
                                    if (name.isNotEmpty) {
                                      await provider.addLocation(name);
                                      await provider.setLocationGridSize(name, rows, cols);
                                    }
                                  } catch (_) {}
                                }
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Add location'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...provider.locations.map((loc) {
                          final metaRows = provider.getGridRows(loc);
                          final metaCols = provider.getGridColumns(loc);
                          return ListTile(
                            title: Text(loc),
                            subtitle: Text('Grid: $metaRows×$metaCols'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () async {
                                    // edit dialog: rename + rows/cols
                                    final result = await showDialog<String>(
                                      context: context,
                                      builder: (context) {
                                        final nameController = TextEditingController(text: loc);
                                        int rows = metaRows;
                                        int cols = metaCols;
                                        return AlertDialog(
                                          title: const Text('Edit location'),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Location name')),
                                              const SizedBox(height: 12),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: DropdownButtonFormField<int>(
                                                      initialValue: rows,
                                                      decoration: const InputDecoration(labelText: 'Rows'),
                                                      items: List.generate(6, (i) => i + 1).map((v) => DropdownMenuItem(value: v, child: Text('$v'))).toList(),
                                                      onChanged: (v) => rows = v ?? rows,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: DropdownButtonFormField<int>(
                                                      initialValue: cols,
                                                      decoration: const InputDecoration(labelText: 'Columns'),
                                                      items: List.generate(6, (i) => i + 1).map((v) => DropdownMenuItem(value: v, child: Text('$v'))).toList(),
                                                      onChanged: (v) => cols = v ?? cols,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                                            ElevatedButton(
                                              onPressed: () {
                                                final newName = nameController.text.trim();
                                                if (newName.isEmpty) return;
                                                Navigator.pop(context, jsonEncode({'name': newName, 'rows': rows, 'columns': cols}));
                                              },
                                              child: const Text('Save'),
                                            ),
                                          ],
                                        );
                                      },
                                    );

                                    if (result != null) {
                                      try {
                                        final parsed = json.decode(result) as Map<String, dynamic>;
                                        final newName = parsed['name'] as String? ?? loc;
                                        final rows = (parsed['rows'] as num?)?.toInt() ?? metaRows;
                                        final cols = (parsed['columns'] as num?)?.toInt() ?? metaCols;
                                        if (newName != loc) {
                                          await provider.renameLocation(loc, newName);
                                        }
                                        await provider.setLocationGridSize(newName, rows, cols);
                                      } catch (_) {}
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Remove location'),
                                        content: Text('Remove "$loc"? Items assigned to this location will be moved to another location.'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove')),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await provider.removeLocation(loc);
                                    }
                                  },
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                SwitchListTile(
                  title: const Text('Open Add screen after lookup'),
                  subtitle: const Text('Automatically open the Add Item screen when a barcode lookup finds a product.'),
                  value: provider.autoOpenAddAfterLookup,
                  onChanged: (v) => provider.setAutoOpenAddAfterLookup(v),
                  secondary: const Icon(Icons.open_in_new),
                ),
                SwitchListTile(
                  title: const Text('Auto-add product when found'),
                  subtitle: const Text('Automatically add the product to your pantry when a lookup returns a match.'),
                  value: provider.autoAddWhenProductFound,
                  onChanged: (v) => provider.setAutoAddWhenProductFound(v),
                  secondary: const Icon(Icons.add_shopping_cart),
                ),
                ListTile(
                  leading: const Icon(Icons.sync),
                  title: const Text('Sync settings'),
                  subtitle: Text(provider.isSyncEnabled
                      ? 'Synced to Firebase user ${provider.syncUserId}.'
                      : 'Not signed in. Firebase sync is available. Configure firebase_options.dart before using Firebase.'),
                  trailing: ElevatedButton(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      if (provider.isSyncEnabled) {
                        await provider.signOutFirebase();
                        messenger.showSnackBar(const SnackBar(content: Text('Signed out from Firebase sync.')));
                      } else {
                        final success = await provider.signInAnonymously();
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(success
                                ? 'Firebase anonymous sign-in succeeded.'
                                : 'Firebase sign-in failed. Configure firebase_options.dart or check network permissions.'),
                          ),
                        );
                      }
                    },
                    child: Text(provider.isSyncEnabled ? 'Sign out' : 'Sign in'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
