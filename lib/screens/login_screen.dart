import 'package:flutter/material.dart';
import 'dart:convert'; // Para decodificar JSON
import 'package:shared_preferences/shared_preferences.dart'; // Para guardar sesión
import '../services/api_service.dart';
import 'home_screen.dart';
import 'registro_screen.dart';
import 'vendedor/vendedor_home_screen.dart'; // Importamos la pantalla del vendedor

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
      // Nota: Asumimos que tu ApiService.login devuelve el mapa de respuesta (JSON)
      // Si tu ApiService devuelve void, avísame para ajustar esto.
      final response = await _apiService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      // Analizamos la respuesta para ver el ROL
      // La estructura esperada es: { token: "...", usuario: { rol_id: 3, ... } }
      
      // Asegúrate de que tu ApiService devuelva el objeto decoded, o hazlo aquí:
      // Si response es String: final data = jsonDecode(response);
      // Si response ya es Map, úsalo directo.
      final usuario = response['usuario']; 
      final rolId = usuario['rol_id'];
      
      // Guardamos datos clave en SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      // Guardamos token (si viene en la respuesta)
      if (response['token'] != null) {
        await prefs.setString('token', response['token']);
      }

      await prefs.setInt('rol_id', rolId ?? 0);
      await prefs.setString('nombre', usuario['nombre'] ?? '');
      await prefs.setInt('userId', usuario['id']);

      // --- MODIFICA ESTA PARTE (Línea 78 aprox) ---
      if (usuario['microempresa_id'] != null) {
        // Cámbialo a 'id_microempresa' para que coincida con tu ApiService
        await prefs.setInt('id_microempresa', usuario['microempresa_id']); 
        print("✅ ID Empresa guardado: ${usuario['microempresa_id']}"); 
      }
      // --------------------------------------------

      if (mounted) {
        // 4. DECISIÓN DE REDIRECCIÓN
        if (rolId == 3) {
          // ==> ES VENDEDOR
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const VendedorHomeScreen()),
          );
        } else {
          // ==> ES CLIENTE O ADMIN
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
          );
        }
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
                  Icons.inventory_2_rounded,
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
                      backgroundColor: Colors.blue.shade50,
                      foregroundColor: Colors.blue.shade900,
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