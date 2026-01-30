import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; 
class ApiService {
  // 1. DEJAMOS LA URL BASE LIMPIA (Sin /api)
  static const String baseUrl = 'http://10.94.80.222:3000';
  
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

  // ==================== AUTH (Usa /api) ====================
  
  // LOGIN
  Future<Map<String, dynamic>> login(String email, String password) async {
    // ⚠️ AGREGAMOS "/api" AQUÍ
    final url = Uri.parse('$baseUrl/api/auth/login');
    
    try {
      print("🔵 Intentando login en: $url");
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

        if (data['cliente'] != null) {
          _usuario = data['cliente'];
        } else if (data['usuario'] != null) {
          _usuario = data['usuario'];
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
    // ⚠️ AGREGAMOS "/api" AQUÍ
    final url = Uri.parse('$baseUrl/api/auth/register');
    
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

  // ==================== EMPRESAS Y PRODUCTOS (Usa /api) ====================
  
  Future<List<dynamic>> getMicroempresas() async {
    // ⚠️ AGREGAMOS "/api" AQUÍ
    final url = Uri.parse('$baseUrl/api/usuarios/microempresas');
    
    try {
      print("🔵 Obteniendo empresas de: $url");
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data is List ? data : [];
      } else {
        print("❌ Error al obtener empresas: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("❌ Error conexión empresas: $e");
      return [];
    }
  }

  Future<List<dynamic>> getTodosLosProductos({String? busqueda, String? categoria}) async {
    // ⚠️ AGREGAMOS "/api" AQUÍ
    String url = '$baseUrl/api/productos/todos';
    
    final params = <String, String>{};
    if (busqueda != null && busqueda.isNotEmpty) params['busqueda'] = busqueda;
    if (categoria != null && categoria.isNotEmpty) params['categoria'] = categoria;

    try {
      final uri = Uri.parse(url).replace(queryParameters: params.isNotEmpty ? params : null);
      print("🔵 Obteniendo productos de: $uri");
      
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data is List ? data : [];
      } else {
        print("❌ Error productos: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("❌ Error conexión productos: $e");
      return [];
    }
  }

  Future<List<dynamic>> getProductosPorEmpresa(int microempresaId) async {
    // ⚠️ AGREGAMOS "/api" AQUÍ
    final url = Uri.parse('$baseUrl/api/productos/public/$microempresaId');
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

  // ==================== PEDIDOS (Ojo aquí) ====================
  
  // ==================== PEDIDOS (Ajustado a carritoRoutes) ====================
  
  Future<void> crearPedido({
    required String direccionEnvio,
    required String metodoPago,
    required double total,
    required List<Map<String, dynamic>> detalles,
  }) async {
    
    // ⚠️ LA RUTA CORRECTA SEGÚN TU server.js Y carritoRoutes.js ES:
    final url = Uri.parse('$baseUrl/api/carrito/realizar-pedido'); 

    if (_usuario == null || _usuario!['id'] == null) {
      throw Exception("Debes iniciar sesión para realizar un pedido.");
    }

    final clienteId = _usuario!['id'];

    try {
      final bodyData = {
        "cliente_id": clienteId,
        "direccion_envio": direccionEnvio,
        "total": total,
        "metodo_pago": metodoPago,
        "detalles": detalles,
      };

      print("📦 Enviando pedido a: $url");
      print("📦 Datos: ${jsonEncode(bodyData)}");

      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode(bodyData),
      );

      print("📨 Respuesta servidor (${response.statusCode}): ${response.body}");

      // Si el servidor responde con un HTML (comienza con <!DOCTYPE), es un error de ruta 404
      if (response.body.contains("<!DOCTYPE html>")) {
         throw Exception("Ruta no encontrada en el servidor (404). Verifica que el backend esté corriendo.");
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        return; 
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? "Error del servidor (${response.statusCode})");
      }
    } catch (e) {
      print("❌ Error pedido: $e");
      rethrow;
    }
  }

  // ==================== obtener pedidos ====================
 

  // 1. OBTENER MIS PEDIDOS (Corregido para evitar lista vacía)
  Future<List<dynamic>> getMisPedidos() async {
    final user = usuario; 
    // Usamos 'id' o 'id_usuario' dependiendo de cómo lo guardaste al hacer login
    final userId = user['id'] ?? user['id_usuario'];

    if (userId == null) {
      print("⚠️ Error: ID de usuario es nulo. Revisa el Login.");
      return [];
    }

    // Asegúrate que tu backend tenga esta ruta: router.get('/pedidos-cliente/:id', ...)
    final url = Uri.parse('$baseUrl/api/carrito/pedidos-cliente/$userId');
    
    try {
      final response = await http.get(url, headers: {'Content-Type': 'application/json'});
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Si el backend devuelve {ok: true, data: [...]}, extraemos la lista
        if (data is Map && data.containsKey('data')) {
           return data['data']; // Devolvemos la lista dentro de 'data'
        }
        // Si devuelve la lista directamente
        return data is List ? data : [];
      } else {
        print("❌ Error Server Pedidos: ${response.body}");
        return [];
      }
    } catch (e) {
      print("❌ Error de conexión al pedir pedidos: $e");
      return [];
    }
  }

  // 2. ACTUALIZAR PERFIL (Nuevo)
  Future<bool> actualizarPerfil(String nombre, String telefono, String direccion) async {
    final userId = usuario['id'] ?? usuario['id_usuario'];
    // Ajusta la ruta a tu backend: router.put('/usuarios/:id', ...)
    final url = Uri.parse('$baseUrl/api/usuarios/$userId'); 

    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "nombre_completo": nombre,
          "telefono": telefono,
          "direccion": direccion
        }),
      );

      if (response.statusCode == 200) {
        // Actualizamos la variable local 'usuario' para ver los cambios al instante
        usuario['nombre'] = nombre; // O 'nombre_razon_social'
        usuario['telefono'] = telefono;
        usuario['direccion'] = direccion;
        return true;
      }
      return false;
    } catch (e) {
      print("Error actualizando perfil: $e");
      return false;
    }
  }

  Future<bool> enviarPedido(Map<String, dynamic> pedidoData) async {
  final url = Uri.parse('$baseUrl/api/carrito/realizar-pedido');
  
  try {
    // IMPORTANTE: Tu controlador 'procesarVenta' espera estos campos exactos
    final body = jsonEncode({
      "carritoId": "app_user_${usuario['id_usuario']}", // Generamos un ID temporal
      "metodoPago": pedidoData['metodo_pago'] ?? 'efectivo',
      "clienteData": {
        "id_cliente": usuario['id_usuario'],
        "nombre_razon_social": usuario['nombre'],
        "email": usuario['email'],
        "ci_nit": usuario['ci_nit']
      }
    });

    print("📦 Enviando pedido al backend...");
    
    // Antes de enviar el pedido final, debemos asegurar que el carrito 
    // "temporal" exista en el servidor para ese carritoId.
    // Como tu controlador usa 'carritosTemporales', vamos a enviar los productos primero.
    
    for (var item in pedidoData['detalles']) {
      await http.post(
        Uri.parse('$baseUrl/api/carrito/agregar'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "carritoId": "app_user_${usuario['id_usuario']}",
          "microempresaId": item['microempresa_id'] ?? 22, // ID de tu microempresa
          "productoId": item['id_producto'],
          "cantidad": item['cantidad']
        }),
      );
    }

    // Ahora sí, procesamos la venta final
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode == 200) {
      print("✅ Venta procesada con éxito");
      return true;
    } else {
      print("❌ Error en servidor: ${response.body}");
      return false;
    }
  } catch (e) {
    print("❌ Error de conexión: $e");
    return false;
  }
}

