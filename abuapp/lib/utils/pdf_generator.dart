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

    // MultiPage permite dividir la información en varias hojas si hay muchas ventas
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter, // Tamaño Carta tradicional
        margin: const pw.EdgeInsets.all(32),
        
        // Pie de página automático con numeración
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 10),
            child: pw.Text(
              'Página ${context.pageNumber} de ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
          );
        },
        
        build: (pw.Context context) {
          return [
            // ENCABEZADO DEL DOCUMENTO
            pw.Text('REPORTE ADMINISTRATIVO DE CORTE', 
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900)
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Fecha de emisión: ${DateTime.now().toString().substring(0, 16)}', 
              style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)
            ),
            pw.SizedBox(height: 8),
            pw.Divider(thickness: 2, color: PdfColors.blueGrey800),
            pw.SizedBox(height: 15),

            // CUADROS DE RESUMEN FINANCIERO
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
            pw.Text(
              '1. DESGLOSE LÍNEA SAT (Ganado y Medicamentos)', 
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)
            ),
            pw.SizedBox(height: 6),
            _construirTablaPdf(ventasSat),
            pw.SizedBox(height: 25),

            // TABLA 2: LÍNEA GENERAL (CONTROL INTERNO)
            pw.Text(
              '2. DESGLOSE LÍNEA GENERAL (Plásticos y Maquinaria)', 
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.orange900)
            ),
            pw.SizedBox(height: 6),
            _construirTablaPdf(ventasInternas),
          ];
        },
      ),
    );

    // Abre el visor nativo del teléfono para imprimir por Wi-Fi, guardar o compartir en redes
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Reporte_Corte_${DateTime.now().toString().substring(0, 10)}.pdf',
    );
  }

  static pw.Widget _cajaResumenPdf(String titulo, double monto, PdfColor color) {
    return pw.Container(
      width: 160, // Ancho uniforme para balance visual
      padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color, width: 2),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        children: [
          pw.Text(titulo, 
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 4),
          pw.Text('\$${monto.toStringAsFixed(2)}', 
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: color)
          ),
        ],
      ),
    );
  }

  static pw.Widget _construirTablaPdf(List<Venta> ventas) {
    if (ventas.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey100,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        ),
        child: pw.Text('No hubo movimientos en esta categoría durante el periodo.', 
          style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)
        ),
      );
    }

    return pw.TableHelper.fromTextArray(
      headers: ['Folio', 'Fecha y Hora', 'Método Pago', 'Importe'],
      data: ventas.map((v) => [
        v.folio, 
        // Cortamos el ISO al minuto (ej: 2026-07-28 14:30) si viene largo
        v.fecha.length > 16 ? v.fecha.substring(0, 16).replaceFirst('T', ' ') : v.fecha,
        v.metodoPago, 
        '\$${v.total.toStringAsFixed(2)}'
      ]).toList(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 11),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
      cellStyle: const pw.TextStyle(fontSize: 10),
      cellAlignment: pw.Alignment.centerLeft,
      cellAlignments: {
        3: pw.Alignment.centerRight, // Alinear los números monetarios a la derecha en la tabla
      },
      cellPadding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
    );
  }
}