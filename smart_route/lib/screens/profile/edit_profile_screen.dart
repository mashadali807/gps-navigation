import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:smart_route/core/utills/validators.dart';
import 'dart:io';

import '../../providers/auth_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/loading_widget.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;
  File? _imageFile;
  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;

    if (user != null) {
      _nameController.text = user.displayName ?? '';
      _emailController.text = user.email;
      _phoneController.text = user.phoneNumber ?? '';
      _bioController.text = user.bio ?? '';
      _imageUrl = user.photoUrl;
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to pick image: $e';
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();

      final success = await authProvider.updateProfile(
        displayName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        bio: _bioController.text.trim(),
      );

      setState(() {
        _isSaving = false;
      });

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          // Go back to profile screen
          context.go('/profile');
        }
      } else {
        setState(() {
          _error = authProvider.error ?? 'Failed to update profile';
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isSaving = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : Colors.black87,
          ),
          onPressed: () => context.go('/profile'),
        ),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(onPressed: _saveProfile, child: const Text('Save')),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Avatar
              _buildAvatar(theme, isDark),

              const SizedBox(height: AppConstants.paddingLarge),

              // Error Message
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(AppConstants.paddingMedium),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(
                      AppConstants.radiusMedium,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: AppConstants.fontSizeMedium,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              if (_error != null)
                const SizedBox(height: AppConstants.paddingMedium),

              // Name Field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  hintText: 'Enter your full name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: Validators.validateName,
              ),

              const SizedBox(height: AppConstants.paddingMedium),

              // Email Field (Read-only)
              TextFormField(
                controller: _emailController,
                enabled: false,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email_outlined),
                  hintText: 'Email cannot be changed',
                ),
              ),

              const SizedBox(height: AppConstants.paddingMedium),

              // Phone Field
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  hintText: 'Enter your phone number',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    return Validators.validatePhone(value);
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppConstants.paddingMedium),

              // Bio Field
              TextFormField(
                controller: _bioController,
                maxLines: 3,
                maxLength: 200,
                decoration: const InputDecoration(
                  labelText: 'Bio',
                  hintText: 'Tell us about yourself',
                  prefixIcon: Icon(Icons.description_outlined),
                  alignLabelWithHint: true,
                ),
              ),

              const SizedBox(height: AppConstants.paddingExtraLarge),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppConstants.radiusMedium,
                      ),
                    ),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(ThemeData theme, bool isDark) {
    return GestureDetector(
      onTap: _pickImage,
      child: Stack(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: theme.primaryColor.withOpacity(0.1),
            backgroundImage: _imageFile != null
                ? FileImage(_imageFile!)
                : _imageUrl != null
                ? NetworkImage(_imageUrl!)
                : null,
            child: _imageFile == null && _imageUrl == null
                ? Text(
                    context.read<AuthProvider>().currentUser?.initials ?? 'U',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  )
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.primaryColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? Colors.grey[900]! : Colors.white,
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
