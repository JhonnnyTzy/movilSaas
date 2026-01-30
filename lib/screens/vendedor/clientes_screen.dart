import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  final ApiService _apiService = ApiService();
  
  List<dynamic> _clientes = [];
  List<dynamic> _clientesFiltrados = [];
  bool _isLoading = true;
  String _filtro = "";

  @override
  void initState() {
    super.initState();
    _fetchClientes();
  }

  // Carga datos reales desde la BD
  Future<void> _fetchClientes() async {
    setState(() => _isLoading = true);
    try {
      final lista = await _apiService.getClientes();
      setState(() {
        _clientes = lista;
        _clientesFiltrados = lista;
        _isLoading = false;
      });
    } catch (e) {
      print("Error cargando clientes: $e");
      setState(() => _isLoading = false);
    }
  }

  // Función de búsqueda local
  void _filtrarClientes(String texto) {
    setState(() {
      _filtro = texto.toLowerCase();
      _clientesFiltrados = _clientes.where((c) {
        final nombre = (c['nombre_razon_social'] ?? '').toLowerCase();
        final ci = (c['ci_nit'] ?? '').toLowerCase();
        return nombre.contains(_filtro) || ci.contains(_filtro);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Calculamos contadores reales
    final activos = _clientes.where((c) => c['estado'] == 'activo').length;
    final inactivos = _clientes.where((c) => c['estado'] == 'inactivo').length;

    return Column(
      children: [
        // 1. Resumen superior
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildCounterCard("Activos", "$activos", Colors.green),
              _buildCounterCard("Inactivos", "$inactivos", Colors.red),
            ],
          ),
        ),
        const Divider(),
        
        // 2. Buscador
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: TextField(
            onChanged: _filtrarClientes,
            decoration: InputDecoration(
              hintText: "Buscar por nombre o CI/NIT...",
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: Colors.grey[100],
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ),
        
        const SizedBox(height: 10),

        // 3. Lista de clientes desde BD
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _clientesFiltrados.isEmpty
                  ? Center(
                      child: Text(
                        _filtro.isEmpty 
                            ? "No hay clientes registrados" 
                            : "No se encontraron resultados",
                        style: const TextStyle(color: Colors.grey),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchClientes,
                      child: ListView.builder(
                        itemCount: _clientesFiltrados.length,
                        itemBuilder: (context, index) {
                          final cliente = _clientesFiltrados[index];
                          final id = cliente['id_cliente'];
                          final nombre = cliente['nombre_razon_social'] ?? 'Sin Nombre';
                          final ci = cliente['ci_nit'] ?? 'S/N';
                          final contacto = cliente['telefono'] ?? cliente['email'] ?? '';
                          final estado = cliente['estado'] ?? 'inactivo';
                          final esActivo = estado == 'activo';

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: esActivo ? Colors.blue.shade100 : Colors.grey.shade300,
                                child: Text(
                                  "#$id", 
                                  style: TextStyle(
                                    color: esActivo ? Colors.blue.shade900 : Colors.grey.shade700, 
                                    fontSize: 12, 
                                    fontWeight: FontWeight.bold
                                  )
                                ),
                              ),
                              title: Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("CI/NIT: $ci"),
                                  if (contacto.toString().isNotEmpty) 
                                    Text("Contacto: $contacto", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                ],
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: esActivo ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  estado.toUpperCase(),
                                  style: TextStyle(
                                    color: esActivo ? Colors.green : Colors.red,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold
                                  ),
                                ),
                              ),
                              onTap: () {
                                 // Aquí podrías navegar a editar cliente
                              },
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildCounterCard(String label, String count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5)]
      ),
      child: Column(
        children: [
          Text(count, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}