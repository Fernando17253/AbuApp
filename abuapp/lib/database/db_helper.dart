import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
// Asegúrate de importar tus modelos aquí:
import '../models/producto_model.dart';
import '../models/cliente_model.dart';
import '../models/venta_model.dart';

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
      // SUBIMOS A VERSIÓN 2 PARA ACTIVAR LA ACTUALIZACIÓN
      version: 2, 
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade, // <-- MÉTODO NUEVO PARA EVITAR BORRAR DATOS VIEJOS
    );
  }

  // Es fundamental activar las llaves foráneas en SQLite en cada sesión
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
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
        stock REAL NOT NULL, -- REAL para permitir pesos (ej. 240.5 kg)
        es_por_peso INTEGER DEFAULT 0, -- 0: No (pieza), 1: Sí (kilo)
        reporta_sat INTEGER DEFAULT 0, -- 0: No (General), 1: Sí (SAT)
        
        -- Campos exclusivos para Ganado
        arete_fierro TEXT NULL,
        foto_path TEXT NULL, -- Ruta local de la foto del fierro o arete
        
        -- Campos exclusivos para Medicamentos y Maquinaria
        fecha_caducidad TEXT NULL,
        laboratorio TEXT NULL,
        garantia_meses INTEGER DEFAULT 0,
        
        activo INTEGER DEFAULT 1 -- 1: Activo, 0: Eliminado (Soft Delete)
      )
    ''');

    // 2. TABLA DE HISTORIAL DE ENTRADAS Y MERMAS
    await db.execute('''
      CREATE TABLE movimientos_inventario (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        producto_id INTEGER NOT NULL,
        tipo_movimiento TEXT NOT NULL, -- 'ENTRADA', 'MERMA', 'VENTA', 'VENTA_CANCELADA'
        cantidad REAL NOT NULL,
        motivo TEXT NULL, -- Ej: "Caducó", "Se rompió", "Compra a proveedor"
        fecha TEXT NOT NULL, -- ISO 8601
        FOREIGN KEY (producto_id) REFERENCES productos (id) ON DELETE CASCADE
      )
    ''');

    // 3. TABLA DE CLIENTES (LIBRETA DE FIADOS)
    await db.execute('''
      CREATE TABLE clientes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        domicilio TEXT NULL,
        ine_texto TEXT NULL,
        ine_imagenes TEXT NULL, -- <-- COLUMNA NUEVA AGREGADA A LA CREACIÓN
        limite_credito REAL DEFAULT 10000,
        deuda_actual REAL DEFAULT 0,
        activo INTEGER DEFAULT 1
      )
    ''');

    // 4. TABLA DE VENTAS (HISTORIAL PARA CORTE DE CAJA Y REPORTES)
    await db.execute('''
      CREATE TABLE ventas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        folio TEXT NOT NULL,
        fecha TEXT NOT NULL, -- ISO 8601
        total REAL NOT NULL,
        metodo_pago TEXT NOT NULL, -- 'EFECTIVO', 'TRANSFERENCIA', 'FIADO', o 'MIXTO (...)'
        es_linea_sat INTEGER DEFAULT 0, -- 1: Nota SAT, 0: Nota General
        cliente_id INTEGER NULL, -- Si fue fiado, se vincula aquí al cliente
        FOREIGN KEY (cliente_id) REFERENCES clientes (id) ON DELETE SET NULL
      )
    ''');

    // 5. TABLA DE ABONOS DE CLIENTES
    await db.execute('''
      CREATE TABLE abonos_historial (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cliente_id INTEGER NOT NULL,
        monto REAL NOT NULL,
        fecha TEXT NOT NULL, -- ISO 8601
        nota TEXT NULL, -- Explicación opcional del abono
        FOREIGN KEY (cliente_id) REFERENCES clientes (id) ON DELETE CASCADE
      )
    ''');
  }

  // ===========================================================================
  // MAGIA MIGRATORIA: ACTUALIZA BASE DE DATOS VIEJA A LA VERSIÓN NUEVA
  // ===========================================================================
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Le agregamos la columna nueva de fotos de INE a los que tenían la versión 1
      await db.execute('ALTER TABLE clientes ADD COLUMN ine_imagenes TEXT NULL');
    }
  }


  // ===========================================================================
  // MÉTODOS CRUD: PRODUCTOS E INVENTARIO
  // ===========================================================================

  Future<List<Producto>> obtenerProductos() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'productos',
      where: 'activo = ?',
      whereArgs: [1],
      orderBy: 'nombre ASC',
    );
    return maps.map((e) => Producto.fromMap(e)).toList();
  }

  Future<int> insertarProducto(Producto prod) async {
    final db = await database;
    return await db.insert(
      'productos', 
      prod.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> actualizarProducto(Producto prod) async {
    final db = await database;
    return await db.update(
      'productos',
      prod.toMap(),
      where: 'id = ?',
      whereArgs: [prod.id],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> actualizarStockProducto(int id, double nuevoStock) async {
    final db = await database;
    return await db.update(
      'productos',
      {'stock': nuevoStock},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> eliminarProductoSoft(int id) async {
    final db = await database;
    return await db.update(
      'productos',
      {'activo': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> registrarMovimiento(int productoId, String tipo, double cantidad, [String? motivo]) async {
    final db = await database;
    return await db.insert('movimientos_inventario', {
      'producto_id': productoId,
      'tipo_movimiento': tipo,
      'cantidad': cantidad,
      'motivo': motivo,
      'fecha': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> obtenerMovimientosPorProducto(int productoId) async {
    final db = await database;
    return await db.query(
      'movimientos_inventario',
      where: 'producto_id = ?',
      whereArgs: [productoId],
      orderBy: 'fecha DESC',
    );
  }

  // ===========================================================================
  // MÉTODOS CRUD: CLIENTES Y LIBRETA
  // ===========================================================================

  Future<List<Cliente>> obtenerClientes() async {
    final db = await database;
    // Ordenamos primero por los que deben más dinero
    final List<Map<String, dynamic>> maps = await db.query(
      'clientes',
      where: 'activo = ?',
      whereArgs: [1],
      orderBy: 'deuda_actual DESC',
    );
    return maps.map((e) => Cliente.fromMap(e)).toList();
  }

  Future<int> insertarCliente(Cliente cliente) async {
    final db = await database;
    return await db.insert(
      'clientes', 
      cliente.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> actualizarCliente(Cliente cliente) async {
    final db = await database;
    return await db.update(
      'clientes',
      cliente.toMap(),
      where: 'id = ?',
      whereArgs: [cliente.id],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> actualizarDeudaCliente(int id, double nuevaDeuda) async {
    final db = await database;
    return await db.update(
      'clientes',
      {'deuda_actual': nuevaDeuda},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> registrarAbono(int clienteId, double monto, String fechaIso, [String? nota]) async {
    final db = await database;
    return await db.insert('abonos_historial', {
      'cliente_id': clienteId,
      'monto': monto,
      'fecha': fechaIso,
      'nota': nota,
    });
  }

  Future<int> registrarAbonoHistorial(int clienteId, double monto, String fechaIso) async {
    return registrarAbono(clienteId, monto, fechaIso, 'Abono general en libreta');
  }

  Future<List<Map<String, dynamic>>> obtenerAbonosPorCliente(int clienteId) async {
    final db = await database;
    return await db.query(
      'abonos_historial',
      where: 'cliente_id = ?',
      whereArgs: [clienteId],
      orderBy: 'fecha DESC',
    );
  }

  // ===========================================================================
  // MÉTODOS CRUD: VENTAS Y REPORTES
  // ===========================================================================

  Future<int> insertarVenta(Venta venta) async {
    final db = await database;
    return await db.insert(
      'ventas', 
      venta.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Venta>> obtenerVentas() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'ventas',
      orderBy: 'fecha DESC',
    );
    return maps.map((e) => Venta.fromMap(e)).toList();
  }

  Future<List<Venta>> obtenerVentasPorRango(String fechaInicioIso, [String? fechaFinIso]) async {
    final db = await database;
    
    final String whereClause = fechaFinIso != null ? 'fecha >= ? AND fecha <= ?' : 'fecha >= ?';
    final List<String> whereArgs = fechaFinIso != null ? [fechaInicioIso, fechaFinIso] : [fechaInicioIso];

    final List<Map<String, dynamic>> maps = await db.query(
      'ventas',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'fecha DESC',
    );
    return maps.map((e) => Venta.fromMap(e)).toList();
  }

  Future<List<Map<String, dynamic>>> obtenerTodosLosMovimientos() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT m.*, 
             p.nombre AS producto_nombre, 
             p.categoria AS producto_categoria, 
             p.es_por_peso AS es_por_peso,
             p.precio_costo AS precio_costo
      FROM movimientos_inventario m 
      LEFT JOIN productos p ON m.producto_id = p.id 
      ORDER BY m.fecha DESC
    ''');
  }

}