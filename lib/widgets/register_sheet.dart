import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../core/auth_service.dart';

class RegisterSheet extends StatefulWidget {
  final VoidCallback onLoginTap;
  final VoidCallback? onRegisterSuccess;
  const RegisterSheet({super.key, required this.onLoginTap, this.onRegisterSuccess});

  @override
  State<RegisterSheet> createState() => _RegisterSheetState();
}

class _RegisterSheetState extends State<RegisterSheet> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _obscure = true;
  bool _agree = false;
  bool _isLoading = false;
  String? _error;

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Vyplňte všetky polia');
      return;
    }
    
    if (password.length < 6) {
      setState(() => _error = 'Heslo musí mať aspoň 6 znakov');
      return;
    }
    
    if (!_agree) {
      setState(() => _error = 'Musíte súhlasiť so spracovaním údajov');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _authService.registerWithEmailAndPassword(
        email: email,
        password: password,
        name: name,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registrácia úspešná!')), 
        );
        await Future.delayed(const Duration(milliseconds: 300));
        if (widget.onRegisterSuccess != null) widget.onRegisterSuccess!();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 32),
          const Text(
            'Začnime',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 26),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _nameController,
                  enabled: !_isLoading,
                  decoration: const InputDecoration(
                    labelText: 'Celé meno:',
                    hintText: 'Meno a Priezvisko',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  enabled: !_isLoading,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'example@gmail.com',
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  enabled: !_isLoading,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Heslo',
                    hintText: 'kupujemKaVu!',
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                      onPressed: _isLoading ? null : () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Checkbox(
                      value: _agree,
                      onChanged: _isLoading ? null : (v) => setState(() => _agree = v ?? false),
                    ),
                    const Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: 'Súhlasím so spracovaním ',
                          children: [
                            TextSpan(
                              text: 'osobných údajov',
                              style: TextStyle(decoration: TextDecoration.underline),
                            ),
                          ],
                        ),
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF603013),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _isLoading ? null : _register,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Registrovať sa', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text('Registrovať sa pomocou', style: TextStyle(color: Color(0xFF603013))),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset('assets/icons/google.svg', width: 32, height: 32),
                    const SizedBox(width: 24),
                    SvgPicture.asset('assets/icons/apple.svg', width: 32, height: 32),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Už máte účet?'),
                    TextButton(
                      onPressed: _isLoading ? null : widget.onLoginTap,
                      child: const Text('Prihláste sa'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 