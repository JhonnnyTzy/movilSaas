import 'package:flutter/material.dart';
import '../services/api_service.dart'; // Asegúrate de importar tu servicio

// Importa tu modelo de producto si lo tienes, o usa Map como en el ejemplo

class CheckoutScreen extends StatefulWidget {
  final List<dynamic> carrito;
  final double total;

  const CheckoutScreen({Key? key, required this.carrito, required this.total}) : super(key: key);

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _isLoading = false;
  String _metodoPago = 'Efectivo'; // Valor por defecto

  // Obtener datos del usuario logueado
  final Map<String, dynamic> usuario = ApiService.usuario;

  void _confirmarPedido() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Preparamos los detalles para el formato que pide el backend
      List<Map<String, dynamic>> detalles = widget.carrito.map((prod) {
        return {
          "id_producto": prod['id_producto'],
          "cantidad": prod['cantidad'],
          "precio_unitario": prod['precio'],
          "nombre": prod['nombre'] // Opcional, solo referencia
        };
      }).toList();

      await ApiService().crearPedido(
        direccionEnvio: "Dirección registrada del cliente", // O un campo de texto si prefieres
        metodoPago: _metodoPago,
        total: widget.total,
        detalles: detalles,
      );

      // Éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ ¡Venta confirmada exitosamente!'), backgroundColor: Colors.green),
      );

      // Regresar al inicio y limpiar carrito (ajusta esto según tu navegación)
      Navigator.popUntil(context, (route) => route.isFirst);

    } catch (e) {
      // Mostrar error bonito
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Error al procesar"),
          content: Text(e.toString().contains("DOCTYPE") 
            ? "Error de conexión con el servidor (Ruta no encontrada)." 
            : e.toString().replaceAll("Exception:", "")),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cerrar"))
          ],
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calcular cantidad total de unidades
    int totalUnidades = widget.carrito.fold(0, (sum, item) => sum + (item['cantidad'] as int));

    return Scaffold(
      backgroundColor: Colors.grey[100], // Fondo gris suave como web
      appBar: AppBar(
        title: const Text("Confirmar Compra"),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Resumen de la Compra",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 15),

            // 1️⃣ SECCIÓN INFORMACIÓN DEL CLIENTE
            _buildSectionTitle("Información del Cliente"),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildInfoRow(Icons.person, "Cliente:", usuario['nombre_razon_social'] ?? 'Desconocido'),
                    const Divider(),
                    _buildInfoRow(Icons.email, "Email:", usuario['email'] ?? 'No registrado'),
                    const Divider(),
                    _buildInfoRow(Icons.badge, "ID Cliente:", "#${usuario['id'] ?? '0'}"),
                    const Divider(),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: Colors.green.shade200)
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 20),
                          SizedBox(width: 8),
                          Text("Cliente Registrado y Activo", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 2️⃣ MÉTODO DE PAGO
            _buildSectionTitle("Método de Pago"),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 5),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _metodoPago,
                    isExpanded: true,
                    icon: const Icon(Icons.payment, color: Colors.blue),
                    items: <String>['Efectivo', 'QR', 'Transferencia'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _metodoPago = newValue!;
                      });
                    },
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(left: 8.0, top: 5),
              child: Text("ℹ️ Prepare el cambio correspondiente si es efectivo.", style: TextStyle(color: Colors.grey, fontSize: 12)),
            ),
            const SizedBox(height: 20),

            // 3️⃣ RESUMEN DEL PEDIDO
            _buildSectionTitle("Resumen del Pedido"),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Column(
                children: [
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.carrito.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = widget.carrito[index];
                      final subtotal = (item['cantidad'] * double.parse(item['precio'].toString()));
                      return ListTile(
                        leading: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8)
                          ),
                          child: const Icon(Icons.shopping_bag_outlined, color: Colors.blue),
                        ),
                        title: Text(item['nombre'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("x${item['cantidad']} unidades"),
                        trailing: Text("Bs ${subtotal.toStringAsFixed(2)}", 
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      );
                    },
                  ),
                  Container(
                    color: Colors.blue[50],
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildSummaryRow("Cantidad de productos:", "${widget.carrito.length}"),
                        const SizedBox(height: 5),
                        _buildSummaryRow("Unidades totales:", "$totalUnidades"),
                        const Divider(color: Colors.blue),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("TOTAL A PAGAR:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                            Text("Bs ${widget.total.toStringAsFixed(2)}", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue[800])),
                          ],
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 30),

            // 4️⃣ BOTÓN CONFIRMAR
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _confirmarPedido,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 5,
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("CONFIRMAR VENTA", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 20),

            // 5️⃣ ADVERTENCIAS (FOOTER)
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.shade200)
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text("⚠️ Verificaciones importantes:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                  SizedBox(height: 5),
                  Text("• Se verificará el stock antes de procesar.", style: TextStyle(fontSize: 12)),
                  Text("• Si algún producto no tiene stock, la venta será cancelada.", style: TextStyle(fontSize: 12)),
                  Text("• Se generará un comprobante de venta automático.", style: TextStyle(fontSize: 12)),
                  Text("• Los datos se guardarán en el historial.", style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // Widgets auxiliares para limpiar el código
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(title.toUpperCase(), 
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.0)),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600], size: 20),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.black54)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}