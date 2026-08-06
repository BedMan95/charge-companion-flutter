import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/tuya_api.dart';
import '../providers/settings_provider.dart';

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  static const routeName = '/settings';

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  static const platform = MethodChannel('id.my.fornubi.chargecompanion/version');
  final _clientIdController = TextEditingController();
  final _clientSecretController = TextEditingController();
  final _deviceIdController = TextEditingController();
  final _baseUrlController = TextEditingController();
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadCredentials();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final String version = await platform.invokeMethod('getAppVersion');
      setState(() {
        _appVersion = version;
      });
    } on PlatformException catch (e) {
      setState(() {
        _appVersion = "Failed to get version: '${e.message}'.";
      });
    }
  }

  Future<void> _loadCredentials() async {
    final creds = await TuyaApi.getCredentials();
    if (creds != null) {
      setState(() {
        _clientIdController.text = creds['clientId'] ?? '';
        _clientSecretController.text = creds['clientSecret'] ?? '';
        _deviceIdController.text = creds['deviceId'] ?? '';
        _baseUrlController.text = creds['baseUrl'] ?? '';
      });
    }
  }

  Future<void> _saveCredentials() async {
    await TuyaApi.saveCredentials(
      _clientIdController.text,
      _clientSecretController.text,
      _deviceIdController.text,
      _baseUrlController.text,
    );
    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Credentials saved successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF020617), // slate-950
      appBar: AppBar(
        backgroundColor: const Color(0xFF020617),
        elevation: 0,
        title: const Text('Pengaturan', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Tarif Listrik',
              style: TextStyle(
                  color: Color(0xFF34D399), // emerald-400
                  fontSize: 14,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildSettingInput(
            label: 'Tarif PLN (Rp/kWh)',
            value: settings.tarifPln.toString(),
            onChanged: (v) {
              final val = double.tryParse(v);
              if (val != null) notifier.updateTarifPln(val);
            },
          ),
          const SizedBox(height: 32),
          const Text('Tuya API Credentials',
              style: TextStyle(
                  color: Color(0xFF34D399), // emerald-400
                  fontSize: 14,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildTextField('Client ID', _clientIdController),
          const SizedBox(height: 16),
          _buildTextField('Client Secret', _clientSecretController,
              obscureText: true),
          const SizedBox(height: 16),
          _buildTextField('Device ID', _deviceIdController),
          const SizedBox(height: 16),
          _buildTextField('Base URL', _baseUrlController),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669), // emerald-600
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _saveCredentials,
            child: const Text('Save Credentials',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 32),
          Center(
            child: Text(
              'Versi Aplikasi: $_appVersion',
              style: const TextStyle(
                color: Color(0xFF64748B), // slate-500
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSettingInput({
    required String label,
    required String value,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF94A3B8), // slate-400
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: value,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF0F172A), // slate-900
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1E293B)), // slate-800
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1E293B)), // slate-800
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF10B981)), // emerald-500
            ),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool obscureText = false}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF94A3B8)), // slate-400
        filled: true,
        fillColor: const Color(0xFF0F172A), // slate-900
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF1E293B)), // slate-800
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF10B981)), // emerald-500
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
