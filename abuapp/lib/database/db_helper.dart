import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DbHelper {
  static final DbHelper _instance = DbHelper._internal();
  factory DbHelper() => _instance;
  DbHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'pos_ganadero.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. TABLA PRINCIPAL DE PRODUCTOS Y GANADO
    await db.execute('''
      CREATE TABLE productos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        categoria TEXT NOT NULL, -- 'plastico', 'maquinaria', 'ganado', 'medicamento'
        precio_costo REAL NOT NULL,
        precio_publico REAL NOT NULL,
        stock REAL NOT NULL, -- Se usa REAL (decimales) para permitir ventas por peso (ej. 250.5 kg)
        es_por_peso INTEGER DEFAULT 0, -- 0: No (por pieza), 1: Sí (por kilo)
        reporta_sat INTEGER DEFAULT 0, -- 0: No (Plástico/Maquinaria), 1: Sí (Ganado/Medicina)
        
        -- Campos exclusivos para Ganado (pueden ser NULL en plásticos)
        arete_fierro TEXT NULL,
        
        -- Campos exclusivos para Medicamentos y Maquinaria
        fecha_caducidad TEXT NULL,
        laboratorio TEXT NULL,
        garantia_meses INTEGER DEFAULT 0,
        
        activo INTEGER DEFAULT 1 -- Para "borrar" sin perder el historial contable (Soft Delete)
      )
    ''');

    // 2. TABLA DE HISTORIAL DE ENTRADAS Y MERMAS
    await db.execute('''
      CREATE TABLE movimientos_inventario (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        producto_id INTEGER NOT NULL,
        tipo_movimiento TEXT NOT NULL, -- 'ENTRADA', 'MERMA', 'VENTA_CANCELADA'
        cantidad REAL NOT NULL,
        motivo TEXT NULL, -- Ej: "Caducó", "Se rompió la cubeta", "Llegó pedido"
        fecha TEXT NOT NULL, -- Formato ISO 8601 (YYYY-MM-DD HH:MM:SS)
        FOREIGN KEY (producto_id) REFERENCES productos (id)
      )
    ''');
  }
}