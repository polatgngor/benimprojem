import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../auth/data/auth_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../rides/data/ride_repository.dart';

final driverProfileProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final authService = ref.read(authServiceProvider);
  return authService.getProfile();
});

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  bool _isLoading = false;
  bool _hasChanges = false;
  bool _isDataInitialized = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    
    _firstNameController.addListener(_checkForChanges);
    _lastNameController.addListener(_checkForChanges);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  void _checkForChanges() {
    final asyncData = ref.read(driverProfileProvider);
    if (!asyncData.hasValue) return;
    
    final user = asyncData.value!['user'];
    final originalFirst = user['first_name'] ?? '';
    final originalLast = user['last_name'] ?? '';

    final newFirst = _firstNameController.text.trim();
    final newLast = _lastNameController.text.trim();
    
    setState(() {
      _hasChanges = (newFirst != originalFirst || newLast != originalLast) && 
                    newFirst.isNotEmpty && 
                    newLast.isNotEmpty;
    });
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    try {
      final newFirst = _firstNameController.text.trim();
      final newLast = _lastNameController.text.trim();
      
      await ref.read(authServiceProvider).updateProfile(
        firstName: newFirst,
        lastName: newLast,
      );
      
      // Refresh profile data
      ref.invalidate(driverProfileProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('profile.updated'.tr())),
        );
        setState(() => _hasChanges = false);
        // We set _isDataInitialized to false to allow re-syncing with new data if needed,
        // but better to keep it true and just let the refresh happen naturally.
        // Actually, if we invalidate, the provider rebuilds, 'data' updates. 
        // We might want to update our controllers to match exactly what server returned purely for consistency,
        // but they should already match what we sent.
        // Let's reset initialization flag to be safe so it pulls fresh from server response.
        _isDataInitialized = false; 
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('profile.error'.tr(args: [e.toString()]))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() => _isLoading = true);
      try {
        final File imageFile = File(pickedFile.path);
        // Use authService to upload
        await ref.read(authServiceProvider).uploadProfilePhoto(imageFile);
        
        // Refresh profile data
        ref.invalidate(driverProfileProvider);
        
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('profile.updated'.tr())),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('profile.error'.tr(args: [e.toString()]))),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(driverProfileProvider);
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('profile.title'.tr()),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: profileAsync.when(
        data: (data) {
          final user = data['user'];
          final driver = data['driver'];
          
          if (user == null) return const Center(child: Text('Kullanıcı bilgisi bulunamadı'));

          // Initialize controllers once
          if (!_isDataInitialized) {
             _firstNameController.text = user['first_name'] ?? '';
             _lastNameController.text = user['last_name'] ?? '';
             _isDataInitialized = true;
          }

          final profilePhoto = user['profile_photo'];

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 10),
              Center(
                child: GestureDetector(
                  onTap: _pickAndUploadImage,
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: (profilePhoto != null && profilePhoto.isNotEmpty)
                              ? Image.network(
                                  profilePhoto.startsWith('http') ? profilePhoto : '${AppConstants.baseUrl}/$profilePhoto',
                                  fit: BoxFit.cover,
                                  width: 100,
                                  height: 100,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Center(child: Icon(Icons.error, color: Colors.grey[400])),
                                )
                              : Center(
                                  child: Text(
                                    user['first_name'] != null ? user['first_name'][0].toUpperCase() : 'S',
                                    style: TextStyle(fontSize: 40, color: primaryColor, fontWeight: FontWeight.bold),
                                  ),
                                ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.edit, size: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

               // --- Personal Info Section ---
              Text(
                'profile.personal_info'.tr(),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              // Inline Editing Fields
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _firstNameController,
                      label: 'profile.first_name'.tr(),
                      icon: Icons.person_outline,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _lastNameController,
                      label: 'profile.last_name'.tr(),
                      icon: Icons.person_outline,
                    ),
                  ),
                ],
              ),
              
               // Save Button
              AnimatedCrossFade(
                firstChild: Container(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                       onPressed: _isLoading ? null : _saveProfile,
                       style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text('profile.save_changes'.tr()),
                    ),
                  ),
                ),
                crossFadeState: _hasChanges ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 300),
              ),

              const SizedBox(height: 24),
              const SizedBox(height: 24),
              _buildInfoTile('profile.reference_code'.tr(), user['ref_code'] ?? '-', Icons.share_outlined, context),
              _buildInfoTile(
                'profile.plate'.tr(), 
                driver?['vehicle_plate'] ?? '-', 
                Icons.directions_car_outlined,
                context,
                onEdit: () => _showUpdatePlateDialog(context, ref, driver?['vehicle_plate']),
              ),
              _buildInfoTile('profile.vehicle_type'.tr(), driver?['vehicle_type'] ?? '-', Icons.category_outlined, context),
              if (driver?['working_region'] != null)
                 _buildInfoTile('profile.working_region'.tr(), '${driver?['working_region']} / ${driver?['working_district'] ?? '-'}', Icons.map_outlined, context),

              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 20),
              
              // --- Security Section ---
              Text(
                'profile.security'.tr(),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              _buildReadOnlyField(
                 label: 'profile.phone'.tr(),
                 value: user['phone'] ?? '-',
                 actionLabel: 'profile.change'.tr(),
                 onAction: () => context.push('/profile/change-phone'),
                 icon: Icons.phone_android,
                 context: context
              ),
              
              const SizedBox(height: 16),

              _buildActionTile(
                context,
                'profile.change_password'.tr(),
                Icons.lock_outline,
                Colors.black87,
                () => context.push('/profile/change-password'),
              ),
              
              const SizedBox(height: 32),

              _buildActionTile(
                context,
                'profile.delete_account'.tr(),
                Icons.delete_outline,
                Colors.red,
                () => _showDeleteAccountDialog(context, ref),
              ),
              const SizedBox(height: 40),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Hata: $err')),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20, color: Colors.grey[600]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
  
   Widget _buildReadOnlyField({
    required String label,
    required String value,
    required String actionLabel,
    required VoidCallback onAction,
    required IconData icon,
    required BuildContext context,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 22),
          const SizedBox(width: 16),
          Expanded(
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                 Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
               ],
             ),
          ),
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              actionLabel,
              style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon, BuildContext context, {VoidCallback? onEdit}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          if (onEdit != null)
            IconButton(
              icon: Icon(Icons.edit_outlined, color: Colors.grey[600], size: 20),
              onPressed: onEdit,
              splashRadius: 24,
            )
        ],
      ),
    );
  }

   Widget _buildActionTile(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 16)),
      trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey[400]),
      onTap: onTap,
    );
  }

  void _showUpdatePlateDialog(BuildContext context, WidgetRef ref, String? currentPlate) {
    final controller = TextEditingController(text: currentPlate);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('profile.update_plate'.tr()),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: 'profile.new_plate'.tr()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('profile.cancel'.tr(), style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref.read(driverRideRepositoryProvider).updatePlate(controller.text.trim());
                ref.refresh(driverProfileProvider);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('profile.plate_updated'.tr())),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('profile.error'.tr(args: [e.toString()]))),
                  );
                }
              }
            },
            child: Text('profile.save'.tr()),
          ),
        ],
      ),
    );
  }
  
  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('profile.delete_account'.tr()),
        content: Text(
          'profile.delete_account_confirm'.tr(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('profile.cancel'.tr(), style: const TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(authServiceProvider).deleteAccount();
                if (context.mounted) {
                  context.go('/login');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('profile.deleted'.tr())),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('profile.error'.tr(args: [e.toString()]))),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('profile.delete'.tr()),
          ),
        ],
      ),
    );
  }
}
