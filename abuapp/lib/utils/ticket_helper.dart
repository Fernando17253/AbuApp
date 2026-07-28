import '../screens/pos/pos_screen.dart'; // Para importar ItemCarrito

class TicketHelper {
  
  // Genera el texto plano que se enviará a la impresora Bluetooth
  static String generarTextoTicket({
    required String folio,
    required List<ItemCarrito> items,
    required double total,
    required String metodoPago,
  }) {
    final StringBuffer ticket = StringBuffer();
    
    // Revisa si en este cobro va alguna maquinaria (aspersor, motor, etc.)
    final tieneMaquinaria = items.any((item) => item.producto.categoria == 'maquinaria');

    // 1. ENCABEZADO
    ticket.writeln('=================================');
    ticket.writeln('   NEGOCIO GANADERO Y AGRÍCOLA   ');
    ticket.writeln('=================================');
    ticket.writeln('Folio: $folio');
    ticket.writeln('Fecha: ${DateTime.now().toString().substring(0, 16)}');
    ticket.writeln('Pago:  $metodoPago');
    ticket.writeln('---------------------------------');
    ticket.writeln('CANT  DESCRIPCIÓN      IMPORTE   ');
    ticket.writeln('---------------------------------');

    // 2. DESGLOSE DE PRODUCTOS
    for (var item in items) {
      final cant = item.producto.esPorPeso 
          ? '${item.cantidad.toStringAsFixed(1)}kg' 
          : '${item.cantidad.toInt()}pz';
      final nombre = item.producto.nombre.length > 14 
          ? item.producto.nombre.substring(0, 14) 
          : item.producto.nombre.padRight(14);
      final precio = '\$${item.precioTotal.toStringAsFixed(2)}'.padLeft(9);

      ticket.writeln('$cant $nombre $precio');
      
      // Si el animal tiene arete o fierro registrado, se imprime debajo
      if (item.producto.areteFierro != null && item.producto.areteFierro!.isNotEmpty) {
        ticket.writeln('   Fierro/Arete: ${item.producto.areteFierro}');
      }
    }

    ticket.writeln('---------------------------------');
    ticket.writeln('TOTAL A PAGAR:  \$${total.toStringAsFixed(2)}'.padLeft(33));
    ticket.writeln('=================================');

    // 3. CLÁUSULA LEGAL DE GARANTÍA (SOLO SE IMPRIME SI HAY MAQUINARIA)
    if (tieneMaquinaria) {
      ticket.writeln('');
      ticket.writeln('*********************************');
      ticket.writeln('     GARANTÍA DE MAQUINARIA      ');
      ticket.writeln('*********************************');
      ticket.writeln('Las máquinas y equipos incluidos en');
      ticket.writeln('esta nota cuentan con 3 MESES DE ');
      ticket.writeln('GARANTÍA contra defectos de fábrica.');
      ticket.writeln('Es OBLIGATORIO presentar este ticket');
      ticket.writeln('físico para cualquier reclamo o');
      ticket.writeln('devolución con el proveedor.');
      ticket.writeln('*********************************');
    }

    ticket.writeln('');
    ticket.writeln('     ¡GRACIAS POR SU COMPRA!     ');
    ticket.writeln('\n\n\n'); // Espacio para cortar el papel

    return ticket.toString();
  }
}