import 'package:flutter/material.dart';
import 'api_service.dart';
import 'movie_list_screen.dart';
import 'snow_widget.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _ipController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  void _handleLogin() async {
    if (_ipController.text.isEmpty || _usernameController.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in Server IP and Username'), backgroundColor: Colors.redAccent),
        );
      }
      return;
    }

    setState(() => _isLoading = true);
    ApiService.setBaseUrl(_ipController.text);
    final success = await ApiService.login(_usernameController.text, _passwordController.text);
    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MovieListScreen()));
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login failed. Check IP and credentials.'), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = const Color(0xFF000000);
    final cardColor = const Color(0xFF1F2937).withOpacity(0.6);
    final inputColor = const Color(0xFF111827).withOpacity(0.5);
    final accentGradient = const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF4F46E5)]);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          const Positioned.fill(child: SnowWidget()),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.3), blurRadius: 40, spreadRadius: 0),
                      ],
                    ),
                    // --- YOUR LOGO GOES HERE ---
                    child: Image.asset(
                      'assets/logo.png', // Ensure file exists in assets folder
                      width: 120,
                      height: 120,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "SynCinema",
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 10))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel("Server Address"),
                        _buildInput(controller: _ipController, hint: "192.168.1.x:17701", icon: Icons.wifi, inputColor: inputColor),
                        const SizedBox(height: 20),
                        _buildLabel("Username"),
                        _buildInput(controller: _usernameController, hint: "Enter your username", icon: Icons.person_outline, inputColor: inputColor),
                        const Padding(
                          padding: EdgeInsets.only(top: 8.0, left: 4.0),
                          child: Text("Ask your Host for the username", style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic)),
                        ),
                        const SizedBox(height: 20),
                        _buildLabel("Password"),
                        _buildInput(controller: _passwordController, hint: "Enter your password", icon: Icons.lock_outline, inputColor: inputColor, isPassword: true, obscureText: _obscurePassword, onTogglePassword: () => setState(() => _obscurePassword = !_obscurePassword)),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            SizedBox(height: 24, width: 24, child: Checkbox(value: _rememberMe, onChanged: (v) => setState(() => _rememberMe = v!), activeColor: const Color(0xFF4F46E5), side: BorderSide(color: Colors.grey.shade600), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)))),
                            const SizedBox(width: 8),
                            const Text("Remember me", style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        GestureDetector(
                          onTap: _isLoading ? null : _handleLogin,
                          child: Container(
                            width: double.infinity,
                            height: 50,
                            decoration: BoxDecoration(gradient: accentGradient, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: const Color(0xFF4F46E5).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))]),
                            child: Center(
                              child: _isLoading
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text("Enter Cinema", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)), SizedBox(width: 8), Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20)]),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(padding: const EdgeInsets.only(bottom: 8.0, left: 4.0), child: Text(text, style: const TextStyle(color: Color(0xFFD1D5DB), fontWeight: FontWeight.w500, fontSize: 14)));
  }

  Widget _buildInput({required TextEditingController controller, required String hint, required IconData icon, required Color inputColor, bool isPassword = false, bool obscureText = false, VoidCallback? onTogglePassword}) {
    return Container(
      decoration: BoxDecoration(color: inputColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.withOpacity(0.3))),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade600),
          prefixIcon: Icon(icon, color: Colors.grey.shade400),
          suffixIcon: isPassword ? IconButton(icon: Icon(obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey.shade400), onPressed: onTogglePassword) : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}