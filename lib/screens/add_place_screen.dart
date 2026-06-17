import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../config/app_constants.dart';
import '../models/restaurant_model.dart';
import '../providers/auth_provider.dart';
import '../providers/restaurant_provider.dart';
import '../utils/validators.dart';
import '../widgets/app_text_field.dart';
import '../widgets/primary_button.dart';

class AddPlaceScreen extends StatefulWidget {
  const AddPlaceScreen({
    super.key,
    this.restaurant,
  });

  final RestaurantModel? restaurant;

  bool get isEditing => restaurant != null;

  @override
  State<AddPlaceScreen> createState() => _AddPlaceScreenState();
}

class _AddPlaceScreenState extends State<AddPlaceScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _cuisineController;
  late final TextEditingController _phoneController;

  late String _selectedType;
  late List<String> _selectedImagePaths;

  @override
  void initState() {
    super.initState();
    final RestaurantModel? restaurant = widget.restaurant;
    _nameController = TextEditingController(text: restaurant?.name ?? '');
    _addressController = TextEditingController(text: restaurant?.address ?? '');
    _descriptionController = TextEditingController(
      text: restaurant?.description ?? '',
    );
    _cuisineController = TextEditingController(text: restaurant?.cuisine ?? '');
    _phoneController = TextEditingController(text: restaurant?.phone ?? '');
    _selectedType = restaurant?.placeType ?? AppConstants.restaurantTypeRestaurant;
    _selectedImagePaths = restaurant?.imagePaths.toList() ?? <String>[];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _cuisineController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImagesFromGallery() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isEmpty || !mounted) {
        return;
      }

      setState(() {
        // Keep unique file paths only so the preview stays clean.
        _selectedImagePaths = <String>{
          ..._selectedImagePaths,
          ...images.map((XFile image) => image.path),
        }.toList();
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to pick images: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    }
  }

  Future<void> _captureImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
      );

      if (image == null || !mounted) {
        return;
      }

      setState(() {
        if (!_selectedImagePaths.contains(image.path)) {
          _selectedImagePaths = <String>[..._selectedImagePaths, image.path];
        }
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to open the camera: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    }
  }

  Future<void> _removeImage(String imagePath) async {
    setState(() {
      _selectedImagePaths = _selectedImagePaths
          .where((String path) => path != imagePath)
          .toList();
    });
  }

  Future<void> _submit() async {
    try {
      if (!_formKey.currentState!.validate()) {
        return;
      }

      if (_nameController.text.trim().isEmpty ||
          _addressController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppConstants.addPlaceValidationMessage),
          ),
        );
        return;
      }

      final int? userId = context.read<AuthProvider>().currentUser?.id;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in before adding a place.')),
        );
        return;
      }

      // Keep existing saved coordinates when editing, otherwise fall back to app defaults.
      final double latitude =
          widget.restaurant?.latitude ?? AppConstants.defaultLatitude;
      final double longitude =
          widget.restaurant?.longitude ?? AppConstants.defaultLongitude;

      final RestaurantProvider restaurantProvider =
          context.read<RestaurantProvider>();
      final String serializedImagePaths =
          _selectedImagePaths.join(RestaurantModel.imagePathSeparator);

      final bool success = widget.isEditing
          ? await restaurantProvider.updatePlace(
              userId: userId,
              restaurant: widget.restaurant!.copyWith(
                name: _nameController.text.trim(),
                address: _addressController.text.trim(),
                placeType: _selectedType,
                description: _descriptionController.text.trim(),
                cuisine: _cuisineController.text.trim(),
                phone: _phoneController.text.trim(),
                imagePath: serializedImagePaths,
                latitude: latitude,
                longitude: longitude,
              ),
            )
          : await restaurantProvider.addPlace(
              userId: userId,
              name: _nameController.text.trim(),
              address: _addressController.text.trim(),
              placeType: _selectedType,
              description: _descriptionController.text.trim(),
              cuisine: _cuisineController.text.trim(),
              phone: _phoneController.text.trim(),
              imagePath: serializedImagePaths,
              latitude: latitude,
              longitude: longitude,
            );

      if (!mounted) {
        return;
      }

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              restaurantProvider.errorMessage ?? 'Unable to save this place.',
            ),
          ),
        );
        return;
      }

      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditing
                ? 'Place updated successfully.'
                : 'Place added successfully.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final RestaurantProvider restaurantProvider =
        context.watch<RestaurantProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Place' : 'Add Place'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: <Widget>[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        widget.isEditing
                            ? 'Update your shared place'
                            : 'Share a new community pick',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add a restaurant or cafe with an address, optional details, and a gallery photo.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 20),
                      AppTextField(
                        controller: _nameController,
                        labelText: 'Name',
                        hintText: 'Le Petit Cafe',
                        prefixIcon: Icons.storefront_outlined,
                        validator: Validators.validateRequiredPlaceName,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedType,
                        decoration: const InputDecoration(
                          labelText: 'Type',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        items: AppConstants.supportedPlaceTypes
                            .map(
                              (String type) => DropdownMenuItem<String>(
                                value: type,
                                child: Text(type),
                              ),
                            )
                            .toList(),
                        onChanged: (String? value) {
                          setState(() {
                            _selectedType =
                                value ?? AppConstants.restaurantTypeRestaurant;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _addressController,
                        labelText: 'Address',
                        hintText: '12 Rue de Paris',
                        prefixIcon: Icons.location_on_outlined,
                        validator: Validators.validateRequiredAddress,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _descriptionController,
                        labelText: 'Description',
                        hintText: 'Cozy spot with outdoor seating',
                        prefixIcon: Icons.notes_rounded,
                        validator: Validators.validateOptionalDescription,
                        maxLines: 4,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _cuisineController,
                        labelText: 'Cuisine',
                        hintText: 'French, brunch, bakery...',
                        prefixIcon: Icons.restaurant_outlined,
                        validator: Validators.validateOptionalCuisine,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _phoneController,
                        labelText: 'Phone',
                        hintText: '+33 1 23 45 67 89',
                        keyboardType: TextInputType.phone,
                        prefixIcon: Icons.phone_outlined,
                        validator: Validators.validateOptionalPhone,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Images',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      if (_selectedImagePaths.isEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            width: double.infinity,
                            height: 180,
                            color: const Color(0xFFF1EEE3),
                            child: const Center(
                              child: Icon(
                                Icons.image_outlined,
                                size: 48,
                              ),
                            ),
                          ),
                        )
                      else
                        SizedBox(
                          height: 180,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _selectedImagePaths.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 12),
                            itemBuilder: (BuildContext context, int index) {
                              final String imagePath = _selectedImagePaths[index];
                              return Stack(
                                children: <Widget>[
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(18),
                                    child: Container(
                                      width: 220,
                                      height: 180,
                                      color: const Color(0xFFF1EEE3),
                                      child: Image.file(
                                        File(imagePath),
                                        fit: BoxFit.cover,
                                        errorBuilder: (
                                          BuildContext context,
                                          Object error,
                                          StackTrace? stackTrace,
                                        ) {
                                          return const Center(
                                            child: Icon(
                                              Icons.broken_image_outlined,
                                              size: 48,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 10,
                                    right: 10,
                                    child: Material(
                                      color: Colors.black54,
                                      shape: const CircleBorder(),
                                      child: IconButton(
                                        onPressed: () => _removeImage(imagePath),
                                        icon: const Icon(
                                          Icons.close_rounded,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: <Widget>[
                          ElevatedButton.icon(
                            onPressed: _pickImagesFromGallery,
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text('Choose from Gallery'),
                          ),
                          OutlinedButton.icon(
                            onPressed: _captureImageFromCamera,
                            icon: const Icon(Icons.photo_camera_outlined),
                            label: const Text('Take Photo'),
                          ),
                          if (_selectedImagePaths.isNotEmpty)
                            OutlinedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _selectedImagePaths = <String>[];
                                });
                              },
                              icon: const Icon(Icons.delete_outline_rounded),
                              label: const Text('Remove All'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      PrimaryButton(
                        label: widget.isEditing ? 'Save Changes' : 'Share Place',
                        icon: widget.isEditing
                            ? Icons.save_rounded
                            : Icons.add_location_alt_rounded,
                        isLoading: restaurantProvider.isSubmitting,
                        onPressed: _submit,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
