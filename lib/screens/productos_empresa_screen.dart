// 1. ESTA LÍNEA ES LA QUE TE FALTABA Y CAUSABA EL ERROR:
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ProductosEmpresaScreen extends StatelessWidget {
  final int microempresaId;
  final String nombreEmpresa;

  // Constructor para recibir los datos de la empresa
  const ProductosEmpresaScreen({
    Key? key,
    required this.microempresaId,
    required this.nombreEmpresa,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(nombreEmpresa),
        backgroundColor: Colors.blue, // Opcional: Color de la barra
      ),
      body: FutureBuilder(
        // Llamamos al servicio para obtener productos solo de esta empresa
        future: ApiService().getProductosPorEmpresa(microempresaId),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          
          // 1. Cargando...
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. Si hay error
          if (snapshot.hasError) {
            return Center(
              child: Text('Error al cargar productos: ${snapshot.error}'),
            );
          }

          // 3. Si no hay datos o la lista está vacía
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey),
                  SizedBox(height: 10),
                  Text('Esta empresa aún no tiene productos.'),
                ],
              ),
            );
          }

          // 4. Mostrar la lista de productos
          final productos = snapshot.data!;

          return GridView.builder(
            padding: const EdgeInsets.all(10),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // 2 columnas
              childAspectRatio: 0.8, // Proporción alto/ancho
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: productos.length,
            itemBuilder: (context, index) {
              final prod = productos[index];
              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Imagen del producto
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                        child: prod['imagen_url'] != null
                            ? Image.network(
                                // TU IP Y RUTA CORRECTA:
                                'http://10.94.80.222:3000/uploads/productos/${prod['imagen_url']}',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.image_not_supported, color: Colors.grey),
                                  );
                                },
                              )
                            : Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.image, color: Colors.grey),
                              ),
                      ),
                    ),
                    // Datos del producto
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            prod['nombre'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '\$${prod['precio']}',
                            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                          ),
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
    );
  }
}