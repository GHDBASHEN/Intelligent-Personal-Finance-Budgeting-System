import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../providers/currency_state_provider.dart';
import '../../providers/infrastructure_providers.dart';
import '../../widgets/custom_app_bar.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  late TextEditingController _phoneController;
  String? _selectedCurrency;
  bool _isUploading = false;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _usernameController = TextEditingController(text: user?.username ?? '');
    _phoneController = TextEditingController(text: user?.phoneNumber ?? '');
    _selectedCurrency = user?.preferredCurrency;
    _profileImageUrl = user?.profileImageUrl;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      
      if (pickedFile != null) {
        setState(() => _isUploading = true);
        
        final user = ref.read(authProvider).user;
        if (user == null || user.id == null) {
          throw Exception('User not authenticated or ID missing');
        }
        
        final cloudinaryService = ref.read(cloudinaryServiceProvider);
        final imageUrl = await cloudinaryService.uploadProfileImage(
          File(pickedFile.path), 
          user.id!,
        );
        
        if (imageUrl != null) {
          setState(() {
            _profileImageUrl = imageUrl;
            _isUploading = false;
          });
        } else {
          throw Exception('Failed to get image URL from Cloudinary');
        }
      }
    } catch (e) {
      setState(() => _isUploading = false);
      debugPrint('Upload error: $e');
      
      if (mounted) {
        String errorMessage = 'Failed to upload image. Please check your connection and try again.';
        if (e.toString().contains('permission')) {
          errorMessage = 'Unable to access storage. Please grant permission to upload photos.';
        } else if (e.toString().contains('network')) {
          errorMessage = 'Network issue. Please check your internet connection.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isUploading = true);
    
    try {
      await ref.read(authProvider.notifier).updateUserProfile(
        username: _usernameController.text.trim(),
        profileImageUrl: _profileImageUrl,
        preferredCurrency: _selectedCurrency,
        phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      );
      
      if (_selectedCurrency != null && _selectedCurrency != ref.read(currencyStateProvider).targetCurrency) {
        ref.read(currencyStateProvider.notifier).setTargetCurrency(_selectedCurrency!);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final currencyState = ref.watch(currencyStateProvider);
    final availableCurrencies = currencyState.rates.keys.toList()..sort();
    
    return Scaffold(
      appBar: const CustomAppBar(title: 'Profile'),
      body: authState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.grey.shade200,
                              backgroundImage: _profileImageUrl != null
                                  ? NetworkImage(_profileImageUrl!)
                                  : null,
                              child: _profileImageUrl == null && !_isUploading
                                  ? Icon(
                                      Icons.person,
                                      size: 60,
                                      color: Colors.grey.shade400,
                                    )
                                  : null,
                            ),
                          ),
                          if (_isUploading)
                            const Positioned.fill(
                              child: CircleAvatar(
                                radius: 60,
                                backgroundColor: Colors.black54,
                                child: CircularProgressIndicator(),
                              ),
                            ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                                onPressed: _isUploading ? null : _pickImage,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 40,
                                  minHeight: 40,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Email Address',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.email, size: 20, color: Colors.grey),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    user?.email ?? '',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Email cannot be changed',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: 'Username',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a username';
                        }
                        if (value.length < 3) {
                          return 'Username must be at least 3 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: 'Phone Number (Optional)',
                        prefixIcon: const Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        helperText: 'Enter your phone number for recovery',
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    
                    DropdownButtonFormField<String>(
                      value: _selectedCurrency,
                      decoration: InputDecoration(
                        labelText: 'Preferred Currency',
                        prefixIcon: const Icon(Icons.currency_exchange),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: availableCurrencies.map((currency) {
                        return DropdownMenuItem(
                          value: currency,
                          child: Text(currency),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCurrency = value;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    ElevatedButton(
                      onPressed: authState.isLoading || _isUploading ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: authState.isLoading || _isUploading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Save Changes',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}