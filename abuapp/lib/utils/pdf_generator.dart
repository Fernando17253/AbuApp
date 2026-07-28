import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/venta_model.dart';

class PdfGenerator {
  
  static Future<void> generarReporteDueno(
    List<Venta> ventas, 
    double totalGeneral, 
    double totalSat, 
    double totalInterno
  ) async {
    final doc = pw.Document();

    // Separar las listas para las dos tablas del documento
    final ventasSat = ventas.where((v) => v.esLineaSat).toList();
    final ventasInternas = ventas.where((v) => !v.esLineaSat).toList();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter, // Tamaño Carta tradicional
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ENCABEZADO DEL DOCUMENTO
              pw.Text('REPORTE ADMINISTRATIVO DE CORTE', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
              pw.Text('Fecha de emisión: ${DateTime.now().toString().substring(0, 10)}', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 10),

              // CUADROS DE RESUMEN
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _cajaResumenPdf('TOTAL INGRESOS', totalGeneral, PdfColors.green800),
                  _cajaResumenPdf('LÍNEA SAT (Ganado/Meds)', totalSat, PdfColors.blue800),
                  _cajaResumenPdf('LÍNEA GENERAL (Plásticos)', totalInterno, PdfColors.orange800),
                ],
              ),
              pw.SizedBox(height: 25),

              // TABLA 1: LÍNEA SAT (ESTA ES LA QUE SE ENTREGA AL CONTADOR)
              pw.Text('1. DESGLOSE LÍNEA SAT (Ganado y Medicamentos)', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
              pw.SizedBox(height: 6),
              _construirTablaPdf(ventasSat),
              pw.SizedBox(height: 25),

              // TABLA 2: LÍNEA GENERAL (CONTROL INTERNO)
              pw.Text('2. DESGLOSE LÍNEA GENERAL (Plásticos y Maquinaria)', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.orange900)),
              pw.SizedBox(height: 6),
              _construirTablaPdf(ventasInternas),
            ],
          );
        },
      ),
    );

    // Abre el visor nativo del teléfono para imprimir por Wi-Fi o enviar el PDF
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Reporte_Corte_${DateTime.now().toString().substring(0, 10)}.pdf',
    );
  }

  static pw.Widget _cajaResumenPdf(String titulo, double monto, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color, width: 2),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        children: [
          pw.Text(titulo, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text('\$${monto.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  static pw.Widget _construirTablaPdf(List<Venta> ventas) {
    if (ventas.isEmpty) {
      return pw.Text('No hubo movimientos en esta categoría.', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey));
    }

    return pw.TableHelper.fromTextArray(
      headers: ['Folio', 'Fecha', 'Método Pago', 'Importe'],
      data: ventas.map((v) => [v.folio, v.fecha, v.metodoPago, '\$${v.total.toStringAsFixed(2)}']).toList(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
      cellAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.all(6),
    );
  }
}