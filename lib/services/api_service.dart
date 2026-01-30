import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

class ApiService {
  // ⚠️ Ajusta esto si tu backend no usa el prefijo /api
  static const String baseUrl = 'http://10.94.80.222:3000/api'; 
  
  // --- VARIABLES ESTÁTICAS ---
  static String? _token;
  static Map<String, dynamic>? _usuario; 

  // --- GETTERS Y SETTERS ---

  static bool estaLogueado() {
    return _token != null && _token!.isNotEmpty;
  }

  static Map<String, dynamic> get usuario => _usuario ?? {};

  static void setToken(String token) {
    _token = token;
  }

  static Map<String, String> _getHeaders() { 
    return {
      'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }

  // ==================== AUTH ====================
  
  // LOGIN
  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/auth/login');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['token'] != null) {
          setToken(data['token']);
        }

        // Guardamos usuario o cliente
        if (data['usuario'] != null) {
          _usuario = data['usuario'];
        } else if (data['cliente'] != null) {
          _usuario = data['cliente'];
        }
        
        return data;
      } else {
        throw Exception(jsonDecode(response.body)['message'] ?? 'Error en login');
      }
    } catch (e) {
      print("❌ Error login: $e");
      throw Exception('Error de conexión: $e');
    }
  }

  // REGISTRO
  Future<bool> registrarUsuario(Map<String, dynamic> datos) async {
    final url = Uri.parse('$baseUrl/auth/register');
    Map<String, dynamic> bodyFinal;

    if (datos['rol_id'] == 4) {
      bodyFinal = {
        'nombre_razon_social': datos['nombre'], 
        'apellidos': datos['apellido'],        
        'email': datos['email'],
        'password': datos['password'],
        'telefono': datos['telefono'], 
        'es_cliente': true,
      };
    } else {
      bodyFinal = datos;
    }

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(bodyFinal),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Error en registro');
      }
    } catch (e) {
      print("❌ Error registro: $e");
      throw Exception('Error: $e');
    }
  }

  // ==================== EMPRESAS Y PRODUCTOS ====================
  
  Future<List<dynamic>> getMicroempresas() async {
    final url = Uri.parse('$baseUrl/usuarios/microempresas');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data is List ? data : [];
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> getTodosLosProductos({String? busqueda, String? categoria}) async {
    String url = '$baseUrl/productos/todos';
    final params = <String, String>{};
    if (busqueda != null && busqueda.isNotEmpty) params['busqueda'] = busqueda;
    if (categoria != null && categoria.isNotEmpty) params['categoria'] = categoria;

    try {
      final uri = Uri.parse(url).replace(queryParameters: params.isNotEmpty ? params : null);
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data is List ? data : [];
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> getProductosPorEmpresa(int microempresaId) async {
    final url = Uri.parse('$baseUrl/productos/public/$microempresaId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data is List ? data : [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ==================== PEDIDOS ====================
  
  // ✅ Esta es la versión CORRECTA que funciona con CheckoutScreen
  Future<bool> crearPedido({
    required String direccionEnvio,
    required String metodoPago,
    required double total,
    required List<Map<String, dynamic>> detalles,
  }) async {
    // Nota: quitamos /api aquí si tu ruta es directa, o lo dejamos si es subruta.
    // Asumiré que sigue la lógica de baseUrl
    final url = Uri.parse('$baseUrl/pedidos');
    
    // Obtenemos el ID del usuario logueado
    final idUsuario = _usuario != null ? _usuario!['id'] : null; 

    if (idUsuario == null) {
      print("⚠️ Error: Intento de compra sin usuario logueado");
      throw Exception("Usuario no identificado. Por favor inicia sesión.");
    }

    try {
      final body = jsonEncode({
          "id_usuario": idUsuario,
          "direccion_envio": direccionEnvio,
          "metodo_pago": metodoPago,
          "total": total,
          "detalles": detalles
        });

      final response = await http.post(
        url,
        headers: _getHeaders(), 
        body: body,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        print("❌ Error servidor (${response.statusCode}): ${response.body}");
        return false;
      }
    } catch (e) {
      print("❌ Error conexión: $e");
      throw Exception("No se pudo conectar con el servidor");
    }
  }

  // ==================== LOGOUT ====================
  
  Future<bool> logout() async {
    try {
      final url = Uri.parse('$baseUrl/auth/logout');
      // Copia de headers antes de borrar el token
      final headers = Map<String, String>.from(_getHeaders());
      
      await http.post(url, headers: headers);
      
      _token = null;
      _usuario = null;
      return true;
    } catch (e) {
      return false;
    }
  }
}