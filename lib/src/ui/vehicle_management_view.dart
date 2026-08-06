import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/vehicle_provider.dart';

class VehicleManagementView extends ConsumerWidget {
  const VehicleManagementView({super.key});

  static const routeName = '/vehicles';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesState = ref.watch(vehicleProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF020617), // slate-950
      appBar: AppBar(
        backgroundColor: const Color(0xFF020617),
        elevation: 0,
        title: const Text('Manajemen Kendaraan',
            style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plus),
            onPressed: () => _showAddVehicleDialog(context, ref),
          ),
        ],
      ),
      body: vehiclesState.when(
        data: (vehicles) {
          if (vehicles.isEmpty) {
            return const Center(
              child: Text('Belum ada kendaraan.',
                  style: TextStyle(color: Colors.grey)),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: vehicles.length,
            itemBuilder: (context, index) {
              final vehicle = vehicles[index];
              return _buildVehicleCard(context, ref, vehicle);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
            child: Text('Error: $err',
                style: const TextStyle(color: Colors.redAccent))),
      ),
    );
  }

  Widget _buildVehicleCard(
      BuildContext context, WidgetRef ref, Vehicle vehicle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withOpacity(0.4), // slate-900/40
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: vehicle.isActive
              ? const Color(0xFF10B981) // emerald-500
              : const Color(0xFF1E293B).withOpacity(0.8), // slate-800/80
          width: vehicle.isActive ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (vehicle.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(vehicle.imageUrl!),
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B), // slate-800
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(LucideIcons.car,
                      color: Colors.white, size: 30),
                ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(vehicle.name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    Text('Model ID: ${vehicle.evModelId}',
                        style: const TextStyle(
                            color: Color(0xFF94A3B8), fontSize: 12)), // slate-400
                    if (vehicle.isActive)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Aktif',
                            style: TextStyle(
                                color: Color(0xFF34D399), fontSize: 10, fontWeight: FontWeight.bold)), // emerald-400
                      ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(LucideIcons.moreVertical, color: Colors.white),
                color: const Color(0xFF0F172A), // slate-900
                onSelected: (value) async {
                  if (value == 'set_active') {
                    ref
                        .read(vehicleProvider.notifier)
                        .setActiveVehicle(vehicle.id);
                  } else if (value == 'change_photo') {
                    try {
                      // Request permissions first
                      if (Platform.isAndroid) {
                        final status = await Permission.photos.request();
                        if (status.isDenied) {
                          await Permission.storage.request();
                        }
                      } else if (Platform.isIOS) {
                        await Permission.photos.request();
                      }

                      final picker = ImagePicker();
                      final image =
                          await picker.pickImage(source: ImageSource.gallery);
                      if (image != null) {
                        final appDir = await getApplicationDocumentsDirectory();
                        final fileName = path.basename(image.path);
                        final savedImage = await File(image.path)
                            .copy('${appDir.path}/$fileName');
                        ref
                            .read(vehicleProvider.notifier)
                            .updateVehicleImage(vehicle.id, savedImage.path);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                                  Text('Error: $e (Coba restart aplikasi)')),
                        );
                      }
                    }
                  } else if (value == 'delete') {
                    ref
                        .read(vehicleProvider.notifier)
                        .deleteVehicle(vehicle.id);
                  } else if (value == 'settings') {
                    _showVehicleSettingsDialog(context, ref, vehicle);
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  if (!vehicle.isActive)
                    const PopupMenuItem<String>(
                      value: 'set_active',
                      child: Text('Jadikan Aktif',
                          style: TextStyle(color: Colors.white)),
                    ),
                  const PopupMenuItem<String>(
                    value: 'settings',
                    child: Text('Pengaturan Kendaraan',
                        style: TextStyle(color: Colors.white)),
                  ),
                  const PopupMenuItem<String>(
                    value: 'change_photo',
                    child: Text('Ubah Foto',
                        style: TextStyle(color: Colors.white)),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Text('Hapus',
                        style: TextStyle(color: Colors.redAccent)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddVehicleDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final modelIdController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A), // slate-900
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF334155), // slate-700
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Tambah Kendaraan',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Nama Kendaraan',
                  border: UnderlineInputBorder(),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF1E293B)),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF10B981), width: 2),
                  ),
                  filled: false,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: modelIdController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Model ID (contoh: uwinfly_t3)',
                  border: UnderlineInputBorder(),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF1E293B)),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF10B981), width: 2),
                  ),
                  filled: false,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669), // emerald-600
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  if (nameController.text.isNotEmpty &&
                      modelIdController.text.isNotEmpty) {
                    ref
                        .read(vehicleProvider.notifier)
                        .addVehicle(nameController.text, modelIdController.text);
                    Navigator.pop(context);
                  }
                },
                child: const Text('Simpan',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showVehicleSettingsDialog(
      BuildContext context, WidgetRef ref, Vehicle vehicle) {
    final voltController = TextEditingController(
        text: vehicle.customBatteryVolt?.toString() ?? vehicle.batteryVolt.toString());
    final ahController = TextEditingController(
        text: vehicle.customBatteryAh?.toString() ?? vehicle.batteryAh.toString());
    final efisiensiController = TextEditingController(
        text: vehicle.customEfisiensiCharger?.toString() ?? vehicle.efisiensiCharger.toString());

    final usableBatteryController = TextEditingController(
        text: vehicle.calibrationUsableBatteryKwh?.toString() ?? '');
    final wallEnergyController = TextEditingController(
        text: vehicle.calibrationWallEnergyFullKwh?.toString() ?? '');
    final fullChargeHoursController = TextEditingController(
        text: vehicle.calibrationFullChargeHours?.toString() ?? '');
    final taperStartController = TextEditingController(
        text: vehicle.calibrationTaperStartPercent?.toString() ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A), // slate-900
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF334155), // slate-700
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Text(
                  'Pengaturan Kendaraan',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 8.0),
                    child: Text('Spesifikasi Dasar (Override)', style: TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.bold, fontSize: 12)),
                  )
                ),
                _buildSheetTextField('Voltase Baterai (V)', voltController),
                const SizedBox(height: 16),
                _buildSheetTextField('Kapasitas (Ah)', ahController),
                const SizedBox(height: 16),
                _buildSheetTextField('Efisiensi Charger (0.0 - 1.0)', efisiensiController),
                const SizedBox(height: 24),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 12.0),
                    child: Text('Kalibrasi Waktu & Taper', style: TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.bold, fontSize: 12)),
                  )
                ),
                _buildSheetTextField('Kapasitas Baterai (kWh)', usableBatteryController),
                const SizedBox(height: 16),
                _buildSheetTextField('Kapasitas Listrik Real (kWh)', wallEnergyController),
                const SizedBox(height: 16),
                _buildSheetTextField('Estimasi Waktu 0-100% (Jam)', fullChargeHoursController),
                const SizedBox(height: 16),
                _buildSheetTextField('Taper Charger Mulai (%)', taperStartController),
                const SizedBox(height: 32),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669), // emerald-600
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    ref.read(vehicleProvider.notifier).updateVehicleSettings(
                          vehicle.id,
                          customBatteryVolt: double.tryParse(voltController.text),
                          customBatteryAh: double.tryParse(ahController.text),
                          customEfisiensiCharger: double.tryParse(efisiensiController.text),
                          usableBatteryKwh:
                              double.tryParse(usableBatteryController.text),
                          wallEnergyFullKwh:
                              double.tryParse(wallEnergyController.text),
                          fullChargeHours:
                              double.tryParse(fullChargeHoursController.text),
                          taperStartPercent:
                              double.tryParse(taperStartController.text),
                        );
                    Navigator.pop(context);
                  },
                  child: const Text('Simpan',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSheetTextField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        border: const UnderlineInputBorder(),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF1E293B)),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF10B981), width: 2),
        ),
        filled: false,
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
      ),
    );
  }
}
