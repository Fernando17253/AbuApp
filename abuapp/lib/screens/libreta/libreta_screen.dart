import 'package:flutter/material.dart';
import '../../models/cliente_model.dart';
import '../../database/db_helper.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class LibretaScreen extends StatefulWidget {
  const LibretaScreen({super.key});

  @override
  State<LibretaScreen> createState() => _LibretaScreenState();
}

class _LibretaScreenState extends State<LibretaScreen> {
  String _busqueda = '';
  final _busquedaController = TextEditingController();

  // ===========================================================================
  // ESTADO SQLITE: Lista dinámica y bandera de carga
  // ===========================================================================
  List<Cliente> _clientes = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarClientes(); // Consultar la libreta real en SQLite al iniciar
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  // MÉTODO PARA CONSULTAR CLIENTES Y ORDENAR POR MAYOR DEUDA
  Future<void> _cargarClientes() async {
    setState(() => _cargando = true);
    try {
      final db = DbHelper();
      final lista = await db.obtenerClientes();
      
      // Ordenamos: los que deben más dinero van en la parte superior
      lista.sort((a, b) => b.deudaActual.compareTo(a.deudaActual));

      setState(() {
        _clientes = lista.where((c) => c.activo).toList();
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
      _mostrarAlerta('Error al cargar la libreta: $e');
    }
  }

  void _mostrarAlerta(String mensaje, {bool esExito = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: esExito ? Colors.green[800] : Colors.red[800],
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filtrado por texto (Nombre, Rancho o INE) sobre los datos ya cargados de SQLite
    final clientesFiltrados = _clientes.where((c) {
      final termino = _busqueda.trim().toLowerCase();
      return termino.isEmpty ||
             c.nombre.toLowerCase().contains(termino) ||
             c.domicilio.toLowerCase().contains(termino) ||
             (c.ineTexto?.toLowerCase().contains(termino) ?? false);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('LIBRETA DE FIADOS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
        backgroundColor: Colors.orange[900],
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 28),
            tooltip: 'Actualizar Libreta',
            onPressed: _cargarClientes,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. BARRA DE BÚSQUEDA GIGANTE
            Container(
              padding: const EdgeInsets.all(14),
              color: Colors.orange[900],
              child: TextField(
                controller: _busquedaController,
                style: const TextStyle(fontSize: 20, color: Colors.black, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre, rancho o INE...',
                  hintStyle: TextStyle(color: Colors.grey[600], fontSize: 17, fontWeight: FontWeight.normal),
                  prefixIcon: const Icon(Icons.search, size: 32, color: Colors.black87),
                  suffixIcon: _busqueda.isNotEmpty 
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 28), 
                        onPressed: () {
                          _busquedaController.clear();
                          setState(() => _busqueda = '');
                        }
                      ) 
                    : null,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
                onChanged: (val) => setState(() => _busqueda = val),
              ),
            ),

            // 2. RESUMEN DE DEUDA TOTAL EN LA CALLE
            _buildResumenDeuda(clientesFiltrados),

            // 3. LISTA DE TARJETAS CON INDICADOR DE CARGA
            Expanded(
              child: _cargando
                ? const Center(child: CircularProgressIndicator(color: Colors.orange))
                : clientesFiltrados.isEmpty
                  ? const Center(
                      child: Text(
                        'No se encontraron clientes\nen la libreta 📒', 
                        style: TextStyle(fontSize: 20, color: Colors.grey, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : RefreshIndicator(
                      color: Colors.orange[900],
                      onRefresh: _cargarClientes,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 85),
                        itemCount: clientesFiltrados.length,
                        itemBuilder: (context, index) => _buildTarjetaCliente(clientesFiltrados[index]),
                      ),
                    ),
            ),
          ],
        ),
      ),
      
      // 4. BOTÓN FLOTANTE ROBUSTO Y ERGONÓMICO
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirModalNuevoCliente(context),
        backgroundColor: Colors.green[700],
        elevation: 6,
        icon: const Icon(Icons.person_add, size: 32, color: Colors.white),
        label: const Padding(
          padding: EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Text('NUEVO CLIENTE', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5)),
        ),
      ),
    );
  }

  Widget _buildResumenDeuda(List<Cliente> clientes) {
    final totalDeuda = clientes.fold(0.0, (sum, c) => sum + c.deudaActual);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 3))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(
            child: Text('TOTAL FIADO EN LA CALLE:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.blueGrey)),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text('\$${totalDeuda.toStringAsFixed(2)}', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.red[800])),
          ),
        ],
      ),
    );
  }

  Widget _buildTarjetaCliente(Cliente cliente) {
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
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colorBorde, width: 3),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // =================================================================
            // FILA 1: NOMBRE, ESTADO Y BOTÓN DE EDITAR
            // =================================================================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cliente.nombre, 
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black87, height: 1.2),
                      ),
                      const SizedBox(height: 6),
                      Text('📍 ${cliente.domicilio}', style: const TextStyle(fontSize: 17, color: Colors.black54, fontWeight: FontWeight.w600)),
                      if (cliente.ineTexto != null && cliente.ineTexto!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('🪪 INE: ${cliente.ineTexto}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.blueGrey[800])),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Botón para editar / eliminar
                    IconButton(
                      icon: const Icon(Icons.edit_note, size: 34, color: Colors.blueGrey),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Editar o Eliminar',
                      onPressed: () => _abrirModalNuevoCliente(context, clienteAEditar: cliente), // PASAMOS EL CLIENTE AQUÍ
                    ),
                    const SizedBox(height: 12),
                    // Semáforo de crédito
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: colorFondoBadget, borderRadius: BorderRadius.circular(10)),
                      child: Text(textoSemaforo, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: colorTextoBadget)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
// ... Resto de tu código: CUADRO FINANCIERO Y BOTÓN ABONAR (No cambia)

            // CUADRO FINANCIERO GIGANTE
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey[100], 
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey[300]!, width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('DEBE ACTUALMENTE:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(height: 2),
                        Text('\$${cliente.deudaActual.toStringAsFixed(2)}', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: colorBorde)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Límite permitido:', style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text('\$${cliente.limiteCredito.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // BOTÓN GIGANTE DE ABONAR
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: cliente.deudaActual <= 0 ? Colors.grey : Colors.blue[800],
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 58),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: cliente.deudaActual <= 0 ? 0 : 3,
              ),
              icon: const Icon(Icons.monetization_on, size: 30),
              label: Text(
                cliente.deudaActual <= 0 ? 'CUENTA SALDADA' : 'ABONAR A CUENTA', 
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)
              ),
              onPressed: cliente.deudaActual <= 0 ? null : () => _abrirModalAbono(cliente),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // MODAL DE ABONO CONECTADO A SQLITE CON HISTORIAL
  // ===========================================================================
  void _abrirModalAbono(Cliente cliente) {
    final abonoController = TextEditingController();
    bool guardandoAbono = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
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
                  const Text('💵 REGISTRAR PAGO / ABONO', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.blue)),
                  const SizedBox(height: 10),
                  Text('Cliente: ${cliente.nombre}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Deuda actual: \$${cliente.deudaActual.toStringAsFixed(2)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red[800])),
                  const SizedBox(height: 24),

                  TextField(
                    controller: abonoController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    autofocus: true,
                    style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Colors.blue),
                    decoration: InputDecoration(
                      labelText: '¿Cuánto dinero abona hoy?',
                      labelStyle: const TextStyle(fontSize: 18, color: Colors.black87),
                      prefixText: '\$ ',
                      prefixStyle: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Colors.blue),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      filled: true,
                      fillColor: Colors.blue[50],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    ),
                  ),
                  const SizedBox(height: 28),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700], 
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 60),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                    ),
                    onPressed: guardandoAbono ? null : () async {
                      final texto = abonoController.text.trim();
                      final abono = double.tryParse(texto);
                      
                      if (abono == null || abono <= 0) {
                        _mostrarAlerta('Por favor ingresa una cantidad válida mayor a \$0');
                        return;
                      }

                      if (abono > cliente.deudaActual) {
                        _mostrarAlerta('El abono no puede ser mayor a la deuda actual (\$${cliente.deudaActual.toStringAsFixed(2)})');
                        return;
                      }

                      setModalState(() => guardandoAbono = true);

                      try {
                        final db = DbHelper();
                        final nuevaDeuda = cliente.deudaActual - abono;

                        // 1. Actualizamos el saldo del cliente en SQLite
                        await db.actualizarDeudaCliente(cliente.id!, nuevaDeuda);

                        // 2. Registramos el abono en el historial para auditoría y cortes
                        // Si tu método se llama diferente en DbHelper, ajusta esta línea (ej. db.insertarAbono)
                        await db.registrarAbono(
                          cliente.id!,
                          abono,
                          DateTime.now().toIso8601String(),
                          'Abono en efectivo en libreta',
                        );

                        if (!mounted) return;
                        Navigator.pop(context);
                        
                        _mostrarAlerta('¡Abono de \$${abono.toStringAsFixed(2)} registrado con éxito!', esExito: true);
                        _cargarClientes(); // Recargar la lista visual
                      } catch (e) {
                        setModalState(() => guardandoAbono = false);
                        _mostrarAlerta('Error al registrar abono: $e');
                      }
                    },
                    child: guardandoAbono
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('CONFIRMAR ABONO', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // MODAL PARA CREAR UN NUEVO CLIENTE EN SQLITE
  // ===========================================================================
  // ===========================================================================
  // MODAL PARA CREAR O EDITAR UN CLIENTE (Y OPCIÓN DE ELIMINAR)
  // ===========================================================================
  // ===========================================================================
  // MODAL PARA CREAR O EDITAR UN CLIENTE (Y OPCIÓN DE ELIMINAR CON FOTOS)
  // ===========================================================================
  void _abrirModalNuevoCliente(BuildContext context, {Cliente? clienteAEditar}) {
    final bool esEdicion = clienteAEditar != null;
    
    // Controladores de texto
    final nombreController = TextEditingController(text: esEdicion ? clienteAEditar.nombre : '');
    final domicilioController = TextEditingController(text: esEdicion ? clienteAEditar.domicilio : '');
    final ineController = TextEditingController(text: esEdicion ? (clienteAEditar.ineTexto ?? '') : '');
    final limiteController = TextEditingController(text: esEdicion ? clienteAEditar.limiteCredito.toStringAsFixed(0) : '10000');
    
    // LISTA DE RUTAS DE IMÁGENES (Se carga con las existentes si es edición)
    // OJO: Asegúrate de que tu modelo 'Cliente' tenga la propiedad 'ineImagenes'
    List<String> rutasImagenesIne = [];
    if (esEdicion && clienteAEditar.ineImagenes != null && clienteAEditar.ineImagenes!.isNotEmpty) {
      rutasImagenesIne = clienteAEditar.ineImagenes!.split(',');
    }

    bool guardandoCliente = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          
          // MÉTODO INTERNO PARA TOMAR FOTO O ELEGIR DE GALERÍA
          Future<void> _agregarFoto(ImageSource fuente) async {
            try {
              final ImagePicker picker = ImagePicker();
              final XFile? imagen = await picker.pickImage(
                source: fuente,
                imageQuality: 70, // Comprime la imagen para no saturar SQLite ni el teléfono
              );
              
              if (imagen != null) {
                setModalState(() {
                  rutasImagenesIne.add(imagen.path);
                });
              }
            } catch (e) {
              _mostrarAlerta('Error al obtener la imagen: $e');
            }
          }

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
                  Text(
                    esEdicion ? '✏️ EDITAR CLIENTE' : '📒 REGISTRAR NUEVO CLIENTE', 
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: esEdicion ? Colors.blue[800] : Colors.green[800])
                  ),
                  const SizedBox(height: 18),
                  
                  _campoTexto(controller: nombreController, label: 'Nombre Completo / Apodo *', icono: Icons.person),
                  const SizedBox(height: 14),
                  
                  _campoTexto(controller: domicilioController, label: 'Domicilio o Rancho *', icono: Icons.home),
                  const SizedBox(height: 14),
                  
                  _campoTexto(controller: ineController, label: 'Clave INE o Nota (Opcional)', icono: Icons.badge),
                  const SizedBox(height: 18),
                  
                  // =================================================================
                  // NUEVA SECCIÓN: CAPTURA DE FOTOS DEL INE
                  // =================================================================
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('📸 FOTOS DEL INE (Opcional)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.blueGrey)),
                        const SizedBox(height: 12),
                        
                        // BOTONES DE CÁMARA Y GALERÍA
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  side: BorderSide(color: Colors.blue[700]!, width: 1.5),
                                ),
                                icon: Icon(Icons.camera_alt, color: Colors.blue[800]),
                                label: Text('CÁMARA', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[800])),
                                onPressed: () => _agregarFoto(ImageSource.camera),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  side: BorderSide(color: Colors.purple[700]!, width: 1.5),
                                ),
                                icon: Icon(Icons.photo_library, color: Colors.purple[800]),
                                label: Text('GALERÍA', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple[800])),
                                onPressed: () => _agregarFoto(ImageSource.gallery),
                              ),
                            ),
                          ],
                        ),
                        
                        // PREVISUALIZACIÓN DE IMÁGENES SELECCIONADAS
                        if (rutasImagenesIne.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 100,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: rutasImagenesIne.length,
                              itemBuilder: (context, index) {
                                final ruta = rutasImagenesIne[index];
                                return Stack(
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.only(right: 12, top: 8),
                                      width: 120,
                                      height: 90,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.grey[400]!, width: 2),
                                        image: DecorationImage(
                                          image: FileImage(File(ruta)), // Muestra la foto real
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    // BOTÓN PARA BORRAR LA FOTO
                                    Positioned(
                                      top: 0,
                                      right: 4,
                                      child: InkWell(
                                        onTap: () {
                                          setModalState(() {
                                            rutasImagenesIne.removeAt(index);
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                          child: const Icon(Icons.close, size: 16, color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  
                  _campoTexto(controller: limiteController, label: 'Límite de Crédito Permitido (\$)', icono: Icons.monetization_on, esNumero: true),
                  const SizedBox(height: 28),
                  
                  // =================================================================
                  // BOTÓN GUARDAR / ACTUALIZAR
                  // =================================================================
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: esEdicion ? Colors.blue[800] : Colors.green[700], 
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 62),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                    ),
                    onPressed: guardandoCliente ? null : () async {
                      final nombre = nombreController.text.trim();
                      final domicilio = domicilioController.text.trim();
                      
                      if (nombre.isEmpty || domicilio.isEmpty) {
                        _mostrarAlerta('Por favor completa el nombre y el domicilio.');
                        return;
                      }

                      setModalState(() => guardandoCliente = true);

                      try {
                        final db = DbHelper();
                        // Convertimos la lista de imágenes a un String separado por comas
                        final String imagenesUnidas = rutasImagenesIne.join(',');

                        if (esEdicion) {
                          clienteAEditar.nombre = nombre;
                          clienteAEditar.domicilio = domicilio;
                          clienteAEditar.ineTexto = ineController.text.trim().isEmpty ? null : ineController.text.trim();
                          clienteAEditar.limiteCredito = double.tryParse(limiteController.text.trim()) ?? 10000.0;
                          clienteAEditar.ineImagenes = imagenesUnidas; // <-- ASIGNAMOS LAS IMÁGENES
                          
                          final dbReal = await db.database;
                          await dbReal.update('clientes', clienteAEditar.toMap(), where: 'id = ?', whereArgs: [clienteAEditar.id]);
                          
                          if (!mounted) return;
                          Navigator.pop(context);
                          _mostrarAlerta('¡Datos de "$nombre" actualizados!', esExito: true);

                        } else {
                          final nuevoCliente = Cliente(
                            nombre: nombre,
                            domicilio: domicilio,
                            ineTexto: ineController.text.trim().isEmpty ? null : ineController.text.trim(),
                            limiteCredito: double.tryParse(limiteController.text.trim()) ?? 10000.0,
                            deudaActual: 0.0,
                            activo: true,
                            ineImagenes: imagenesUnidas, // <-- ASIGNAMOS LAS IMÁGENES
                          );
                          await db.insertarCliente(nuevoCliente);

                          if (!mounted) return;
                          Navigator.pop(context);
                          _mostrarAlerta('¡Cliente "$nombre" agregado a la libreta!', esExito: true);
                        }

                        _cargarClientes(); 
                      } catch (e) {
                        setModalState(() => guardandoCliente = false);
                        _mostrarAlerta('Error al guardar: $e');
                      }
                    },
                    child: guardandoCliente
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(esEdicion ? 'ACTUALIZAR DATOS' : 'GUARDAR EN LIBRETA', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                  ),

                  if (esEdicion) ...[
                    const SizedBox(height: 16),
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
                            'ELIMINAR CLIENTE DE LA LIBRETA',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ),
                        onPressed: () {
                          if (clienteAEditar.deudaActual > 0) {
                            Navigator.pop(context);
                            _mostrarAlerta('❌ No puedes eliminar a un cliente que todavía te debe dinero (\$' + clienteAEditar.deudaActual.toStringAsFixed(2) + ').');
                          } else {
                            _confirmarYEliminarCliente(clienteAEditar);
                          }
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // ALERTA DE ELIMINACIÓN DE CLIENTE (CON CASILLA DE CONFIRMACIÓN OBLIGATORIA)
  // ===========================================================================
  void _confirmarYEliminarCliente(Cliente cliente) {
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
                      '¿ELIMINAR CLIENTE?',
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
                      'Estás a punto de eliminar a "${cliente.nombre}" de tu libreta de fiados.',
                      style: const TextStyle(fontSize: 17, color: Colors.black87, height: 1.3),
                      softWrap: true,
                    ),
                    const SizedBox(height: 18),

                    // CASILLA DE VERIFICACIÓN
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
                                'Entiendo y acepto que el cliente desaparecerá permanentemente de la libreta.',
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
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 100, 216, 58)),
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
                                // Hacemos un Soft Delete o eliminación física según prefieras.
                                // Usaremos borrado físico en este caso ya que tiene deuda 0
                                await dbReal.delete('clientes', where: 'id = ?', whereArgs: [cliente.id]);

                                if (!mounted) return;
                                Navigator.pop(context); // Cierra Alerta
                                Navigator.pop(context); // Cierra Modal de Edición

                                _cargarClientes(); // Actualiza la lista

                                _mostrarAlerta('🗑️ Cliente "${cliente.nombre}" eliminado de la libreta.');
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

  Widget _campoTexto({required TextEditingController controller, required String label, required IconData icono, bool esNumero = false}) {
    return TextField(
      controller: controller,
      keyboardType: esNumero ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 16, color: Colors.grey[700], fontWeight: FontWeight.w600),
        prefixIcon: Icon(icono, size: 30, color: Colors.blueGrey[700]),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.green[700]!, width: 2.5)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),
    );
  }
}