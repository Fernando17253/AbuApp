import 'package:flutter/material.dart';
import '../inventario/inventario_screen.dart';
import '../pos/pos_screen.dart'; // Descomentaremos esto en el Paso 3 para la Fase 2

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('CONTROL DE NEGOCIO', 
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
        backgroundColor: Colors.blueGrey[900],
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 10),
            // BOTÓN 1: PUNTO DE VENTA (EL MÁS GRANDE E IMPORTANTE)
            Expanded(
              flex: 3, // Ocupa más espacio vertical
              child: _buildBotonGigante(
                context,
                titulo: 'VENDER / COBRAR',
                subtitulo: 'Ganado, Medicinas, Plásticos y Maquinaria',
                emoji: '💰',
                colorFondo: Colors.green[700]!,
                alPresionar: () {
                  // AQUÍ CONECTAREMOS LA PANTALLA DE VENTAS DE LA FASE 2
                  //ScaffoldMessenger.of(context).showSnackBar(
                  //  const SnackBar(content: Text('Abriendo módulo de ventas (Fase 2)...', style: TextStyle(fontSize: 18)))
                  //);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const PosScreen()));
                },
              ),
            ),
            const SizedBox(height: 16),

            // BOTÓN 2: INVENTARIO (FASE 1 COMPLETADA)
            Expanded(
              flex: 2,
              child: _buildBotonGigante(
                context,
                titulo: 'INVENTARIO',
                subtitulo: 'Ver existencias, entradas y mermas',
                emoji: '📦',
                colorFondo: Colors.blue[800]!,
                alPresionar: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const InventarioScreen()),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // BOTONES 3 Y 4 EN FILA: LIBRETA Y REPORTES
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Expanded(
                    child: _buildBotonGigante(
                      context,
                      titulo: 'LIBRETA',
                      subtitulo: 'Deudores y fiados',
                      emoji: '📒',
                      colorFondo: Colors.orange[800]!,
                      alPresionar: () {
                        _mostrarAlertaPronto(context, 'Módulo de Libreta (Fase 3)');
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildBotonGigante(
                      context,
                      titulo: 'REPORTES',
                      subtitulo: 'Ganancias y SAT',
                      emoji: '📊',
                      colorFondo: Colors.purple[800]!,
                      alPresionar: () {
                        _mostrarAlertaPronto(context, 'Módulo de Reportes (Fase 4)');
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // Componente visual para crear botones accesibles de alto contraste
  Widget _buildBotonGigante(BuildContext context, {
    required String titulo,
    required String subtitulo,
    required String emoji,
    required Color colorFondo,
    required VoidCallback alPresionar,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorFondo,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.all(16),
      ),
      onPressed: alPresionar,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 45)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitulo,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 28, color: Colors.white),
        ],
      ),
    );
  }

  void _mostrarAlertaPronto(BuildContext context, String modulo) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$modulo disponible próximamente.', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueGrey,
      ),
    );
  }
}