import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'home_screen.dart';
import 'registro_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Clave para validar el formulario
  final _formKey = GlobalKey<FormState>();
  
  // Controladores de texto
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // Instancia del servicio API
  final ApiService _apiService = ApiService();

  // Variables de estado visual
  bool _isLoading = false;
  bool _isObscure = true; // Para ocultar/mostrar contraseña

  // Función de Login
  void _handleLogin() async {
    // 1. Validar campos vacíos
    if (!_formKey.currentState!.validate()) return;

    // 2. Ocultar teclado
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      // 3. Llamada al API
      await _apiService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (mounted) {
        // 4. Éxito: Navegar al Home (y eliminar Login del historial)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      }
    } catch (e) {
      // 5. Error: Mostrar mensaje
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception:', '').trim()),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      // 6. Restaurar estado de carga
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // LOGO O ÍCONO
                const Icon(
                  Icons.inventory_2_rounded, // Icono de caja similar a tu logo
                  size: 80,
                  color: Colors.blue,
                ),
                const SizedBox(height: 16),
                const Text(
                  "PARAGIT",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 40),

                // CAMPO EMAIL
                const Text("Email", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.email_outlined),
                    hintText: "ejemplo@correo.com",
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Ingresa tu email';
                    if (!value.contains('@')) return 'Email no válido';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // CAMPO CONTRASEÑA
                const Text("Contraseña", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _isObscure,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock_outline),
                    hintText: "••••••",
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    // Ojo para ver contraseña
                    suffixIcon: IconButton(
                      icon: Icon(_isObscure ? Icons.visibility_off : Icons.visibility),
                      onPressed: () {
                        setState(() {
                          _isObscure = !_isObscure;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Ingresa tu contraseña';
                    return null;
                  },
                ),
                
                const SizedBox(height: 30),

                // BOTÓN INGRESAR
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade50, // Fondo azul suave
                      foregroundColor: Colors.blue.shade900, // Texto azul oscuro
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            "INGRESAR",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),

                const SizedBox(height: 20),
                
                // BOTÓN GOOGLE (Simulado)
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Google Sign-In próximamente")),
                    );
                  },
                  icon: const Icon(Icons.g_mobiledata, size: 30, color: Colors.red),
                  label: const Text("Ingresar con Google", style: TextStyle(color: Colors.black)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),

                const SizedBox(height: 30),

                // LINK A REGISTRO
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("¿No tienes cuenta? "),
                    GestureDetector(
                      onTap: () {
                        // Navegación directa al registro
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => RegistroScreen()),
                        );
                      },
                      child: const Text(
                        "Regístrate aquí",
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}