// Agrega esto dentro de class ApiService { ... }

  // Obtener lista de clientes
  Future<List<dynamic>> getClientes() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    // Ajusta la URL si es necesario (localhost o IP)
    final url = Uri.parse('$baseUrl/api/clientes'); 

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Importante para el verifyToken del backend
        },
      );

      if (response.statusCode == 200) {
        // El backend devuelve directamente una lista JSON: [ {...}, {...} ]
        return json.decode(response.body);
      } else {
        throw Exception('Error al cargar clientes: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

// Agrega esto en VentasVendedor
// EN lib/services/api_service.dart

Future<List<dynamic>> getVentasVendedor() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');
  final userId = prefs.getInt('userId'); // Asegúrate de tener guardado el userId

  if (userId == null) return [];

  // ⚠️ INTENTO DE CORRECCIÓN DE RUTA
  // Si esta ruta falla, necesitamos ver tu archivo 'routes' del backend
  // Opción A: Buscar pedidos donde el vendedor sea el usuario actual
  final url = Uri.parse('$baseUrl/api/carrito/ventas-vendedor/$userId'); 
  
  try {
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // Validamos si la respuesta viene dentro de una propiedad 'data' o es directa
      if (data is Map && data.containsKey('data')) {
        return data['data'];
      }
      return data is List ? data : [];
    }
    return [];
  } catch (e) {
    print("Error cargando ventas: $e");
    return [];
  }
}

Future<List<dynamic>> getProductosEmpresa() async {
  final prefs = await SharedPreferences.getInstance();
  final idEmpresa = prefs.getInt('id_microempresa');
  final token = prefs.getString('token');

  // Si no hay ID, retornamos lista vacía para evitar errores
  if (idEmpresa == null) return [];

  // ⚠️ CORRECCIÓN: Cambia 'empresa' por 'public'
  final url = Uri.parse('$baseUrl/api/productos/public/$idEmpresa'); 

  try {
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      // Si falla, retornamos lista vacía en lugar de lanzar error que rompe la app
      print("❌ Error servidor productos: ${response.statusCode}");
      return [];
    }
  } catch (e) {
    print("❌ Error conexión productos: $e");
    return [];
  }
}
  Future<bool> logout() async {
    try {
      // ⚠️ AGREGAMOS "/api" AQUÍ
      final url = Uri.parse('$baseUrl/api/auth/logout');
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