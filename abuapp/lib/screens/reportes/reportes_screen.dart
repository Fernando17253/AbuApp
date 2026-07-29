import 'package:flutter/material.dart';
import '../../models/venta_model.dart';
import '../../database/db_helper.dart'; // CONECTADO A SQLITE
import '../../utils/pdf_generator.dart'; // Lo activaremos cuando generemos los PDFs

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  String _periodoSeleccionado = 'hoy'; // 'hoy', 'semana', 'mes'

  // ===========================================================================
  // ESTADO SQLITE: Lista de ventas, movimientos y bandera de carga
  // ===========================================================================
  List<Venta> _ventasPeriodo = [];
  List<Map<String, dynamic>> _movimientosPeriodo = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarVentas(); // Consultar ventas reales al abrir la pantalla
  }

  // ===========================================================================
  // CARGA SIMULTÁNEA DE VENTAS E INVENTARIO PARA CRUZAR DATOS
  // ===========================================================================
  Future<void> _cargarVentas() async {
    setState(() => _cargando = true);
    try {
      final db = DbHelper();
      final todasLasVentas = await db.obtenerVentas();
      final todosLosMovimientos = await db.obtenerTodosLosMovimientos(); 
      
      final ahora = DateTime.now();
      final fechaHoyStr = ahora.toIso8601String().substring(0, 10); 

      List<Venta> ventasFiltradas = [];
      List<Map<String, dynamic>> movimientosFiltrados = [];

      if (_periodoSeleccionado == 'hoy') {
        ventasFiltradas = todasLasVentas.where((v) => v.fecha.startsWith(fechaHoyStr)).toList();
        movimientosFiltrados = todosLosMovimientos.where((m) => (m['fecha'] as String).startsWith(fechaHoyStr)).toList();
      } else if (_periodoSeleccionado == 'semana') {
        final haceSieteDias = ahora.subtract(const Duration(days: 7));
        ventasFiltradas = todasLasVentas.where((v) {
          final fechaVenta = DateTime.tryParse(v.fecha);
          return fechaVenta != null && fechaVenta.isAfter(haceSieteDias);
        }).toList();
        movimientosFiltrados = todosLosMovimientos.where((m) {
          final fechaMov = DateTime.tryParse(m['fecha'] as String);
          return fechaMov != null && fechaMov.isAfter(haceSieteDias);
        }).toList();
      } else if (_periodoSeleccionado == 'mes') {
        final mesActualStr = fechaHoyStr.substring(0, 7); 
        ventasFiltradas = todasLasVentas.where((v) => v.fecha.startsWith(mesActualStr)).toList();
        movimientosFiltrados = todosLosMovimientos.where((m) => (m['fecha'] as String).startsWith(mesActualStr)).toList();
      }

      setState(() {
        _ventasPeriodo = ventasFiltradas;
        _movimientosPeriodo = movimientosFiltrados; 
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
      _mostrarAlerta(context, 'Error al calcular los reportes: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, 
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: const Text('HISTORIAL DEL RANCHO', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
          backgroundColor: Colors.purple[900],
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0, 
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, size: 28),
              tooltip: 'Actualizar Datos',
              onPressed: _cargarVentas,
            ),
          ],
          bottom: const TabBar(
            indicatorColor: Colors.amber, 
            indicatorWeight: 4,
            labelColor: Colors.amber, 
            unselectedLabelColor: Colors.white70, 
            labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            labelPadding: EdgeInsets.symmetric(horizontal: 4), 
            tabs: [
              Tab(icon: Icon(Icons.bar_chart, size: 26), text: 'FINANZAS'),
              Tab(icon: Icon(Icons.receipt_long, size: 26), text: 'TICKETS'),
              Tab(icon: Icon(Icons.inventory, size: 26), text: 'INVENTARIO'),
            ],
          ),
        ),
        body: _cargando
            ? Center(child: CircularProgressIndicator(color: Colors.purple[900]))
            : TabBarView(
                children: [
                  _buildPestanaFinanzas(),
                  _buildPestanaHistorialVentas(),
                  _buildPestanaHistorialInventario(),
                ],
              ),
      ),
    );
  }

  // ===========================================================================
  // CONSTRUCCIÓN DE LA PESTAÑA 1: FINANZAS Y GENERACIÓN DE PDF
  // ===========================================================================
  Widget _buildPestanaFinanzas() {
    // 1. Calcular Ingresos de Ventas
    final totalIngresos = _ventasPeriodo.fold(0.0, (sum, v) => sum + v.total);
    final totalSat = _ventasPeriodo.where((v) => v.esLineaSat).fold(0.0, (sum, v) => sum + v.total);
    final totalGeneral = _ventasPeriodo.where((v) => !v.esLineaSat).fold(0.0, (sum, v) => sum + v.total);
    
    // 2. Ganancia Bruta (Estimación del 25% de margen sobre las ventas)
    final gananciaBruta = totalIngresos * 0.25; 

    // 3. Calcular Dinero Perdido en Mermas (Cantidad x Precio Costo)
    double valorPerdidoMermas = 0.0;
    for (var mov in _movimientosPeriodo) {
      final String tipo = (mov['tipo_movimiento'] ?? '').toString().toUpperCase();
      if (tipo == 'MERMA') {
        final cant = (mov['cantidad'] as num?)?.toDouble() ?? 0.0;
        // Si no han actualizado el DbHelper, evita error poniéndolo en 0
        final costo = (mov['precio_costo'] as num?)?.toDouble() ?? 0.0; 
        valorPerdidoMermas += (cant * costo);
      }
    }

    // 4. Ganancia Real Limpia (Ganancia Bruta - Mermas)
    final gananciaReal = gananciaBruta - valorPerdidoMermas;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('1. FILTRAR POR PERIODO', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black87)),
            const SizedBox(height: 12),
            
            // SELECTOR DE TIEMPO
            Row(
              children: [
                _botonPeriodo('hoy', 'HOY', '📅'),
                const SizedBox(width: 8),
                _botonPeriodo('semana', 'SEMANA', '📆'),
                const SizedBox(width: 8),
                _botonPeriodo('mes', 'MES', '🗓️'),
              ],
            ),
            const SizedBox(height: 28),

            const Text('2. RESUMEN DE DINERO', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black87)),
            const SizedBox(height: 12),

            // TARJETA GIGANTE: TOTAL VENDIDO
            _tarjetaMetrica(
              titulo: 'TOTAL INGRESOS (VENTAS)',
              monto: totalIngresos,
              colorFondo: Colors.green[800]!,
              icono: Icons.point_of_sale,
            ),
            const SizedBox(height: 16),

            // =================================================================
            // NUEVO: GRÁFICO VISUAL DE BARRAS (GANANCIAS VS MERMAS)
            // =================================================================
            _buildGraficoBarras(gananciaBruta, valorPerdidoMermas, gananciaReal),
            const SizedBox(height: 28),

            const Text('3. SEPARACIÓN DE CORTES', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black87)),
            const SizedBox(height: 12),

            // COMPARATIVA DE LÍNEAS FISCALES
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _tarjetaMini(
                      titulo: 'LÍNEA SAT\n(Ganado / Medicamentos)',
                      monto: totalSat,
                      color: Colors.blue[800]!,
                      emoji: '🐄💊',
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _tarjetaMini(
                      titulo: 'LÍNEA GENERAL\n(Plásticos / Maquinaria)',
                      monto: totalGeneral,
                      color: Colors.orange[800]!,
                      emoji: '🪣⚙️',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 36),

            // BOTÓN GIGANTE PARA CREAR EL ARCHIVO PDF
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey[900],
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 70), 
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 6,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              icon: const Icon(Icons.picture_as_pdf, size: 36, color: Colors.redAccent),
              label: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('CREAR DOCUMENTO PDF\nPara imprimir en hoja o enviar', 
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, height: 1.2),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
              ),
              onPressed: () async {
                if (_ventasPeriodo.isEmpty) {
                  _mostrarAlerta(context, '⚠️ No hay ventas en este periodo para exportar');
                  return;
                }
                _mostrarAlerta(context, '📄 Generando PDF con separación fiscal...');
                await PdfGenerator.generarReporteDueno(_ventasPeriodo, totalIngresos, totalSat, totalGeneral);
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // WIDGET: GRÁFICA DE BARRAS NATIVA (SIN LIBRERÍAS EXTERNAS)
  // ===========================================================================
  Widget _buildGraficoBarras(double gananciaBruta, double mermas, double gananciaReal) {
    // Calculamos el valor máximo para escalar la altura de las barras proporcionalmente
    final double maxVal = gananciaBruta > mermas ? gananciaBruta : mermas;
    final double limite = maxVal <= 0 ? 1 : maxVal; // Evita división entre cero

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[300]!, width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: Colors.purple[800], size: 28),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  '📊 RENDIMIENTO (GANANCIAS VS MERMAS)', 
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.blueGrey),
                  softWrap: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // CONTENEDOR DE LAS 3 BARRAS
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end, // Para que las barras crezcan desde abajo
            children: [
              _barraIndividual(titulo: 'Ganancia\nBruta', valor: gananciaBruta, limite: limite, color: Colors.purple[400]!),
              _barraIndividual(titulo: 'Pérdida por\nMermas', valor: mermas, limite: limite, color: Colors.red[500]!),
              _barraIndividual(titulo: 'Ganancia\nReal Neta', valor: gananciaReal, limite: limite, color: Colors.green[600]!),
            ],
          ),
        ],
      ),
    );
  }

  // Componente interno para dibujar cada columna vertical
  Widget _barraIndividual({required String titulo, required double valor, required double limite, required Color color}) {
    // Escala la altura de 0.0 a 1.0. Si la ganancia neta es negativa, la altura es 0.
    double factor = valor / limite;
    if (factor < 0) factor = 0; 
    if (factor > 1) factor = 1;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // MONTO ARRIBA DE LA BARRA
        Text(
          valor < 0 ? '-\$${valor.abs().toStringAsFixed(0)}' : '\$${valor.toStringAsFixed(0)}', 
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: valor < 0 ? Colors.red[800] : color)
        ),
        const SizedBox(height: 8),
        
        // LA BARRA ANIMADA (Crece y decrece suavemente al cambiar de periodo)
        AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          height: factor * 120, // Altura máxima en pixeles
          width: 50, // Grosor de la barra
          decoration: BoxDecoration(
            color: valor < 0 ? Colors.red[100] : color.withOpacity(0.85),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
        ),
        
        // LÍNEA BASE (Suelo)
        Container(height: 3, width: 70, color: Colors.grey[300]),
        const SizedBox(height: 10),
        
        // ETIQUETA INFERIOR
        Text(
          titulo, 
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54, height: 1.2)
        ),
      ],
    );
  }

  // ===========================================================================
  // CONSTRUCCIÓN DE LA PESTAÑA 2: HISTORIAL DE TICKETS DE VENTA
  // ===========================================================================
  Widget _buildPestanaHistorialVentas() {
    if (_ventasPeriodo.isEmpty) {
      return Container(
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long, size: 80, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                'No hay tickets registrados\nen el periodo seleccionado.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
            color: Colors.purple[800],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TICKETS EMITIDOS (${_ventasPeriodo.length}):',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                ),
                Text(
                  _periodoSeleccionado.toUpperCase(),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.amberAccent),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: _ventasPeriodo.length,
              itemBuilder: (context, index) {
                final venta = _ventasPeriodo[index];
                return _buildTarjetaVenta(venta);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTarjetaVenta(Venta venta) {
    final bool esSat = venta.esLineaSat;
    final Color colorBorde = esSat ? Colors.blue[700]! : Colors.orange[700]!;
    final Color colorBadge = esSat ? Colors.blue[50]! : Colors.orange[50]!;
    final Color colorTextoBadge = esSat ? Colors.blue[900]! : Colors.orange[900]!;

    final String fechaLimpia = venta.fecha.length > 16 
        ? venta.fecha.substring(0, 16).replaceFirst('T', ' - ') 
        : venta.fecha;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorBorde, width: 2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _mostrarDetalleVenta(venta),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Folio: ${venta.folio}',
                      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Colors.black87),
                      softWrap: true,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorBadge,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: colorBorde),
                    ),
                    child: Text(
                      esSat ? '🐄 LÍNEA SAT' : '🪣 GENERAL',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: colorTextoBadge),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 18, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    fechaLimpia,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey[700]),
                  ),
                ],
              ),
              const Divider(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('PAGO EN:', style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(
                        venta.metodoPago.toUpperCase(),
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.blueGrey[800]),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('TOTAL DE NOTA:', style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '\$${venta.total.toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.green[800]),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // HOJA DE DETALLE DEL TICKET (Corregida contra Overflow)
  // ===========================================================================
  void _mostrarDetalleVenta(Venta venta) {
    final String fechaLimpia = venta.fecha.length > 16 
        ? venta.fecha.substring(0, 16).replaceFirst('T', ' - ') 
        : venta.fecha;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Permite que la hoja tome más de la mitad de la pantalla si es necesario
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        // Envolvemos en SingleChildScrollView para pantallas pequeñas
        return SingleChildScrollView(
          child: SafeArea(
            child: Padding(
              // El padding bottom dinámico asegura que no lo tapen los botones del celular
              padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ENCABEZADO
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start, // Alineación arriba por si el texto baja
                    children: [
                      // El Expanded asegura que el título largo baje de renglón
                      Expanded(
                        child: Text(
                          'TICKET #${venta.folio}',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.black87, height: 1.1),
                          softWrap: true,
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.close, size: 30),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // CUADRO RESUMEN
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[300]!, width: 1.5),
                    ),
                    child: Column(
                      children: [
                        _filaDatoDetalle('Fecha de emisión:', fechaLimpia),
                        const Divider(height: 20),
                        _filaDatoDetalle('Método de Pago:', venta.metodoPago),
                        const Divider(height: 20),
                        _filaDatoDetalle('Clasificación:', venta.esLineaSat ? 'Fiscal (Línea SAT)' : 'Nota General'),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('TOTAL COBRADO:', style: TextStyle(fontSize: 17, color: Colors.grey[800], fontWeight: FontWeight.bold)),
                            Expanded(
                              child: Text(
                                '\$${venta.total.toStringAsFixed(2)}', 
                                style: TextStyle(fontSize: 26, color: Colors.green[800], fontWeight: FontWeight.w900),
                                textAlign: TextAlign.right,
                                softWrap: true,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // BOTÓN PARA CERRAR
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey[900],
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('CERRAR DETALLE', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  ),
                  const SizedBox(height: 14),

                  // BOTÓN ROJO PARA CANCELAR TICKET
                  Center(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red[800],
                        side: BorderSide(color: Colors.red[300]!, width: 1.5),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.delete_forever, size: 22),
                      label: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'CANCELAR / ELIMINAR ESTE TICKET',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ),
                      onPressed: () => _confirmarYEliminarVenta(venta),
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

  void _confirmarYEliminarVenta(Venta venta) {
    bool aceptoEliminar = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              title: Row(
                children: [
                  Icon(Icons.warning_rounded, color: Colors.red[800], size: 36),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      '¿ELIMINAR TICKET?',
                      style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: Colors.black87),
                      softWrap: true,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estás a punto de eliminar el ticket "${venta.folio}" por un total de \$${venta.total.toStringAsFixed(2)}.',
                      style: const TextStyle(fontSize: 17, color: Colors.black87, height: 1.3),
                      softWrap: true,
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, color: Colors.red[900], size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Esta nota se restará de los ingresos de tu corte y desaparecerá de los reportes fiscales/generales.',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.red[900], height: 1.3),
                              softWrap: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
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
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                                'Entiendo que cancelar y eliminar este ticket es una acción irreversible.',
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
                                final dbReal = await db.database;
                                await dbReal.delete('ventas', where: 'id = ?', whereArgs: [venta.id]);

                                if (!mounted) return;
                                Navigator.pop(context); 
                                Navigator.pop(context); 

                                _cargarVentas(); 

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('🗑️ Ticket "${venta.folio}" eliminado correctamente.', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

  // ===========================================================================
  // CONSTRUCCIÓN DE LA PESTAÑA 3: MOVIMIENTOS DE INVENTARIO
  // ===========================================================================
  Widget _buildPestanaHistorialInventario() {
    if (_movimientosPeriodo.isEmpty) {
      return Container(
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inventory_2, size: 80, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                'No hay entradas ni mermas registradas\nen el periodo seleccionado.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
            color: Colors.purple[800],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'MOVIMIENTOS DE STOCK (${_movimientosPeriodo.length}):',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                ),
                Text(
                  _periodoSeleccionado.toUpperCase(),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.amberAccent),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: _movimientosPeriodo.length,
              itemBuilder: (context, index) {
                final mov = _movimientosPeriodo[index];
                return _buildTarjetaMovimiento(mov);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTarjetaMovimiento(Map<String, dynamic> mov) {
    final String tipo = (mov['tipo_movimiento'] ?? '').toString().toUpperCase();
    final bool esEntrada = tipo == 'ENTRADA';
    
    final Color colorBorde = esEntrada ? Colors.green[700]! : Colors.red[700]!;
    final Color colorFondoBadge = esEntrada ? Colors.green[50]! : Colors.red[50]!;
    final Color colorTextoBadge = esEntrada ? Colors.green[900]! : Colors.red[900]!;

    final String nombreProd = (mov['producto_nombre'] ?? 'Producto eliminado').toString();
    final String categoria = (mov['producto_categoria'] ?? 'plastico').toString();
    final bool esPorPeso = (mov['es_por_peso'] ?? 0) == 1;
    final double cantidad = (mov['cantidad'] as num?)?.toDouble() ?? 0.0;
    final String unidad = esPorPeso ? 'KILOS' : 'PIEZAS';

    String emojiCat = '🪣';
    if (categoria == 'ganado') emojiCat = '🐄';
    if (categoria == 'medicamento') emojiCat = '💊';
    if (categoria == 'maquinaria') emojiCat = '⚙️';

    final String fechaIso = (mov['fecha'] ?? '').toString();
    final String fechaLimpia = fechaIso.length > 16 
        ? fechaIso.substring(0, 16).replaceFirst('T', ' - ') 
        : fechaIso;

    final String motivo = (mov['motivo'] ?? 'Sin nota de motivo').toString();

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorBorde, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorFondoBadge,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: colorBorde, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Icon(esEntrada ? Icons.add_circle : Icons.remove_circle, size: 18, color: colorTextoBadge),
                      const SizedBox(width: 6),
                      Text(
                        esEntrada ? 'ENTRADA DE STOCK' : 'MERMA / PÉRDIDA',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: colorTextoBadge),
                      ),
                    ],
                  ),
                ),
                Text(
                  fechaLimpia,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[700]),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(emojiCat, style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          nombreProd,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black87, height: 1.2),
                          softWrap: true,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${esEntrada ? "+" : "-"}${cantidad.toStringAsFixed(esPorPeso ? 1 : 0)}',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: colorBorde, height: 1.0),
                    ),
                    Text(
                      unidad,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: colorBorde),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.sticky_note_2_outlined, size: 20, color: Colors.blueGrey[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      motivo,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.blueGrey[900], height: 1.3),
                      softWrap: true,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // WIDGETS AUXILIARES GLOBALES
  // ===========================================================================

  Widget _botonPeriodo(String id, String texto, String emoji) {
    final seleccionado = _periodoSeleccionado == id;
    return Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: seleccionado ? Colors.purple[800] : Colors.white,
          foregroundColor: seleccionado ? Colors.white : Colors.black87,
          minimumSize: const Size(0, 52), 
          elevation: seleccionado ? 6 : 2,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: seleccionado ? Colors.purple : Colors.grey[300]!, width: 2),
          ),
        ),
        onPressed: () {
          setState(() => _periodoSeleccionado = id);
          _cargarVentas(); 
        },
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '$emoji $texto', 
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
            maxLines: 1,
          ),
        ),
      ),
    );
  }

  Widget _tarjetaMetrica({required String titulo, required double monto, required Color colorFondo, required IconData icono, bool esGanancia = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colorFondo,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: colorFondo.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 5))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icono, size: 50, color: Colors.white),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo, 
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white, height: 1.2),
                  softWrap: true,
                ),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '\$${monto.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1),
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tarjetaMini({required String titulo, required double monto, required Color color, required String emoji}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color, width: 3),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 30)),
              const SizedBox(height: 10),
              Text(
                titulo, 
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[800], height: 1.2),
                softWrap: true,
              ),
            ],
          ),
          const SizedBox(height: 16),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '\$${monto.toStringAsFixed(2)}', 
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color, height: 1.1),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _filaDatoDetalle(String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              etiqueta, 
              style: TextStyle(fontSize: 15, color: Colors.grey[700], fontWeight: FontWeight.w600),
              softWrap: true,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: Text(
              valor, 
              style: const TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w900),
              textAlign: TextAlign.end,
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarAlerta(BuildContext context, String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), 
        backgroundColor: Colors.purple[800],
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      )
    );
  }
}