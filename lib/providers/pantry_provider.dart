import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/pantry_item.dart';
import '../services/firebase_service.dart';
import '../services/firebase_storage_service.dart';
import '../services/local_storage_service.dart';

enum HomeGroupType { expiry, location }

class PantryProvider extends ChangeNotifier {
  PantryProvider({
    LocalStorageService? storageService,
    FirebaseService? firebaseService,
    FirebaseStorageService? firebaseStorageService,
  })  : _storageService = storageService ?? LocalStorageService(),
        _firebaseService = firebaseService ?? FirebaseService(),
        _firebaseStorageService = firebaseStorageService ?? FirebaseStorageService();

  final LocalStorageService _storageService;
  final FirebaseService _firebaseService;
  final FirebaseStorageService _firebaseStorageService;
  final _uuid = const Uuid();
  StreamSubscription<List<PantryItem>>? _remoteSubscription;

  List<PantryItem> _items = [];
  HomeGroupType _groupType = HomeGroupType.expiry;
  bool _isLoading = true;
  String _currentUser = 'local_user';
  List<String> _stores = [];
  List<String> _locations = [];
  // Per-location metadata: rows/columns for each location
  Map<String, Map<String, int>> _locationMeta = {};
  bool _autoOpenAddAfterLookup = true;
  bool _autoAddWhenProductFound = false;
  String _profileName = 'My Pantry';
  int _defaultExpiryDays = 14;
  int _preferredColorSeedIndex = 0;

  static const int gridRowCount = 3;
  static const int gridColumnCount = 4;

  List<PantryItem> get items => List.unmodifiable(_items);
  HomeGroupType get groupType => _groupType;
  bool get isLoading => _isLoading;
  String get currentUser => _currentUser;
  bool get isSyncEnabled => _firebaseService.isSignedIn;
  String get syncUserId => _firebaseService.currentUserId;
  List<String> get stores => List.unmodifiable(_stores);
  List<String> get locations => List.unmodifiable(_locations);

  int getGridRows(String location) => _locationMeta[location]?['rows'] ?? gridRowCount;
  int getGridColumns(String location) => _locationMeta[location]?['columns'] ?? gridColumnCount;

  bool get autoOpenAddAfterLookup => _autoOpenAddAfterLookup;
  bool get autoAddWhenProductFound => _autoAddWhenProductFound;

  Future<void> setAutoOpenAddAfterLookup(bool value) async {
    _autoOpenAddAfterLookup = value;
    await _storageService.saveAutoOpenAdd(value);
    notifyListeners();
  }

  Future<void> setAutoAddWhenProductFound(bool value) async {
    _autoAddWhenProductFound = value;
    await _storageService.saveAutoAddWhenProductFound(value);
    notifyListeners();
  }

  String get profileName => _profileName;

  int get defaultExpiryDays => _defaultExpiryDays;

  int get preferredColorSeedIndex => _preferredColorSeedIndex;

  void setProfileName(String name) {
    _profileName = name.trim().isEmpty ? 'My Pantry' : name.trim();
    _storageService.saveProfileName(_profileName);
    notifyListeners();
  }

  void setDefaultExpiryDays(int days) {
    _defaultExpiryDays = days;
    _storageService.saveDefaultExpiryDays(days);
    notifyListeners();
  }

  void setPreferredColorSeedIndex(int index) {
    _preferredColorSeedIndex = index;
    _storageService.savePreferredColorSeed(index);
    notifyListeners();
  }

