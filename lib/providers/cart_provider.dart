import 'package:flutter/material.dart';

// Modelo simple para un ítem del carrito
class CartItem {
  final int id;
  final String nombre;
  final double precio;
  final String imagenUrl; // ✅ Usaremos solo esta para evitar errores
  int cantidad;
  final int stockMaximo;

  CartItem({
    required this.id,
    required this.nombre,
    required this.precio,
    required this.imagenUrl, // ✅ AÑADIDO: Ahora se inicializa correctamente
    required this.cantidad,
    required this.stockMaximo,
  });
}

class CartProvider with ChangeNotifier {
  // Mapa para guardar los items (ID del producto -> Item del carrito)
  Map<int, CartItem> _items = {};

  Map<int, CartItem> get items => _items;

  // Cantidad total de artículos en el carrito
  int get itemCount => _items.length;

  // Total a pagar
  double get totalAmount {
    var total = 0.0;
    _items.forEach((key, item) {
      total += item.precio * item.cantidad;
    });
    return total;
  }

  // AGREGAR AL CARRITO
  String? agregarItem(int id, String nombre, double precio, String imagenUrl, int stockDisponible) {
    if (_items.containsKey(id)) {
      // Si ya existe, intentamos sumar 1
      if (_items[id]!.cantidad < stockDisponible) {
        _items.update(
          id,
          (existingItem) => CartItem(
            id: existingItem.id,
            nombre: existingItem.nombre,
            precio: existingItem.precio,
            imagenUrl: existingItem.imagenUrl, // Mantenemos la imagen original
            cantidad: existingItem.cantidad + 1,
            stockMaximo: stockDisponible,
          ),
        );
      } else {
        return "¡Has alcanzado el límite de stock disponible!";
      }
    } else {
      // Si no existe, lo creamos
      if (stockDisponible > 0) {
        _items.putIfAbsent(
          id,
          () => CartItem(
            id: id,
            nombre: nombre,
            precio: precio,
            imagenUrl: imagenUrl, // Guardamos la imagen que viene
            cantidad: 1,
            stockMaximo: stockDisponible,
          ),
        );
      } else {
        return "Producto agotado.";
      }
    }
    notifyListeners();
    return null;
  }

  // RESTAR CANTIDAD
  void removerUnItem(int id) {
    if (!_items.containsKey(id)) return;

    if (_items[id]!.cantidad > 1) {
      _items.update(
        id,
        (existingItem) => CartItem(
            id: existingItem.id,
            nombre: existingItem.nombre,
            precio: existingItem.precio,
            imagenUrl: existingItem.imagenUrl,
            cantidad: existingItem.cantidad - 1,
            stockMaximo: existingItem.stockMaximo),
      );
    } else {
      _items.remove(id);
    }
    notifyListeners();
  }

  // BORRAR COMPLETAMENTE UN PRODUCTO
  // ✅ RENOMBRADO: De 'eliminarProducto' a 'eliminarItem' para que coincida con CartScreen
  void eliminarItem(int id) {
    _items.remove(id);
    notifyListeners();
  }

  // LIMPIAR CARRITO
  void limpiarCarrito() {
    _items = {};
    notifyListeners();
  }
}