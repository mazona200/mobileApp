// ReportProblemPage.dart
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;
import '../components/role_protected_page.dart';
import '../services/database_service.dart';
import '../services/push_notifications.dart';

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
  bool _isLoadingLocation = false;
  String _locationError = '';
  String _selectedAddress = '';
  
  List<XFile> _imageFiles = [];
  final ImagePicker _picker = ImagePicker();
  
  LocationData? _currentLocation;
  LatLng? _selectedLocation;
  final Location _location = Location();
  Set<Marker> _markers = {};
  GoogleMapController? _mapController;
  bool _mapControllerCompleted = false;
  
  // Add debouncing for map updates
  Timer? _debounceTimer;
  
  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _debounceTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }
  
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = '';
    });

    try {
      final status = await Permission.location.request();
      if (status.isPermanentlyDenied) {
        if (!mounted) return;
        _showPermissionDialog();
        return;
      }
      
      if (!status.isGranted) {
        if (mounted) {
          setState(() {
            _locationError = 'Location permission is required to report problems';
            _isLoadingLocation = false;
          });
        }
        return;
      }
      
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          if (mounted) {
            setState(() {
              _locationError = 'Location services must be enabled to report problems';
              _isLoadingLocation = false;
            });
          }
          return;
        }
      }
      
      final locationData = await _location.getLocation();
      if (mounted && locationData.latitude != null && locationData.longitude != null) {
        final position = LatLng(locationData.latitude!, locationData.longitude!);
        
        setState(() {
          _currentLocation = locationData;
          _selectedLocation = position;
          _isLoadingLocation = false;
          _selectedAddress = 'Lat: ${position.latitude.toStringAsFixed(6)}, Lng: ${position.longitude.toStringAsFixed(6)}';
        });

        _updateMarkerDebounced(position);

        // Move camera to current location only if map is ready
        if (_mapControllerCompleted && _mapController != null) {
          try {
            await _mapController!.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(target: position, zoom: 16),
              ),
            );
          } catch (e) {
            debugPrint('Camera animation error: $e');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationError = 'Error getting location: $e';
          _isLoadingLocation = false;
        });
      }
    }
  }

  void _updateMarkerDebounced(LatLng position) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        _updateMarker(position);
      }
    });
  }

  void _updateMarker(LatLng position) {
    final newMarkers = {
      Marker(
        markerId: const MarkerId('selected_location'),
        position: position,
        draggable: true,
        infoWindow: InfoWindow(
          title: 'Problem Location',
          snippet: 'Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        onDragEnd: (newPosition) {
          _onMarkerDragEnd(newPosition);
        },
      ),
    };

    // Only update if markers actually changed
    if (_markers.isEmpty || _markers.first.position != position) {
      setState(() {
        _markers = newMarkers;
      });
    }
  }

  void _onMarkerDragEnd(LatLng newPosition) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _selectedLocation = newPosition;
          _selectedAddress = 'Lat: ${newPosition.latitude.toStringAsFixed(6)}, Lng: ${newPosition.longitude.toStringAsFixed(6)}';
        });
      }
    });
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

  void _onMapTap(LatLng position) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _selectedLocation = position;
          _selectedAddress = 'Lat: ${position.latitude.toStringAsFixed(6)}, Lng: ${position.longitude.toStringAsFixed(6)}';
        });
        _updateMarker(position);
      }
    });
  }

  Future<void> _moveToCurrentLocation() async {
    if (_currentLocation != null && _mapController != null && _mapControllerCompleted) {
      final position = LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!);
      try {
        await _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: position, zoom: 16),
          ),
        );
      } catch (e) {
        debugPrint('Camera movement error: $e');
      }
    } else {
      await _getCurrentLocation();
    }
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error taking picture: $e')),
        );
      }
    }
  }
  
  Future<List<String>> _uploadImages() async {
    if (_imageFiles.isEmpty) return [];
    
    final List<String> imageUrls = [];
    final storage = FirebaseStorage.instance;
    
    for (final XFile imageFile in _imageFiles) {
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.path)}';
      final Reference storageRef = storage.ref().child('problem_reports/$fileName');
      final uploadTask = storageRef.putFile(File(imageFile.path));
      final taskSnapshot = await uploadTask;
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
      final List<String> imageUrls = await _uploadImages();
      
      final reportRef = await DatabaseService.addProblemReport(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _problemType,
        location: GeoPoint(_selectedLocation!.latitude, _selectedLocation!.longitude),
        imageUrls: imageUrls,
      );
      
      // Send push notification to government users
      final userData = await DatabaseService.getCurrentUserData();
      await PushNotificationService.notifyNewProblemReport(
        reportId: reportRef.id,
        title: _titleController.text.trim(),
        reporterName: userData?['name'] ?? 'Unknown Citizen',
        problemType: _problemType,
      );
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Problem reported successfully! Government has been notified.'),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit report: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return RoleProtectedPage(
      requiredRole: 'citizen',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Report a Problem'),
          backgroundColor: Colors.red.shade600,
          foregroundColor: Colors.white,
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
                      // Problem Type Dropdown
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Problem Type',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category),
                        ),
                        value: _problemType,
                        items: _problemTypes
                            .map((type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) setState(() => _problemType = value);
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a problem type';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Title Field
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          hintText: 'Brief description of the problem',
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
                      
                      // Description Field
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'Provide more details about the problem',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description),
                        ),
                        maxLines: 4,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a description';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      
                      // Location Section
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.red),
                          const SizedBox(width: 8),
                          const Text(
                            'Problem Location',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          if (!_isLoadingLocation)
                            IconButton(
                              onPressed: _moveToCurrentLocation,
                              icon: const Icon(Icons.my_location),
                              tooltip: 'Go to my location',
                            ),
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      const Text(
                        'Tap on the map to set the exact location or drag the red marker',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      
                      if (_selectedAddress.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.location_on, color: Colors.blue.shade600, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _selectedAddress,
                                  style: TextStyle(
                                    color: Colors.blue.shade700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 12),
                      
                      // Map Container
                      Container(
                        height: 250,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _buildMapWidget(),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Photos Section
                      Row(
                        children: [
                          const Icon(Icons.photo_camera, color: Colors.green),
                          const SizedBox(width: 8),
                          const Text(
                            'Problem Photos',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          Text(
                            '${_imageFiles.length}/5',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Add photos to help us understand the problem better',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      
                      // Photo Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _imageFiles.length < 5 ? _takePicture : null,
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Take Photo'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                backgroundColor: Colors.green.shade600,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _imageFiles.length < 5 ? _pickImage : null,
                              icon: const Icon(Icons.photo_library),
                              label: const Text('Gallery'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                backgroundColor: Colors.blue.shade600,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Selected Images
                      if (_imageFiles.isNotEmpty)
                        SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _imageFiles.length,
                            itemBuilder: (context, index) => Stack(
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(right: 12),
                                  width: 120,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(8),
                                    image: DecorationImage(
                                      image: FileImage(File(_imageFiles[index].path)),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 16,
                                  child: GestureDetector(
                                    onTap: () => setState(() => _imageFiles.removeAt(index)),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
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
                            ),
                          ),
                        ),
                      
                      const SizedBox(height: 24),
                      
                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _selectedLocation != null ? _submitReport : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            disabledBackgroundColor: Colors.grey.shade300,
                          ),
                          child: const Text(
                            'Submit Report',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildMapWidget() {
    if (_isLoadingLocation) {
      return Container(
        color: Colors.grey.shade100,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('Getting your location...'),
            ],
          ),
        ),
      );
    }

    if (_locationError.isNotEmpty) {
      return Container(
        color: Colors.red.shade50,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_off, size: 48, color: Colors.red.shade400),
              const SizedBox(height: 12),
              Text(
                'Location Error',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  _locationError,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red.shade600,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _getCurrentLocation,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_selectedLocation == null) {
      return Container(
        color: Colors.grey.shade100,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_searching, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              const Text('Waiting for location...'),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _getCurrentLocation,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: _selectedLocation!,
        zoom: 16,
      ),
      markers: _markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: false, // We have our own button
      mapToolbarEnabled: false, // Disable to reduce UI overhead
      compassEnabled: false, // Disable to reduce UI overhead
      zoomControlsEnabled: false, // Disable to reduce UI overhead
      rotateGesturesEnabled: false, // Disable to reduce UI overhead
      scrollGesturesEnabled: true,
      zoomGesturesEnabled: true,
      tiltGesturesEnabled: false, // Disable to reduce UI overhead
      onMapCreated: (controller) {
        _mapController = controller;
        _mapControllerCompleted = true;
        // Move to location if we have one
        if (_selectedLocation != null) {
          Future.delayed(const Duration(milliseconds: 100), () {
            if (_mapController != null && mounted) {
              _mapController!.animateCamera(
                CameraUpdate.newCameraPosition(
                  CameraPosition(target: _selectedLocation!, zoom: 16),
                ),
              ).catchError((e) {
                debugPrint('Initial camera animation error: $e');
              });
            }
          });
        }
      },
      onTap: _onMapTap,
      mapType: MapType.normal,
    );
  }
}