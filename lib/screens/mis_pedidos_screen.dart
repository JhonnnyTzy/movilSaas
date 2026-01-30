import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/pdf_service.dart'; // Asegúrate de importar tu servicio de PDF

class MisPedidosScreen extends StatefulWidget {
  const MisPedidosScreen({Key? key}) : super(key: key);

  @override
  State<MisPedidosScreen> createState() => _MisPedidosScreenState();
}

class _MisPedidosScreenState extends State<MisPedidosScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Mis Pedidos"),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: ApiService().getMisPedidos(), 
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Aún no tienes pedidos registrados."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final pedido = snapshot.data![index];
              return _buildPedidoCard(pedido);
            },
          );
        },
      ),
    );
  }

  Widget _buildPedidoCard(dynamic pedido) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 3,
      child: ExpansionTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.blueAccent,
          child: Icon(Icons.receipt_long, color: Colors.white),
        ),
        title: Text("Pedido #${pedido['id_pedido']}", style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Fecha: ${pedido['fecha'].toString().substring(0, 10)}"),
        trailing: _buildStatusBadge(pedido['estado'] ?? 'Pendiente'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Detalle de productos:", style: TextStyle(fontWeight: FontWeight.bold)),
                const Divider(),
                ...(pedido['productos'] as List).map((prod) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("${prod['cantidad']}x ${prod['nombre']}"),
                      Text("Bs ${prod['precio_unitario']}"),
                    ],
                  ),
                )).toList(),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("TOTAL:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text("Bs ${pedido['total']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blueAccent)),
                  ],
                ),
                const SizedBox(height: 20),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _generarComprobante(pedido),
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text("VER OPCIONES DE COMPROBANTE"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String estado) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: estado == 'Entregado' ? Colors.green : Colors.orange,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(estado, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  void _generarComprobante(dynamic pedido) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.picture_as_pdf, color: Colors.red),
            SizedBox(width: 10),
            Text("Comprobante"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Se generará el reporte de la Compra #${pedido['id_pedido']}"),
            const SizedBox(height: 10),
            Text("Proveedor: ${pedido['empresa_nombre'] ?? 'Desconocido'}"),
            const SizedBox(height: 5),
            const Text("Formato: PDF (A4)"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("CANCELAR"),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              // Llamada al servicio que creamos para generar el PDF real
            PdfGenerator.generarPDF(pedido);            },
            icon: const Icon(Icons.download),
            label: const Text("DESCARGAR"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}