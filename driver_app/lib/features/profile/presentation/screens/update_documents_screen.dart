import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taksibu_driver/features/auth/data/vehicle_repository.dart';
import 'package:taksibu_driver/features/auth/presentation/auth_provider.dart';

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

  Future<void> _pickFile(Function(File) onPicked) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      setState(() {
        onPicked(File(result.files.single.path!));
      });
    }
  }

  Future<void> _submitRequest() async {
    // Basic validation: user must upload at least one doc? 
    // Or maybe all are required for a "Fresh Update"?
    // The user said "Update their vehicle information", usually means re-compliance.
    // Let's assume all are required to keep it simple and safe for compliance, 
    // OR allow partial if user just wants to update one.
    // Given the backend logic replaces files if sent, let's enforce AT LEAST ONE file.
    
    if (_vehicleLicenseFile == null &&
        _ibbCardFile == null &&
        _drivingLicenseFile == null &&
        _identityCardFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen en az bir belge yükleyin.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final repo = ref.read(vehicleRepositoryProvider);
      
      // We pass request_type = 'update_info'
      await repo.requestVehicleChange(
        requestType: 'update_info',
        newPlate: null, // Not changing
        newBrand: null, // Not changing
        newModel: null, // Not changing
        newVehicleType: null, // Not changing
        vehicleLicense: _vehicleLicenseFile,
        ibbCard: _ibbCardFile,
        drivingLicense: _drivingLicenseFile,
        identityCard: _identityCardFile,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Belge güncelleme talebiniz başarıyla gönderildi.')),
        );
        Navigator.pop(context); // Return to Dashboard
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
    final authState = ref.watch(authProvider);
    final user = authState.value?.user;
    
    // Safety check just in case, though likely user is logged in
    final currentPlate = user?['vehicle_plate'] ?? 'Bilinmiyor';
    final currentBrand = user?['vehicle_brand'] ?? 'Bilinmiyor';
    final currentModel = user?['vehicle_model'] ?? 'Bilinmiyor';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Belgelerimi Güncelle'),
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
                    "Mevcut Araç Bilgileri",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text("Plaka: $currentPlate"),
                  Text("Marka: $currentBrand"),
                  Text("Model: $currentModel"),
                  const SizedBox(height: 8),
                  const Text(
                    "Not: Araç bilgilerinizi değiştirmeden sadece belgelerinizi güncellemek için bu formu kullanınız.",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
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
                        'Belgeleri Gönder',
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
