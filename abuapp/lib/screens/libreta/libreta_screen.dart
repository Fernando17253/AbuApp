import 'package:flutter/material.dart';
import '../../models/cliente_model.dart';

class LibretaScreen extends StatefulWidget {
  const LibretaScreen({super.key});

  @override
  State<LibretaScreen> createState() => _LibretaScreenState();
}

class _LibretaScreenState extends State<LibretaScreen> {
  String _busqueda = '';
  final _busquedaController = TextEditingController();

  // Lista simulada (En producción vendrá de SQLite: ordenados por deuda DESC)
  final List<Cliente> _clientes = [
    Cliente(id: 1, nombre: 'Don Artemio López', domicilio: 'Rancho Las Palmas', ineTexto: 'LPZAR650812MCH', limiteCredito: 20000, deudaActual: 21500), // ROJO (Se pasó)
    Cliente(id: 2, nombre: 'Rogelio Garza (El Güero)', domicilio: 'Ejido El Mezquite', ineTexto: 'GRZRG780123MCH', limiteCredito: 15000, deudaActual: 13000), // NARANJA
    Cliente(id: 3, nombre: 'Don Chema Morales', domicilio: 'Camino Real #45', ineTexto: 'MRLCH551102MCH', limiteCredito: 30000, deudaActual: 4500), // VERDE
  ];

