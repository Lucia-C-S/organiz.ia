import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/pantry_item.dart';
import '../providers/pantry_provider.dart';

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
  final _locationController = TextEditingController();
  DateTime? _expiryDate;
  int? _gridRow;
  int? _gridColumn;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialItem;
    if (initial != null) {
      _nameController.text = initial.name;
      _brandController.text = initial.brand;
      _barcodeController.text = initial.barcode;
      _storeController.text = initial.store;
      _locationController.text = initial.location;
      _expiryDate = initial.expiryDate;
      _gridRow = initial.gridRow;
      _gridColumn = initial.gridColumn;
    } else {
      _locationController.text = widget.initialLocation ?? '';
      _gridRow = widget.initialGridRow;
      _gridColumn = widget.initialGridColumn;
    }
    _updateGridSelection();
  }

  bool get _isFreezer => _locationController.text.toLowerCase().contains('freezer');
  bool get _isFridge => _locationController.text.toLowerCase().contains('fridge');

  void _updateGridSelection() {
    if (_isFreezer) {
      _gridRow = (_gridRow != null && _gridRow! >= 1 && _gridRow! <= 3) ? _gridRow : 1;
      _gridColumn = 1;
    } else if (_isFridge) {
      _gridRow = (_gridRow != null && _gridRow! >= 1 && _gridRow! <= 8) ? _gridRow : 1;
      _gridColumn = 1;
    }
  }

  String _sectionLabel(int index) {
    if (_isFreezer) {
      return 'Drawer $index';
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
      return fridgeLabels[index] ?? 'Section $index';
    }
    return 'Row $index';
  }

  List<int> _rowOptions(PantryProvider provider) {
    if (_isFreezer) {
      return [1, 2, 3];
    }
    if (_isFridge) {
      return List<int>.generate(8, (index) => index + 1);
    }
    final location = _locationController.text.trim();
    final rowCount = location.isNotEmpty ? provider.getGridRows(location) : PantryProvider.gridRowCount;
    return List<int>.generate(rowCount, (index) => index + 1);
  }

  bool get _usesGridColumn => !_isFreezer && !_isFridge;

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _barcodeController.dispose();
    _storeController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickExpiryDate() async {
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

    final provider = context.read<PantryProvider>();
    final item = PantryItem(
      id: widget.initialItem?.id ?? '',
      name: _nameController.text.trim(),
      brand: _brandController.text.trim(),
      photoUrl: '',
      expiryDate: _expiryDate!,
      store: _storeController.text.trim(),
      location: _locationController.text.trim(),
      gridRow: _gridRow,
      gridColumn: _gridColumn,
      barcode: _barcodeController.text.trim(),
      addedBy: provider.currentUser,
      addedAt: widget.initialItem?.addedAt ?? DateTime.now(),
    );

    if (widget.initialItem == null || widget.initialItem!.id.isEmpty) {
      provider.addItem(item);
    } else {
      provider.updateItem(item);
    }

    Navigator.pop(context);
  }

  Widget _buildAutocompleteField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required List<String> options,
    String? Function(String?)? validator,
  }) {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: controller.text),
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return options;
        }
        return options.where((option) => option
            .toLowerCase()
            .contains(textEditingValue.text.toLowerCase()));
      },
      onSelected: (selection) {
        controller.text = selection;
        if (label == 'Location') {
          setState(() {
            _updateGridSelection();
          });
        }
      },
      fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: textController,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon),
          ),
          validator: validator,
          textInputAction: TextInputAction.next,
          onChanged: (value) {
            if (label == 'Location') {
              setState(() {
                _locationController.text = value;
                _updateGridSelection();
              });
            }
          },
          onFieldSubmitted: (_) => onFieldSubmitted(),
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PantryProvider>();
    final isEditing = widget.initialItem != null;
    final expiryLabel = _expiryDate == null
        ? 'Pick expiry date'
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
                TextFormField(
                  controller: _barcodeController,
                  decoration: const InputDecoration(
                    labelText: 'Barcode',
                    prefixIcon: Icon(Icons.qr_code),
                  ),
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),
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
                _buildAutocompleteField(
                  controller: _storeController,
                  label: 'Store',
                  icon: Icons.location_city,
                  options: provider.stores,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter the store name.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _buildAutocompleteField(
                  controller: _locationController,
                  label: 'Location',
                  icon: Icons.kitchen,
                  options: provider.locations,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter where you store this item.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: _gridRow,
                        decoration: InputDecoration(
                          labelText: _isFreezer
                              ? 'Drawer'
                              : _isFridge
                                  ? 'Section'
                                  : 'Grid row',
                          prefixIcon: const Icon(Icons.grid_view),
                        ),
                        items: _rowOptions(provider).map((value) {
                          return DropdownMenuItem<int>(
                            value: value,
                            child: Text(_sectionLabel(value)),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() {
                          _gridRow = value;
                          if (_usesGridColumn && _gridColumn == null) {
                            _gridColumn = 1;
                          }
                        }),
                        validator: (value) {
                          if (value == null) {
                            return 'Select a ${_isFreezer || _isFridge ? 'section' : 'row'}.';
                          }
                          return null;
                        },
                      ),
                    ),
                    if (_usesGridColumn) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: _gridColumn,
                          decoration: const InputDecoration(
                            labelText: 'Grid column',
                            prefixIcon: Icon(Icons.view_column),
                          ),
                          items: List.generate(PantryProvider.gridColumnCount, (index) {
                            final value = index + 1;
                            return DropdownMenuItem<int>(
                              value: value,
                              child: Text('Col $value'),
                            );
                          }),
                          onChanged: (value) => setState(() => _gridColumn = value),
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
                const SizedBox(height: 24),
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
}