  Future<void> loadItems() async {
    _isLoading = true;
    notifyListeners();

    _items = await _storageService.loadPantryItems();
    _stores = await _storageService.loadStores();
    _locations = await _storageService.loadLocations();

    if (_stores.isEmpty) {
      _stores = ['Supermarket', 'Farmacia', 'Corner shop'];
    }
    if (_locations.isEmpty) {
      _locations = ['Pantry', 'Fridge', 'Freezer'];
    }

    // load per-location metadata (grid sizes)
    try {
      _locationMeta = await _storageService.loadLocationMeta();
    } catch (_) {
      _locationMeta = {};
    }
    _locationMeta.putIfAbsent('Pantry', () => {'rows': 5, 'columns': 5});
    _locationMeta.putIfAbsent('Fridge', () => {'rows': 8, 'columns': 1});
    _locationMeta.putIfAbsent('Freezer', () => {'rows': 3, 'columns': 1});
    for (final loc in _locations) {
      _locationMeta.putIfAbsent(loc, () => {'rows': gridRowCount, 'columns': gridColumnCount});
    }
    // persist any defaults we added
    await _storageService.saveLocationMeta(_locationMeta);

    // load settings
    try {
      _autoOpenAddAfterLookup = await _storageService.loadAutoOpenAdd();
      _autoAddWhenProductFound = await _storageService.loadAutoAddWhenProductFound();
      _profileName = await _storageService.loadProfileName();
      _defaultExpiryDays = await _storageService.loadDefaultExpiryDays();
      _preferredColorSeedIndex = await _storageService.loadPreferredColorSeed();
    } catch (_) {
      _autoOpenAddAfterLookup = false;
      _autoAddWhenProductFound = false;
      _profileName = 'My Pantry';
      _defaultExpiryDays = 14;
      _preferredColorSeedIndex = 0;
    }

    try {
      await _firebaseService.initialize();
      final signedIn = await _firebaseService.signInAnonymously();
      if (signedIn) {
        _currentUser = _firebaseService.currentUserId;
        _subscribeToRemoteItems();
      }
    } catch (_) {
      // Continue using local storage if Firebase is unavailable.
    }

    _items.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addItem(PantryItem item) async {
    final newItem = item.copyWith(
      id: _uuid.v4(),
      addedAt: DateTime.now(),
      addedBy: _currentUser,
    );
    _items.add(newItem);
    await _save();
    await _saveStoreAndLocation(newItem);
    if (_firebaseService.isSignedIn) {
      try {
        await _firebaseService.savePantryItem(newItem);
      } catch (_) {}
    }
    notifyListeners();
  }

  Future<String?> uploadItemPhoto(dynamic file, String itemId) async {
    // If not signed in, return a local path or identifier when possible.
    if (!_firebaseService.isSignedIn) {
      try {
        if (file is String) return file;
        // if it's a picked XFile or similar, try to return path if available
        final path = file?.path;
        if (path is String) return path;
      } catch (_) {}
      return null;
    }

    try {
      return await _firebaseStorageService.uploadItemPhoto(file, itemId);
    } catch (_) {
      return null;
    }
  }

  Future<void> updateItem(PantryItem item) async {
    final index = _items.indexWhere((entry) => entry.id == item.id);
    if (index < 0) return;

    _items[index] = item;
    await _save();
    await _saveStoreAndLocation(item);
    if (_firebaseService.isSignedIn) {
      try {
        await _firebaseService.savePantryItem(item);
      } catch (_) {}
    }
    notifyListeners();
  }

  Future<void> removeItem(String id) async {
    _items.removeWhere((item) => item.id == id);
    await _save();
    if (_firebaseService.isSignedIn) {
      try {
        await _firebaseService.deletePantryItem(id);
      } catch (_) {}
    }
    notifyListeners();
  }

  Future<void> clearAll() async {
    if (_firebaseService.isSignedIn) {
      for (final item in _items) {
        try {
          await _firebaseService.deletePantryItem(item.id);
        } catch (_) {}
      }
    }
    _items.clear();
    await _storageService.clearPantryItems();
    notifyListeners();
  }

  void addStore(String store) {
    final trimmed = store.trim();
    if (trimmed.isEmpty || _stores.contains(trimmed)) return;
    _stores.add(trimmed);
    _storageService.saveStores(_stores);
    notifyListeners();
  }

  Future<void> addLocation(String location) async {
    final trimmed = location.trim();
    if (trimmed.isEmpty || _locations.contains(trimmed)) return;
    _locations.add(trimmed);
    // ensure default grid metadata for the new location
    _locationMeta.putIfAbsent(trimmed, () => {'rows': gridRowCount, 'columns': gridColumnCount});
    await _storageService.saveLocations(_locations);
    await _storageService.saveLocationMeta(_locationMeta);
    notifyListeners();
  }

  /// Rename a location and migrate any items assigned to it.
  Future<void> renameLocation(String oldName, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty || oldName == trimmed) return;
    if (!_locations.contains(oldName) || _locations.contains(trimmed)) return;

    final idx = _locations.indexOf(oldName);
    if (idx >= 0) {
      _locations[idx] = trimmed;
    }

    // migrate meta
    final meta = _locationMeta.remove(oldName);
    if (meta != null) {
      _locationMeta[trimmed] = meta;
    } else {
      _locationMeta.putIfAbsent(trimmed, () => {'rows': gridRowCount, 'columns': gridColumnCount});
    }

    // update items assigned to oldName
    for (var i = 0; i < _items.length; i++) {
      if (_items[i].location == oldName) {
        _items[i] = _items[i].copyWith(location: trimmed);
      }
    }

    await _storageService.saveLocations(_locations);
    await _save();
    await _storageService.saveLocationMeta(_locationMeta);
    notifyListeners();
  }

