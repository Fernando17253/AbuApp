class Producto {
  int? id;
  String nombre;
  String categoria; // 'plastico', 'maquinaria', 'ganado', 'medicamento'
  double precioCosto;
  double precioPublico;
  double stock;
  bool esPorPeso;
  bool reportaSat;
  
  // Campos opcionales (dependen de la categoría)
  String? areteFierro;     // Para ganado
  String? fechaCaducidad;  // Para medicamentos
  String? laboratorio;     // Para medicamentos
  int garantiaMeses;       // Para maquinaria
  bool activo;

  Producto({
    this.id,
    required this.nombre,
    required this.categoria,
    required this.precioCosto,
    required this.precioPublico,
    required this.stock,
    this.esPorPeso = false,
    bool? reportaSat,
    this.areteFierro,
    this.fechaCaducidad,
    this.laboratorio,
    this.garantiaMeses = 0,
    this.activo = true,
  }) : reportaSat = reportaSat ?? (categoria == 'ganado' || categoria == 'medicamento');

  // Convertir a Map para guardar en SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'categoria': categoria,
      'precio_costo': precioCosto,
      'precio_publico': precioPublico,
      'stock': stock,
      'es_por_peso': esPorPeso ? 1 : 0,
      'reporta_sat': reportaSat ? 1 : 0,
      'arete_fierro': areteFierro,
      'fecha_caducidad': fechaCaducidad,
      'laboratorio': laboratorio,
      'garantia_meses': garantiaMeses,
      'activo': activo ? 1 : 0,
    };
  }

  // Convertir de SQLite a Objeto Dart
  factory Producto.fromMap(Map<String, dynamic> map) {
    return Producto(
      id: map['id'],
      nombre: map['nombre'],
      categoria: map['categoria'],
      precioCosto: (map['precio_costo'] as num).toDouble(),
      precioPublico: (map['precio_publico'] as num).toDouble(),
      stock: (map['stock'] as num).toDouble(),
      esPorPeso: map['es_por_peso'] == 1,
      reportaSat: map['reporta_sat'] == 1,
      areteFierro: map['arete_fierro'],
      fechaCaducidad: map['fecha_caducidad'],
      laboratorio: map['laboratorio'],
      garantiaMeses: map['garantia_meses'] ?? 0,
      activo: map['activo'] == 1,
    );
  }
}