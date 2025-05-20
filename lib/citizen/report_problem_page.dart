import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;
import '../components/role_protected_page.dart';
import '../services/user_service.dart';
import '../services/database_service.dart';

class ReportProblemPage extends StatefulWidget {
  const ReportProblemPage({super.key});

  @override
  State<ReportProblemPage> createState() => _ReportProblemPageState();
}

class _ReportProblemPageState extends State<ReportProblemPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _problemType = 'Other';
  final List<String> _problemTypes = [
    'Street Light Issues',
    'Water Issues',
    'Road Damage',
    'Garbage Collection',
    'Public Property Damage',
    'Safety Concerns',
    'Other'
  ];
  
  bool _isSubmitting = false;
  List<XFile> _imageFiles = [];
  final ImagePicker _picker = ImagePicker();
  
  // Location data
  LocationData? _currentLocation;
  LatLng? _selectedLocation;
  final Location _location = Location();
  Set<Marker> _markers = {};
  GoogleMapController? _mapController;
  
  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _mapController?.dispose();
    super.dispose();
  }
  
  Future<void> _getCurrentLocation() async {
    try {
      // Check permissions first using permission_handler
      final status = await Permission.location.request();
      if (status.isPermanentlyDenied) {
        if (!mounted) return;
        _showPermissionDialog();
        return;
      }
      
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission is required to report problems')),
          );
        }
        return;
      }
      
      // Then check if location service is enabled
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location services must be enabled to report problems')),
            );
          }
          return;
        }
      }
      
      // Now get current location
      final locationData = await _location.getLocation();
      if (mounted) {
        setState(() {
          _currentLocation = locationData;
          _selectedLocation = LatLng(
            locationData.latitude ?? 0,
            locationData.longitude ?? 0,
          );
          
          // Add marker at current location
          _markers.add(
            Marker(
              markerId: const MarkerId('selected_location'),
              position: _selectedLocation!,
              draggable: true,
              onDragEnd: (newPosition) {
                setState(() {
                  _selectedLocation = newPosition;
                });
              },
            ),
          );
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to get location: $e')),
        );
      }
    }
  }
  
  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Location Permission Required'),
        content: const Text(
          'This app needs location permission to report problems accurately. '
          'Please enable location in app settings.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              openAppSettings();
              Navigator.pop(context);
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _pickImage() async {
    try {
      final List<XFile> selectedImages = await _picker.pickMultiImage(
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      
      if (selectedImages.isNotEmpty && mounted) {
        setState(() {
          _imageFiles.addAll(selectedImages);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }
  
  Future<void> _takePicture() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      
      if (image != null && mounted) {
        setState(() {
          _imageFiles.add(image);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error taking picture: $e')),
      );
    }
  }
  
  Future<List<String>> _uploadImages() async {
    if (_imageFiles.isEmpty) return [];
    
    final List<String> imageUrls = [];
    final storage = FirebaseStorage.instance;
    
    for (final XFile imageFile in _imageFiles) {
      // Generate a unique file name
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.path)}';
      
      // Create storage reference
      final Reference storageRef = storage.ref().child('problem_reports/$fileName');
      
      // Upload image
      final uploadTask = storageRef.putFile(File(imageFile.path));
      final taskSnapshot = await uploadTask;
      
      // Get download URL
      final downloadUrl = await taskSnapshot.ref.getDownloadURL();
      imageUrls.add(downloadUrl);
    }
    
    return imageUrls;
  }
  
  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location on the map')),
      );
      return;
    }
    
    setState(() => _isSubmitting = true);
    
    try {
      // Upload images
      final List<String> imageUrls = await _uploadImages();
      
      // Use DatabaseService to add problem report
      await DatabaseService.addProblemReport(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _problemType,
        location: GeoPoint(_selectedLocation!.latitude, _selectedLocation!.longitude),
        imageUrls: imageUrls,
      );
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Problem reported successfully!')),
      );
      
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit report: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return RoleProtectedPage(
      requiredRole: 'citizen',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Report a Problem'),
        ),
        body: _isSubmitting 
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Submitting your report...'),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Problem type dropdown
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Problem Type',
                          border: OutlineInputBorder(),
                        ),
                        value: _problemType,
                        items: _problemTypes.map((type) => 
                          DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          ),
                        ).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _problemType = value);
                          }
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a problem type';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Title field
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          hintText: 'Brief description of the problem',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Description field
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'Provide more details about the problem',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 4,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a description';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Location section
                      const Text(
                        'Problem Location',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tap to set the exact location or drag the marker',
                        style: TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      
                      // Map container
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: _selectedLocation == null
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'Waiting for location...',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    const SizedBox(height: 12),
                                    const CircularProgressIndicator(),
                                    const SizedBox(height: 12),
                                    TextButton.icon(
                                      onPressed: _getCurrentLocation,
                                      icon: const Icon(Icons.refresh),
                                      label: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: GoogleMap(
                                  initialCameraPosition: CameraPosition(
                                    target: _selectedLocation!,
                                    zoom: 15,
                                  ),
                                  markers: _markers,
                                  myLocationEnabled: true,
                                  myLocationButtonEnabled: true,
                                  mapToolbarEnabled: true,
                                  compassEnabled: true,
                                  zoomControlsEnabled: true,
                                  onMapCreated: (controller) {
                                    _mapController = controller;
                                  },
                                  onTap: (position) {
                                    setState(() {
                                      _selectedLocation = position;
                                      _markers = {
                                        Marker(
                                          markerId: const MarkerId('selected_location'),
                                          position: position,
                                          draggable: true,
                                          onDragEnd: (newPosition) {
                                            setState(() {
                                              _selectedLocation = newPosition;
                                            });
                                          },
                                        ),
                                      };
                                    });
                                  },
                                ),
                              ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Photos section
                      const Text(
                        'Problem Photos',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Photo action buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _takePicture,
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Take Photo'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _pickImage,
                              icon: const Icon(Icons.photo_library),
                              label: const Text('Gallery'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Image preview grid
                      if (_imageFiles.isNotEmpty) ...[
                        SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _imageFiles.length,
                            itemBuilder: (context, index) {
                              return Stack(
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    width: 120,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(8),
                                      image: DecorationImage(
                                        image: FileImage(File(_imageFiles[index].path)),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 12,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _imageFiles.removeAt(index);
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      // Submit button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submitReport,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'Submit Report',
                            style: TextStyle(fontSize: 16),
                          ),
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