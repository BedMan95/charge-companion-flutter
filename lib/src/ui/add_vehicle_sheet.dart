import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/vehicle_provider.dart';

class AddVehicleSheet extends ConsumerStatefulWidget {
  const AddVehicleSheet({super.key});

  @override
  ConsumerState<AddVehicleSheet> createState() => _AddVehicleSheetState();
}

class _AddVehicleSheetState extends ConsumerState<AddVehicleSheet> {
  bool _isSaving = false;
  String _addMode = 'database'; // 'database' or 'custom'
  
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _voltController = TextEditingController();
  final _ahController = TextEditingController();
  final _effController = TextEditingController(text: '0.82');
  
  String? _selectedEvModelId;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0F172A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Tambah Kendaraan', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              
              Row(
                children: [
                  Expanded(child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: _addMode == 'database' ? const Color(0xFF10B981) : Colors.transparent),
                    onPressed: () => setState(() => _addMode = 'database'),
                    child: const Text('Dari Database', style: TextStyle(color: Colors.white, fontSize: 12)),
                  )),
                  Expanded(child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: _addMode == 'custom' ? const Color(0xFF10B981) : Colors.transparent),
                    onPressed: () => setState(() => _addMode = 'custom'),
                    child: const Text('Kendaraan Baru', style: TextStyle(color: Colors.white, fontSize: 12)),
                  )),
                ],
              ),
              const SizedBox(height: 20),

              if (_addMode == 'database') ...[
                const Text('Pilih Model EV:', style: TextStyle(color: Colors.white)),
                const SizedBox(height: 8),
                Consumer(
                  builder: (context, ref, child) {
                    final modelsAsync = ref.watch(evModelsProvider);
                    return modelsAsync.when(
                      data: (models) {
                        return DropdownButtonFormField<String>(
                          value: _selectedEvModelId,
                          dropdownColor: const Color(0xFF1E293B),
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(filled: true, fillColor: const Color(0xFF1E293B), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF10B981))), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
                          items: models.map((m) => DropdownMenuItem<String>(value: m['id'] as String, child: Text(m['brand'] + ' ' + m['model']))).toList(),
                          onChanged: (val) => setState(() => _selectedEvModelId = val),
                        );
                      },
                      loading: () => const CircularProgressIndicator(),
                      error: (e, _) => Text('Error: $e'),
                    );
                  }
                ),
              ] else ...[
                _buildTextField('Merk', _brandController),
                _buildTextField('Tipe', _modelController),
                _buildTextField('Voltase', _voltController, true),
                _buildTextField('Kapasitas Ah', _ahController, true),
                _buildTextField('Efisiensi', _effController, true),
              ],
              
              const SizedBox(height: 20),
              _buildTextField('Nama Kendaraan (Panggilan)', _nameController),
              const SizedBox(height: 32),
              
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669)),
                onPressed: _isSaving ? null : _saveVehicle,
                child: _isSaving ? const CircularProgressIndicator() : const Text('Simpan Kendaraan', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, [bool isNum = false]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        keyboardType: isNum ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(color: Color(0xFF94A3B8)), filled: true, fillColor: const Color(0xFF1E293B), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF10B981))), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
      ),
    );
  }

  Future<void> _saveVehicle() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nama kendaraan wajib diisi!')));
      return;
    }
    setState(() => _isSaving = true);
    try {
      if (_addMode == 'database') {
        if (_selectedEvModelId == null) {
          throw Exception('Pilih model EV dari daftar!');
        }
        await ref.read(vehicleProvider.notifier).addVehicle(_nameController.text, _selectedEvModelId!);
      } else {
        if (_brandController.text.trim().isEmpty || 
            _modelController.text.trim().isEmpty || 
            _voltController.text.trim().isEmpty || 
            _ahController.text.trim().isEmpty) {
          throw Exception('Mohon lengkapi data merk, tipe, voltase, dan kapasitas Ah!');
        }
        await ref.read(vehicleProvider.notifier).addCustomVehicle(
          name: _nameController.text,
          brand: _brandController.text,
          model: _modelController.text,
          batteryVolt: double.parse(_voltController.text),
          batteryAh: double.parse(_ahController.text),
          efisiensiCharger: double.parse(_effController.text),
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
