import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../services/api_service.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final ApiService _apiService = ApiService();
  
  List<dynamic> productos = [];
  List<dynamic> clientes = []; 
  Map<String, dynamic>? clienteSeleccionado; 
  String nombreVendedor = "Cargando...";
  bool isLoading = true;
  List<Map<String, dynamic>> carrito = []; 

  // URL exacta según tu estructura de backend y tu IP local
  final String baseUrlImagenes = "http://10.94.80.222:3000/uploads/productos/"; 

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
  }

  Future<void> _cargarDatosIniciales() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      nombreVendedor = prefs.getString('nombre_usuario') ?? "Vendedor";
    });

    try {
      final resProd = await _apiService.getProductosEmpresa();
      final resCli = await _apiService.getClientes(); 
      
      setState(() {
        productos = resProd;
        clientes = resCli;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error al cargar datos: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  // --- FUNCIÓN PARA GENERAR EL TICKET PDF ---
  Future<void> _generarTicketPDF(double total) async {
    final pdf = pw.Document();
    
    // Cargamos una fuente que soporte caracteres especiales como "Bs" o tildes
    final font = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80, // Formato ideal para ticketeras térmicas
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text("TICKET DE VENTA", 
                  style: pw.TextStyle(font: fontBold, fontSize: 16)),
              ),
              pw.SizedBox(height: 10),
              pw.Text("Vendedor: $nombreVendedor", style: pw.TextStyle(font: font)),
              pw.Text("Cliente: ${clienteSeleccionado?['nombre_razon_social'] ?? 'Público General'}", 
                style: pw.TextStyle(font: font)),
              pw.Text("Fecha: ${DateTime.now().toString().substring(0, 19)}", 
                style: pw.TextStyle(font: font)),
              pw.Divider(thickness: 1),
              pw.Text("PRODUCTOS:", style: pw.TextStyle(font: fontBold)),
              pw.SizedBox(height: 5),
              
              // Listado de productos en el PDF
              ...carrito.map((item) => pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 2),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      child: pw.Text("${item['nombre']} x${item['cantidad']}", 
                        style: pw.TextStyle(font: font)),
                    ),
                    pw.Text("Bs ${(item['precio'] * item['cantidad']).toStringAsFixed(2)}", 
                      style: pw.TextStyle(font: font)),
                  ],
                ),
              )),
              
              pw.Divider(thickness: 1),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text("TOTAL: Bs ${total.toStringAsFixed(2)}", 
                  style: pw.TextStyle(font: fontBold, fontSize: 14)),
              ),
              pw.SizedBox(height: 20),
              pw.Center(
                child: pw.Text("¡GRACIAS POR SU COMPRA!", 
                  style: pw.TextStyle(font: font, fontSize: 10)),
              ),
            ],
          );
        },
      ),
    );

    // Muestra la previsualización del PDF antes de imprimir o guardar
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Ticket_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  // --- MODAL DEL CARRITO Y PAGO ---
  void _abrirCarrito(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25))
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            double totalVenta = carrito.fold(0, (sum, item) => sum + (item['precio'] * item['cantidad']));

            return Container(
              padding: const EdgeInsets.all(20),
              height: MediaQuery.of(context).size.height * 0.8,
              child: Column(
                children: [
                  const Text("RESUMEN DE VENTA", 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  
                  // DROPDOWN PARA SELECCIONAR CLIENTE (Usando tu campo nombre_razon_social)
                  DropdownButtonFormField<Map<String, dynamic>>(
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: "Cliente",
                      border: OutlineInputBorder(),
                    ),
                    hint: const Text("Seleccionar Cliente"),
                    value: clienteSeleccionado,
                    items: clientes.map((cli) {
                      return DropdownMenuItem<Map<String, dynamic>>(
                        value: cli as Map<String, dynamic>,
                        child: Text(cli['nombre_razon_social']?.toString() ?? 'Sin nombre'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setModalState(() => clienteSeleccionado = val);
                      setState(() {}); 
                    },
                  ),
                  
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: carrito.length,
                      itemBuilder: (context, i) {
                        final item = carrito[i];
                        return ListTile(
                          leading: const Icon(Icons.shopping_bag_outlined),
                          title: Text(item['nombre']),
                          subtitle: Text("Bs ${item['precio']} x ${item['cantidad']}"),
                          trailing: Text("Bs ${(item['precio'] * item['cantidad']).toStringAsFixed(2)}"),
                        );
                      },
                    ),
                  ),
                  
                  const Divider(thickness: 2),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("TOTAL A PAGAR:", 
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text("Bs ${totalVenta.toStringAsFixed(2)}", 
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green)),
                      ],
                    ),
                  ),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[900],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                      ),
                      icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                      label: const Text("FINALIZAR VENTA Y PDF", 
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                      onPressed: (clienteSeleccionado == null || carrito.isEmpty) 
                        ? null 
                        : () {
                          Navigator.pop(context);
                          _generarTicketPDF(totalVenta);
                          setState(() {
                            carrito.clear();
                            clienteSeleccionado = null;
                          });
                        },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Vendedor: $nombreVendedor", style: const TextStyle(fontSize: 16)),
        backgroundColor: Colors.blue[800],
        actions: [
          if (carrito.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.white),
              onPressed: () => setState(() => carrito.clear()),
            )
        ],
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator())
        : GridView.builder(
            padding: const EdgeInsets.all(10),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, 
              childAspectRatio: 0.72,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10
            ),
            itemCount: productos.length,
            itemBuilder: (context, index) {
              final p = productos[index];
              final urlFinal = "$baseUrlImagenes${p['imagen_url']}";

              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Column(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                        child: Image.network(
                          urlFinal,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          // Fallback si la imagen no carga
                          errorBuilder: (context, error, stackTrace) {
                            debugPrint("Error cargando: $urlFinal");
                            return Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                            );
                          },
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      child: Text(
                        p['nombre'] ?? 'Sin nombre', 
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text("Bs ${p['precio']}", 
                      style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                    
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 0),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                          ),
                          icon: const Icon(Icons.add_shopping_cart, size: 18, color: Colors.white),
                          label: const Text("Agregar", style: TextStyle(color: Colors.white, fontSize: 12)),
                          onPressed: () {
                            setState(() {
                              // Buscar si ya existe el producto en el carrito
                              int existingIndex = carrito.indexWhere((item) => item['id'] == p['id_producto']);
                              
                              if (existingIndex != -1) {
                                carrito[existingIndex]['cantidad']++;
                              } else {
                                carrito.add({
                                  'id': p['id_producto'],
                                  'nombre': p['nombre'],
                                  'precio': double.tryParse(p['precio'].toString()) ?? 0.0,
                                  'cantidad': 1
                                });
                              }
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("${p['nombre']} añadido"),
                                duration: const Duration(seconds: 1),
                              )
                            );
                          },
                        ),
                      ),
                    )
                  ],
                ),
              );
            },
          ),
      floatingActionButton: carrito.isNotEmpty ? FloatingActionButton.extended(
        onPressed: () => _abrirCarrito(context),
        label: Text("COBRAR BS ${carrito.fold(0.0, (sum, item) => sum + (item['precio'] * item['cantidad'])).toStringAsFixed(2)}"),
        icon: const Icon(Icons.shopping_cart_checkout),
        backgroundColor: Colors.blue[900],
      ) : null,
    );
  }
}