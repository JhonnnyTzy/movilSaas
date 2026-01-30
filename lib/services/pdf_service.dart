import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfGenerator {
  static Future<void> generarPDF(dynamic pedido) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              // CORRECCIÓN AQUÍ: Se llama crossAxisAlignment, no 'cross'
              crossAxisAlignment: pw.CrossAxisAlignment.start, 
              children: [
                pw.Header(level: 0, child: pw.Text("COMPROBANTE DE COMPRA")),
                pw.SizedBox(height: 10),
                pw.Text("Pedido #: ${pedido['id_pedido']}"),
                pw.Text("Fecha: ${pedido['fecha'].toString().substring(0, 10)}"),
                pw.Text("Estado: ${pedido['estado']}"),
                pw.SizedBox(height: 20),
                
                // Tabla de productos
                pw.Table.fromTextArray(
                  headers: ['Cant.', 'Producto', 'Precio Unit.', 'Subtotal'],
                  data: (pedido['productos'] as List).map((item) {
                    final cant = item['cantidad'];
                    // Aseguramos que sea un número para evitar errores de parseo
                    final precio = double.parse(item['precio_unitario'].toString());
                    return [
                      cant,
                      item['nombre'],
                      "Bs $precio",
                      "Bs ${(cant * precio).toStringAsFixed(2)}"
                    ];
                  }).toList(),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
                ),
                
                pw.SizedBox(height: 20),
                pw.Divider(),
                
                // Total
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                    "TOTAL PAGADO: Bs ${pedido['total']}",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18),
                  ),
                ),
                
                pw.SizedBox(height: 40),
                pw.Center(
                  child: pw.Text("Gracias por su preferencia", 
                    style: pw.TextStyle(fontStyle: pw.FontStyle.italic, color: PdfColors.grey700)
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    // Abre el diálogo de impresión/guardado
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Comprobante_${pedido['id_pedido']}.pdf',
    );
  }
}