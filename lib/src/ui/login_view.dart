import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../api/api_client.dart';
import 'dashboard_view.dart';
import 'package:lucide_icons/lucide_icons.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});
  static const routeName = '/login';

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _hostController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _hostController.text = ApiClient.baseUrl;
  }

  Future<void> _updateHost() async {
    final url = _hostController.text.trim();
    if (url.isNotEmpty) {
      await ApiClient.updateBaseUrl(url);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Host updated'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    }
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text('Backend Host', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: _hostController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Base URL',
            hintText: 'http://127.0.0.1:8787',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: _updateHost,
            child: const Text('Simpan', style: TextStyle(color: Color(0xFF10B981))),
          ),
        ],
      ),
    );
  }

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiClient.instance.post('/api/auth/login', data: {
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
      });

      if (response.statusCode == 200 && response.data['success'] == true) {
        final token = response.data['token'];
        final userId = response.data['user']['id'].toString();
        
        await ApiClient.saveAuth(token, userId);
        
        if (mounted) {
          Navigator.pushReplacementNamed(context, DashboardView.routeName);
        }
      } else {
        throw Exception('Login gagal');
      }
    } on DioException catch (e) {
       _showError(e.response?.data?['message'] ?? 'Koneksi error');
    } catch (e) {
       _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
     ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.redAccent,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.settings, color: Color(0xFF94A3B8)),
            onPressed: _showSettingsDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.zap, size: 64, color: Color(0xFF10B981)),
                const SizedBox(height: 24),
                const Text(
                  'Charge Companion',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Login ke Backend',
                  style: TextStyle(color: Color(0xFF94A3B8)),
                ),
                const SizedBox(height: 48),
                TextField(
                  controller: _emailController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(LucideIcons.mail, color: Color(0xFF94A3B8)),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(LucideIcons.lock, color: Color(0xFF94A3B8)),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
