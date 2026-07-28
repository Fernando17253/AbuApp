import 'package:flutter/material.dart';
import '../../models/venta_model.dart';
// import '../../utils/pdf_generator.dart'; // Lo crearemos en el Paso 2

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  String _periodoSeleccionado = 'hoy'; // 'hoy', 'semana', 'mes'

  // Datos simulados (En producción vendrán de SQLite según las fechas filtradas)
  final List<Venta> _ventasPeriodo = [
    Venta(id: 1, folio: 'SAT-101', fecha: '2026-07-27', total: 13500.00, metodoPago: 'EFECTIVO', esLineaSat: true), // Becerro
    Venta(id: 2, folio: 'GEN-102', fecha: '2026-07-27', total: 450.00, metodoPago: 'EFECTIVO', esLineaSat: false), // Cubetas
    Venta(id: 3, folio: 'SAT-103', fecha: '2026-07-27', total: 850.00, metodoPago: 'TRANSFERENCIA', esLineaSat: true), // Medicinas
    Venta(id: 4, folio: 'GEN-104', fecha: '2026-07-27', total: 3800.00, metodoPago: 'FIADO', esLineaSat: false), // Aspersor
  ];

  @override
  Widget build(BuildContext context) {
    // Cálculos matemáticos rápidos
    final totalIngresos = _ventasPeriodo.fold(0.0, (sum, v) => sum + v.total);
    final totalSat = _ventasPeriodo.where((v) => v.esLineaSat).fold(0.0, (sum, v) => sum + v.total);
    final totalGeneral = _ventasPeriodo.where((v) => !v.esLineaSat).fold(0.0, (sum, v) => sum + v.total);
    
    // Simulación de ganancia neta estimada (ej. 25% del total después de restar costos de inventario)
    final gananciaNetaEstimada = totalIngresos * 0.25; 

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('REPORTES Y CUENTAS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        backgroundColor: Colors.purple[900],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('1. SELECCIONAR PERIODO', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            
            // SELECTOR DE TIEMPO GIGANTE
            Row(
              children: [
                _botonPeriodo('hoy', 'HOY', '📅'),
                const SizedBox(width: 8),
                _botonPeriodo('semana', 'SEMANA', '📆'),
                const SizedBox(width: 8),
                _botonPeriodo('mes', 'MES', '🗓️'),
              ],
            ),
            const SizedBox(height: 20),

            const Text('2. RESUMEN DE DINERO', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            // TARJETA GIGANTE: TOTAL VENDIDO
            _tarjetaMetrica(
              titulo: 'TOTAL VENDIDO EN EL PERIODO',
              monto: totalIngresos,
              colorFondo: Colors.green[800]!,
              icono: Icons.point_of_sale,
            ),
            const SizedBox(height: 12),

            // TARJETA GIGANTE: GANANCIA NETA
            _tarjetaMetrica(
              titulo: 'GANANCIA LIMPIA (ESTIMADA)',
              monto: gananciaNetaEstimada,
              colorFondo: Colors.purple[800]!,
              icono: Icons.trending_up,
              esGanancia: true,
            ),
            const SizedBox(height: 20),

            const Text('3. SEPARACIÓN PARA EL SAT / CONTADOR', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            // COMPARATIVA DE LÍNEAS FISCALES
            Row(
              children: [
                Expanded(
                  child: _tarjetaMini(
                    titulo: 'LÍNEA SAT\n(Ganado / Meds)',
                    monto: totalSat,
                    color: Colors.blue[800]!,
                    emoji: '🐄💊',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _tarjetaMini(
                    titulo: 'LÍNEA GENERAL\n(Plásticos / Maq)',
                    monto: totalGeneral,
                    color: Colors.orange[800]!,
                    emoji: '🪣⚙️',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // BOTÓN GIGANTE PARA CREAR EL ARCHIVO PDF
            SizedBox(
              width: double.infinity,
              height: 65,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey[900],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 6,
                ),
                icon: const Icon(Icons.picture_as_pdf, size: 32, color: Colors.redAccent),
                label: const Text('CREAR DOCUMENTO PDF\nPara imprimir en hoja o enviar', 
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                onPressed: () {
                  _mostrarAlerta(context, 'Generando PDF tamaño carta con separación fiscal...');
                  // await PdfGenerator.generarReporteDueno(_ventasPeriodo, totalIngresos, totalSat, totalGeneral);
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _botonPeriodo(String id, String texto, String emoji) {
    final seleccionado = _periodoSeleccionado == id;
    return Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: seleccionado ? Colors.purple[800] : Colors.white,
          foregroundColor: seleccionado ? Colors.white : Colors.black87,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: seleccionado ? Colors.purple : Colors.grey[400]!, width: 2),
          ),
        ),
        onPressed: () => setState(() => _periodoSeleccionado = id),
        child: Text('$emoji $texto', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _tarjetaMetrica({required String titulo, required double monto, required Color colorFondo, required IconData icono, bool esGanancia = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorFondo,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: colorFondo.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Icon(icono, size: 50, color: Colors.white),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                Text(
                  '\$${monto.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white),
                ),
                if (esGanancia)
                  const Text('Dinero libre para el negocio', style: TextStyle(fontSize: 13, color: Colors.greenAccent, fontWeight: FontWeight.bold)),
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 8),
          Text(titulo, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[800])),
          const SizedBox(height: 8),
          Text('\$${monto.toStringAsFixed(2)}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }

  void _mostrarAlerta(BuildContext context, String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje, style: const TextStyle(fontSize: 16)), backgroundColor: Colors.purple));
  }
}