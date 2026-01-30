import 'package:flutter/material.dart';
import '../../services/api_service.dart'; // Ruta corregida hacia services

class VentasScreen extends StatefulWidget {
  const VentasScreen({super.key});

  @override
  State<VentasScreen> createState() => _VentasScreenState();
}

class _VentasScreenState extends State<VentasScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> ventas = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchVentas();
  }

  Future<void> _fetchVentas() async {
    // Si ya estamos cargando y el usuario refresca, no seteamos isLoading a true visualmente
    // para no parpadear, a menos que sea la primera carga.
    if (ventas.isEmpty) {
      setState(() => isLoading = true);
    }

    try {
      final lista = await _apiService.getVentasVendedor();
      
      if (mounted) {
        setState(() {
          ventas = lista;
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error cargando ventas: $e");
      if (mounted) {
        setState(() => isLoading = false);
        // Solo mostramos error si la lista está vacía, para no molestar si ya hay datos
        if (ventas.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("No se pudo cargar el historial. Revisa tu conexión."),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Estado de Carga Inicial
    if (isLoading && ventas.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // 2. Estado Sin Ventas
    if (ventas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 15),
            const Text(
              "No tienes ventas registradas",
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _fetchVentas,
              icon: const Icon(Icons.refresh),
              label: const Text("Recargar"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
            )
          ],
        ),
      );
    }

    // 3. Lista de Ventas
    return RefreshIndicator(
      onRefresh: _fetchVentas,
      color: Colors.indigo,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: ventas.length,
        itemBuilder: (context, index) {
          final venta = ventas[index];

          // --- EXTRACCIÓN SEGURA DE DATOS ---
          // Aceptamos 'id' o 'id_pedido' según como venga del backend
          final idDisplay = venta['id'] ?? venta['id_pedido'] ?? '---';
          
          // Nombre del cliente o Genérico
          final cliente = venta['cliente_nombre'] ?? venta['nombre_cliente'] ?? 'Cliente';
          
          // Fecha formateada
          String fechaDisplay = 'Fecha desc.';
          if (venta['fecha_creacion'] != null) {
            fechaDisplay = venta['fecha_creacion'].toString().substring(0, 10);
          } else if (venta['fecha'] != null) {
             fechaDisplay = venta['fecha'].toString().substring(0, 10);
          }

          // Total con formato decimal seguro
          final rawTotal = venta['total'] ?? 0;
          final totalDisplay = double.parse(rawTotal.toString()).toStringAsFixed(2);
          
          // Estado
          final estado = venta['estado'] ?? 'completado'; // Asumimos completado si no viene

          return Card(
            elevation: 3,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                // Aquí podrías navegar al detalle de la venta en el futuro
                ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(content: Text("Venta #$idDisplay seleccionada"))
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getColorEstado(estado).withOpacity(0.2),
                    child: Icon(Icons.shopping_bag, color: _getColorEstado(estado)),
                  ),
                  title: Text(
                    "Venta #$idDisplay",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text("$cliente", style: TextStyle(color: Colors.grey[700])),
                      Text(fechaDisplay, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "Bs $totalDisplay",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent // Color azul como en tu diseño web
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getColorEstado(estado),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          estado.toString().toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Helper para colores según estado
  Color _getColorEstado(String estado) {
    switch (estado.toString().toLowerCase()) {
      case 'pendiente': return Colors.orange;
      case 'completado': return Colors.green;
      case 'entregado': return Colors.blue;
      case 'cancelado': return Colors.red;
      default: return Colors.green; // Por defecto verde para ventas exitosas
    }
  }
}