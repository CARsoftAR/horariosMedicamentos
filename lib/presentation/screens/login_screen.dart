import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_card.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  void _handleLogin() async {
    setState(() => _isLoading = true);
    // Simulación de login
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppTheme.backgroundDecoration,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.medication_liquid, size: 80, color: AppTheme.primaryRed),
                const SizedBox(height: 20),
                const Text(
                  'Bienvenido',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.darkGrey),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Tu salud en buenas manos',
                  style: TextStyle(color: AppTheme.mediumGrey, fontSize: 16),
                ),
                const SizedBox(height: 40),
                GlassCard(
                  child: Column(
                    children: [
                      _buildTextField('Usuario', _usernameController, Icons.person_outline),
                      const SizedBox(height: 20),
                      _buildTextField('Contraseña', _passwordController, Icons.lock_outline, obscureText: true),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryRed,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            elevation: 5,
                            shadowColor: AppTheme.primaryRed.withValues(alpha: 0.3),
                          ),
                          child: _isLoading 
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('INGRESAR', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool obscureText = false}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: AppTheme.darkGrey),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.mediumGrey),
        prefixIcon: Icon(icon, color: AppTheme.primaryRed),
        filled: true,
        fillColor: AppTheme.offWhite,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: AppTheme.primaryRed, width: 1)),
      ),
    );
  }
}
