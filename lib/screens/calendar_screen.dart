import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/pantry_provider.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  bool _sameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PantryProvider>();
    final items = provider.items;
    final now = DateTime.now();
    final nextWeek = List.generate(7, (index) => DateTime(now.year, now.month, now.day + index));
    final counts = {
      for (final date in nextWeek)
        date: items.where((item) => _sameDate(item.expiryDate, date)).length,
    };

    final expiringItems = items
        .where((item) => !item.expiryDate.isBefore(DateTime(now.year, now.month, now.day)))
        .toList()
      ..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));

    return Scaffold(
      appBar: AppBar(title: const Text('Expiry Calendar')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Next 7 days', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: nextWeek.map((date) {
                          final count = counts[date] ?? 0;
                          final isToday = _sameDate(date, now);
                          return Container(
                            width: 110,
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isToday ? Theme.of(context).colorScheme.primaryContainer : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${date.day}/${date.month}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isToday ? Theme.of(context).colorScheme.onPrimaryContainer : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  count == 0 ? 'No expiring' : '$count expiring',
                                  style: TextStyle(
                                    color: isToday ? Theme.of(context).colorScheme.onPrimaryContainer : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Items by expiry', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      if (expiringItems.isEmpty)
                        const Expanded(
                          child: Center(
                            child: Text('No items with upcoming expiry dates.'),
                          ),
                        )
                      else
                        Expanded(
                          child: ListView.separated(
                            itemCount: expiringItems.length,
                            separatorBuilder: (context, index) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final item = expiringItems[index];
                              final daysLeft = item.expiryDate.difference(now).inDays;
                              final badgeColor = daysLeft <= 1
                                  ? Theme.of(context).colorScheme.error
                                  : daysLeft <= 3
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.secondary;
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: badgeColor.withAlpha((0.16 * 255).round()),
                                  child: Text(
                                    '${daysLeft >= 0 ? daysLeft : 0}',
                                    style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                title: Text(item.name),
                                subtitle: Text('${item.location} • expiring ${item.expiryDate.toLocal().toIso8601String().split('T').first}'),
                                trailing: Icon(Icons.calendar_today, color: badgeColor),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
