import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/pantry_item.dart';

class LocalStorageService {
  static const _pantryItemsKey = 'pantry_items';
  static const _storesKey = 'pantry_stores';
  static const _locationsKey = 'pantry_locations';
  static const _locationsMetaKey = 'pantry_locations_meta';
  static const _profileNameKey = 'profile_name';
  static const _defaultExpiryDaysKey = 'default_expiry_days';
  static const _preferredColorSeedKey = 'preferred_color_seed';
  static const _autoOpenAddKey = 'auto_open_add_after_lookup';
  static const _autoAddKey = 'auto_add_when_product_found';
  static const _wineCategoriesKey = 'wine_categories';

  Future<List<PantryItem>> loadPantryItems() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_pantryItemsKey);
    if (raw == null || raw.isEmpty) {
      return <PantryItem>[];
    }

    final decoded = json.decode(raw) as List<dynamic>;
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(PantryItem.fromJson)
        .toList();
  }

  Future<void> savePantryItems(List<PantryItem> items) async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = json.encode(items.map((item) => item.toJson()).toList());
    await preferences.setString(_pantryItemsKey, encoded);
  }

  Future<List<String>> loadStores() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getStringList(_storesKey) ?? [];
  }

  Future<void> saveStores(List<String> stores) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(_storesKey, stores);
  }

  Future<List<String>> loadLocations() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getStringList(_locationsKey) ?? [];
  }

  Future<void> saveLocations(List<String> locations) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(_locationsKey, locations);
  }

  /// Load per-location metadata (rows/columns) saved as a JSON object.
  /// Example format: { "Pantry shelf": {"rows": 3, "columns": 4}, "Fridge": {"rows":2,"columns":2} }
  Future<Map<String, Map<String, int>>> loadLocationMeta() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_locationsMetaKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = json.decode(raw) as Map<String, dynamic>;
      return decoded.map((key, value) {
        final m = value as Map<String, dynamic>;
        return MapEntry(key, {
          'rows': (m['rows'] as num?)?.toInt() ?? 0,
          'columns': (m['columns'] as num?)?.toInt() ?? 0,
        });
      });
    } catch (_) {
      return {};
    }
  }

  Future<void> saveLocationMeta(Map<String, Map<String, int>> meta) async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = json.encode(meta);
    await preferences.setString(_locationsMetaKey, encoded);
  }

  Future<String> loadProfileName() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_profileNameKey) ?? 'My Pantry';
  }

  Future<void> saveProfileName(String name) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_profileNameKey, name);
  }

  Future<int> loadDefaultExpiryDays() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getInt(_defaultExpiryDaysKey) ?? 14;
  }

  Future<void> saveDefaultExpiryDays(int days) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(_defaultExpiryDaysKey, days);
  }

  Future<int> loadPreferredColorSeed() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getInt(_preferredColorSeedKey) ?? 0;
  }

  Future<void> savePreferredColorSeed(int index) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(_preferredColorSeedKey, index);
  }

  Future<bool> loadAutoOpenAdd() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_autoOpenAddKey) ?? false;
  }

  Future<void> saveAutoOpenAdd(bool value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_autoOpenAddKey, value);
  }

  Future<bool> loadAutoAddWhenProductFound() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_autoAddKey) ?? false;
  }

  Future<void> saveAutoAddWhenProductFound(bool value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_autoAddKey, value);
  }

  Future<void> clearPantryItems() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_pantryItemsKey);
  }

  Future<List<String>> loadWineCategories() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getStringList(_wineCategoriesKey) ?? [
      'Red wine',
      'White wine',
      'Portuguese wine',
      'Champagne',
      'Specials',
      'Beer',
    ];
  }

  Future<void> saveWineCategories(List<String> categories) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(_wineCategoriesKey, categories);
  }
}
