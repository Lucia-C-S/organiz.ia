import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../models/pantry_item.dart';
import '../providers/pantry_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/storage_provider.dart';

class AddEditItemScreen extends StatefulWidget {
  const AddEditItemScreen({
    super.key,
    this.initialItem,
    this.initialLocation,
    this.initialGridRow,
    this.initialGridColumn,
  });

  final PantryItem? initialItem;
  final String? initialLocation;
  final int? initialGridRow;
  final int? initialGridColumn;

  @override
  State<AddEditItemScreen> createState() => _AddEditItemScreenState();
}

class _AddEditItemScreenState extends State<AddEditItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _storeController = TextEditingController();
  DateTime? _expiryDate;
  int? _gridRow;
  int? _gridColumn;
  String _locationType = 'Pantry';
  String _pantryZone = 'Cupboard 1';
  int _pantryShelf = 1;
  int _pantryColumn = 1;
  String _wineCategory = '';
  String _photoUrl = '';
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialItem;
    if (initial != null) {
      _nameController.text = initial.name;
      _brandController.text = initial.brand;
      _barcodeController.text = initial.barcode;
      _storeController.text = initial.store;
      _expiryDate = initial.expiryDate;
      _photoUrl = initial.photoUrl;
      _gridRow = initial.gridRow;
      _gridColumn = initial.gridColumn;
      // If the saved location already specifies a cupboard, use it; otherwise normalize
      if (initial.location == 'Cupboard 1' || initial.location == 'Cupboard 2' || initial.location == 'Wine cellar') {
        _locationType = 'Pantry';
        _pantryZone = initial.location;
      } else {
        _locationType = _normalizeLocationType(initial.locationType.isNotEmpty ? initial.locationType : initial.location);
        _pantryZone = _parsePantryZone(initial.locationDetail) ?? 'Cupboard 1';
      }
      _pantryShelf = _parsePantryShelf(initial.locationDetail) ?? (_gridRow != null && _gridRow! >= 1 && _gridRow! <= 5 ? _gridRow! : 1);
      _pantryColumn = _parsePantryColumn(initial.locationDetail) ?? (_gridColumn != null && _gridColumn! >= 1 && _gridColumn! <= 5 ? _gridColumn! : 1);
    } else {
      _locationType = _normalizeLocationType(widget.initialLocation ?? 'Pantry');
      _gridRow = widget.initialGridRow;
      _gridColumn = widget.initialGridColumn;
      if (_isPantry) {
        _pantryShelf = _gridRow != null && _gridRow! >= 1 && _gridRow! <= 5 ? _gridRow! : 1;
        _pantryColumn = _gridColumn != null && _gridColumn! >= 1 && _gridColumn! <= 5 ? _gridColumn! : 1;
      }
    }
    _syncGridSelection();
  }

  bool get _isPantry => _locationType == 'Pantry';
  bool get _isFreezer => _locationType == 'Freezer';
  bool get _isFridge => _locationType == 'Fridge';

  void _syncGridSelection() {
    if (_isFreezer) {
      _gridRow = (_gridRow != null && _gridRow! >= 1 && _gridRow! <= 3) ? _gridRow : 1;
      _gridColumn = 1;
    } else if (_isFridge) {
      _gridRow = (_gridRow != null && _gridRow! >= 1 && _gridRow! <= 8) ? _gridRow : 1;
      _gridColumn = 1;
    } else {
      _pantryShelf = (_pantryShelf >= 1 && _pantryShelf <= 5) ? _pantryShelf : 1;
      _pantryColumn = (_pantryColumn >= 1 && _pantryColumn <= 5) ? _pantryColumn : 1;
      _gridRow = _pantryShelf;
      _gridColumn = _pantryColumn;
    }
  }

  String _normalizeLocationType(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.contains('freezer')) {
      return 'Freezer';
    }
    if (normalized.contains('fridge')) {
      return 'Fridge';
    }
    return 'Pantry';
  }

  String? _parsePantryZone(String detail) {
    final normalized = detail.toLowerCase();
    if (normalized.contains('wine cellar')) {
      return 'Wine cellar';
    }
    if (normalized.contains('cupboard 2')) {
      return 'Cupboard 2';
    }
    if (normalized.contains('cupboard 1')) {
      return 'Cupboard 1';
    }
    return null;
  }

  int? _parsePantryShelf(String detail) {
    final match = RegExp(r'shelf\s*(\d+)', caseSensitive: false).firstMatch(detail);
    return match == null ? null : int.tryParse(match.group(1)!);
  }

  int? _parsePantryColumn(String detail) {
    final match = RegExp(r'column\s*(\d+)', caseSensitive: false).firstMatch(detail);
    return match == null ? null : int.tryParse(match.group(1)!);
  }

  String _buildPantryLocationDetail() {
    if (_pantryZone == 'Wine cellar') {
      return 'Wine cellar';
    }
    return '$_pantryZone • Shelf $_pantryShelf • Column $_pantryColumn';
  }

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile == null) return;

    if (!mounted) return;

    setState(() {
      _isUploadingPhoto = true;
    });

    final storageProvider = context.read<StorageProvider>();
    final authProvider = context.read<AuthProvider>();

    // Create a unique product ID (use current timestamp + user id)
    final productId = '${authProvider.currentUserId}-${DateTime.now().millisecondsSinceEpoch}';

    final downloadUrl = await storageProvider.uploadProductPhoto(
      fileOrBytes: File(pickedFile.path),
      productId: productId,
      photoIndex: 0,
    );

    if (!mounted) return;

    setState(() {
      _isUploadingPhoto = false;
      if (downloadUrl != null) {
        _photoUrl = downloadUrl;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo uploaded successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload photo: ${storageProvider.errorMessage}')),
        );
      }
    });
  }

  void _pickExpiryDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (selected != null) {
      setState(() {
        _expiryDate = selected;
      });
    }
  }

  void _saveItem() {
    if (!_formKey.currentState!.validate() || _expiryDate == null) {
      return;
    }

    final pantryProvider = context.read<PantryProvider>();
    final authProvider = context.read<AuthProvider>();

    // Determine saved location name: for pantry, save cupboard name; for fridge/freezer use that name
    final savedLocation = _isPantry ? _pantryZone : _locationType;
    final savedLocationDetail = _pantryZone == 'Wine cellar' ? (_wineCategory.trim().isNotEmpty ? _wineCategory.trim() : 'Uncategorized') : _isPantry ? _buildPantryLocationDetail() : '';

    final item = PantryItem(
      id: widget.initialItem?.id ?? '',
      name: _nameController.text.trim(),
      brand: _brandController.text.trim(),
      photoUrl: _photoUrl,
      expiryDate: _expiryDate!,
      store: _storeController.text.trim(),
      location: savedLocation,
      locationType: _locationType,
      locationDetail: savedLocationDetail,
      gridRow: _gridRow,
      gridColumn: _gridColumn,
      barcode: _isFreezer ? '' : _barcodeController.text.trim(),
      addedBy: authProvider.currentUserDisplayName,
      addedAt: widget.initialItem?.addedAt ?? DateTime.now(),
    );

    if (widget.initialItem == null || widget.initialItem!.id.isEmpty) {
      pantryProvider.addItem(item);
    } else {
      pantryProvider.updateItem(item);
    }

    Navigator.pop(context);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _barcodeController.dispose();
    _storeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PantryProvider>();
    final isEditing = widget.initialItem != null;
    final expiryLabel = _expiryDate == null
        ? (_isFreezer ? 'Pick freezing date' : 'Pick expiry date')
        : DateFormat.yMMMMd().format(_expiryDate!);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit pantry item' : 'Add pantry item'),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Photo section at the top
                GestureDetector(
                  onTap: _isUploadingPhoto ? null : _pickAndUploadPhoto,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _isUploadingPhoto
                        ? const Center(
                            child: CircularProgressIndicator(),
                          )
                        : (_photoUrl.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  _photoUrl,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.camera_alt, size: 48, color: Colors.grey),
                                    SizedBox(height: 8),
                                    Text('Tap to add photo', style: TextStyle(color: Colors.grey)),
                                  ],
                                ),
                              )),
                  ),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: _locationType,
                  decoration: const InputDecoration(
                    labelText: 'Storage area',
                    prefixIcon: Icon(Icons.kitchen),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Pantry', child: Text('Pantry')),
                    DropdownMenuItem(value: 'Fridge', child: Text('Fridge')),
                    DropdownMenuItem(value: 'Freezer', child: Text('Freezer')),
                  ],
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _locationType = value;
                      _syncGridSelection();
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Select a storage area.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                if (_isPantry) ...[
                  DropdownButtonFormField<String>(
                    value: _pantryZone,
                    decoration: const InputDecoration(
                      labelText: 'Pantry location',
                      prefixIcon: Icon(Icons.bento),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Cupboard 1', child: Text('Cupboard 1')),
                      DropdownMenuItem(value: 'Cupboard 2', child: Text('Cupboard 2')),
                      DropdownMenuItem(value: 'Wine cellar', child: Text('Wine cellar')),
                    ],
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _pantryZone = value;
                        if (_pantryZone == 'Wine cellar') {
                          _pantryShelf = 1;
                          _pantryColumn = 1;
                        }
                        _syncGridSelection();
                      });
                    },
                  ),
                  const SizedBox(height: 14),
                ],
                if (!_isFreezer)
                  TextFormField(
                    controller: _barcodeController,
                    decoration: const InputDecoration(
                      labelText: 'Barcode (optional)',
                      prefixIcon: Icon(Icons.qr_code),
                    ),
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                  ),
                if (!_isFreezer) const SizedBox(height: 14),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Item name',
                    prefixIcon: Icon(Icons.shopping_bag),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter a name for the item.';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _brandController,
                  decoration: const InputDecoration(
                    labelText: 'Brand',
                    prefixIcon: Icon(Icons.store),
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _storeController,
                  decoration: InputDecoration(
                    labelText: _isFreezer ? 'Store (optional)' : 'Store',
                    prefixIcon: const Icon(Icons.location_city),
                  ),
                  validator: _isFreezer
                      ? null
                      : (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter the store name.';
                          }
                          return null;
                        },
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _gridRow,
                        decoration: InputDecoration(
                          labelText: _isFreezer
                              ? 'Drawer'
                              : _isFridge
                                  ? 'Section'
                                  : 'Shelf',
                          prefixIcon: const Icon(Icons.grid_view),
                        ),
                        items: _buildSelectionItems(provider),
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setState(() {
                            _gridRow = value;
                            if (_isPantry) {
                              _pantryShelf = value;
                            }
                            if (!_isPantry) {
                              _gridColumn = 1;
                            }
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Select a ${_isFreezer || _isFridge ? 'section' : 'shelf'}.';
                          }
                          return null;
                        },
                      ),
                    ),
                    if (_isPantry) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _gridColumn,
                          decoration: const InputDecoration(
                            labelText: 'Column',
                            prefixIcon: Icon(Icons.view_column),
                          ),
                          items: List.generate(5, (index) {
                            final value = index + 1;
                            return DropdownMenuItem<int>(
                              value: value,
                              child: Text('Col $value'),
                            );
                          }),
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }
                            setState(() {
                              _gridColumn = value;
                              _pantryColumn = value;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Select a column.';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 14),
                // If Wine cellar, show category dropdown
                if (_isPantry && _pantryZone == 'Wine cellar') ...[
                  Consumer<PantryProvider>(
                    builder: (context, provider, child) {
                      final categories = provider.wineCategories;
                      return Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _wineCategory.trim().isNotEmpty ? _wineCategory : (categories.isNotEmpty ? categories.first : 'Uncategorized'),
                              decoration: const InputDecoration(
                                labelText: 'Wine category',
                                prefixIcon: Icon(Icons.local_bar),
                              ),
                              items: [
                                ...categories.map((c) => DropdownMenuItem<String>(value: c, child: Text(c))),
                                if (_wineCategory.trim().isNotEmpty && !categories.contains(_wineCategory))
                                  DropdownMenuItem<String>(value: _wineCategory, child: Text(_wineCategory)),
                              ],
                              onChanged: (v) => setState(() => _wineCategory = v ?? ''),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.add),
                            tooltip: 'Add new category',
                            onPressed: () async {
                              final controller = TextEditingController();
                              final result = await showDialog<String?>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Add wine category'),
                                  content: TextField(
                                    controller: controller,
                                    decoration: const InputDecoration(hintText: 'e.g., Rosé, Natural wine'),
                                  ),
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
                                  setState(() => _wineCategory = result);
                                }
                              }
                            },
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickExpiryDate,
                        icon: const Icon(Icons.calendar_month),
                        label: Text(expiryLabel),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _expiryDate == null ? null : _saveItem,
                    child: Text(isEditing ? 'Save changes' : 'Add item'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<DropdownMenuItem<int>> _buildSelectionItems(PantryProvider provider) {
    if (_isFreezer) {
      return [1, 2, 3].map((value) => DropdownMenuItem<int>(value: value, child: Text('Drawer $value'))).toList();
    }
    if (_isFridge) {
      const fridgeLabels = {
        1: 'Shelf 1',
        2: 'Shelf 2',
        3: 'Shelf 3',
        4: 'Shelf 4',
        5: 'Shelf 5',
        6: 'Door',
        7: 'Drawer 1',
        8: 'Drawer 2',
      };
      return List<DropdownMenuItem<int>>.generate(8, (index) {
        final value = index + 1;
        return DropdownMenuItem<int>(value: value, child: Text(fridgeLabels[value] ?? 'Section $value'));
      });
    }

    final rowCount = provider.getGridRows('Pantry');
    final rc = _isPantry ? provider.getGridRows(_pantryZone) : provider.getGridRows('Pantry');
    final count = rc > 0 ? rc : 5;
    return List<DropdownMenuItem<int>>.generate(count, (index) {
      final value = index + 1;
      return DropdownMenuItem<int>(value: value, child: Text('Shelf $value'));
    });
  }
}
