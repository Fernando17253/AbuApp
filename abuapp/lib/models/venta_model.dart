class Venta {
  int? id;
  String folio; // Ej: "SAT-001" o "GEN-001"
  String fecha;
  double total;
  String metodoPago; // 'EFECTIVO', 'TRANSFERENCIA', 'FIADO', 'MIXTO (...)'
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

  // CONVIERTE EL OBJETO A MAPA PARA GUARDARLO EN SQLITE
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'folio': folio,
      'fecha': fecha,
      'total': total,
      'metodo_pago': metodoPago,
      'es_linea_sat': esLineaSat ? 1 : 0, // SQLite guarda 1 para true, 0 para false
      'cliente_id': clienteId,
    };
  }

  // NUEVO: CONVIERTE LA RESPUESTA DE SQLITE DE REGRESO A UN OBJETO VENTA
  factory Venta.fromMap(Map<String, dynamic> map) {
    return Venta(
      id: map['id'] != null ? map['id'] as int : null,
      folio: map['folio'] ?? '',
      fecha: map['fecha'] ?? '',
      // Usamos num.toDouble() por si SQLite lo devuelve como entero o decimal
      total: (map['total'] as num).toDouble(),
      metodoPago: map['metodo_pago'] ?? 'EFECTIVO',
      // Si en SQLite es 1, lo convertimos a true; de lo contrario, false
      esLineaSat: (map['es_linea_sat'] as int?) == 1,
      clienteId: map['cliente_id'] != null ? map['cliente_id'] as int : null,
    );
  }
}