  /// Remove a location. Items assigned to the removed location will be
  /// reassigned to the first available location (if any) or left empty.
  Future<void> removeLocation(String location) async {
    if (!_locations.contains(location)) return;
    _locations.remove(location);
    _locationMeta.remove(location);

    final fallback = _locations.isNotEmpty ? _locations.first : '';
    for (var i = 0; i < _items.length; i++) {
      if (_items[i].location == location) {
        _items[i] = _items[i].copyWith(location: fallback);
      }
    }

    await _storageService.saveLocations(_locations);
    await _save();
    await _storageService.saveLocationMeta(_locationMeta);
    notifyListeners();
  }

  void setGroupType(HomeGroupType type) {
    if (_groupType == type) return;
    _groupType = type;
    notifyListeners();
  }

  Future<void> setLocationGridSize(String location, int rows, int columns) async {
    if (!_locations.contains(location)) return;
    _locationMeta[location] = {'rows': rows, 'columns': columns};
    await _storageService.saveLocationMeta(_locationMeta);
    notifyListeners();
  }

  void setCurrentUser(String userId) {
    _currentUser = userId;
    notifyListeners();
  }

  int get totalItemCount => _items.length;

  int get expiredItemCount =>
      _items.where((item) => item.isExpired).length;

  int get expiringSoonCount =>
      _items.where((item) => item.isExpiringSoon).length;

  int get freshItemCount =>
      _items.where((item) => !item.isExpired && !item.isExpiringSoon).length;

  Map<String, int> get locationCounts {
    final counts = <String, int>{};
    for (final item in _items) {
      counts[item.location] = (counts[item.location] ?? 0) + 1;
    }
    return counts;
  }

  Map<String, List<PantryItem>> groupedItems() {
    switch (_groupType) {
      case HomeGroupType.location:
        return _groupByLocation();
      case HomeGroupType.expiry:
        return _groupByExpiry();
    }
  }

  Map<String, List<PantryItem>> get itemsByLocation => _groupByLocation();

  Map<String, List<PantryItem>> _groupByLocation() {
    final groups = <String, List<PantryItem>>{};
    for (final item in items) {
      groups.putIfAbsent(item.location, () => []).add(item);
    }
    return groups;
  }

  Map<String, List<PantryItem>> _groupByExpiry() {
    final groups = <String, List<PantryItem>>{
      'Expired': [],
      'Expiring soon': [],
      'Fresh': [],
    };

    for (final item in items) {
      if (item.isExpired) {
        groups['Expired']!.add(item);
      } else if (item.isExpiringSoon) {
        groups['Expiring soon']!.add(item);
      } else {
        groups['Fresh']!.add(item);
      }
    }

    return groups..removeWhere((key, value) => value.isEmpty);
  }

  Future<void> _save() async {
    await _storageService.savePantryItems(_items);
  }

  void _subscribeToRemoteItems() {
    _remoteSubscription?.cancel();
    _remoteSubscription = _firebaseService.pantryItemsStream().listen(
      (remoteItems) async {
        remoteItems.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
        _items = remoteItems;
        await _save();
        notifyListeners();
      },
      onError: (_) {
        // Ignore remote stream failures and keep using local data.
      },
    );
  }

  @override
  void dispose() {
    _remoteSubscription?.cancel();
    super.dispose();
  }

  Future<bool> signInAnonymously() async {
    final signedIn = await _firebaseService.signInAnonymously();
    if (signedIn) {
      _currentUser = _firebaseService.currentUserId;
      _subscribeToRemoteItems();
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> signOutFirebase() async {
    await _firebaseService.signOut();
    _remoteSubscription?.cancel();
    _currentUser = 'local_user';
    notifyListeners();
    return true;
  }

  Future<void> _saveStoreAndLocation(PantryItem item) async {
    addStore(item.store);
    await addLocation(item.location);
  }
}
