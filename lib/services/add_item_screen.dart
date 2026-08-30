import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'cloudinary_service.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  File? _selectedImage;
  String? _uploadedImageUrl;
  bool _isUploading = false;

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();

    // Let user choose camera or gallery
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Take photo'),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Choose from gallery'),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ],
      ),
    );

    if (source == null) return;

    final picked = await picker.pickImage(
      source: source,
      imageQuality: 75, // Compress before upload — saves Cloudinary bandwidth
      maxWidth: 800,
    );

    if (picked == null) return;

    setState(() {
      _selectedImage = File(picked.path);
      _isUploading = true;
    });

    final url = await CloudinaryService.uploadImage(_selectedImage!);

    setState(() {
      _uploadedImageUrl = url;
      _isUploading = false;
    });

    if (url == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo upload failed. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Photo preview + pick button
          GestureDetector(
            onTap: _pickAndUploadImage,
            child: Container(
              width: double.infinity,
              height: 200,
              color: Colors.grey[200],
              child: _isUploading
                  ? const Center(child: CircularProgressIndicator())
                  : _selectedImage != null
                      ? Image.file(_selectedImage!, fit: BoxFit.cover)
                      : const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add_a_photo, size: 48),
                              Text('Add photo'),
                            ],
                          ),
                        ),
            ),
          ),

          // Rest of your form fields go here
          // When saving the item to Firestore, use _uploadedImageUrl
        ],
      ),
    );
  }
}