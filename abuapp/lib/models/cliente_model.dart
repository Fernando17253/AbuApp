class Cliente {
  int? id;
  String nombre;
  String domicilio;
  String? ineTexto; // Número de clave de elector o nota de su identificación
  double limiteCredito;
  double deudaActual;
  bool activo;

  Cliente({
    this.id,
    required this.nombre,
    required this.domicilio,
    this.ineTexto,
    required this.limiteCredito,
    this.deudaActual = 0.0,
    this.activo = true,
  });

  // Lógica de Semáforo de Crédito para la interfaz
  // 0 = Verde (Todo bien), 1 = Naranja (Cerca del límite, >80%), 2 = Rojo (Límite superado)
  int get estadoSemaforo {
    if (limiteCredito <= 0) return 0;
    final porcentaje = deudaActual / limiteCredito;
    if (porcentaje >= 1.0) return 2; // Rojo: Ya no se le debe fiar
    if (porcentaje >= 0.8) return 1; // Naranja: Precaución
    return 0; // Verde: Crédito sano
  }

  double get creditoDisponible => (limiteCredito - deudaActual).clamp(0.0, double.infinity);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'domicilio': domicilio,
      'ine_texto': ineTexto,
      'limite_credito': limiteCredito,
      'deuda_actual': deudaActual,
      'activo': activo ? 1 : 0,
    };
  }

  factory Cliente.fromMap(Map<String, dynamic> map) {
    return Cliente(
      id: map['id'],
      nombre: map['nombre'],
      domicilio: map['domicilio'],
      ineTexto: map['ine_texto'],
      limiteCredito: (map['limite_credito'] as num).toDouble(),
      deudaActual: (map['deuda_actual'] as num).toDouble(),
      activo: map['activo'] == 1,
    );
  }
}