import 'dart:io'; // 1. NECESARIO PARA LEER LOS ARCHIVOS DE FOTO LOCALES
import 'package:flutter/material.dart';
import '../../models/producto_model.dart';
import 'agregar_producto_screen.dart';
import '../../database/db_helper.dart'; // CONECTADO A SQLITE

class InventarioScreen extends StatefulWidget {
  const InventarioScreen({super.key});

  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
  String _categoriaFiltro = 'todos';
  String _busqueda = '';
  final _busquedaController = TextEditingController();

  List<Producto> _productos = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarProductosDesdeBD();
  }

  Future<void> _cargarProductosDesdeBD() async {
    setState(() => _cargando = true);
    final listaBD = await DbHelper().obtenerProductos();
    setState(() {
      _productos = listaBD;
      _cargando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final productosFiltrados = _productos.where((prod) {
      final coincideCategoria = _categoriaFiltro == 'todos' || prod.categoria == _categoriaFiltro;
      final coincideNombre = prod.nombre.toLowerCase().contains(_busqueda.toLowerCase()) || 
                             (prod.areteFierro != null && prod.areteFierro!.toLowerCase().contains(_busqueda.toLowerCase()));
      return coincideCategoria && coincideNombre;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('MI INVENTARIO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
        backgroundColor: const Color.fromARGB(255, 20, 99, 184),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 28),
            tooltip: 'Actualizar Inventario',
            onPressed: _cargarProductosDesdeBD,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. BARRA DE BÚSQUEDA GIGANTE Y ERGONÓMICA
            Container(
              padding: const EdgeInsets.all(14),
              color: const Color.fromARGB(255, 15, 84, 158),
              child: TextField(
                controller: _busquedaController,
                style: const TextStyle(fontSize: 20, color: Colors.black, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre, fierro o arete...',
                  hintStyle: TextStyle(color: Colors.grey[600], fontSize: 17, fontWeight: FontWeight.normal),
                  prefixIcon: const Icon(Icons.search, size: 32, color: Colors.black87),
                  suffixIcon: _busqueda.isNotEmpty 
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 28), 
                        onPressed: () {
                          _busquedaController.clear();
                          setState(() { _busqueda = ''; });
                        }) 
                    : null,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
                onChanged: (val) => setState(() { _busqueda = val; }),
              ),
            ),

            // 2. FILTROS POR CATEGORÍA OPTIMIZADOS
            Container(
              color: const Color.fromRGBO(36, 124, 219, 1),
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    _buildFiltroBoton('todos', 'Todos', '🌟'),
                    _buildFiltroBoton('plastico', 'Plásticos', '🪣'),
                    _buildFiltroBoton('ganado', 'Ganado', '🐄'),
                    _buildFiltroBoton('medicamento', 'Medicina', '💊'),
                    _buildFiltroBoton('maquinaria', 'Maquinaria', '⚙️'),
                  ],
                ),
              ),
            ),

            // 3. LISTA O INDICADOR DE CARGA
            Expanded(
              child: _cargando
                ? const Center(
                    child: CircularProgressIndicator(color: Color.fromARGB(255, 20, 99, 184)),
                  )
                : productosFiltrados.isEmpty
                  ? const Center(
                      child: Text(
                        'No hay productos en tu base de datos',
                        style: TextStyle(fontSize: 20, color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                      itemCount: productosFiltrados.length,
                      itemBuilder: (context, index) {
                        final prod = productosFiltrados[index];
                        return _buildTarjetaProducto(prod);
                      },
                    ),
            ),
          ],
        ),
      ),
      
      // 4. AL VOLVER DE LA PANTALLA DE AGREGAR PRODUCTO, RECARGAMOS SQLITE
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AgregarProductoScreen()),
          );
          _cargarProductosDesdeBD(); 
        },
        backgroundColor: Colors.green[700],
        elevation: 6,
        icon: const Icon(Icons.add_circle, size: 36, color: Colors.white),
        label: const Padding(
          padding: EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Text('NUEVO PRODUCTO', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5)),
        ),
      ),
    );
  }

  Widget _buildFiltroBoton(String id, String titulo, String emoji) {
    final seleccionado = _categoriaFiltro == id;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: seleccionado ? Colors.blue[600] : Colors.white,
          foregroundColor: seleccionado ? Colors.white : Colors.black87,
          elevation: seleccionado ? 6 : 2,
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
        onPressed: () => setState(() => _categoriaFiltro = id),
        child: Text(
          '$emoji $titulo',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // COMPONENTE: Tarjeta de Producto (Ahora es táctil para abrir la ficha técnica)
  Widget _buildTarjetaProducto(Producto prod) {
    final unidad = prod.esPorPeso ? 'Kilos' : 'Piezas';
    final esGanado = prod.categoria == 'ganado';

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: esGanado ? Colors.orange : Colors.grey[300]!, width: 2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _mostrarDetalleProducto(prod), // AL TOCAR ABRE LA FICHA COMPLETA
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                prod.nombre, 
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black87, height: 1.2),
                              ),
                            ),
                            const Icon(Icons.info_outline, color: Colors.blueGrey, size: 24), // Indicador visual de ficha
                          ],
                        ),
                        const SizedBox(height: 6),
                        if (prod.areteFierro != null && prod.areteFierro!.isNotEmpty)
                          Text('Identificación: ${prod.areteFierro}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue[800])),
                        if (prod.fechaCaducidad != null && prod.fechaCaducidad!.isNotEmpty)
                          Text('Caduca: ${prod.fechaCaducidad}', style: const TextStyle(fontSize: 16, color: Colors.redAccent, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: prod.stock <= 5 ? Colors.red[100] : Colors.green[100],
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: prod.stock <= 5 ? Colors.red : Colors.green, width: 2.5),
                    ),
                    child: Column(
                      children: [
                        Text(
                          prod.stock.toStringAsFixed(prod.esPorPeso ? 1 : 0), 
                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: prod.stock <= 5 ? Colors.red[900] : Colors.green[900]),
                        ),
                        Text(
                          unidad.toUpperCase(), 
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: prod.stock <= 5 ? Colors.red[900] : Colors.green[900]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text('Precio público: \$${prod.precioPublico.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black54)),
              
              const Divider(height: 28, thickness: 1.5),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 2,
                      ),
                      icon: const Icon(Icons.add_circle_outline, size: 26),
                      label: Text(esGanado ? 'PESO' : '+ ENTRADA', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                      onPressed: () => _abrirHojaMovimiento(prod, esEntrada: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[700],
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 2,
                      ),
                      icon: const Icon(Icons.remove_circle_outline, size: 26),
                      label: const Text('- MERMA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                      onPressed: () => _abrirHojaMovimiento(prod, esEntrada: false),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarDetalleProducto(Producto prod) {
    final esGanado = prod.categoria == 'ganado';
    final esMedicina = prod.categoria == 'medicamento';
    final esMaquinaria = prod.categoria == 'maquinaria';

    // Parseamos todas las fotos separadas por comas
    List<String> listaFotos = [];
    if (prod.fotoPath != null && prod.fotoPath!.isNotEmpty) {
      listaFotos = prod.fotoPath!.split(',');
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return SafeArea(
          child: Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ENCABEZADO ELÁSTICO
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Text(esGanado ? '🐄' : (esMedicina ? '💊' : (esMaquinaria ? '⚙️' : '🪣')), style: const TextStyle(fontSize: 32)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                prod.categoria.toUpperCase(),
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.blueGrey[700]),
                                softWrap: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 30),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // NOMBRE DEL PRODUCTO
                  Text(
                    prod.nombre,
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.black87, height: 1.2),
                    softWrap: true,
                  ),
                  const SizedBox(height: 16),

                  // CUADRO DE PRECIOS Y EXISTENCIAS
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[300]!, width: 1.5),
                    ),
                    child: Column(
                      children: [
                        _filaDatoDetalle('Existencias en rancho:', '${prod.stock.toStringAsFixed(prod.esPorPeso ? 1 : 0)} ${prod.esPorPeso ? "Kilos" : "Piezas"}'),
                        const Divider(height: 20),
                        _filaDatoDetalle('Precio de Venta (Público):', '\$${prod.precioPublico.toStringAsFixed(2)}'),
                        const Divider(height: 20),
                        _filaDatoDetalle('Precio de Costo (Inversión):', '\$${prod.precioCosto.toStringAsFixed(2)}'),
                        const Divider(height: 20),
                        _filaDatoDetalle('Modo de venta:', prod.esPorPeso ? 'Por Kilo / Peso' : 'Por Pieza / Unidad'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // DATOS ESPECÍFICOS DE GANADO
                  if (esGanado && prod.areteFierro != null && prod.areteFierro!.isNotEmpty) ...[
                    const Text('📍 IDENTIFICACIÓN DEL ANIMAL:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.blueGrey)),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.orange[300]!, width: 2),
                      ),
                      child: Text(
                        prod.areteFierro!,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange[900], height: 1.4),
                        softWrap: true,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // DATOS ESPECÍFICOS DE MEDICAMENTOS O MAQUINARIA
                  if (esMedicina) ...[
                    if (prod.fechaCaducidad != null && prod.fechaCaducidad!.isNotEmpty)
                      _filaDatoDetalle('Fecha de Caducidad:', prod.fechaCaducidad!),
                    if (prod.laboratorio != null && prod.laboratorio!.isNotEmpty)
                      _filaDatoDetalle('Laboratorio / Fórmula:', prod.laboratorio!),
                    const SizedBox(height: 20),
                  ],
                  if (esMaquinaria && prod.garantiaMeses > 0) ...[
                    _filaDatoDetalle('Garantía del fabricante:', '${prod.garantiaMeses} Meses'),
                    const SizedBox(height: 20),
                  ],

                  // GALERÍA DE IMÁGENES GUARDADAS
                  const Text('📷 FOTOGRAFÍAS GUARDADAS:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.blueGrey)),
                  const SizedBox(height: 6),
                  const Text('Toca cualquier imagen para verla en pantalla completa:', style: TextStyle(fontSize: 14, color: Colors.grey)),
                  const SizedBox(height: 12),

                  if (listaFotos.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Text('Este registro no tiene fotos adjuntas', style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold)),
                      ),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.1,
                      ),
                      itemCount: listaFotos.length,
                      itemBuilder: (context, idx) {
                        final ruta = listaFotos[idx];
                        return GestureDetector(
                          onTap: () => _abrirFotoPantallaCompleta(ruta),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.blueGrey[800]!, width: 2),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
                            ),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(File(ruta), fit: BoxFit.cover),
                                ),
                                Positioned(
                                  bottom: 6,
                                  right: 6,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.zoom_in, color: Colors.white, size: 20),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 24),

                  // BOTÓN PARA EDITAR REGISTRO / FOTOS
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[800],
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 58),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 3,
                    ),
                    icon: const Icon(Icons.edit, size: 28),
                    label: const Text('EDITAR DATOS / FOTOS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                    onPressed: () async {
                      Navigator.pop(context);
                      final editado = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AgregarProductoScreen(productoAEditar: prod),
                        ),
                      );
                      if (editado == true) {
                        _cargarProductosDesdeBD();
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  // BOTÓN PRINCIPAL PARA CERRAR FICHA
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey[900],
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 58),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('CERRAR INFORMACIÓN', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  ),
                  const SizedBox(height: 20),

                  // ===========================================================
                  // BOTÓN DISCRETO DE ELIMINACIÓN (Separado para evitar accidentes)
                  // ===========================================================
                  Center(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red[800],
                        side: BorderSide(color: Colors.red[300]!, width: 1.5),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.delete_forever, size: 24),
                      label: const Text(
                        'ELIMINAR ESTE REGISTRO DEL INVENTARIO',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () => _confirmarYEliminarProducto(prod),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // NUEVO: ALERTA DE ELIMINACIÓN CON CASILLA DE VERIFICACIÓN OBLIGATORIA
  // ===========================================================================
  // ===========================================================================
  // ALERTA DE ELIMINACIÓN (BLINDADA CONTRA ERROR DE DESBORDAMIENTO / OVERFLOW)
  // ===========================================================================
  void _confirmarYEliminarProducto(Producto prod) {
    bool aceptoEliminar = false; // Estado local de la casilla

    showDialog(
      context: context,
      barrierDismissible: false, // Obliga a responder o cancelar explícitamente
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              // 1. TÍTULO ELÁSTICO
              title: Row(
                children: [
                  Icon(Icons.warning_rounded, color: Colors.red[800], size: 36),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      '¿ELIMINAR REGISTRO?',
                      style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: Colors.black87),
                      softWrap: true,
                    ),
                  ),
                ],
              ),
              // 2. CUERPO DESLIZABLE PARA EVITAR OVERFLOW VERTICAL
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estás a punto de eliminar "${prod.nombre}" de tu inventario activo.',
                      style: const TextStyle(fontSize: 17, color: Colors.black87, height: 1.3),
                      softWrap: true,
                    ),
                    const SizedBox(height: 14),

                    // CAJA DE ADVERTENCIA ROJA (Alineada arriba por si ocupa varias líneas)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start, // Evita que el ícono flote en medio
                        children: [
                          Icon(Icons.info_outline, color: Colors.red[900], size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Esta acción removerá el producto del catálogo y ya no podrás venderlo ni sumarle existencias.',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.red[900], height: 1.3),
                              softWrap: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 3. CASILLA DE VERIFICACIÓN CON ALINEACIÓN ARRIBA
                    InkWell(
                      onTap: () {
                        setDialogState(() {
                          aceptoEliminar = !aceptoEliminar;
                        });
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        decoration: BoxDecoration(
                          color: aceptoEliminar ? Colors.red[100] : Colors.grey[100],
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: aceptoEliminar ? Colors.red : Colors.grey[400]!, width: 1.5),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start, // Checkbox siempre arriba
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: aceptoEliminar,
                                activeColor: Colors.red[800],
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                onChanged: (val) {
                                  setDialogState(() {
                                    aceptoEliminar = val ?? false;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Entiendo y acepto que la eliminación de este registro es irreversible.',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87, height: 1.3),
                                softWrap: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              // 4. BOTONES BLINDADOS CONTRA CORTE DE TEXTO (FittedBox + Flex optimizado)
              actions: [
                Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          minimumSize: const Size(0, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'CANCELAR',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey),
                            maxLines: 1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 6,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: aceptoEliminar ? Colors.red[800] : Colors.grey[400],
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 50),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: aceptoEliminar ? 4 : 0,
                        ),
                        icon: const Icon(Icons.delete, size: 22),
                        label: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'ELIMINAR',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                            maxLines: 1,
                          ),
                        ),
                        onPressed: !aceptoEliminar
                            ? null
                            : () async {
                                final db = DbHelper();
                                await db.eliminarProductoSoft(prod.id!);

                                if (!mounted) return;
                                Navigator.pop(context); // Cierra la alerta
                                Navigator.pop(context); // Cierra la ficha técnica

                                _cargarProductosDesdeBD(); // Refresca el inventario en vivo

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('🗑️ "${prod.nombre}" se ha eliminado del inventario.', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    backgroundColor: Colors.red[800],
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                              },
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  // WIDGET AUXILIAR ANTI-DESBORDAMIENTO (El secreto para que baje de línea en pantallas chicas)
  Widget _filaDatoDetalle(String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start, // Alinea arriba cuando el valor ocupa varias líneas
        children: [
          Expanded(
            flex: 5,
            child: Text(
              etiqueta, 
              style: TextStyle(fontSize: 16, color: Colors.grey[700], fontWeight: FontWeight.w600),
              softWrap: true,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: Text(
              valor, 
              style: const TextStyle(fontSize: 17, color: Colors.black87, fontWeight: FontWeight.w900),
              textAlign: TextAlign.end,
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // NUEVO: VISOR A PANTALLA COMPLETA CON ZOOM (INTERACTIVE VIEWER)
  // ===========================================================================
  void _abrirFotoPantallaCompleta(String rutaFoto) {
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            // INTERACTIVE VIEWER PERMITE HACER ZOOM CON 2 DEDOS (HASTA 4X)
            Center(
              child: InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.file(File(rutaFoto), fit: BoxFit.contain),
              ),
            ),
            // BOTÓN DE CERRAR EN LA ESQUINA SUPERIOR DERECHA
            Positioned(
              top: 40,
              right: 20,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 32),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _abrirHojaMovimiento(Producto prod, {required bool esEntrada}) {
    final cantidadController = TextEditingController();
    final motivoController = TextEditingController();
    final esGanado = prod.categoria == 'ganado';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              left: 24, right: 24, top: 24
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(esEntrada ? Icons.add_box : Icons.warning_rounded, size: 36, color: esEntrada ? Colors.blue[800] : Colors.red[800]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        esEntrada ? (esGanado ? 'ACTUALIZAR PESO DE ANIMAL' : 'ENTRADA DE MERCANCÍA') : 'REGISTRAR MERMA O PÉRDIDA',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: esEntrada ? Colors.blue[900] : Colors.red[900]),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text('Producto: ${prod.nombre}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Stock actual: ${prod.stock.toStringAsFixed(prod.esPorPeso ? 1 : 0)} ${prod.esPorPeso ? "Kilos" : "Piezas"}', style: const TextStyle(fontSize: 17, color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),

                TextField(
                  controller: cantidadController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87),
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: esGanado && esEntrada ? 'Nuevo peso en Kilos' : (esEntrada ? '¿Cuántas unidades/kilos entraron?' : '¿Cuántas unidades/kilos salieron?'),
                    labelStyle: const TextStyle(fontSize: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    prefixIcon: const Icon(Icons.numbers, size: 36),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: motivoController,
                  style: const TextStyle(fontSize: 18),
                  decoration: InputDecoration(
                    labelText: esEntrada ? 'Nota o Proveedor (Opcional)' : 'Motivo (Ej. Caducó, Se rompió, Murió)',
                    labelStyle: const TextStyle(fontSize: 16),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    prefixIcon: const Icon(Icons.note, size: 28),
                  ),
                ),
                const SizedBox(height: 28),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: esEntrada ? Colors.blue[800] : Colors.red[800],
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 60),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                  ),
                  onPressed: () async {
                    final cantidad = double.tryParse(cantidadController.text.trim());
                    if (cantidad == null || cantidad <= 0) return;

                    if (!esEntrada && cantidad > prod.stock) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('⚠️ No puedes mermar más del stock actual disponible'), backgroundColor: Colors.red),
                      );
                      return;
                    }

                    double nuevoStock = prod.stock;
                    String tipoMovimiento = esEntrada ? 'ENTRADA' : 'MERMA';

                    if (esGanado && esEntrada) {
                      nuevoStock = cantidad;
                    } else if (esEntrada) {
                      nuevoStock += cantidad;
                    } else {
                      nuevoStock -= cantidad;
                      if (nuevoStock < 0) nuevoStock = 0;
                    }

                    final db = DbHelper();

                    await db.actualizarStockProducto(prod.id!, nuevoStock);

                    final motivoEscrito = motivoController.text.trim();
                    final motivoFinal = motivoEscrito.isEmpty 
                        ? (esEntrada ? 'Entrada manual de inventario' : 'Merma registrada en inventario')
                        : motivoEscrito;

                    await db.registrarMovimiento(
                      prod.id!,
                      tipoMovimiento,
                      cantidad,
                      motivoFinal,
                    );

                    if (!mounted) return;
                    Navigator.pop(context);
                    
                    _cargarProductosDesdeBD();

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          esEntrada ? '¡Stock actualizado con éxito!' : '¡Merma registrada correctamente!', 
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                        ),
                        backgroundColor: esEntrada ? Colors.green[800] : Colors.orange[800],
                      ),
                    );
                  },
                  child: Text('CONFIRMAR ${esEntrada ? "ENTRADA" : "MERMA"}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }
}