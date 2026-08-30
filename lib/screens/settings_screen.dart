import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/pantry_provider.dart';
import '../providers/auth_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Consumer2<PantryProvider, AuthProvider>(
          builder: (context, pantryProvider, authProvider, child) {
            return ListView(
              children: [
                // User Account section
                Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('User Account', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 12),
                        ListTile(
                          leading: const Icon(Icons.person),
                          title: const Text('Name'),
                          subtitle: Text(authProvider.currentUserDisplayName),
                        ),
                        ListTile(
                          leading: const Icon(Icons.email),
                          title: const Text('Email'),
                          subtitle: Text(authProvider.currentUserEmail),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.logout),
                            label: const Text('Sign Out'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Sign out?'),
                                  content: const Text('Are you sure you want to sign out?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                      child: const Text('Sign Out'),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true && context.mounted) {
                                await authProvider.signOut();
                                // The AuthProvider listener will trigger a rebuild
                                // and the app will automatically show the AuthScreen
                              }
                            },
                          ),
                        ),
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
                        Text('My Pantry settings', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 12),
                        TextField(
                          decoration: InputDecoration(
                            labelText: 'Pantry display name',
                            hintText: 'My Kitchen Pantry',
                            suffixIcon: const Icon(Icons.edit_note),
                          ),
                          controller: TextEditingController(text: pantryProvider.profileName),
                          onSubmitted: (value) => pantryProvider.setProfileName(value),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Default expiry days',
                            helperText: 'Suggested days for new pantry items',
                          ),
                          controller: TextEditingController(text: pantryProvider.defaultExpiryDays.toString()),
                          onSubmitted: (value) {
                            final days = int.tryParse(value) ?? pantryProvider.defaultExpiryDays;
                            pantryProvider.setDefaultExpiryDays(days.clamp(1, 365));
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
                                      await pantryProvider.addLocation(name);
                                      await pantryProvider.setLocationGridSize(name, rows, cols);
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
                        ...pantryProvider.locations.map((loc) {
                          final metaRows = pantryProvider.getGridRows(loc);
                          final metaCols = pantryProvider.getGridColumns(loc);
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
                                          await pantryProvider.renameLocation(loc, newName);
                                        }
                                        await pantryProvider.setLocationGridSize(newName, rows, cols);
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
                                      await pantryProvider.removeLocation(loc);
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
                  value: pantryProvider.autoOpenAddAfterLookup,
                  onChanged: (v) => pantryProvider.setAutoOpenAddAfterLookup(v),
                  secondary: const Icon(Icons.open_in_new),
                ),
                SwitchListTile(
                  title: const Text('Auto-add product when found'),
                  subtitle: const Text('Automatically add the product to your pantry when a lookup returns a match.'),
                  value: pantryProvider.autoAddWhenProductFound,
                  onChanged: (v) => pantryProvider.setAutoAddWhenProductFound(v),
                  secondary: const Icon(Icons.add_shopping_cart),
                ),
                ListTile(
                  leading: const Icon(Icons.sync),
                  title: const Text('Sync settings'),
                  subtitle: Text(pantryProvider.isSyncEnabled
                      ? 'Synced to Firebase user ${pantryProvider.syncUserId}.'
                      : 'Not signed in. Firebase sync is available. Configure firebase_options.dart before using Firebase.'),
                  trailing: ElevatedButton(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      if (pantryProvider.isSyncEnabled) {
                        await pantryProvider.signOutFirebase();
                        messenger.showSnackBar(const SnackBar(content: Text('Signed out from Firebase sync.')));
                      } else {
                        final success = await pantryProvider.signInAnonymously();
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(success
                                ? 'Firebase anonymous sign-in succeeded.'
                                : 'Firebase sign-in failed. Configure firebase_options.dart or check network permissions.'),
                          ),
                        );
                      }
                    },
                    child: Text(pantryProvider.isSyncEnabled ? 'Sign out' : 'Sign in'),
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
