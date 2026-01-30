import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../services/api_service.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _direccionController = TextEditingController();
  String _metodoPago = 'Efectivo'; // Valor por defecto
  bool _isLoading = false;

  @override
  void dispose() {
    _direccionController.dispose();
    super.dispose();
  }

  Future<void> _confirmarPedido() async {
    if (!_formKey.currentState!.validate()) {
      return; // Si el formulario no es válido (falta dirección), no enviamos nada
    }

    final cart = Provider.of<CartProvider>(context, listen: false);
    
    // Validar que el carrito no esté vacío
    if (cart.items.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("El carrito está vacío")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = ApiService();
      
      // Preparamos los detalles de los productos para enviarlos al backend
      List<Map<String, dynamic>> detalles = cart.items.entries.map((entry) {
        final item = entry.value;
        return {
          "id_producto": item.id, // Asegúrate de que esto sea int
          "cantidad": item.cantidad,
          "precio_unitario": item.precio,
        };
      }).toList();

      // Enviamos los datos al servidor
      final success = await apiService.crearPedido(
        direccionEnvio: _direccionController.text,
        metodoPago: _metodoPago,
        total: cart.totalAmount,
        detalles: detalles,
      );

      if (success) {
        // ÉXITO
        cart.limpiarCarrito(); // Vaciamos el carrito local
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
              content: const Text(
                '¡Pedido realizado con éxito!\nGracias por tu compra.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop(); // Cerrar diálogo
                    Navigator.of(context).popUntil((route) => route.isFirst); // Ir al inicio
                  },
                  child: const Text('Volver al Inicio'),
                )
              ],
            ),
          );
        }
      } else {
        throw Exception("El servidor rechazó el pedido");
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${error.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Confirmar Pedido"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: cart.items.isEmpty
          ? const Center(child: Text("No hay productos para comprar."))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- SECCIÓN 1: RESUMEN DE PRODUCTOS ---
                    Text("Resumen de compra", style: theme.textTheme.titleLarge),
                    const SizedBox(height: 10),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: cart.items.length,
                      itemBuilder: (ctx, i) {
                        final item = cart.items.values.toList()[i];
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          child: ListTile(
                            leading: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                                image: item.imagenUrl.isNotEmpty
                                    ? DecorationImage(
                                        // Ajusta la IP aquí si la imagen no carga
                                        image: NetworkImage('http://10.94.80.222:3000/uploads/productos/${item.imagenUrl}'),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: item.imagenUrl.isEmpty ? const Icon(Icons.shopping_bag) : null,
                            ),
                            title: Text(item.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text("${item.cantidad} x \$${item.precio}"),
                            trailing: Text(
                              "\$${(item.cantidad * item.precio).toStringAsFixed(2)}",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                        );
                      },
                    ),

                    const Divider(height: 40),

                    // --- SECCIÓN 2: DATOS DE ENVÍO ---
                    Text("Datos de Envío", style: theme.textTheme.titleLarge),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _direccionController,
                      decoration: InputDecoration(
                        labelText: "Dirección de entrega",
                        hintText: "Ej: Av. 6 de Marzo #123, El Alto",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.location_on),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa una dirección';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // --- SECCIÓN 3: MÉTODO DE PAGO ---
                    Text("Método de Pago", style: theme.textTheme.titleLarge),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _metodoPago,
                          isExpanded: true,
                          icon: const Icon(Icons.payment, color: Colors.blue),
                          items: <String>['Efectivo', 'QR', 'Tarjeta'].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
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

                    const SizedBox(height: 30),

                    // --- SECCIÓN 4: TOTAL Y BOTÓN ---
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("TOTAL A PAGAR:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(
                            "\$${cart.totalAmount.toStringAsFixed(2)}",
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 5,
                        ),
                        onPressed: _isLoading ? null : _confirmarPedido,
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text("CONFIRMAR PEDIDO", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}