class MovimientoInventario {
  int? id;
  int productoId;
  String tipoMovimiento; // 'ENTRADA' o 'MERMA'
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
}