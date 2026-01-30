import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../login_screen.dart';
import 'pos_screen.dart';      // Crea este archivo para el Punto de Venta
import 'clientes_screen.dart'; // Tu pantalla de clientes conectada a BD
import 'ventas_screen.dart';   // Tu pantalla de historial de ventas

class VendedorHomeScreen extends StatefulWidget {
  const VendedorHomeScreen({super.key});

  @override
  State<VendedorHomeScreen> createState() => _VendedorHomeScreenState();
}

class _VendedorHomeScreenState extends State<VendedorHomeScreen> {
  int _selectedIndex = 0;
  String? nombreVendedor;

  // Lista de las 3 funciones principales que quieres
  final List<Widget> _screens = [
    const PosScreen(),      // Interfaz de "Ventas" (Punto de Venta)
    const ClientesScreen(), // Interfaz de "Clientes"
    const VentasScreen(),   // Interfaz de Historial de Ventas realizadas
  ];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      nombreVendedor = prefs.getString('nombre');
    });
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedIndex == 0 
            ? "Punto de Venta" 
            : _selectedIndex == 1 ? "Gestión de Clientes" : "Historial de Ventas"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          if (nombreVendedor != null)
            Center(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text("Vendedor: $nombreVendedor", style: const TextStyle(fontSize: 12)),
            )),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
            },
          )
        ],
      ),
      body: _screens[_selectedIndex],
      // Menú inferior para que el vendedor pueda vender y ver clientes
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Vender'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Clientes'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Historial'),
        ],
      ),
    );
  }
}