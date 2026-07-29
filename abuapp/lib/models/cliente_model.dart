class Cliente {
  int? id;
  String nombre;
  String domicilio;
  String? ineTexto; // Número de clave de elector o nota de su identificación
  String? ineImagenes; // <-- NUEVA PROPIEDAD: Rutas de las fotos separadas por comas
  double limiteCredito;
  double deudaActual;
  bool activo;

  Cliente({
    this.id,
    required this.nombre,
    required this.domicilio,
    this.ineTexto,
    this.ineImagenes, // <-- SE AGREGA AL CONSTRUCTOR
    required this.limiteCredito,
    this.deudaActual = 0.0,
    this.activo = true,
  });

  // Lógica de Semáforo de Crédito para la interfaz
  // 0 = Verde (Todo bien), 1 = Naranja (Cerca del límite, >=80%), 2 = Rojo (Límite superado)
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
      'ine_imagenes': ineImagenes, // <-- SE MAPEA PARA SQLITE
      'limite_credito': limiteCredito,
      'deuda_actual': deudaActual,
      'activo': activo ? 1 : 0,
    };
  }

  factory Cliente.fromMap(Map<String, dynamic> map) {
    return Cliente(
      id: map['id'] != null ? map['id'] as int : null,
      nombre: map['nombre'] ?? 'Sin Nombre',
      domicilio: map['domicilio'] ?? 'Sin Domicilio',
      ineTexto: map['ine_texto'],
      ineImagenes: map['ine_imagenes'], // <-- SE RECUPERA DE SQLITE
      // Usamos num.toDouble() para garantizar compatibilidad con enteros y decimales en SQLite
      limiteCredito: map['limite_credito'] != null ? (map['limite_credito'] as num).toDouble() : 10000.0,
      deudaActual: map['deuda_actual'] != null ? (map['deuda_actual'] as num).toDouble() : 0.0,
      activo: (map['activo'] as int?) != 0, // Si es 1 o null, se considera activo
    );
  }
}