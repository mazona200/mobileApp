import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/advertisement.dart';

class AdForm extends StatefulWidget {
  final Advertisement? advertisement;
  final Function({
    required String title,
    required String description,
    required File image,
    required String category,
    String? businessLocation,
  }) onSubmit;
  final bool isLoading;

  const AdForm({
    super.key,
    this.advertisement,
    required this.onSubmit,
    this.isLoading = false,
  });

  @override
  State<AdForm> createState() => _AdFormState();
}

class _AdFormState extends State<AdForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _businessLocationController = TextEditingController();
  String _selectedCategory = 'food';
  File? _image;
  String? _errorMessage;

  final List<String> _categories = [
    'food',
    'services',
    'sales',
    'real_estate',
    'jobs',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.advertisement != null) {
      _titleController.text = widget.advertisement!.title;
      _descriptionController.text = widget.advertisement!.description;
      _businessLocationController.text = widget.advertisement!.businessLocation ?? '';
      _selectedCategory = widget.advertisement!.category;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _businessLocationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to pick image: ${e.toString()}';
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_image == null && widget.advertisement == null) {
      setState(() {
        _errorMessage = 'Please select an image';
      });
      return;
    }

    widget.onSubmit(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      image: _image ?? File(widget.advertisement!.imageUrl),
      category: _selectedCategory,
      businessLocation: _businessLocationController.text.trim().isEmpty
          ? null
          : _businessLocationController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.title),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a title';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.description),
            ),
            maxLines: 3,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a description';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.category),
            ),
            items: _categories.map((category) {
              return DropdownMenuItem(
                value: category,
                child: Text(category.replaceAll('_', ' ').toUpperCase()),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedCategory = value;
                });
              }
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _businessLocationController,
            decoration: const InputDecoration(
              labelText: 'Business Location (Optional)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.location_on),
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _pickImage,
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _image != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        _image!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    )
                  : widget.advertisement != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            widget.advertisement!.imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        )
                      : const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate,
                                size: 50,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Tap to select image',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
            ),
          ),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                _errorMessage!,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: widget.isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: widget.isLoading
                ? const CircularProgressIndicator()
                : Text(widget.advertisement == null ? 'Create Ad' : 'Update Ad'),
          ),
        ],
      ),
    );
  }
} 