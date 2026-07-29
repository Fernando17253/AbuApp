import 'package:abuapp/screens/libreta/libreta_screen.dart';
import 'package:flutter/material.dart';
import '../inventario/inventario_screen.dart';
import '../pos/pos_screen.dart';
import '../reportes/reportes_screen.dart'; // Asegúrate de importar tus pantallas reales

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
        elevation: 4,
      ),
      // SingleChildScrollView + SafeArea para responsividad perfecta al scroll y escalado
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),

              // BOTÓN 1: PUNTO DE VENTA (El más grande, altura mínima garantizada de 130px)
              _buildBotonHorizontal(
                context,
                titulo: 'VENDER / COBRAR',
                subtitulo: 'Ganado, Medicinas, Plásticos y Maquinaria',
                emoji: '💰',
                colorFondo: Colors.green[700]!,
                alturaMinima: 130, // Nunca será más pequeño que esto
                esDestacado: true,
                alPresionar: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const PosScreen()));
                },
              ),
              const SizedBox(height: 16),

              // BOTÓN 2: INVENTARIO (Altura mínima garantizada de 110px)
              _buildBotonHorizontal(
                context,
                titulo: 'INVENTARIO',
                subtitulo: 'Ver existencias, entradas y mermas',
                emoji: '📦',
                colorFondo: Colors.blue[800]!,
                alturaMinima: 110,
                alPresionar: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const InventarioScreen()));
                },
              ),
              const SizedBox(height: 16),

              // BOTONES 3 Y 4 EN FILA: SIMETRÍA INTELIGENTE CON ALTURA MÍNIMA DE 145px
              // IntrinsicHeight asegura que si uno crece por texto largo, el otro lo empareja exactamente
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _buildBotonVertical(
                        context,
                        titulo: 'LIBRETA',
                        subtitulo: 'Deudores y fiados',
                        emoji: '📒',
                        colorFondo: Colors.orange[800]!,
                        alturaMinima: 145, // Tarjetas altas y cómodas al tacto
                        alPresionar: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const LibretaScreen()));
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildBotonVertical(
                        context,
                        titulo: 'REPORTES',
                        subtitulo: 'Ganancias y SAT',
                        emoji: '📊',
                        colorFondo: Colors.purple[800]!,
                        alturaMinima: 145,
                        alPresionar: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const ReportesScreen()));
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // COMPONENTE A: Botón Horizontal para Vender e Inventario (Con minimumSize y letras grandes)
  Widget _buildBotonHorizontal(BuildContext context, {
    required String titulo,
    required String subtitulo,
    required String emoji,
    required Color colorFondo,
    required double alturaMinima,
    required VoidCallback alPresionar,
    bool esDestacado = false,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorFondo,
        foregroundColor: Colors.white,
        elevation: esDestacado ? 8 : 4,
        // ESTE ES EL SECRETO: Garantiza un botón robusto en pantallas chicas, pero permite crecer si se requiere
        minimumSize: Size(double.infinity, alturaMinima),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      ),
      onPressed: alPresionar,
      child: Row(
        children: [
          // Emoji significativamente más grande para rápida identificación visual
          Text(emoji, style: TextStyle(fontSize: esDestacado ? 48 : 42)),
          const SizedBox(width: 18),
          // Expanded permite que el texto baje a otra línea libremente sin recortarse
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: esDestacado ? 24 : 22, // Letra muy clara y legible
                    fontWeight: FontWeight.w900, 
                    letterSpacing: 0.5
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitulo,
                  style: TextStyle(
                    fontSize: esDestacado ? 16 : 15, 
                    fontWeight: FontWeight.w500, 
                    color: Colors.white.withOpacity(0.95),
                    height: 1.2, // Interlineado cómodo para leer
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.arrow_forward_ios, size: esDestacado ? 26 : 22, color: Colors.white70),
        ],
      ),
    );
  }

  // COMPONENTE B: Botón Vertical en Tarjeta para Libreta y Reportes
  Widget _buildBotonVertical(BuildContext context, {
    required String titulo,
    required String subtitulo,
    required String emoji,
    required Color colorFondo,
    required double alturaMinima,
    required VoidCallback alPresionar,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorFondo,
        foregroundColor: Colors.white,
        elevation: 4,
        minimumSize: Size(double.infinity, alturaMinima),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      ),
      onPressed: alPresionar,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text(
            titulo,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, letterSpacing: 0.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            subtitulo,
            style: TextStyle(
              fontSize: 14, 
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.95),
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
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