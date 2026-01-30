import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; //
import 'providers/cart_provider.dart';   //
import 'screens/home_screen.dart';

void main() {
  runApp(
    // [MODIFICACIÓN] MultiProvider es el encargado de que toda la app 
    // tenga acceso al carrito de compras.
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()), //
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Paragit Movil',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // Inicia con HomeScreen para ver productos sin login
      home: HomeScreen(), 
    );
  }
}