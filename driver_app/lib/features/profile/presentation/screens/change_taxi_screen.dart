import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import '../../../auth/data/vehicle_repository.dart';
import '../../../auth/presentation/auth_provider.dart';
import '../../../auth/data/auth_service.dart';
import 'package:driver_app/features/auth/presentation/widgets/otp_sheet.dart';

class ChangeTaxiScreen extends ConsumerStatefulWidget {
  const ChangeTaxiScreen({super.key});

  @override
  ConsumerState<ChangeTaxiScreen> createState() => _ChangeTaxiScreenState();
}

class _ChangeTaxiScreenState extends ConsumerState<ChangeTaxiScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Plate
  final _plateMiddleController = TextEditingController();
  final _plateSuffixController = TextEditingController();
  String _selectedPlateCity = '34';
  
  // Brand/Model
  Map<String, List<String>> _vehicleData = {};
  String? _selectedBrand;
  String? _selectedModel;
  String _selectedVehicleType = 'sari';

  // Files
  File? _vehicleLicense;
  File? _ibbCard;
  File? _drivingLicense;
  File? _identityCard;

  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  final List<String> _cityCodes = ['34', '06', '35', '07', '16', '41', '59'];

  @override
  void initState() {
    super.initState();
    _loadVehicleData();
  }

  Future<void> _loadVehicleData() async {
    try {
      final data = await ref.read(vehicleRepositoryProvider).getVehicleData();
      if (mounted) {
        setState(() {
          _vehicleData = data;
        });
      }
    } catch (e) {
      debugPrint('Error loading vehicles: $e');
    }
  }

  Future<void> _pickImage(String type) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      setState(() {
        switch (type) {
          case 'vehicle': _vehicleLicense = File(image.path); break;
          case 'ibb': _ibbCard = File(image.path); break;
          case 'driving': _drivingLicense = File(image.path); break;
          case 'identity': _identityCard = File(image.path); break;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Validate Files
    if (_vehicleLicense == null || _ibbCard == null || _drivingLicense == null || _identityCard == null) {
       ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lütfen tüm belgeleri yükleyiniz.'), backgroundColor: Colors.red),
       );
       return;
    }

    // Get Phone Number
    final authState = ref.read(authProvider); // Using read to get current value
    final phone = authState.value?['user']?['phone'];
    
    if (phone == null) {
       ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Telefon numarası bulunamadı.'), backgroundColor: Colors.red),
       );
      return;
    }

    // Show OTP Dialog
    _showOtpDialog(phone);
  }

  void _showOtpDialog(String phone) {
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
    Navigator.pop(context); // Close sheet
    
    String fullPlate;
    if (_selectedPlateCity == '34') {
       fullPlate = '$_selectedPlateCity ${_plateMiddleController.text.toUpperCase()} ${_plateSuffixController.text}';
    } else {
       fullPlate = '$_selectedPlateCity T ${_plateMiddleController.text}';
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(vehicleRepositoryProvider).requestVehicleChange(
        requestType: 'change_taxi',
        otpCode: otpCode, // Send Verified Code
        plate: fullPlate,
        brand: _selectedBrand!,
        model: _selectedModel!,
        vehicleType: _selectedVehicleType,
        vehicleLicense: _vehicleLicense,
        ibbCard: _ibbCard,
        drivingLicense: _drivingLicense,
        identityCard: _identityCard,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Talebiniz başarıyla gönderildi.')),
        );
        // Refresh auth to catch pending status
        // Await the new state to ensure router picks it up
        await ref.refresh(authProvider.future);
        
        // No need to pop manually if router redirects to /pending
        // But if router fails, we might want to pop or show something.
        // Actually, if status is pending, router will force redirect.
        // If we pop, we might go to profile, then router redirects.
        // Let's just pop to be safe against non-redirect cases, but await first.
        if (mounted) {
           // Check if we are still active (not redirected)
           if (ModalRoute.of(context)?.isCurrent ?? false) {
              context.pop(); 
           }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Taksi Değiştir'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
               const Text(
                 'Yeni Aracınızın Bilgileri',
                 style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
               ),
               const SizedBox(height: 8),
               Text(
                 'Bu işlem yönetici onayı gerektirir. Onaylanana kadar mevcut aracınızla çalışmaya devam edebilirsiniz.',
                 style: TextStyle(color: Colors.grey[600]),
               ),
               const SizedBox(height: 24),

               // Plate Input
                const Text('Plaka', style: TextStyle(fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 80,
                      child: DropdownButtonFormField<String>(
                        value: _selectedPlateCity,
                        items: _cityCodes.map((code) => DropdownMenuItem(value: code, child: Text(code))).toList(),
                        onChanged: (val) {
                           setState(() {
                             _selectedPlateCity = val!;
                             _plateMiddleController.clear();
                             _plateSuffixController.clear();
                           });
                        },
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_selectedPlateCity == '34') ...[
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _plateMiddleController,
                          decoration: InputDecoration(
                            hintText: 'ABC',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            counterText: "",
                          ),
                          maxLength: 3,
                          textCapitalization: TextCapitalization.characters,
                          validator: (v) => (v?.isEmpty ?? true) ? '!' : null,
                        ),
                      ),
                       const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _plateSuffixController,
                          decoration: InputDecoration(
                            hintText: '123',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            counterText: "",
                          ),
                          keyboardType: TextInputType.number,
                          maxLength: 4,
                          validator: (v) => (v?.isEmpty ?? true) ? '!' : null,
                        ),
                      ),
                    ] else ...[
                       Container(
                         height: 58,
                         width: 50,
                         alignment: Alignment.center,
                         decoration: BoxDecoration(
                           color: Colors.grey[200],
                           borderRadius: BorderRadius.circular(8),
                           border: Border.all(color: Colors.grey)
                         ),
                         child: const Text('T', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                       ),
                       const SizedBox(width: 8),
                       Expanded(
                        child: TextFormField(
                          controller: _plateMiddleController, 
                          decoration: InputDecoration(
                            hintText: '1234',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            counterText: '',
                          ),
                          keyboardType: TextInputType.number,
                          maxLength: 5,
                          validator: (v) => (v?.isEmpty ?? true) ? '!' : null,
                        ),
                      ),
                    ],
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Brand Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedBrand,
                  decoration: InputDecoration(
                    labelText: 'Araç Markası',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
                     border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: (_selectedBrand != null && _vehicleData.containsKey(_selectedBrand))
                      ? _vehicleData[_selectedBrand]!.map((model) {
                          return DropdownMenuItem(value: model, child: Text(model));
                        }).toList()
                      : [],
                  onChanged: (val) => setState(() => _selectedModel = val),
                  validator: (v) => v == null ? 'Lütfen model seçiniz' : null,
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: _selectedVehicleType,
                  decoration: InputDecoration(labelText: 'Araç Tipi'),
                  items: [
                    DropdownMenuItem(value: 'sari', child: Text('Sarı Taksi')),
                    DropdownMenuItem(value: 'turkuaz', child: Text('Turkuaz Taksi')),
                    DropdownMenuItem(value: 'vip', child: Text('Siyah Taksi (VIP)')),
                    DropdownMenuItem(value: '8+1', child: Text('8+1 Taksi')),
                  ],
                  onChanged: (v) => setState(() => _selectedVehicleType = v!),
                ),

                const SizedBox(height: 32),
                const Text('Belgeler', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                _buildUploadButton('Araç Ruhsatı', _vehicleLicense, () => _pickImage('vehicle')),
                const SizedBox(height: 12),
                _buildUploadButton('İBB Çalışma Ruhsatı', _ibbCard, () => _pickImage('ibb')),
                const SizedBox(height: 12),
                _buildUploadButton('Sürücü Belgesi', _drivingLicense, () => _pickImage('driving')),
                const SizedBox(height: 12),
                _buildUploadButton('Kimlik Kartı', _identityCard, () => _pickImage('identity')),

                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text('Onaya Gönder', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadButton(String label, File? file, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: file != null ? Colors.green : Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(
              file != null ? Icons.check_circle : Icons.cloud_upload_outlined,
              color: file != null ? Colors.green : Colors.grey[600],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                file != null ? '$label (Yüklendi)' : label,
                style: TextStyle(
                  color: file != null ? Colors.green[700] : Colors.grey[800],
                  fontWeight: file != null ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


