import 'package:flutter/material.dart';
import '../../database/db_helper.dart';
import '../../models/movimiento_model.dart';
import '../../models/producto_model.dart';

class EntradaMermaScreen extends StatefulWidget {
  final Producto producto;
  final bool esEntrada; // true = Entrada (Compra/Devolución), false = Merma (Daño/Caducidad/Pérdida)

  const EntradaMermaScreen({
    Key? key,
    required this.producto,
    required this.esEntrada,
  }) : super(key: key);

  @override
  State<EntradaMermaScreen> createState() => _EntradaMermaScreenState();
}

class _EntradaMermaScreenState extends State<EntradaMermaScreen> {
  final TextEditingController _cantidadController = TextEditingController();
  final TextEditingController _motivoController = TextEditingController();
  final FocusNode _cantidadFocus = FocusNode();

  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    // Abrir el teclado automáticamente en el campo de cantidad al entrar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_cantidadFocus);
    });
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    _motivoController.dispose();
    _cantidadFocus.dispose();
    super.dispose();
  }

  // ===========================================================================
  // LÓGICA DE GUARDADO EN SQLITE (TRANSACCIÓN)
  // ===========================================================================
  Future<void> _guardarMovimiento() async {
    final textoCantidad = _cantidadController.text.trim();
    if (textoCantidad.isEmpty) {
      _mostrarAlerta('Por favor ingresa una cantidad.');
      return;
    }

    final cantidad = double.tryParse(textoCantidad);
    if (cantidad == null || cantidad <= 0) {
      _mostrarAlerta('Ingresa una cantidad válida mayor a 0.');
      return;
    }

    // Si es MERMA, verificamos que no intente mermar más del stock disponible
    if (!widget.esEntrada && cantidad > widget.producto.stock) {
      _mostrarAlerta(
          'No puedes mermar ${cantidad.toStringAsFixed(2)} porque solo tienes ${widget.producto.stock.toStringAsFixed(2)} en inventario.');
      return;
    }

    setState(() => _guardando = true);

    try {
      final db = DbHelper();

      // 1. Calcular el nuevo stock
      double nuevoStock;
      String tipoMov;
      if (widget.esEntrada) {
        nuevoStock = widget.producto.stock + cantidad;
        tipoMov = 'ENTRADA';
      } else {
        nuevoStock = widget.producto.stock - cantidad;
        tipoMov = 'MERMA';
      }

      // 2. Registrar el historial de movimiento
      final movimiento = MovimientoInventario(
        productoId: widget.producto.id!,
        tipoMovimiento: tipoMov,
        cantidad: cantidad,
        motivo: _motivoController.text.trim().isEmpty
            ? (widget.esEntrada ? 'Entrada manual de inventario' : 'Merma no especificada')
            : _motivoController.text.trim(),
        fecha: DateTime.now().toIso8601String(),
      );

      // Creamos el método de registrar usando el modelo directamente
      await db.registrarMovimiento(
        movimiento.productoId,
        movimiento.tipoMovimiento,
        movimiento.cantidad,
        movimiento.motivo,
      );

      // 3. Actualizar el stock del producto en la BD
      await db.actualizarStockProducto(widget.producto.id!, nuevoStock);

      if (!mounted) return;

      // Devolvemos `true` para que la pantalla de Inventario sepa que debe recargar la lista
      Navigator.pop(context, true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.esEntrada
                ? '¡Entrada registrada! Nuevo stock: ${nuevoStock.toStringAsFixed(2)}'
                : '¡Merma registrada! Nuevo stock: ${nuevoStock.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          backgroundColor: widget.esEntrada ? Colors.green[800] : Colors.orange[900],
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      setState(() => _guardando = false);
      _mostrarAlerta('Error al guardar en base de datos: $e');
    }
  }

  void _mostrarAlerta(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje, style: const TextStyle(fontSize: 16)),
        backgroundColor: Colors.red[800],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorTema = widget.esEntrada ? Colors.green[700]! : Colors.orange[800]!;
    final titulo = widget.esEntrada ? 'REGISTRAR ENTRADA' : 'REGISTRAR MERMA';
    final icono = widget.esEntrada ? Icons.add_circle : Icons.remove_circle;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(), // Ocultar teclado al tocar fuera
      child: Scaffold(
        appBar: AppBar(
          title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: colorTema,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ===============================================================
              // TARJETA DE RESUMEN DEL PRODUCTO (ERGONÓMICA)
              // ===============================================================
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.producto.nombre.toUpperCase(),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Categoría: ${widget.producto.categoria.toUpperCase()}',
                          style: TextStyle(fontSize: 14, color: Colors.grey[700], fontWeight: FontWeight.w600),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: widget.producto.stock <= 5 ? Colors.red[100] : Colors.blue[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Stock Actual: ${widget.producto.stock.toStringAsFixed(2)} ${widget.producto.esPorPeso ? "Kg" : "Pzas"}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: widget.producto.stock <= 5 ? Colors.red[900] : Colors.blue[900],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // ===============================================================
              // CAMPO DE CANTIDAD (GIGANTE PARA FÁCIL LECTURA)
              // ===============================================================
              Text(
                widget.esEntrada ? 'CANTIDAD QUE ENTRA:' : 'CANTIDAD QUE SE MERMA / PIERDE:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorTema),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _cantidadController,
                focusNode: _cantidadFocus,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  prefixIcon: Icon(icono, color: colorTema, size: 36),
                  suffixText: widget.producto.esPorPeso ? 'Kilos' : 'Piezas',
                  suffixStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  hintText: '0.00',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorTema, width: 2)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorTema, width: 3)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                ),
              ),

              const SizedBox(height: 25),

              // ===============================================================
              // CAMPO DE MOTIVO / NOTAS
              // ===============================================================
              Text(
                'MOTIVO O NOTA (OPCIONAL):',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[800]),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _motivoController,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 3,
                style: const TextStyle(fontSize: 18),
                decoration: InputDecoration(
                  hintText: widget.esEntrada ? 'Ej: Compra a proveedor, devolución...' : 'Ej: Se caducó, se rompió el costal...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),

              const SizedBox(height: 40),

              // ===============================================================
              // BOTÓN GIGANTE DE ACCIÓN (ERGONÓMICO)
              // ===============================================================
              SizedBox(
                height: 65,
                child: ElevatedButton.icon(
                  onPressed: _guardando ? null : _guardarMovimiento,
                  icon: _guardando
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Icon(widget.esEntrada ? Icons.save : Icons.warning_amber_rounded, size: 32),
                  label: Text(
                    _guardando ? 'GUARDANDO...' : (widget.esEntrada ? 'CONFIRMAR ENTRADA' : 'CONFIRMAR MERMA'),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorTema,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}