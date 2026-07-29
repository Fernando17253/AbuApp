import 'package:flutter/material.dart';
import '../../database/db_helper.dart';
import '../../models/venta_model.dart';
import '../../models/cliente_model.dart';
import '../../models/producto_model.dart';

// Estructura auxiliar para manejar ítems dentro del carrito de compras
class ItemCarrito {
  final Producto producto;
  double cantidad; // Puede ser piezas (1.0, 2.0) o peso (240.5 kg)
  double precioTotal;

  ItemCarrito({required this.producto, required this.cantidad})
      : precioTotal = producto.precioPublico * cantidad;
}

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  String _categoriaFiltro = 'todos';
  String _busquedaFiltro = ''; 
  final TextEditingController _searchController = TextEditingController(); 
  final FocusNode _searchFocus = FocusNode(); 
  final List<ItemCarrito> _carrito = [];

  // ===========================================================================
  // ESTADO SQLITE: Lista dinámica y bandera de carga
  // ===========================================================================
  List<Producto> _productosDisponibles = [];
  bool _cargandoProductos = true;

  @override
  void initState() {
    super.initState();
    _cargarProductos(); // Cargar inventario real desde SQLite al iniciar
  }

  // MÉTODO PARA CONSULTAR PRODUCTOS ACTIVOS A SQLITE
  Future<void> _cargarProductos() async {
    setState(() => _cargandoProductos = true);
    try {
      final db = DbHelper();
      final lista = await db.obtenerProductos();
      setState(() {
        // Solo mostramos en el POS los productos que estén activos en el negocio
        _productosDisponibles = lista.where((p) => p.activo).toList();
        _cargandoProductos = false;
      });
    } catch (e) {
      setState(() => _cargandoProductos = false);
      _mostrarAlertaPronto(context, 'Error al cargar inventario: $e');
    }
  }

  double get _totalCarrito => _carrito.fold(0, (sum, item) => sum + item.precioTotal);

  bool _esLineaSat(Producto p) => p.categoria == 'ganado' || p.categoria == 'medicamento';

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _deseleccionarBuscador() {
    _searchFocus.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    // FILTRADO DOBLE: Por Categoría Y por Texto de Búsqueda
    final productosFiltrados = _productosDisponibles.where((prod) {
      final coincideCategoria = _categoriaFiltro == 'todos' || prod.categoria == _categoriaFiltro;
      final textoBusqueda = _busquedaFiltro.trim().toLowerCase();
      final coincideTexto = textoBusqueda.isEmpty ||
          prod.nombre.toLowerCase().contains(textoBusqueda) ||
          (prod.areteFierro?.toLowerCase().contains(textoBusqueda) ?? false);

      return coincideCategoria && coincideTexto;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('PUNTO DE VENTA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 4,
        actions: [
          // Botón para refrescar el inventario manualmente si se requiere
          IconButton(
            icon: const Icon(Icons.refresh, size: 28),
            tooltip: 'Actualizar Inventario',
            onPressed: _cargarProductos,
          ),
        ],
      ),
      body: GestureDetector(
        onTap: _deseleccionarBuscador,
        child: SafeArea(
          child: Column(
            children: [
              // SELECTOR RÁPIDO DE CATEGORÍAS
              Container(
                color: Colors.green[900],
                padding: const EdgeInsets.symmetric(vertical: 12),
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

              // BARRA DE BÚSQUEDA RÁPIDA
              _buildBarraBusqueda(),

              // CUADRÍCULA DE PRODUCTOS (CON ESTADO DE CARGA ASÍNCRONO)
              Expanded(
                child: _cargandoProductos
                    ? const Center(child: CircularProgressIndicator(color: Colors.green))
                    : productosFiltrados.isEmpty
                        ? const Center(
                            child: Text(
                              'No se encontraron productos\ncon ese nombre o categoría 🔍',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.all(12),
                            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.95, 
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: productosFiltrados.length,
                            itemBuilder: (context, index) {
                              final prod = productosFiltrados[index];
                              return _buildTarjetaProductoPOS(prod);
                            },
                          ),
              ),

              // BARRA INFERIOR DE CARRITO
              _buildBarraCobro(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBarraBusqueda() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      color: Colors.grey[100],
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocus,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        onTapOutside: (event) => _deseleccionarBuscador(),
        decoration: InputDecoration(
          hintText: 'Buscar producto o # de arete...',
          hintStyle: const TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.normal),
          prefixIcon: const Icon(Icons.search, size: 28, color: Colors.green),
          suffixIcon: _busquedaFiltro.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 26, color: Colors.red),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _busquedaFiltro = '');
                    _deseleccionarBuscador();
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[300]!, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[300]!, width: 2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.green[800]!, width: 2.5),
          ),
        ),
        onChanged: (texto) => setState(() => _busquedaFiltro = texto),
      ),
    );
  }

  Widget _buildFiltroBoton(String id, String titulo, String emoji) {
    final seleccionado = _categoriaFiltro == id;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: seleccionado ? Colors.orange[800] : Colors.white,
          foregroundColor: seleccionado ? Colors.white : Colors.black87,
          elevation: seleccionado ? 6 : 2,
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
        onPressed: () {
          _deseleccionarBuscador();
          setState(() => _categoriaFiltro = id);
        },
        child: Text(
          '$emoji $titulo',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildTarjetaProductoPOS(Producto prod) {
    final esGanado = prod.categoria == 'ganado';
    return InkWell(
      onTap: () {
        _deseleccionarBuscador();
        _agregarAlCarrito(prod);
      },
      borderRadius: BorderRadius.circular(18),
      child: Card(
        elevation: 4,
        color: esGanado ? Colors.orange[50] : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: esGanado ? Colors.orange : Colors.grey[300]!, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                prod.nombre,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, height: 1.2),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Text(
                prod.esPorPeso ? '\$${prod.precioPublico}/Kg' : '\$${prod.precioPublico}',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.green[800]),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: prod.stock <= 5 ? Colors.red[100] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Stock: ${prod.stock.toStringAsFixed(1)} ${prod.esPorPeso ? "Kg" : "Pz"}',
                  style: TextStyle(
                    fontSize: 14,
                    color: prod.stock <= 5 ? Colors.red[900] : Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarModalPagoMixto() {
    bool usaEfectivo = true;
    bool usaTransferencia = true;
    bool usaFiado = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return SafeArea(
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              int seleccionados = 0;
              if (usaEfectivo) seleccionados++;
              if (usaTransferencia) seleccionados++;
              if (usaFiado) seleccionados++;

              List<String> nombres = [];
              if (usaEfectivo) nombres.add('EFECTIVO');
              if (usaTransferencia) nombres.add('TRANSF.');
              if (usaFiado) nombres.add('FIADO');
              final String etiquetaMixta = 'MIXTO (${nombres.join(" + ")})';

              return Container(
                height: MediaQuery.of(context).size.height * 0.82,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            '🔀 CONFIGURAR PAGO MIXTO', 
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black87),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 30),
                          onPressed: () {
                            Navigator.pop(context);
                            _mostrarModalMetodosPago();
                          },
                        ),
                      ],
                    ),
                    const Divider(thickness: 2),
                    const SizedBox(height: 8),

                    const Text(
                      'Selecciona los métodos que vas a combinar para cubrir el total:',
                      style: TextStyle(fontSize: 16, color: Colors.blueGrey, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),

                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            _tarjetaOpcionMixta(
                              titulo: 'EFECTIVO (BILLETES)',
                              emoji: '💵',
                              seleccionado: usaEfectivo,
                              color: Colors.green[700]!,
                              alTocar: () => setModalState(() => usaEfectivo = !usaEfectivo),
                            ),
                            const SizedBox(height: 12),
                            _tarjetaOpcionMixta(
                              titulo: 'TRANSFERENCIA BANCARIA',
                              emoji: '📱',
                              seleccionado: usaTransferencia,
                              color: Colors.blue[700]!,
                              alTocar: () => setModalState(() => usaTransferencia = !usaTransferencia),
                            ),
                            const SizedBox(height: 12),
                            _tarjetaOpcionMixta(
                              titulo: 'FIAR A LA LIBRETA (CRÉDITO)',
                              emoji: '📒',
                              seleccionado: usaFiado,
                              color: Colors.orange[800]!,
                              alTocar: () => setModalState(() => usaFiado = !usaFiado),
                            ),
                          ],
                        ),
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: seleccionados < 2 ? Colors.red[50] : Colors.purple[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: seleccionados < 2 ? Colors.red : Colors.purple, width: 1.5),
                      ),
                      child: Column(
                        children: [
                          Text(
                            seleccionados < 2 
                              ? '⚠️ DEBES SELECCIONAR AL MENOS 2 MÉTODOS' 
                              : '✅ SE GUARDARÁ COMO:',
                            style: TextStyle(
                              fontSize: 14, 
                              fontWeight: FontWeight.bold, 
                              color: seleccionados < 2 ? Colors.red[800] : Colors.purple[900]
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            seleccionados < 2 ? '---' : etiquetaMixta,
                            style: TextStyle(
                              fontSize: 18, 
                              fontWeight: FontWeight.w900, 
                              color: seleccionados < 2 ? Colors.grey : Colors.black87
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: seleccionados < 2 ? Colors.grey : Colors.purple[700],
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 65),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: seleccionados < 2 ? 0 : 4,
                      ),
                      icon: const Icon(Icons.check_circle_outline, size: 30),
                      label: const Text('CONFIRMAR COBRO MIXTO', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                      onPressed: seleccionados < 2 ? null : () {
                        Navigator.pop(context);
                        if (usaFiado) {
                          _seleccionarClienteParaFiado(metodoPagoCustom: etiquetaMixta);
                        } else {
                          _procesarYDividirVenta(etiquetaMixta);
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _tarjetaOpcionMixta({required String titulo, required String emoji, required bool seleccionado, required Color color, required VoidCallback alTocar}) {
    return InkWell(
      onTap: alTocar,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: seleccionado ? color.withOpacity(0.15) : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: seleccionado ? color : Colors.grey[300]!, 
            width: seleccionado ? 3 : 1.5
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 34)),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                titulo, 
                style: TextStyle(
                  fontSize: 18, 
                  fontWeight: seleccionado ? FontWeight.w900 : FontWeight.w600,
                  color: seleccionado ? Colors.black87 : Colors.grey[700],
                ),
              ),
            ),
            Icon(
              seleccionado ? Icons.check_box : Icons.check_box_outline_blank,
              size: 34,
              color: seleccionado ? color : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  void _agregarAlCarrito(Producto prod) {
    if (prod.esPorPeso) {
      _mostrarAlertaPeso(prod);
    } else {
      // Validamos no agregar más stock del que existe
      final index = _carrito.indexWhere((item) => item.producto.id == prod.id);
      double cantidadActual = index != -1 ? _carrito[index].cantidad : 0;
      if (cantidadActual + 1 > prod.stock) {
        _mostrarAlertaPronto(context, '⚠️ No hay suficiente stock de ${prod.nombre}');
        return;
      }

      setState(() {
        if (index != -1) {
          _carrito[index].cantidad += 1;
          _carrito[index] = ItemCarrito(producto: prod, cantidad: _carrito[index].cantidad);
        } else {
          _carrito.add(ItemCarrito(producto: prod, cantidad: 1.0));
        }
      });
    }
  }

  void _mostrarAlertaPeso(Producto prod) {
    final pesoController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Text('⚖️ ', style: TextStyle(fontSize: 34)),
            Expanded(child: Text('PESO DE ${prod.nombre.toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20))),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Precio actual: \$${prod.precioPublico} por Kilo', style: const TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                controller: pesoController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue),
                decoration: InputDecoration(
                  labelText: '¿Cuántos kilos pesó hoy?',
                  labelStyle: const TextStyle(fontSize: 18),
                  suffixText: 'KG',
                  suffixStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  filled: true,
                  fillColor: Colors.blue[50],
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                ),
              ),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.all(16),
        actions: [
          TextButton(
            style: TextButton.styleFrom(minimumSize: const Size(100, 50)),
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR', style: TextStyle(fontSize: 16, color: Colors.red, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
              minimumSize: const Size(160, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              final peso = double.tryParse(pesoController.text);
              if (peso != null && peso > 0) {
                if (peso > prod.stock) {
                  _mostrarAlertaPronto(context, '⚠️ Solo tienes ${prod.stock} Kg en inventario.');
                  return;
                }
                setState(() {
                  _carrito.add(ItemCarrito(producto: prod, cantidad: peso));
                });
                Navigator.pop(context);
              }
            },
            child: const Text('AGREGAR AL CARRITO', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildBarraCobro() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${_carrito.length} PRODUCTOS EN CARRITO', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey)),
                  Text(
                    '\$${_totalCarrito.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.green[800]),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _carrito.isEmpty ? Colors.grey : Colors.green[700],
                foregroundColor: Colors.white,
                minimumSize: const Size(180, 70),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: _carrito.isEmpty ? 0 : 6,
              ),
              icon: const Icon(Icons.shopping_cart_checkout, size: 30),
              label: const Text('COBRAR', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              onPressed: _carrito.isEmpty ? null : () {
                _deseleccionarBuscador();
                _mostrarModalCarrito();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarModalCarrito() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return SafeArea(
              child: Container(
                height: MediaQuery.of(context).size.height * 0.88,
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            '🛒 PRODUCTOS A COBRAR', 
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black87),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 30),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(thickness: 2),
                    const SizedBox(height: 8),

                    Expanded(
                      child: _carrito.isEmpty
                        ? const Center(child: Text('El carrito está vacío', style: TextStyle(fontSize: 20, color: Colors.grey)))
                        : ListView.builder(
                            itemCount: _carrito.length,
                            itemBuilder: (context, index) {
                              final item = _carrito[index];
                              final unidad = item.producto.esPorPeso ? 'Kg' : 'Pz';
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 2,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      Text(_esLineaSat(item.producto) ? '🐄' : '🪣', style: const TextStyle(fontSize: 28)),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(item.producto.nombre, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${item.cantidad} $unidad x \$${item.producto.precioPublico}', 
                                              style: TextStyle(fontSize: 16, color: Colors.grey[700], fontWeight: FontWeight.w600)
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text('\$${item.precioTotal.toStringAsFixed(2)}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.green[800])),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 28),
                                            onPressed: () {
                                              setModalState(() {
                                                _carrito.removeAt(index);
                                              });
                                              setState(() {});
                                              if (_carrito.isEmpty) Navigator.pop(context);
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                    ),
                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100], 
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'TOTAL A PAGAR:', 
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey, height: 1.2),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FittedBox(
                              alignment: Alignment.centerRight,
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '\$${_totalCarrito.toStringAsFixed(2)}', 
                                style: TextStyle(
                                  fontSize: 32, 
                                  fontWeight: FontWeight.w900, 
                                  color: Colors.green[800],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 65),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                      ),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 32),
                      label: const Text('PROCEDER A COBRAR', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                      onPressed: () {
                        Navigator.pop(context);
                        _mostrarModalMetodosPago();
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _mostrarModalMetodosPago() {
    final itemsSat = _carrito.where((item) => _esLineaSat(item.producto)).toList();
    final itemsGeneral = _carrito.where((item) => !_esLineaSat(item.producto)).toList();
    
    final totalSat = itemsSat.fold(0.0, (sum, item) => sum + item.precioTotal);
    final totalGeneral = itemsGeneral.fold(0.0, (sum, item) => sum + item.precioTotal);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return SafeArea(
          child: Container(
            height: MediaQuery.of(context).size.height * 0.88,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        '💳 MÉTODO DE PAGO', 
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black87),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 30, color: Colors.black87),
                      onPressed: () {
                        Navigator.pop(context);
                        _mostrarModalCarrito();
                      },
                    ),
                  ],
                ),
                const Divider(thickness: 2),
                const SizedBox(height: 8),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Text(
                            '\$${_totalCarrito.toStringAsFixed(2)}',
                            style: TextStyle(fontSize: 46, fontWeight: FontWeight.w900, color: Colors.green[800]),
                          ),
                        ),
                        const SizedBox(height: 16),

                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blueGrey[50],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.blueGrey[200]!, width: 1.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('ℹ️ SEPARACIÓN AUTOMÁTICA DE NOTAS:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.blueGrey)),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text('🐄 / 💊 Línea SAT (${itemsSat.length} ítems):', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, height: 1.2)),
                                  ),
                                  const SizedBox(width: 8),
                                  Text('\$${totalSat.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black87)),
                                ],
                              ),
                              const Divider(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text('🪣 / ⚙️ Línea General (${itemsGeneral.length} ítems):', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, height: 1.2)),
                                  ),
                                  const SizedBox(width: 8),
                                  Text('\$${totalGeneral.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black87)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        const Text('¿CÓMO PAGARÁ EL CLIENTE?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 14),

                        _botonPagoGigante(
                          titulo: 'EFECTIVO (BILLETES)',
                          emoji: '💵',
                          color: Colors.green[700]!,
                          alPresionar: () => _procesarYDividirVenta('EFECTIVO'),
                        ),
                        const SizedBox(height: 12),
                        
                        _botonPagoGigante(
                          titulo: 'TRANSFERENCIA BANCARIA',
                          emoji: '📱',
                          color: Colors.blue[700]!,
                          alPresionar: () => _procesarYDividirVenta('TRANSFERENCIA'),
                        ),
                        const SizedBox(height: 12),

                        _botonPagoGigante(
                          titulo: 'FIAR A LA LIBRETA (CRÉDITO)',
                          emoji: '📒',
                          color: Colors.orange[800]!,
                          alPresionar: () {
                            Navigator.pop(context);
                            _seleccionarClienteParaFiado();
                          },
                        ),
                        const SizedBox(height: 12),

                        _botonPagoGigante(
                          titulo: 'PAGO MIXTO (ELEGIR COMBINACIÓN)',
                          emoji: '🔀',
                          color: Colors.purple[700]!,
                          alPresionar: () {
                            Navigator.pop(context);
                            _mostrarModalPagoMixto();
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _botonPagoGigante({required String titulo, required String emoji, required Color color, required VoidCallback alPresionar}) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 65),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      onPressed: alPresionar,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              titulo, 
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // MODAL DE CLIENTES CONECTADO EN VIVO A SQLITE CON FUTUREBUILDER
  // ===========================================================================
  void _seleccionarClienteParaFiado({String metodoPagoCustom = 'FIADO'}) {
    final db = DbHelper();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Container(
          padding: const EdgeInsets.all(20),
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('📒 ¿A QUIÉN LE VAMOS A FIAR?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 14),
              Expanded(
                child: FutureBuilder<List<Cliente>>(
                  future: db.obtenerClientes(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Colors.orange));
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error al cargar clientes: ${snapshot.error}'));
                    }
                    final clientes = snapshot.data?.where((c) => c.activo).toList() ?? [];
                    if (clientes.isEmpty) {
                      return const Center(
                        child: Text(
                          'No hay clientes registrados en la libreta.\nRegístralos primero en el menú Clientes.',
                          style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: clientes.length,
                      itemBuilder: (context, index) {
                        final c = clientes[index];
                        final excedeLimite = (c.deudaActual + _totalCarrito) > c.limiteCredito;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          color: excedeLimite ? Colors.red[50] : Colors.white,
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: excedeLimite ? Colors.red : Colors.grey[300]!, width: 2),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            title: Text(c.nombre, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                'Debe: \$${c.deudaActual.toStringAsFixed(2)} | Límite: \$${c.limiteCredito.toStringAsFixed(2)}', 
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)
                              ),
                            ),
                            trailing: excedeLimite 
                                ? const Icon(Icons.warning, color: Colors.red, size: 40)
                                : const Icon(Icons.check_circle, color: Colors.green, size: 40),
                            onTap: () {
                              Navigator.pop(context);
                              if (excedeLimite) {
                                _mostrarAlertaLimiteSuperado(c, metodoPagoCustom);
                              } else {
                                // Pasamos el cliente seleccionado para guardar su deuda en SQLite
                                _procesarYDividirVenta(metodoPagoCustom, c);
                              }
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarAlertaLimiteSuperado(Cliente c, String metodoPago) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.red[900],
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.white, size: 40),
            SizedBox(width: 12),
            Expanded(child: Text('¡CRÉDITO SUPERADO!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22))),
          ],
        ),
        content: Text(
          '${c.nombre} ya debe \$${c.deudaActual.toStringAsFixed(2)}. Si le fías esta nota de \$${_totalCarrito.toStringAsFixed(2)}, su deuda llegará a \$${(c.deudaActual + _totalCarrito).toStringAsFixed(2)}, superando su límite de \$${c.limiteCredito.toStringAsFixed(2)}.\n\n¿Estás seguro de que deseas fiarle?',
          style: const TextStyle(color: Colors.white, fontSize: 18, height: 1.3),
        ),
        actionsPadding: const EdgeInsets.all(16),
        actions: [
          TextButton(
            style: TextButton.styleFrom(minimumSize: const Size(120, 50)),
            onPressed: () => Navigator.pop(context),
            child: const Text('NO FIAR (CANCELAR)', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white, 
              foregroundColor: Colors.red[900],
              minimumSize: const Size(180, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(context);
              // Registra el pago conservando al cliente bajo riesgo
              _procesarYDividirVenta('$metodoPago - LÍMITE SUPERADO', c);
            },
            child: const Text('SÍ, FIAR BAJO MI RIESGO', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
  
  // ===========================================================================
  // TRANSACCIÓN SQLITE: GUARDAR VENTA, BAJAR STOCK Y SUMAR DEUDA
  // ===========================================================================
  Future<void> _procesarYDividirVenta(String metodoPago, [Cliente? clienteSeleccionado]) async {
    // Cerramos el modal anterior
    if (Navigator.canPop(context)) Navigator.pop(context);

    final db = DbHelper();
    final fechaHoy = DateTime.now().toIso8601String();
    
    // Generador simple de folio único usando milisegundos
    final folioBase = DateTime.now().millisecondsSinceEpoch.toString().substring(6);

    final itemsSat = _carrito.where((item) => _esLineaSat(item.producto)).toList();
    final itemsGeneral = _carrito.where((item) => !_esLineaSat(item.producto)).toList();

    int notasGeneradas = 0;
    
    try {
      // 1. GUARDAR NOTA SAT SI HAY PRODUCTOS DE ESA LÍNEA
      if (itemsSat.isNotEmpty) {
        notasGeneradas++;
        final totalSat = itemsSat.fold(0.0, (sum, item) => sum + item.precioTotal);
        final ventaSat = Venta(
          folio: 'SAT-$folioBase',
          fecha: fechaHoy,
          total: totalSat,
          metodoPago: metodoPago,
          esLineaSat: true,
          clienteId: clienteSeleccionado?.id,
        );
        await db.insertarVenta(ventaSat);
      }

      // 2. GUARDAR NOTA GENERAL SI HAY PRODUCTOS DE ESA LÍNEA
      if (itemsGeneral.isNotEmpty) {
        notasGeneradas++;
        final totalGen = itemsGeneral.fold(0.0, (sum, item) => sum + item.precioTotal);
        final ventaGen = Venta(
          folio: 'GEN-$folioBase',
          fecha: fechaHoy,
          total: totalGen,
          metodoPago: metodoPago,
          esLineaSat: false,
          clienteId: clienteSeleccionado?.id,
        );
        await db.insertarVenta(ventaGen);
      }

      // 3. DESCONTAR STOCK Y REGISTRAR MOVIMIENTO POR CADA PRODUCTO
      for (var item in _carrito) {
        final nuevoStock = item.producto.stock - item.cantidad;
        await db.actualizarStockProducto(item.producto.id!, nuevoStock);
        
        await db.registrarMovimiento(
          item.producto.id!,
          'VENTA',
          item.cantidad,
          'Venta de POS ($metodoPago)',
        );
      }

      // 4. SI FUE FIADO, SUMAR DEUDA AL CLIENTE EN LA BASE DE DATOS
      if (clienteSeleccionado != null && (metodoPago.contains('FIADO') || metodoPago.contains('LÍMITE'))) {
        final nuevaDeuda = clienteSeleccionado.deudaActual + _totalCarrito;
        await db.actualizarDeudaCliente(clienteSeleccionado.id!, nuevaDeuda);
      }

      // Limpiamos el carrito local
      setState(() {
        _carrito.clear();
      });

      // Recargamos inventario para que se vea reflejado el nuevo stock al instante
      await _cargarProductos();

      if (!mounted) return;

      // 5. MOSTRAR DIÁLOGO DE ÉXITO AL USUARIO
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 90),
                const SizedBox(height: 16),
                const Text('¡COBRO REGISTRADO!', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                Text(
                  notasGeneradas == 2 
                    ? 'Se dividió el cobro y se guardaron 2 notas en SQLite (SAT / General) rebajando el stock.' 
                    : 'Se registró la venta en SQLite y se actualizó el inventario.',
                  style: const TextStyle(fontSize: 17, color: Colors.black87, height: 1.3),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[800], 
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 60),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.print, size: 30),
                  label: const Text('IMPRIMIR TICKETS', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Navigator.pop(context);
                    _mostrarAlertaPronto(context, 'Enviando órdenes a impresora térmica Bluetooth...');
                  },
                ),
                const SizedBox(height: 12),
                TextButton(
                  style: TextButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('LISTO, NUEVA VENTA', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      _mostrarAlertaPronto(context, '❌ Error al procesar venta en base de datos: $e');
    }
  }

  void _mostrarAlertaPronto(BuildContext context, String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje, style: const TextStyle(fontSize: 16))));
  }
}