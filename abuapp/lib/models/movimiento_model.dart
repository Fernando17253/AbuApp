class MovimientoInventario {
  int? id;
  int productoId;
  String tipoMovimiento; // 'ENTRADA', 'MERMA', 'VENTA_CANCELADA'
  double cantidad;
  String? motivo;
  String fecha;

  MovimientoInventario({
    this.id,
    required this.productoId,
    required this.tipoMovimiento,
    required this.cantidad,
    this.motivo,
    required this.fecha,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'producto_id': productoId,
      'tipo_movimiento': tipoMovimiento,
      'cantidad': cantidad,
      'motivo': motivo,
      'fecha': fecha,
    };
  }

  // NUEVO: CONVERTIR DE SQLITE A OBJETO DART
  factory MovimientoInventario.fromMap(Map<String, dynamic> map) {
    return MovimientoInventario(
      id: map['id'] != null ? map['id'] as int : null,
      productoId: map['producto_id'] as int,
      tipoMovimiento: map['tipo_movimiento'] ?? 'ENTRADA',
      cantidad: (map['cantidad'] as num).toDouble(),
      motivo: map['motivo'],
      fecha: map['fecha'] ?? '',
    );
  }
}