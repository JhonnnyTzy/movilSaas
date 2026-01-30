import 'package:flutter/material.dart';
import '../services/api_service.dart';
// Importamos Provider para manejar el estado del carrito
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import 'cart_screen.dart';
import 'login_screen.dart';
import 'registro_screen.dart';
import 'productos_empresa_screen.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final ApiService apiService = ApiService();
  late TabController _tabController;
  String _searchEmpresa = '';
  String _searchProducto = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Función para cerrar sesión y actualizar la pantalla
  void _cerrarSesion() async {
    await apiService.logout();
    if (mounted) {
      setState(() {}); // Actualiza la UI para mostrar "Invitado" de nuevo
      Navigator.pop(context); // Cierra el drawer
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sesión cerrada correctamente")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obtenemos los datos del usuario para el menú
    final usuario = ApiService.usuario;
    final estaLogueado = ApiService.estaLogueado();

    // Intentamos obtener el nombre
    final nombreUsuario = usuario['nombre_razon_social'] ?? usuario['nombre'] ?? 'Usuario';
    final emailUsuario = usuario['email'] ?? '';
    final inicial = nombreUsuario.isNotEmpty ? nombreUsuario[0].toString().toUpperCase() : '?';

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('PARAGIT'),
          centerTitle: true,
          elevation: 0,
          actions: [
            // 🛒 CARRITO CON CONTADOR
            Consumer<CartProvider>(
              builder: (_, cart, ch) => Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined, size: 28),
                    onPressed: () {
                      Navigator.push(
                        context, 
                        // Quitamos 'const' por si acaso
                        MaterialPageRoute(builder: (context) => const CartScreen())
                      );
                    },
                  ),
                  if (cart.itemCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: CircleAvatar(
                        radius: 8,
                        backgroundColor: Colors.red,
                        child: Text(
                          '${cart.itemCount}',
                          style: const TextStyle(fontSize: 10, color: Colors.white),
                        ),
                      ),
                    )
                ],
              ),
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            tabs: const [
              Tab(text: "EMPRESAS", icon: Icon(Icons.business_rounded)),
              Tab(text: "PRODUCTOS", icon: Icon(Icons.grid_view_rounded)),
            ],
          ),
        ),
        
        // ☰ MENU LATERAL (DRAWER) CORREGIDO
        drawer: Drawer(
          child: Column(
            children: [
              UserAccountsDrawerHeader(
                decoration: const BoxDecoration(color: Colors.blue),
                accountName: Text(
                  estaLogueado ? nombreUsuario : "Invitado",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                accountEmail: Text(
                  estaLogueado ? emailUsuario : "Inicia sesión para ver tus datos",
                ),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Text(
                    estaLogueado ? inicial : '?',
                    style: const TextStyle(fontSize: 30.0, color: Colors.blue),
                  ),
                ),
              ),
              
              // Opciones del Menú
              if (!estaLogueado) ...[
                // SI NO ESTÁ LOGUEADO
                ListTile(
                  leading: const Icon(Icons.app_registration_rounded, color: Colors.blue),
                  title: const Text("Registrarse"),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      // ⚠️ CORRECCIÓN: Quitamos 'const' aquí
                      MaterialPageRoute(builder: (context) => RegistroScreen()),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.login_rounded),
                  title: const Text("Iniciar Sesión"),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      // ⚠️ CORRECCIÓN: Quitamos 'const' aquí
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                    );
                  },
                ),
              ] else ...[
                // SI SÍ ESTÁ LOGUEADO
                 ListTile(
                  leading: const Icon(Icons.history, color: Colors.blue),
                  title: const Text("Mis Pedidos"),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Próximamente: Historial de pedidos"))
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: Colors.red),
                  title: const Text("Cerrar Sesión", style: TextStyle(color: Colors.red)),
                  onTap: _cerrarSesion,
                ),
              ],
            ],
          ),
        ),
        
        body: TabBarView(
          controller: _tabController,
          children: [
            _tabEmpresas(),
            _tabProductos(),
          ],
        ),
      ),
    );
  }

  // --- PESTAÑA DE EMPRESAS ---
  Widget _tabEmpresas() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            onChanged: (value) => setState(() => _searchEmpresa = value),
            decoration: InputDecoration(
              hintText: "Buscar empresas...",
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchEmpresa.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _searchEmpresa = ''),
                    )
                  : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder(
            future: apiService.getMicroempresas(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) return _buildErrorWidget();
              
              List<dynamic> empresas = snapshot.data as List? ?? [];
              
              if (_searchEmpresa.isNotEmpty) {
                empresas = empresas.where((empresa) {
                  final nombre = (empresa['nombre_empresa'] ?? '').toString().toLowerCase();
                  final rubro = (empresa['rubro'] ?? '').toString().toLowerCase();
                  final search = _searchEmpresa.toLowerCase();
                  return nombre.contains(search) || rubro.contains(search);
                }).toList();
              }

              if (empresas.isEmpty) return const Center(child: Text("No hay empresas disponibles"));

              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: empresas.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) => Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(10),
                    leading: CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.blue.shade100,
                      child: const Icon(Icons.storefront, color: Colors.blue, size: 30),
                    ),
                    title: Text(
                      empresas[i]['nombre_empresa'] ?? 'Empresa',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(empresas[i]['rubro'] ?? 'Sector comercial'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductosEmpresaScreen(
                            microempresaId: empresas[i]['id_microempresa'],
                            nombreEmpresa: empresas[i]['nombre_empresa'] ?? 'Empresa',
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- PESTAÑA DE PRODUCTOS ---
  Widget _tabProductos() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            onChanged: (value) => setState(() => _searchProducto = value),
            decoration: InputDecoration(
              hintText: "Buscar productos...",
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchProducto.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _searchProducto = ''),
                    )
                  : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder(
            future: apiService.getTodosLosProductos(busqueda: _searchProducto.isNotEmpty ? _searchProducto : null),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) return _buildErrorWidget();
              
              List<dynamic> productos = snapshot.data as List? ?? [];

              if (productos.isEmpty) return const Center(child: Text("No hay productos disponibles"));

              return GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.65,
                ),
                itemCount: productos.length,
                itemBuilder: (context, i) {
                   final prod = productos[i];
                   final int stock = prod['stock'] ?? 10;

                   return Card(
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // IMAGEN
                        Expanded(
                          child: prod['imagen_url'] != null
                              ? Image.network(
                                  // ⚠️ Ajusta la IP si cambia en ApiService
                                  '${ApiService.baseUrl.replaceAll('/api', '')}/uploads/productos/${prod['imagen_url']}',
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    color: Colors.grey[200],
                                    child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                                  ),
                                )
                              : Container(
                                  color: Colors.grey[200],
                                  child: const Center(child: Icon(Icons.image, size: 50, color: Colors.grey)),
                                ),
                        ),
                        // INFORMACIÓN
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                prod['nombre'] ?? 'Producto',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '\$${prod['precio'] ?? 0}',
                                style: const TextStyle(color: Colors.green, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Por: ${prod['nombre_empresa'] ?? 'Sin empresa'}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              
                              const SizedBox(height: 8),

                              // BOTÓN AGREGAR
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.add_shopping_cart, size: 16),
                                  label: const Text("Agregar"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                  ),
                                  onPressed: () {
                                    final cart = Provider.of<CartProvider>(context, listen: false);
                                    String? resultado = cart.agregarItem(
                                      prod['id_producto'], 
                                      prod['nombre'], 
                                      double.parse(prod['precio'].toString()), 
                                      prod['imagen_url'] ?? '', 
                                      stock 
                                    );
                                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                    
                                    if (resultado == null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text("¡Producto agregado!"), 
                                          backgroundColor: Colors.green,
                                          duration: Duration(seconds: 1),
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(resultado), 
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
                                ),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.red),
          const SizedBox(height: 16),
          const Text("Error al conectar"),
          const SizedBox(height: 8),
          const Text(
            "Verifica tu conexión con el servidor",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}