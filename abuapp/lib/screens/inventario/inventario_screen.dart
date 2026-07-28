import 'package:flutter/material.dart';
import '../../models/producto_model.dart';
import 'agregar_producto_screen.dart';
// import '../../database/db_helper.dart'; // Para conectar con SQLite

class InventarioScreen extends StatefulWidget {
  const InventarioScreen({super.key});

  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
  // Filtro de búsqueda y categoría actual
  String _categoriaFiltro = 'todos';
  String _busqueda = '';
  final _busquedaController = TextEditingController();

  // Lista simulada (Esto vendrá de tu SQLite: await DbHelper().getProductos())
  List<Producto> _productos = [
    Producto(id: 1, nombre: 'Cubeta 20L de Plástico', categoria: 'plastico', precioCosto: 40, precioPublico: 85, stock: 15, esPorPeso: false),
    Producto(id: 2, nombre: 'Becerro Pinto #45', categoria: 'ganado', precioCosto: 8000, precioPublico: 12500, stock: 240.5, esPorPeso: true, areteFierro: 'SINIIGA-0045'),
    Producto(id: 3, nombre: 'Desparasitante Ivermectina 500ml', categoria: 'medicamento', precioCosto: 300, precioPublico: 480, stock: 8, esPorPeso: false, fechaCaducidad: '11/2027'),
  ];