  @override
  Widget build(BuildContext context) {
    // Filtrar y ordenar: siempre los que deben más dinero arriba
    final clientesFiltrados = _clientes.where((c) {
      return c.nombre.toLowerCase().contains(_busqueda.toLowerCase()) ||
             c.domicilio.toLowerCase().contains(_busqueda.toLowerCase());
    }).toList()
      ..sort((a, b) => b.deudaActual.compareTo(a.deudaActual));

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('LIBRETA DE FIADOS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        backgroundColor: Colors.orange[900],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // BARRA DE BÚSQUEDA
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.orange[900],
            child: TextField(
              controller: _busquedaController,
              style: const TextStyle(fontSize: 18, color: Colors.black),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o rancho...',
                hintStyle: TextStyle(color: Colors.grey[600], fontSize: 16),
                prefixIcon: const Icon(Icons.search, size: 28, color: Colors.black87),
                suffixIcon: _busqueda.isNotEmpty 
                  ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() { _busquedaController.clear(); _busqueda = ''; })) 
                  : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              onChanged: (val) => setState(() => _busqueda = val),
            ),
          ),

          // RESUMEN DE DEUDA TOTAL EN LA CALLE
          _buildResumenDeuda(clientesFiltrados),

          // LISTA DE TARJETAS DE CLIENTES
          Expanded(
            child: clientesFiltrados.isEmpty
              ? const Center(child: Text('No se encontraron clientes', style: TextStyle(fontSize: 18, color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: clientesFiltrados.length,
                  itemBuilder: (context, index) => _buildTarjetaCliente(clientesFiltrados[index]),
                ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirModalNuevoCliente(context),
        backgroundColor: Colors.green[700],
        icon: const Icon(Icons.person_add, size: 30, color: Colors.white),
        label: const Text('NUEVO CLIENTE', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  Widget _buildResumenDeuda(List<Cliente> clientes) {
    final totalDeuda = clientes.fold(0.0, (sum, c) => sum + c.deudaActual);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('TOTAL FIADO EN LA CALLE:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
          Text('\$${totalDeuda.toStringAsFixed(2)}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.red[800])),
        ],
      ),
    );
  }

  Widget _buildTarjetaCliente(Cliente cliente) {
    // Definir colores y textos del semáforo
    Color colorBorde = Colors.green;
    Color colorFondoBadget = Colors.green[100]!;
    Color colorTextoBadget = Colors.green[900]!;
    String textoSemaforo = 'CRÉDITO SANO';

    if (cliente.estadoSemaforo == 2) {
      colorBorde = Colors.red;
      colorFondoBadget = Colors.red[100]!;
      colorTextoBadget = Colors.red[900]!;
      textoSemaforo = '¡LÍMITE REBASADO!';
    } else if (cliente.estadoSemaforo == 1) {
      colorBorde = Colors.orange;
      colorFondoBadget = Colors.orange[100]!;
      colorTextoBadget = Colors.orange[900]!;
      textoSemaforo = 'CERCA DEL LÍMITE';
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorBorde, width: 3), // Borde grueso de color
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FILA SUPERIOR: Nombre y Etiqueta del Semáforo
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cliente.nombre, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                      Text('📍 ${cliente.domicilio}', style: const TextStyle(fontSize: 16, color: Colors.black54)),
                      if (cliente.ineTexto != null && cliente.ineTexto!.isNotEmpty)
                        Text('🪪 INE: ${cliente.ineTexto}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueGrey[700])),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: colorFondoBadget, borderRadius: BorderRadius.circular(8)),
                  child: Text(textoSemaforo, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: colorTextoBadget)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // NÚMEROS DE DEUDA GIGANTES
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('DEBE ACTUALMENTE:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
                      Text('\$${cliente.deudaActual.toStringAsFixed(2)}', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: colorBorde)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Límite permitido:', style: TextStyle(fontSize: 14, color: Colors.grey)),
                      Text('\$${cliente.limiteCredito.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // BOTÓN GIGANTE DE ABONAR
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[800],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.monetization_on, size: 28),
                label: const Text('ABONAR A CUENTA', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                onPressed: () => _abrirModalAbono(cliente),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // MODAL PARA REGISTRAR UN PAGO / ABONO
  void _abrirModalAbono(Cliente cliente) {
    final abonoController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('💵 REGISTRAR PAGO / ABONO', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.blue)),
            const SizedBox(height: 8),
            Text('Cliente: ${cliente.nombre}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Deuda actual: \$${cliente.deudaActual.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, color: Colors.red)),
            const SizedBox(height: 20),

            TextField(
              controller: abonoController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: '¿Cuánto dinero abona hoy?',
                labelStyle: const TextStyle(fontSize: 18),
                prefixText: '\$ ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.blue[50],
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white),
                onPressed: () {
                  final abono = double.tryParse(abonoController.text);
                  if (abono != null && abono > 0) {
                    setState(() {
                      cliente.deudaActual -= abono;
                      if (cliente.deudaActual < 0) cliente.deudaActual = 0;
                    });
                    // AQUÍ SQLITE: Guardar en tabla de abonos y actualizar cliente
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('¡Abono registrado con éxito!', style: TextStyle(fontSize: 18)), backgroundColor: Colors.green)
                    );
                  }
                },
                child: const Text('CONFIRMAR ABONO', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // MODAL PARA CREAR UN NUEVO CLIENTE RÁPIDAMENTE
  void _abrirModalNuevoCliente(BuildContext context) {
    final nombreController = TextEditingController();
    final domicilioController = TextEditingController();
    final ineController = TextEditingController();
    final limiteController = TextEditingController(text: '10000'); // Límite por defecto

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('📒 REGISTRAR NUEVO CLIENTE', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.green)),
              const SizedBox(height: 16),
              _campoTexto(controller: nombreController, label: 'Nombre Completo / Apodo', icono: Icons.person),
              const SizedBox(height: 12),
              _campoTexto(controller: domicilioController, label: 'Domicilio o Rancho', icono: Icons.home),
              const SizedBox(height: 12),
              _campoTexto(controller: ineController, label: 'Clave INE o Nota de Identificación', icono: Icons.badge),
              const SizedBox(height: 12),
              _campoTexto(controller: limiteController, label: 'Límite de Crédito Permitido (\$)', icono: Icons.monetization_on, esNumero: true),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white),
                  onPressed: () {
                    if (nombreController.text.isNotEmpty) {
                      setState(() {
                        _clientes.add(Cliente(
                          id: _clientes.length + 1,
                          nombre: nombreController.text,
                          domicilio: domicilioController.text,
                          ineTexto: ineController.text,
                          limiteCredito: double.tryParse(limiteController.text) ?? 10000,
                        ));
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('¡Cliente agregado a la libreta!'), backgroundColor: Colors.green)
                      );
                    }
                  },
                  child: const Text('GUARDAR EN LIBRETA', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _campoTexto({required TextEditingController controller, required String label, required IconData icono, bool esNumero = false}) {
    return TextField(
      controller: controller,
      keyboardType: esNumero ? TextInputType.number : TextInputType.text,
      style: const TextStyle(fontSize: 18),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icono, size: 28),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[100],
      ),
    );
  }
}