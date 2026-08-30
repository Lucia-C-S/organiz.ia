# Storage Implementation Guide

This guide explains how to use the Cloud Storage setup for product photos in your Organiz.IA app.

## Overview

You now have:
1. **Authentication** - Users can sign up and sign in with email/password
2. **Cloud Storage** - Organized by product ID with support for multiple photos per product
3. **Storage Provider** - A provider class for managing photo uploads/downloads

## How to Use the Storage System

### 1. Access the Storage Provider in Your Widgets

```dart
import 'package:provider/provider.dart';
import 'package:organiz_ia/providers/storage_provider.dart';

// In your widget:
final storageProvider = Provider.of<StorageProvider>(context, listen: true);
```

### 2. Upload a Photo

```dart
Future<void> uploadPhoto(dynamic fileOrBytes, String productId, int photoIndex) async {
  final storageProvider = Provider.of<StorageProvider>(context, listen: false);
  
  final downloadUrl = await storageProvider.uploadProductPhoto(
    fileOrBytes: fileOrBytes,
    productId: productId,
    photoIndex: photoIndex,
  );
  
  if (downloadUrl != null) {
    print('Photo uploaded: $downloadUrl');
  } else if (storageProvider.errorMessage != null) {
    print('Error: ${storageProvider.errorMessage}');
  }
}
```

### 3. Get a Photo URL

```dart
Future<void> getPhotoUrl(String productId, int photoIndex) async {
  final storageProvider = Provider.of<StorageProvider>(context, listen: false);
  
  final url = await storageProvider.getProductPhotoUrl(
    productId: productId,
    photoIndex: photoIndex,
  );
  
  if (url != null) {
    // Use the URL to display the image
    Image.network(url);
  }
}
```

### 4. Display a Product Photo

```dart
FutureBuilder<String?>(
  future: Provider.of<StorageProvider>(context, listen: false)
      .getProductPhotoUrl(productId: 'product-123', photoIndex: 0),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const CircularProgressIndicator();
    }
    
    if (snapshot.hasData && snapshot.data != null) {
      return Image.network(snapshot.data!);
    }
    
    return const Text('No photo available');
  },
)
```

### 5. Get All Photos for a Product

```dart
Future<void> getProductPhotos(String productId) async {
  final storageProvider = Provider.of<StorageProvider>(context, listen: false);
  
  final photos = await storageProvider.getProductPhotos(productId: productId);
  
  for (var photoUrl in photos) {
    print('Photo: $photoUrl');
  }
}
```

### 6. Delete a Photo

```dart
Future<void> deletePhoto(String productId, int photoIndex) async {
  final storageProvider = Provider.of<StorageProvider>(context, listen: false);
  
  final success = await storageProvider.deleteProductPhoto(
    productId: productId,
    photoIndex: photoIndex,
  );
  
  if (success) {
    print('Photo deleted');
  } else {
    print('Error: ${storageProvider.errorMessage}');
  }
}
```

## Example: Photo Gallery Widget

Here's a complete example of a product photo gallery:

```dart
class ProductPhotoGallery extends StatefulWidget {
  final String productId;
  
  const ProductPhotoGallery({required this.productId, super.key});

  @override
  State<ProductPhotoGallery> createState() => _ProductPhotoGalleryState();
}

class _ProductPhotoGalleryState extends State<ProductPhotoGallery> {
  late Future<List<String>> _photosFuture;

  @override
  void initState() {
    super.initState();
    final storageProvider = 
        Provider.of<StorageProvider>(context, listen: false);
    _photosFuture = 
        storageProvider.getProductPhotos(productId: widget.productId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: _photosFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text('No photos available'),
          );
        }

        final photos = snapshot.data!;
        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: photos.length,
          itemBuilder: (context, index) {
            return Image.network(
              photos[index],
              fit: BoxFit.cover,
            );
          },
        );
      },
    );
  }
}
```

## Using ImagePicker for Photo Upload

You already have `image_picker` in your dependencies. Here's how to use it:

```dart
import 'package:image_picker/image_picker.dart';

Future<void> pickAndUploadPhoto(String productId, int photoIndex) async {
  final picker = ImagePicker();
  final pickedFile = await picker.pickImage(source: ImageSource.camera);

  if (pickedFile == null) return;

  final storageProvider = 
      Provider.of<StorageProvider>(context, listen: false);

  // For mobile, pass the File object
  final downloadUrl = await storageProvider.uploadProductPhoto(
    fileOrBytes: File(pickedFile.path),
    productId: productId,
    photoIndex: photoIndex,
  );

  if (downloadUrl != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Photo uploaded successfully')),
    );
  }
}
```

## Authentication Usage

Access the current user:

```dart
final authProvider = Provider.of<AuthProvider>(context);
print(authProvider.currentUser?.displayName);
print(authProvider.currentUser?.email);
```

Sign out:

```dart
await Provider.of<AuthProvider>(context, listen: false).signOut();
```

## File Organization

Photos are stored in Cloud Storage at:
```
gs://organiz-ia-2026.firebasestorage.app/item_photos/{productId}-photo-{photoIndex}.jpg
```

This structure:
- Makes it easy to organize photos by product
- Allows multiple photos per product (0, 1, 2, etc.)
- Keeps all photos in one folder for easy management
- Is accessible to all 3 authenticated users

## Notes

- All 3 users can see and access all product photos
- Users must be authenticated to upload/download/delete photos
- Photos are cached in the provider for better performance
- The `clearCache()` method can be called on logout to clear cached URLs
