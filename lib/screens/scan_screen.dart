import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../models/pantry_item.dart';
import '../providers/pantry_provider.dart';
import '../services/open_food_facts_service.dart';
import 'add_edit_item_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _barcodeController = TextEditingController();
  final _service = OpenFoodFactsService();
  final _scannerController = MobileScannerController(detectionSpeed: DetectionSpeed.noDuplicates);
  bool _isLoading = false;
  bool _scanning = false;
  String? _errorMessage;
  OpenFoodFactsProduct? _product;

  @override
  void dispose() {
    _barcodeController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _lookupBarcode() async {
    final barcode = _barcodeController.text.trim();
    if (barcode.isEmpty) {
      setState(() {
        _errorMessage = 'Enter a barcode to search.';
        _product = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _product = null;
      _scanning = false;
    });

    final provider = context.read<PantryProvider>();
    try {
      final product = await _service.lookupProduct(barcode);
      setState(() {
        _product = product;
        _errorMessage = product == null ? 'Product not found on Open Food Facts.' : null;
      });

      if (product != null) {
        // Auto-add if enabled
        if (provider.autoAddWhenProductFound) {
          await _addProductItem(product, provider);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product added to pantry')));
            setState(() {
              _product = null;
            });
          }
        } else if (provider.autoOpenAddAfterLookup) {
          // open Add screen prefilled automatically
          if (mounted) {
            await _openAddItemScreen(product, provider);
          }
        }
      }
    } catch (error) {
      setState(() {
        _errorMessage = 'Lookup failed. Check your connection.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleScanner() {
    setState(() {
      _scanning = !_scanning;
      _errorMessage = null;
      _product = null;
    });
  }

  Future<void> _openAddItemScreen(OpenFoodFactsProduct product, PantryProvider provider) async {
    final initialItem = PantryItem(
      id: '',
      name: product.name,
      brand: product.brand,
      photoUrl: product.imageUrl,
      expiryDate: DateTime.now().add(Duration(days: provider.defaultExpiryDays)),
      store: provider.stores.isNotEmpty ? provider.stores.first : '',
      location: provider.locations.isNotEmpty ? provider.locations.first : '',
      gridRow: 1,
      gridColumn: 1,
      barcode: product.barcode,
      addedBy: provider.currentUser,
      addedAt: DateTime.now(),
    );
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AddEditItemScreen(initialItem: initialItem)),
      );
    });
  }

  Future<void> _addProductItem(OpenFoodFactsProduct product, PantryProvider provider) async {
    final initialItem = PantryItem(
      id: '',
      name: product.name,
      brand: product.brand,
      photoUrl: product.imageUrl,
      expiryDate: DateTime.now().add(Duration(days: provider.defaultExpiryDays)),
      store: provider.stores.isNotEmpty ? provider.stores.first : '',
      location: provider.locations.isNotEmpty ? provider.locations.first : '',
      gridRow: 1,
      gridColumn: 1,
      barcode: product.barcode,
      addedBy: provider.currentUser,
      addedAt: DateTime.now(),
    );
    await provider.addItem(initialItem);
  }

  Future<void> _openAddWithBarcode() async {
    final barcode = _barcodeController.text.trim();
    if (barcode.isEmpty) return;

    final provider = context.read<PantryProvider>();
    final initialItem = PantryItem(
      id: '',
      name: '',
      brand: '',
      photoUrl: '',
      expiryDate: DateTime.now().add(Duration(days: provider.defaultExpiryDays)),
      store: provider.stores.isNotEmpty ? provider.stores.first : '',
      location: provider.locations.isNotEmpty ? provider.locations.first : '',
      gridRow: 1,
      gridColumn: 1,
      barcode: barcode,
      addedBy: provider.currentUser,
      addedAt: DateTime.now(),
    );
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddEditItemScreen(initialItem: initialItem)),
    );
  }

  Future<void> _onBarcodeDetected(BarcodeCapture capture) async {
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final code = barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    setState(() {
      _scanning = false;
      _barcodeController.text = code;
    });
    await _lookupBarcode();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PantryProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Scan Barcode')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _barcodeController,
                    decoration: const InputDecoration(
                      labelText: 'Barcode',
                      prefixIcon: Icon(Icons.qr_code),
                    ),
                    keyboardType: TextInputType.number,
                    onFieldSubmitted: (_) => _lookupBarcode(),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _toggleScanner,
                  icon: Icon(_scanning ? Icons.stop : Icons.camera_alt),
                  label: Text(_scanning ? 'Stop scan' : 'Scan'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_scanning)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 260,
                  child: MobileScanner(
                    controller: _scannerController,
                    onDetect: _onBarcodeDetected,
                  ),
                ),
              ),
            if (!_scanning) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _lookupBarcode,
                  icon: const Icon(Icons.search),
                  label: const Text('Lookup product'),
                ),
              ),
            ],
            const SizedBox(height: 20),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_errorMessage != null)
              Column(
                children: [
                  Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _openAddWithBarcode,
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text('Add item with this barcode'),
                  ),
                ],
              )
            else if (_product != null)
              _ProductResultCard(
                product: _product!,
                onAddItem: () {
                  _openAddItemScreen(_product!, provider);
                },
              )
            else
              const Text(
                'Enter a barcode, tap scan, or use lookup to fetch product data from Open Food Facts.',
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}

class _ProductResultCard extends StatelessWidget {
  const _ProductResultCard({required this.product, required this.onAddItem});

  final OpenFoodFactsProduct product;
  final VoidCallback onAddItem;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (product.imageUrl.isNotEmpty)
              Image.network(product.imageUrl, height: 140, fit: BoxFit.contain)
            else
              const SizedBox(height: 140, child: Icon(Icons.shopping_bag_outlined, size: 64)),
            const SizedBox(height: 12),
            Text(
              product.name.isNotEmpty ? product.name : 'Unknown product',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(product.brand.isNotEmpty ? product.brand : 'Unknown brand'),
            if (product.quantity.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Quantity: ${product.quantity}'),
            ],
            if (product.categories.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Category: ${product.categories.join(', ')}'),
            ],
            if (product.ingredientsText.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Ingredients: ${product.ingredientsText}',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onAddItem,
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('Add to pantry'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
