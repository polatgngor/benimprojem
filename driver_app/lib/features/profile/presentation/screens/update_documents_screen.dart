import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driver_app/features/auth/data/vehicle_repository.dart';
import 'package:driver_app/features/auth/presentation/auth_provider.dart';
import 'package:driver_app/features/auth/presentation/widgets/otp_sheet.dart';

class UpdateDocumentsScreen extends ConsumerStatefulWidget {
  const UpdateDocumentsScreen({super.key});

  @override
  ConsumerState<UpdateDocumentsScreen> createState() => _UpdateDocumentsScreenState();
}

class _UpdateDocumentsScreenState extends ConsumerState<UpdateDocumentsScreen> {
  // Files
  File? _vehicleLicenseFile;
  File? _ibbCardFile;
  File? _drivingLicenseFile;
  File? _identityCardFile;

  bool _isLoading = false;

  // Brand/Model
  Map<String, List<String>> _vehicleData = {};
  String? _selectedBrand;
  String? _selectedModel;
  String _selectedVehicleType = 'sari'; // Default

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    // Load Vehicle Data
    try {
      final data = await ref.read(vehicleRepositoryProvider).getVehicleData();
      if (mounted) {
        final authState = ref.read(authProvider);
        final user = authState.value?['user'];
        
        setState(() {
          _vehicleData = data;
          // Pre-fill if exists
          if (user != null) {
              if (data.containsKey(user['vehicle_brand'])) {
                  _selectedBrand = user['vehicle_brand'];
                  if (data[user['vehicle_brand']]!.contains(user['vehicle_model'])) {
                      _selectedModel = user['vehicle_model'];
                  }
              }
              _selectedVehicleType = user['vehicle_type'] ?? 'sari';
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading vehicles: $e');
    }
  }

  Future<void> _pickFile(Function(File) onPicked) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      setState(() {
        onPicked(File(result.files.single.path!));
      });
    }
  }

  Future<void> _submitRequest() async {
    // Basic validation
    // Require Brand/Model selection if we are showing them
    if (_selectedBrand == null || _selectedModel == null) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen araç marka ve modelini seçiniz.')),
      );
      return;
    }

    // At least one file?? Or is it optional if just updating vehicle info?
    // Let's keep it lenient: if files are null, they won't be updated.
    // But since this is "Update Documents", maybe files are the focus?
    // User requested "vehicle update" here too. Let's allow files to be null if vehicle info is changed.

    // Get Phone Number
    final authState = ref.read(authProvider);
    final phone = authState.value?['user']?['phone'];
    
    if (phone == null) {
       ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Telefon numarası bulunamadı.'), backgroundColor: Colors.red),
       );
      return;
    }

    // Show OTP Dialog
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: OtpVerificationSheet(
          phone: phone, 
          onVerified: (code) => _performUpdate(code),
        ),
      ),
    );
  }

  Future<void> _performUpdate(String otpCode) async {
    Navigator.pop(context); // Close OTP sheet

    setState(() {
      _isLoading = true;
    });

    try {
      final repo = ref.read(vehicleRepositoryProvider);
      
      // We pass request_type = 'update_info'
      await repo.requestVehicleChange(
        requestType: 'update_info',
        otpCode: otpCode, 
        // Pass selected dropdown values
        brand: _selectedBrand!,
        model: _selectedModel!,
        vehicleType: _selectedVehicleType,
        
        vehicleLicense: _vehicleLicenseFile,
        ibbCard: _ibbCardFile,
        drivingLicense: _drivingLicenseFile,
        identityCard: _identityCardFile,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Güncelleme talebiniz başarıyla gönderildi. Onay bekleniyor.')),
        );
        // Force refresh of auth state to catch 'pending' status
        await ref.read(authProvider.notifier).build(); 
        
        if (mounted) {
           Navigator.pop(context); // Return
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... (Existing variables)
    final authState = ref.watch(authProvider);
    final user = authState.value?['user'];
    
    final currentPlate = user?['vehicle_plate'] ?? 'Bilinmiyor';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bilgilerimi Güncelle'), // Renamed
        backgroundColor: const Color(0xFF1A77F6),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Mevcut Plaka",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(currentPlate, style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  const Text(
                    "Plaka değişikliği için lütfen 'Taksi Değiştir' menüsünü kullanınız.",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text('Araç Bilgileri', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

             // Vehicle Type Dropdown
            DropdownButtonFormField<String>(
              value: _selectedVehicleType,
              decoration: InputDecoration(
                labelText: 'Araç Tipi',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: [
                DropdownMenuItem(value: 'sari', child: Text('Sarı Taksi')),
                DropdownMenuItem(value: 'turkuaz', child: Text('Turkuaz Taksi')),
                DropdownMenuItem(value: 'vip', child: Text('Siyah Taksi (VIP)')),
                DropdownMenuItem(value: '8+1', child: Text('8+1 Taksi')),
              ],
              onChanged: (v) => setState(() => _selectedVehicleType = v!),
            ),
            const SizedBox(height: 16),

             // Brand Dropdown
            DropdownButtonFormField<String>(
              value: _selectedBrand,
              decoration: InputDecoration(
                labelText: 'Araç Markası',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: _vehicleData.keys.map((brand) {
                return DropdownMenuItem(value: brand, child: Text(brand));
              }).toList(),
              onChanged: (val) => setState(() { _selectedBrand = val; _selectedModel = null; }),
               validator: (v) => v == null ? 'Lütfen marka seçiniz' : null,
            ),
            const SizedBox(height: 16),

            // Model Dropdown
            DropdownButtonFormField<String>(
              value: _selectedModel,
              decoration: InputDecoration(
                labelText: 'Araç Modeli',
                 border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: (_selectedBrand != null && _vehicleData.containsKey(_selectedBrand))
                  ? _vehicleData[_selectedBrand]!.map((model) {
                      return DropdownMenuItem(value: model, child: Text(model));
                    }).toList()
                  : [],
              onChanged: (val) => setState(() => _selectedModel = val),
              validator: (v) => v == null ? 'Lütfen model seçiniz' : null,
            ),
            
            const SizedBox(height: 32),
            
            const Text(
              'Belgeler',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            _buildFilePicker(
              label: 'Ruhsat Fotoğrafı',
              file: _vehicleLicenseFile,
              onPicked: (f) => _vehicleLicenseFile = f,
            ),
            _buildFilePicker(
              label: 'İBB Kartı',
              file: _ibbCardFile,
              onPicked: (f) => _ibbCardFile = f,
            ),
            _buildFilePicker(
              label: 'Sürücü Belgesi',
              file: _drivingLicenseFile,
              onPicked: (f) => _drivingLicenseFile = f,
            ),
            _buildFilePicker(
              label: 'Kimlik Kartı',
              file: _identityCardFile,
              onPicked: (f) => _identityCardFile = f,
            ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A77F6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Onaya Gönder',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilePicker({
    required String label,
    required File? file,
    required Function(File) onPicked,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(
            file != null ? Icons.check_circle : Icons.upload_file,
            color: file != null ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (file != null)
                  Text(
                    file.path.split('/').last,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _pickFile(onPicked),
            child: Text(file != null ? 'Değiştir' : 'Yükle'),
          ),
        ],
      ),
    );
  }
}
