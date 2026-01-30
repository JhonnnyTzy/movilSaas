import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../services/api_service.dart'; // Para verificar si está logueado
import 'login_screen.dart';
import 'checkout_screen.dart'; // Asegúrate de tener este import

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Escuchamos el carrito del Provider
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mi Carrito"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: cart.items.isEmpty
          ? const Center(
              child: Text(
                "Tu carrito está vacío 🛒",
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : Column(
              children: [
                // === LISTA DE PRODUCTOS ===
                Expanded(
                  child: ListView.builder(
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) {
                      // Obtenemos los valores desde el mapa del provider
                      final item = cart.items.values.toList()[index];
                      final productId = cart.items.keys.toList()[index];

                      return Dismissible(
                        key: ValueKey(productId),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) {
                          cart.eliminarItem(productId);
                        },
                        child: Card(
                          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.white,
                              // Verifica si tiene imagen, si no muestra icono
                              backgroundImage: item.imagenUrl.isNotEmpty
                                  ? NetworkImage('http://10.94.80.222:3000/uploads/productos/${item.imagenUrl}')
                                  : null,
                              child: item.imagenUrl.isEmpty
                                  ? const Icon(Icons.image_not_supported)
                                  : null,
                            ),
                            title: Text(item.nombre), // Usamos 'nombre'
                            subtitle: Text(
                                "Total: Bs ${(item.precio * item.cantidad).toStringAsFixed(2)}"),
                            trailing: SizedBox(
                              width: 120,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline),
                                    onPressed: () {
                                      cart.removerUnItem(productId);
                                    },
                                  ),
                                  Text("${item.cantidad}"), // Usamos 'cantidad'
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline),
                                    onPressed: () {
                                      // Al sumar, intentamos agregar 1 más.
                                      // El provider validará el stock automáticamente.
                                      String? error = cart.agregarItem(
                                        productId, 
                                        item.nombre, 
                                        item.precio, 
                                        item.imagenUrl, 
                                        item.stockMaximo
                                      );
                                      if (error != null) {
                                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(error), duration: const Duration(seconds: 1)),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // === RESUMEN Y BOTÓN DE PAGO ===
                Card(
                  margin: const EdgeInsets.all(15),
                  elevation: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Total:", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            Chip(
                              label: Text(
                                "Bs ${cart.totalAmount.toStringAsFixed(2)}",
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                              backgroundColor: Colors.green,
                            )
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () {
                              // 1️⃣ VALIDAR CARRITO VACÍO
                              if (cart.items.isEmpty) return;

                              // 2️⃣ PREPARAR DATOS (Convertir Provider -> Lista para Checkout)
                              // Aquí convertimos los objetos del carrito en la lista que espera la siguiente pantalla
                              List<Map<String, dynamic>> listaParaCheckout = cart.items.values.map((item) {
                                return {
                                  'id_producto': item.id, 
                                  'nombre': item.nombre, 
                                  'cantidad': item.cantidad,
                                  'precio': item.precio,
                                };
                              }).toList();

                              // 3️⃣ LÓGICA DE LOGIN
                              if (ApiService.estaLogueado()) {
                                // ✅ SI ESTÁ LOGUEADO -> VA AL CHECKOUT
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => CheckoutScreen(
                                      carrito: listaParaCheckout, // Lista convertida
                                      total: cart.totalAmount,    // Total del provider
                                    ),
                                  ),
                                );
                              } else {
                                // ❌ NO ESTÁ LOGUEADO -> MUESTRA DIÁLOGO
                                _mostrarDialogoIdentificacion(context);
                              }
                            },
                            child: const Text("PROCEDER AL PAGO", style: TextStyle(fontSize: 16)),
                          ),
                        )
                      ],
                    ),
                  ),
                )
              ],
            ),
    );
  }

  void _mostrarDialogoIdentificacion(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Inicia Sesión'),
        content: const Text('Debes estar registrado para finalizar la compra.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop(); // Cierra el diálogo
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => LoginScreen()) 
              );
            },
            child: const Text('Ir al Login'),
          ),
        ],
      ),
    );
  }
}