  @override
  Widget build(BuildContext context) {
    // Filtrar productos según la búsqueda y categoría seleccionada
    final productosFiltrados = _productos.where((prod) {
      final coincideCategoria = _categoriaFiltro == 'todos' || prod.categoria == _categoriaFiltro;
      final coincideNombre = prod.nombre.toLowerCase().contains(_busqueda.toLowerCase()) || 
                             (prod.areteFierro != null && prod.areteFierro!.toLowerCase().contains(_busqueda.toLowerCase()));
      return coincideCategoria && coincideNombre;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('MI INVENTARIO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        backgroundColor: Colors.blueGrey[900],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 1. BARRA DE BÚSQUEDA GIGANTE
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.blueGrey[900],
            child: TextField(
              controller: _busquedaController,
              style: const TextStyle(fontSize: 18, color: Colors.black),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o fierro/arete...',
                hintStyle: TextStyle(color: Colors.grey[600], fontSize: 16),
                prefixIcon: const Icon(Icons.search, size: 28, color: Colors.black87),
                suffixIcon: _busqueda.isNotEmpty 
                  ? IconButton(icon: const Icon(Icons.clear), onPressed: () {
                      _busquedaController.clear();
                      setState(() { _busqueda = ''; });
                    }) 
                  : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              onChanged: (val) => setState(() { _busqueda = val; }),
            ),
          ),

          // 2. FILTROS POR CATEGORÍA CON EMOJIS
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
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

          // 3. LISTA DE PRODUCTOS EN TARJETAS
          Expanded(
            child: productosFiltrados.isEmpty
              ? const Center(child: Text('No se encontraron productos', style: TextStyle(fontSize: 18, color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: productosFiltrados.length,
                  itemBuilder: (context, index) {
                    final prod = productosFiltrados[index];
                    return _buildTarjetaProducto(prod);
                  },
                ),
          ),
        ],
      ),
      
      // 4. BOTÓN FLOTANTE GIGANTE PARA AGREGAR NUEVO PRODUCTO
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AgregarProductoScreen()),
          );
        },
        backgroundColor: Colors.green[700],
        icon: const Icon(Icons.add_circle, size: 32, color: Colors.white),
        label: const Text('NUEVO PRODUCTO', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  // Componente: Chip de filtro visual
  Widget _buildFiltroChip(String id, String titulo, String emoji) {
    final seleccionado = _categoriaFiltro == id;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text('$emoji $titulo', style: TextStyle(
          fontSize: 16, 
          fontWeight: FontWeight.bold,
          color: seleccionado ? Colors.white : Colors.black87
        )),
        selected: seleccionado,
        selectedColor: Colors.blue[800],
        backgroundColor: Colors.white,
        onSelected: (bool selected) {
          setState(() { _categoriaFiltro = id; });
        },
      ),
    );
  }

  // Componente: Tarjeta de Producto de Alto Contraste
  Widget _buildTarjetaProducto(Producto prod) {
    final unidad = prod.esPorPeso ? 'Kilos' : 'Piezas';
    final esGanado = prod.categoria == 'ganado';

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fila superior: Nombre y Etiqueta de Stock Grande
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(prod.nombre, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                      if (prod.areteFierro != null)
                        Text('Fierro/Arete: ${prod.areteFierro}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.blue[800])),
                      if (prod.fechaCaducidad != null)
                        Text('Caduca: ${prod.fechaCaducidad}', style: const TextStyle(fontSize: 15, color: Colors.redAccent, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                // CUADRO GIGANTE DE STOCK
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: prod.stock <= 5 ? Colors.red[100] : Colors.green[100],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: prod.stock <= 5 ? Colors.red : Colors.green, width: 2),
                  ),
                  child: Column(
                    children: [
                      Text('${prod.stock}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: prod.stock <= 5 ? Colors.red[900] : Colors.green[900])),
                      Text(unidad, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text('Precio público: \$${prod.precioPublico.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, color: Colors.black54)),
            
            const Divider(height: 24, thickness: 1),

            // BOTONES DE ACCIÓN RÁPIDA (ENTRADA Y MERMA)
            Row(
              children: [
                // BOTÓN SUMAR (ENTRADA)
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.add_circle_outline, size: 24),
                    label: Text(esGanado ? 'ACTUALIZAR PESO' : '+ ENTRADA', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    onPressed: () => _abrirHojaMovimiento(prod, esEntrada: true),
                  ),
                ),
                const SizedBox(width: 10),
                // BOTÓN RESTAR (MERMA/PÉRDIDA)
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.remove_circle_outline, size: 24),
                    label: const Text('- MERMA', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    onPressed: () => _abrirHojaMovimiento(prod, esEntrada: false),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // VENTANA EMERGENTE INFERIOR (BOTTOM SHEET) PARA AJUSTAR STOCK FÁCILMENTE
  void _abrirHojaMovimiento(Producto prod, {required bool esEntrada}) {
    final cantidadController = TextEditingController();
    final motivoController = TextEditingController();
    final esGanado = prod.categoria == 'ganado';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20, right: 20, top: 20
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(esEntrada ? Icons.add_box : Icons.warning, size: 32, color: esEntrada ? Colors.blue : Colors.red),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      esEntrada ? (esGanado ? 'ACTUALIZAR PESO DE ANIMAL' : 'ENTRADA DE MERCANCÍA') : 'REGISTRAR MERMA O PÉRDIDA',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: esEntrada ? Colors.blue[900] : Colors.red[900]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text('Producto: ${prod.nombre}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              Text('Stock actual: ${prod.stock} ${prod.esPorPeso ? "Kilos" : "Piezas"}', style: const TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 20),

              // CAMPO GIGANTE DE CANTIDAD
              TextField(
                controller: cantidadController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                autofocus: true,
                decoration: InputDecoration(
                  labelText: esGanado && esEntrada ? 'Nuevo peso en Kilos' : (esEntrada ? '¿Cuántas unidades/kilos entraron?' : '¿Cuántas unidades/kilos salieron?'),
                  labelStyle: const TextStyle(fontSize: 16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[100],
                  prefixIcon: const Icon(Icons.numbers, size: 30),
                ),
              ),
              const SizedBox(height: 16),

              // CAMPO DE MOTIVO (OPCIONAL)
              TextField(
                controller: motivoController,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  labelText: esEntrada ? 'Nota o Proveedor (Opcional)' : 'Motivo (Ej. Caducó, Se rompió, Murió)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.note, size: 24),
                ),
              ),
              const SizedBox(height: 24),

              // BOTÓN DE CONFIRMAR
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: esEntrada ? Colors.blue[800] : Colors.red[800],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    final cantidad = double.tryParse(cantidadController.text);
                    if (cantidad == null || cantidad <= 0) return;

                    setState(() {
                      if (esGanado && esEntrada) {
                        // En ganado, si el animal engordó, simplemente sobreescribimos su peso actual
                        prod.stock = cantidad;
                      } else if (esEntrada) {
                        prod.stock += cantidad;
                      } else {
                        prod.stock -= cantidad;
                        if (prod.stock < 0) prod.stock = 0;
                      }
                    });

                    // AQUÍ LLAMARÍAS A SQLITE PARA GUARDAR EL MOVIMIENTO:
                    // await DbHelper().registrarMovimiento(prod.id!, esEntrada ? 'ENTRADA' : 'MERMA', cantidad, motivoController.text);
                    // await DbHelper().actualizarStock(prod.id!, prod.stock);

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(esEntrada ? '¡Stock sumado con éxito!' : '¡Merma registrada!', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        backgroundColor: esEntrada ? Colors.green : Colors.orange,
                      )
                    );
                  },
                  child: Text('CONFIRMAR ${esEntrada ? "ENTRADA" : "MERMA"}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}