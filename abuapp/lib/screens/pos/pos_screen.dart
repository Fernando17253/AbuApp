import 'package:flutter/material.dart';
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
  final List<ItemCarrito> _carrito = [];

  // Lista simulada de inventario disponible para vender
  final List<Producto> _productosDisponibles = [
    Producto(id: 1, nombre: 'Cubeta 20L de Plástico', categoria: 'plastico', precioCosto: 40, precioPublico: 85, stock: 15, esPorPeso: false),
    Producto(id: 2, nombre: 'Becerro Pinto #45', categoria: 'ganado', precioCosto: 8000, precioPublico: 55.0, stock: 240.0, esPorPeso: true, areteFierro: 'SINIIGA-0045'), // $55 por Kilo
    Producto(id: 3, nombre: 'Desparasitante 500ml', categoria: 'medicamento', precioCosto: 300, precioPublico: 480, stock: 8, esPorPeso: false),
    Producto(id: 4, nombre: 'Aspersor de Motor 20L', categoria: 'maquinaria', precioCosto: 2500, precioPublico: 3800, stock: 3, esPorPeso: false, garantiaMeses: 3),
  ];

  double get _totalCarrito => _carrito.fold(0, (sum, item) => sum + item.precioTotal);

  @override
  Widget build(BuildContext context) {
    final productosFiltrados = _productosDisponibles.where((prod) {
      return _categoriaFiltro == 'todos' || prod.categoria == _categoriaFiltro;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('PUNTO DE VENTA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 1. SELECTOR RÁPIDO DE CATEGORÍAS
          Container(
            color: Colors.green[900],
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  _buildFiltroChip('todos', 'Todos', '🌟'),
                  _buildFiltroChip('plastico', 'Plásticos', '🪣'),
                  _buildFiltroChip('ganado', 'Ganado', '🐄'),
                  _buildFiltroChip('medicamento', 'Medicina', '💊'),
                  _buildFiltroChip('maquinaria', 'Maquinaria', '⚙️'),
                ],
              ),
            ),
          ),

          // 2. CUADRÍCULA DE PRODUCTOS DISPONIBLES PARA TOCAR
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.1,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: productosFiltrados.length,
              itemBuilder: (context, index) {
                final prod = productosFiltrados[index];
                return _buildTarjetaProductoPOS(prod);
              },
            ),
          ),

          // 3. BARRA INFERIOR DE CARRITO Y COBRO GIGANTE
          _buildBarraCobro(),
        ],
      ),
    );
  }

  Widget _buildFiltroChip(String id, String titulo, String emoji) {
    final seleccionado = _categoriaFiltro == id;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text('$emoji $titulo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: seleccionado ? Colors.white : Colors.black87)),
        selected: seleccionado,
        selectedColor: Colors.orange[800],
        backgroundColor: Colors.white,
        onSelected: (bool selected) => setState(() => _categoriaFiltro = id),
      ),
    );
  }

  // Tarjeta grande para tocar y vender
  Widget _buildTarjetaProductoPOS(Producto prod) {
    final esGanado = prod.categoria == 'ganado';
    return InkWell(
      onTap: () => _agregarAlCarrito(prod),
      child: Card(
        elevation: 4,
        color: esGanado ? Colors.orange[50] : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: esGanado ? Colors.orange : Colors.grey[300]!, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                prod.nombre,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                prod.esPorPeso ? '\$${prod.precioPublico}/Kg' : '\$${prod.precioPublico}',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.green[800]),
              ),
              const SizedBox(height: 4),
              Text(
                'Stock: ${prod.stock} ${prod.esPorPeso ? "Kg" : "Pz"}',
                style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Lógica para capturar peso o sumar directo
  void _agregarAlCarrito(Producto prod) {
    if (prod.esPorPeso) {
      _mostrarAlertaPeso(prod);
    } else {
      setState(() {
        // Si ya está en el carrito, sumamos 1, si no, lo creamos
        final index = _carrito.indexWhere((item) => item.producto.id == prod.id);
        if (index != -1) {
          _carrito[index].cantidad += 1;
          _carrito[index] = ItemCarrito(producto: prod, cantidad: _carrito[index].cantidad);
        } else {
          _carrito.add(ItemCarrito(producto: prod, cantidad: 1.0));
        }
      });
    }
  }

  // Ventana emergente obligatoria para pesar ganado en el momento exacto
  void _mostrarAlertaPeso(Producto prod) {
    final pesoController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Text('⚖️ ', style: TextStyle(fontSize: 30)),
            Expanded(child: Text('PESO DE ${prod.nombre.toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Precio actual: \$${prod.precioPublico} por Kilo', style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 16),
            TextField(
              controller: pesoController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue),
              decoration: InputDecoration(
                labelText: '¿Cuántos kilos pesó hoy?',
                labelStyle: const TextStyle(fontSize: 18),
                suffixText: 'KG',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.blue[50],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR', style: TextStyle(fontSize: 16, color: Colors.red)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white),
            onPressed: () {
              final peso = double.tryParse(pesoController.text);
              if (peso != null && peso > 0) {
                setState(() {
                  _carrito.add(ItemCarrito(producto: prod, cantidad: peso));
                });
                Navigator.pop(context);
              }
            },
            child: const Text('AGREGAR AL CARRITO', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // Pega esta función dentro de _PosScreenState en pos_screen.dart

void _seleccionarClienteParaFiado() {
  // En producción, cargarías la lista con: await DbHelper().getClientes();
  // Aquí usamos clientes de prueba:
  final clientes = [
    Cliente(id: 1, nombre: 'Don Artemio López', domicilio: 'Rancho Las Palmas', limiteCredito: 20000, deudaActual: 21500), // Ya se pasó
    Cliente(id: 3, nombre: 'Don Chema Morales', domicilio: 'Camino Real #45', limiteCredito: 30000, deudaActual: 4500),   // Tiene crédito
  ];

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (context) => Container(
      padding: const EdgeInsets.all(20),
      height: 500,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📒 ¿A QUIÉN LE VAMOS A FIAR?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: clientes.length,
              itemBuilder: (context, index) {
                final c = clientes[index];
                final excedeLimite = (c.deudaActual + _totalCarrito) > c.limiteCredito;

                return Card(
                  color: excedeLimite ? Colors.red[50] : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: excedeLimite ? Colors.red : Colors.grey[300]!, width: 2),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    title: Text(c.nombre, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    subtitle: Text('Debe: \$${c.deudaActual} | Límite: \$${c.limiteCredito}', style: const TextStyle(fontSize: 14)),
                    trailing: excedeLimite 
                      ? const Icon(Icons.warning, color: Colors.red, size: 36)
                      : const Icon(Icons.check_circle, color: Colors.green, size: 36),
                    onTap: () {
                      Navigator.pop(context);
                      if (excedeLimite) {
                        _mostrarAlertaLimiteSuperado(c);
                      } else {
                        // Crédito sano: procesamos la venta y sumamos la deuda al cliente
                        _procesarYDividirVenta('FIADO');
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

// ALERTA GIGANTE SI INTENTA FIARLE A ALGUIEN QUE DEBE MUCHO
void _mostrarAlertaLimiteSuperado(Cliente c) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: Colors.red[900],
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.white, size: 36),
          SizedBox(width: 10),
          Expanded(child: Text('¡CRÉDITO SUPERADO!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900))),
        ],
      ),
      content: Text(
        '${c.nombre} ya debe \$${c.deudaActual}. Si le fías esta nota de \$${_totalCarrito.toStringAsFixed(2)}, su deuda llegará a \$${(c.deudaActual + _totalCarrito).toStringAsFixed(2)}, superando su límite de \$${c.limiteCredito}.\n\n¿Estás seguro de que deseas fiarle?',
        style: const TextStyle(color: Colors.white, fontSize: 18),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('NO FIAR (CANCELAR)', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.red[900]),
          onPressed: () {
            Navigator.pop(context);
            _procesarYDividirVenta('FIADO - LÍMITE SUPERADO');
          },
          child: const Text('SÍ, FIAR BAJO MI RIESGO', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );
}

  Widget _buildBarraCobro() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // RESUMEN DEL CARRITO
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${_carrito.length} ÍTEMS EN CUENTA', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
                  Text(
                    '\$${_totalCarrito.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.green[800]),
                  ),
                ],
              ),
            ),
            // BOTÓN GIGANTE DE COBRO
            SizedBox(
              height: 60,
              width: 180,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _carrito.isEmpty ? Colors.grey : Colors.green[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.point_of_sale, size: 28),
                label: const Text('COBRAR', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                onPressed: _carrito.isEmpty ? null : () {
                  // AQUÍ HAREMOS LA SEPARACIÓN DEL SAT Y MÉTODOS DE PAGO
                  _mostrarModalDeCobro();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarModalDeCobro() {
    // 1. REVISAMOS DE ANTEMANO CÓMO SE DIVIDIRÁ LA CUENTA PARA MOSTRARSELO AL DUEÑO
    final itemsSat = _carrito.where((item) => item.producto.reportaSat).toList();
    final itemsGeneral = _carrito.where((item) => !item.producto.reportaSat).toList();
    
    final totalSat = itemsSat.fold(0.0, (sum, item) => sum + item.precioTotal);
    final totalGeneral = itemsGeneral.fold(0.0, (sum, item) => sum + item.precioTotal);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ENCABEZADO DE TOTAL GIGANTE
              const Center(
                child: Text('TOTAL A COBRAR', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
              ),
              Center(
                child: Text(
                  '\$${_totalCarrito.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: Colors.green[800]),
                ),
              ),
              const SizedBox(height: 12),

              // RESUMEN VISUAL DE LA DIVISIÓN PARA EL DUEÑO
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blueGrey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blueGrey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ℹ️ SEPARACIÓN AUTOMÁTICA DE NOTAS:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey)),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('🐄 / 💊 Línea SAT (${itemsSat.length} ítems):', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        Text('\$${totalSat.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('🪣 / ⚙️ Línea General (${itemsGeneral.length} ítems):', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        Text('\$${totalGeneral.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              const Text('¿CÓMO PAGARÁ EL CLIENTE?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              // BOTONES GIGANTES DE MÉTODO DE PAGO
              _botonPagoGigante(
                titulo: 'EFECTIVO (BILLETES)',
                emoji: '💵',
                color: Colors.green[700]!,
                alPresionar: () => _procesarYDividirVenta('EFECTIVO'),
              ),
              const SizedBox(height: 10),
              
              _botonPagoGigante(
                titulo: 'TRANSFERENCIA BANCARIA',
                emoji: '📱',
                color: Colors.blue[700]!,
                alPresionar: () => _procesarYDividirVenta('TRANSFERENCIA'),
              ),
              const SizedBox(height: 10),

              _botonPagoGigante(
                titulo: 'FIAR A LA LIBRETA (CRÉDITO)',
                emoji: '📒',
                color: Colors.orange[800]!,
                alPresionar: () {
                  Navigator.pop(context); // 1. Cierra el menú de métodos de pago
                  _seleccionarClienteParaFiado(); // 2. Abre la lista de deudores con el semáforo
                },
              ),
              const SizedBox(height: 10),

              _botonPagoGigante(
                titulo: 'PAGO MIXTO (EFECTIVO + TRANSF.)',
                emoji: '🔀',
                color: Colors.purple[700]!,
                alPresionar: () => _procesarYDividirVenta('MIXTO'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _botonPagoGigante({required String titulo, required String emoji, required Color color, required VoidCallback alPresionar}) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 3,
        ),
        onPressed: alPresionar,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Text(titulo, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }

  // --- LA MAGIA DEL SISTEMA: DIVISIÓN AUTOMÁTICA ---
  void _procesarYDividirVenta(String metodoPago) {
    Navigator.pop(context); // Cerramos el menú de pago

    // 1. Separamos los ítems de fondo
    final itemsSat = _carrito.where((item) => item.producto.reportaSat).toList();
    final itemsGeneral = _carrito.where((item) => !item.producto.reportaSat).toList();

    int notasGeneradas = 0;

    // 2. Si compró Ganado o Medicinas, creamos la Nota Fiscal/SAT internamente
    if (itemsSat.isNotEmpty) {
      final totalSat = itemsSat.fold(0.0, (sum, item) => sum + item.precioTotal);
      /* AQUÍ GUARDARÍAMOS EN SQLITE:
      await DbHelper().guardarVenta(Venta(
        folio: 'SAT-${DateTime.now().millisecondsSinceEpoch}',
        fecha: DateTime.now().toIso8601String(),
        total: totalSat,
        metodoPago: metodoPago,
        esLineaSat: true,
      ));
      */
      notasGeneradas++;
    }

    // 3. Si compró Plásticos o Maquinaria, creamos la Nota General internamente
    if (itemsGeneral.isNotEmpty) {
      final totalGen = itemsGeneral.fold(0.0, (sum, item) => sum + item.precioTotal);
      /* AQUÍ GUARDARÍAMOS EN SQLITE:
      await DbHelper().guardarVenta(Venta(
        folio: 'GEN-${DateTime.now().millisecondsSinceEpoch}',
        fecha: DateTime.now().toIso8601String(),
        total: totalGen,
        metodoPago: metodoPago,
        esLineaSat: false,
      ));
      */
      notasGeneradas++;
    }

    // 4. Restamos el stock del inventario automáticamente
    for (var item in _carrito) {
      item.producto.stock -= item.cantidad;
      // await DbHelper().actualizarStock(item.producto.id!, item.producto.stock);
    }

    // 5. Limpiamos el carrito
    setState(() {
      _carrito.clear();
    });

    // 6. MOSTRAMOS UNA CONFIRMACIÓN GIGANTE Y SATISFACTORIA
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 16),
            const Text('¡COBRO REGISTRADO!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            Text(
              notasGeneradas == 2 
                ? 'Se dividió el cobro y se generaron 2 notas internas separadas para el control del negocio.' 
                : 'Se registró 1 nota interna en el historial.',
              style: const TextStyle(fontSize: 16, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800], foregroundColor: Colors.white),
                icon: const Icon(Icons.print, size: 28),
                label: const Text('IMPRIMIR TICKETS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                onPressed: () {
                  Navigator.pop(context);
                  _mostrarAlertaPronto(context, 'Enviando órdenes a impresora térmica Bluetooth...');
                },
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('LISTO, NUEVA VENTA', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarAlertaPronto(BuildContext context, String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje, style: const TextStyle(fontSize: 16))));
  }
}