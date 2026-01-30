import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class RegistroScreen extends StatefulWidget {
  @override
  _RegistroScreenState createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _api = ApiService();
  bool _isLoading = false;

  // Controladores
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Datos del registro
  // 4 = Cliente (Comprador), 2 = Admin Empresa, 3 = Vendedor
  String _rolSeleccionado = '4'; 
  String _empresaSeleccionada = '';

  // Campos para empresa (si es administrador)
  final _nombreEmpresaController = TextEditingController();
  final _nitEmpresaController = TextEditingController();
  final _direccionEmpresaController = TextEditingController();
  final _telefonoEmpresaController = TextEditingController();

  void _handleRegistro() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos correctamente')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final Map<String, dynamic> datos = {
        'nombre': _nombreController.text.trim(),
        'apellido': _apellidoController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        'rol_id': int.parse(_rolSeleccionado),
      };

      // Lógica específica por Rol
      if (_rolSeleccionado == '2') {
        // Si es Admin, envía datos de su nueva empresa
        datos['empresa'] = {
          'nombre': _nombreEmpresaController.text.trim(),
          'nit': _nitEmpresaController.text.trim(),
          'direccion': _direccionEmpresaController.text.trim(),
          'telefono': _telefonoEmpresaController.text.trim(),
          'rubro': 'general',
          'moneda': 'BOB',
          'plan_id': 1,
        };
      } else if (_rolSeleccionado == '3' && _empresaSeleccionada.isNotEmpty) {
        // Si es Vendedor, se vincula a una empresa existente
        datos['microempresa_id'] = int.parse(_empresaSeleccionada);
      }
      // Si es Cliente (4), solo se envían los datos básicos

      await _api.registrarUsuario(datos);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Registro exitoso! Por favor inicia sesión.'),
            backgroundColor: Colors.green,
          ),
        );

        // Navegar a login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Crear Cuenta'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- SECCIÓN GOOGLE ---
              const Icon(Icons.account_circle, size: 60, color: Colors.blue),
              const SizedBox(height: 20),
              
              ElevatedButton.icon(
                icon: const Icon(Icons.g_mobiledata, size: 30, color: Colors.red), // Icono Google simulado
                label: const Text("Registrarse con Google"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: Colors.grey, width: 0.5),
                ),
                onPressed: () {
                  // AQUÍ IRÁ LA LÓGICA DE GOOGLE SIGN-IN
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Funcionalidad Google en construcción")),
                  );
                },
              ),
              
              const SizedBox(height: 20),
              const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text("O con tu correo"),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 20),

              // --- FORMULARIO BÁSICO ---
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: "Nombre",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _apellidoController,
                decoration: const InputDecoration(
                  labelText: "Apellido",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "Correo electrónico",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (v) => !v!.contains('@') ? 'Email inválido' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Contraseña",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: (v) => v!.length < 6 ? 'Mínimo 6 caracteres' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Confirmar contraseña",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (v) => v != _passwordController.text ? 'No coinciden' : null,
              ),
              const SizedBox(height: 20),

              // --- SELECTOR DE ROL ---
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _rolSeleccionado,
                    items: const [
                      DropdownMenuItem(value: '4', child: Text('Cliente (Quiero comprar)')),
                      DropdownMenuItem(value: '3', child: Text('Vendedor (Empleado)')),
                      DropdownMenuItem(value: '2', child: Text('Administrador (Tengo empresa)')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _rolSeleccionado = value!;
                        _empresaSeleccionada = '';
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // --- CAMPOS DINÁMICOS ---
              
              // 1. SI ES ADMINISTRADOR (Crea empresa)
              if (_rolSeleccionado == '2') ...[
                const Text("Datos de tu Empresa:", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _nombreEmpresaController,
                  decoration: const InputDecoration(labelText: "Nombre Empresa", border: OutlineInputBorder()),
                  validator: (v) => _rolSeleccionado == '2' && v!.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _nitEmpresaController,
                  decoration: const InputDecoration(labelText: "NIT", border: OutlineInputBorder()),
                  validator: (v) => _rolSeleccionado == '2' && v!.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _direccionEmpresaController,
                  decoration: const InputDecoration(labelText: "Dirección", border: OutlineInputBorder()),
                  validator: (v) => _rolSeleccionado == '2' && v!.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _telefonoEmpresaController,
                  decoration: const InputDecoration(labelText: "Teléfono", border: OutlineInputBorder()),
                  validator: (v) => _rolSeleccionado == '2' && v!.isEmpty ? 'Requerido' : null,
                ),
              ] 
              
              // 2. SI ES VENDEDOR (Elige empresa)
              else if (_rolSeleccionado == '3') ...[
                const Text("Selecciona la empresa donde trabajas:", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                FutureBuilder<List<dynamic>>(
                  future: _api.getMicroempresas(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: LinearProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Text("No hay empresas registradas.");
                    }
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          hint: const Text("Selecciona una empresa"),
                          value: _empresaSeleccionada.isEmpty ? null : _empresaSeleccionada,
                          items: snapshot.data!.map<DropdownMenuItem<String>>((e) {
                            return DropdownMenuItem<String>(
                              value: e['id_microempresa'].toString(),
                              child: Text(e['nombre_empresa']),
                            );
                          }).toList(),
                          onChanged: (v) => setState(() => _empresaSeleccionada = v!),
                        ),
                      ),
                    );
                  },
                ),
              ],

              const SizedBox(height: 30),

              // --- BOTÓN FINAL ---
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegistro,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("REGISTRARME", style: TextStyle(fontSize: 18)),
                ),
              ),

              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("¿Ya tienes cuenta? "),
                  GestureDetector(
                    onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => LoginScreen())),
                    child: const Text("Inicia Sesión", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nombreEmpresaController.dispose();
    _nitEmpresaController.dispose();
    _direccionEmpresaController.dispose();
    _telefonoEmpresaController.dispose();
    super.dispose();
  }
}