import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/pantry_item.dart';
import '../providers/pantry_provider.dart';
import '../widgets/pantry_item_card.dart';
import 'add_edit_item_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PantryProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final groups = provider.groupedItems();
        final groupType = provider.groupType;
        return Scaffold(
          appBar: AppBar(
            title: Text(provider.profileName.isNotEmpty ? provider.profileName : 'Family Pantry'),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Center(child: Text('User: ${provider.currentUser}')),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                _HomeSummary(provider: provider),
                const SizedBox(height: 12),
                _GroupTypeSelector(groupType: groupType),
                const SizedBox(height: 12),
                if (groups.isEmpty)
                  const Expanded(
                    child: Center(
                      child: Text(
                        'No pantry items yet. Tap the + button to add one.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      itemCount: groups.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final sectionName = groups.keys.elementAt(index);
                        final sectionItems = groups[sectionName]!;
                        return _SectionCard(
                          title: sectionName,
                          items: sectionItems,
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => Navigator.push<PantryItem?>(
              context,
              MaterialPageRoute(
                builder: (context) => const AddEditItemScreen(),
              ),
            ),
            tooltip: 'Add pantry item',
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}

class _GroupTypeSelector extends StatelessWidget {
  const _GroupTypeSelector({required this.groupType});

  final HomeGroupType groupType;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: HomeGroupType.values.map((type) {
            final selected = type == groupType;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(_groupLabel(type)),
                  selected: selected,
                  onSelected: (value) {
                    if (value) {
                      context.read<PantryProvider>().setGroupType(type);
                    }
                  },
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  String _groupLabel(HomeGroupType type) {
    switch (type) {
      case HomeGroupType.location:
        return 'By location';
      case HomeGroupType.expiry:
        return 'By expiry';
    }
  }
}

class _HomeSummary extends StatelessWidget {
  const _HomeSummary({required this.provider});

  final PantryProvider provider;

  @override
  Widget build(BuildContext context) {
    final total = provider.totalItemCount;
    final expired = provider.expiredItemCount;
    final expiringSoon = provider.expiringSoonCount;
    final fresh = provider.freshItemCount;
    final locationCounts = provider.locationCounts;
    final maxLocationCount =
        locationCounts.values.fold<int>(0, (prev, value) => value > prev ? value : prev);

    return Column(
      children: [
        Row(
          children: [
            _SummaryChip(label: 'Total', value: total.toString()),
            const SizedBox(width: 8),
            _SummaryChip(label: 'Fresh', value: fresh.toString()),
            const SizedBox(width: 8),
            _SummaryChip(label: 'Soon', value: expiringSoon.toString()),
            const SizedBox(width: 8),
            _SummaryChip(label: 'Expired', value: expired.toString()),
          ],
        ),
        if (locationCounts.isNotEmpty) ...[
          const SizedBox(height: 12),
          Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Location usage',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ...locationCounts.entries.map((entry) {
                    final normalized = maxLocationCount == 0
                        ? 0.0
                        : entry.value / maxLocationCount;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${entry.key} • ${entry.value} item(s)'),
                          const SizedBox(height: 4),
                          Container(
                            height: 8,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: normalized,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
 
class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Chip(
        label: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: Colors.grey.shade100,
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.items});

  final String title;
  final List<PantryItem> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = items[index];
                return PantryItemCard(item: item);
              },
            ),
          ],
        ),
      ),
    );
  }
}
