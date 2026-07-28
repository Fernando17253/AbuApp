class Venta {
  int? id;
  String folio; // Ej: "SAT-001" o "GEN-001"
  String fecha;
  double total;
  String metodoPago; // 'EFECTIVO', 'TRANSFERENCIA', 'FIADO', 'MIXTO'
  bool esLineaSat;   // true = Ganado/Medicina, false = Plásticos/Maquinaria
  int? clienteId;    // Solo si se vendió a fiado

  Venta({
    this.id,
    required this.folio,
    required this.fecha,
    required this.total,
    required this.metodoPago,
    required this.esLineaSat,
    this.clienteId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'folio': folio,
      'fecha': fecha,
      'total': total,
      'metodo_pago': metodoPago,
      'es_linea_sat': esLineaSat ? 1 : 0,
      'cliente_id': clienteId,
    };
  }
}