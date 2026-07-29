import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/producto_model.dart';
import '../../utils/camera_helper.dart';
import '../../database/db_helper.dart'; // CONECTADO A SQLITE

class AgregarProductoScreen extends StatefulWidget {
  final Producto? productoAEditar; // <-- NUEVO PARÁMETRO OPCIONAL

  const AgregarProductoScreen({super.key, this.productoAEditar});

  @override
  State<AgregarProductoScreen> createState() => _AgregarProductoScreenState();
}

class _AgregarProductoScreenState extends State<AgregarProductoScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Categoría seleccionada por defecto
  String _categoriaSeleccionada = 'plastico';
  bool _esPorPeso = false;
  bool _guardando = false; // ESTADO PARA EVITAR DOBLE CLIC AL GUARDAR

  // Controladores de texto
  final _nombreController = TextEditingController();
  final _costoController = TextEditingController();
  final _publicoController = TextEditingController();
  final _stockController = TextEditingController();
  
  // Controladores opcionales
  // Controladores exclusivos para Ganado (todos opcionales)
final _identificadorController = TextEditingController(); // Descripción o nombre propio del animal
final _areteController = TextEditingController();         // Número de arete (SINIGA / Siniiga)
final _fierroController = TextEditingController();        // Descripción o marca del fierro
  final _caducidadController = TextEditingController();
  final _laboratorioController = TextEditingController();
  final _garantiaController = TextEditingController();

// AHORA:
final List<String> _rutasFotosGuardadas = [];

  @override
  void dispose() {
    _nombreController.dispose();
    _costoController.dispose();
    _publicoController.dispose();
    _stockController.dispose();
  _identificadorController.dispose();
  _areteController.dispose();
  _fierroController.dispose();    
  _caducidadController.dispose();
    _laboratorioController.dispose();
    _garantiaController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // SI RECIBIMOS UN PRODUCTO, RELLENAMOS TODO EL FORMULARIO:
    if (widget.productoAEditar != null) {
      final p = widget.productoAEditar!;
      _nombreController.text = p.nombre;
      _costoController.text = p.precioCosto.toString();
      _publicoController.text = p.precioPublico.toString();
      _stockController.text = p.stock.toString();
      _categoriaSeleccionada = p.categoria;
      _esPorPeso = p.esPorPeso;

      // Cargar fechas o garantía
      _caducidadController.text = p.fechaCaducidad ?? '';
      _laboratorioController.text = p.laboratorio ?? '';
      if (p.garantiaMeses > 0) _garantiaController.text = p.garantiaMeses.toString();

      // Cargar las fotos existentes a la lista de miniaturas
      if (p.fotoPath != null && p.fotoPath!.isNotEmpty) {
        _rutasFotosGuardadas.addAll(p.fotoPath!.split(','));
      }

      // Separar inteligente de los campos de Ganado (ID, Arete y Fierro)
      if (p.areteFierro != null && p.areteFierro!.isNotEmpty) {
        final partes = p.areteFierro!.split('  |  ');
        for (var parte in partes) {
          if (parte.startsWith('ID: ')) {
            _identificadorController.text = parte.replaceFirst('ID: ', '');
          } else if (parte.startsWith('Arete: ')) {
            _areteController.text = parte.replaceFirst('Arete: ', '');
          } else if (parte.startsWith('Fierro: ')) {
            _fierroController.text = parte.replaceFirst('Fierro: ', '');
          } else {
            // Si era un texto simple antiguo, lo ponemos en identificador
            _identificadorController.text = parte;
          }
        }
      }
    }
  }

  // WIDGET DEL BOTÓN GIGANTE DE FOTO (Optimizado contra desbordamientos)
  Widget _buildBotonFoto(String prefijo, String etiqueta) {
  final bool hayFotos = _rutasFotosGuardadas.isNotEmpty;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(etiqueta, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.blueGrey)),
      const SizedBox(height: 10),

      // 1. BOTÓN PRINCIPAL PARA AGREGAR FOTO
      InkWell(
        onTap: () async {
          final ruta = await CameraHelper.tomarFotoYComprimir(prefijo);
          if (ruta != null) {
            setState(() {
              _rutasFotosGuardadas.add(ruta); // ¡Agregamos a la lista!
            });
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            color: hayFotos ? Colors.green[50] : Colors.blue[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hayFotos ? Colors.green : Colors.blue, 
              width: 2.5
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                hayFotos ? Icons.add_a_photo : Icons.camera_alt, 
                size: 36, 
                color: hayFotos ? Colors.green[800] : Colors.blue[800]
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  hayFotos 
                    ? 'AGREGAR OTRA FOTO\n(${_rutasFotosGuardadas.length} foto(s) capturada(s))' 
                    : 'TOMAR FOTOS\n(ARETE / FIERRO / ANIMAL)',
                  style: TextStyle(
                    fontSize: 17, 
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                    color: hayFotos ? Colors.green[900] : Colors.blue[900]
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      // 2. GALERÍA HORIZONTAL DE MINIATURAS (Solo visible si hay fotos)
      if (hayFotos) ...[
        const SizedBox(height: 14),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _rutasFotosGuardadas.length,
            itemBuilder: (context, index) {
              final ruta = _rutasFotosGuardadas[index];
              return Container(
                margin: const EdgeInsets.only(right: 12),
                width: 85,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[800]!, width: 2),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Miniatura de la imagen
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(File(ruta), fit: BoxFit.cover),
                    ),
                    // Botón flotante para eliminar una foto si salió mal
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _rutasFotosGuardadas.removeAt(index);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    ],
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
  widget.productoAEditar != null ? 'EDITAR REGISTRO' : 'NUEVO PRODUCTO', 
  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24)
),
        backgroundColor: Colors.blueGrey[900],
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 4,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('1. ¿QUÉ TIPO DE PRODUCTO ES?', 
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black87)),
                const SizedBox(height: 14),
                
                _buildSelectorCategorias(),
                const SizedBox(height: 28),

                const Text('2. DATOS BÁSICOS', 
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black87)),
                const SizedBox(height: 14),

                _buildCampoTexto(
                  controller: _nombreController, 
                  etiqueta: _categoriaSeleccionada == 'ganado' ? 'Nombre o Descripción (Ej. Becerro Pinto)' : 'Nombre del Producto',
                  icono: Icons.label
                ),
                const SizedBox(height: 16),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildCampoTexto(
                        controller: _costoController,
                        etiqueta: 'Costo (\$)',
                        icono: Icons.arrow_downward,
                        esNumero: true
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildCampoTexto(
                        controller: _publicoController,
                        etiqueta: 'Venta (\$)',
                        icono: Icons.attach_money,
                        esNumero: true
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 6,
                      child: _buildCampoTexto(
                        controller: _stockController,
                        etiqueta: _esPorPeso ? 'Kilos iniciales' : 'Existencias (Pz)',
                        icono: Icons.inventory,
                        esNumero: true
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 5,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _esPorPeso ? Colors.orange[50] : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _esPorPeso ? Colors.orange : Colors.grey[300]!, width: 2),
                        ),
                        child: CheckboxListTile(
                          title: const Text('¿Se vende por Kilo?', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, height: 1.1)),
                          value: _esPorPeso,
                          activeColor: Colors.orange[800],
                          onChanged: (val) {
                            setState(() { _esPorPeso = val ?? false; });
                          },
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                if (_categoriaSeleccionada == 'ganado') _buildSeccionGanado(),
                if (_categoriaSeleccionada == 'medicamento') _buildSeccionMedicamento(),
                if (_categoriaSeleccionada == 'maquinaria') _buildSeccionMaquinaria(),

                const SizedBox(height: 36),

                // BOTÓN GIGANTE DE GUARDADO CON ESTADO DE CARGA
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 65),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 6,
                  ),
                  icon: _guardando 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Icon(Icons.save, size: 32),
                  label: Text(
                    _guardando 
                      ? 'GUARDANDO...' 
                      : (widget.productoAEditar != null ? 'ACTUALIZAR CAMBIOS' : 'GUARDAR EN INVENTARIO'), 
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)
                  ),
                  onPressed: _guardando ? null : _guardarProducto,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectorCategorias() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.8, 
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _botonCategoria('plastico', 'Plásticos', '🪣'),
        _botonCategoria('ganado', 'Ganado', '🐄'),
        _botonCategoria('medicamento', 'Medicina', '💊'),
        _botonCategoria('maquinaria', 'Maquinaria', '⚙️'),
      ],
    );
  }

  Widget _botonCategoria(String id, String titulo, String emoji) {
    final seleccionado = _categoriaSeleccionada == id;
    return InkWell(
      onTap: () {
        setState(() {
          _categoriaSeleccionada = id;
          _esPorPeso = (id == 'ganado'); 
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: seleccionado ? Colors.blue[800] : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: seleccionado ? Colors.blue : Colors.grey[300]!, width: seleccionado ? 3 : 1.5),
          boxShadow: [
            if (!seleccionado)
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                titulo,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: seleccionado ? Colors.white : Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCampoTexto({
  required TextEditingController controller, 
  required String etiqueta, 
  required IconData icono, 
  String? hint, 
  bool esNumero = false,
  bool esOpcional = false, // <-- 1. AGREGAMOS ESTE PARÁMETRO
}) {
  return TextFormField(
    controller: controller,
    keyboardType: esNumero ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
    decoration: InputDecoration(
      labelText: etiqueta,
      hintText: hint, // <-- 2. YA SE MUESTRA LA SUGERENCIA GRIS (Ej. 07 1234...)
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 16),
      labelStyle: TextStyle(fontSize: 16, color: Colors.grey[700], fontWeight: FontWeight.w600),
      prefixIcon: Icon(icono, size: 30, color: Colors.blueGrey[700]),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.blue[800]!, width: 2.5)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    ),
    // 3. SI ES OPCIONAL, NO MARCAMOS ERROR AUNQUE ESTÉ VACÍO:
    validator: (val) {
      if (esOpcional) return null;
      return (val == null || val.trim().isEmpty) ? 'Requerido' : null;
    },
  );
}

  Widget _buildSeccionGanado() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        '3. IDENTIFICACIÓN DEL ANIMAL (OPCIONALES)', 
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.blueGrey)
      ),
      const SizedBox(height: 6),
      Text(
        'Llena solo los datos que necesites para reconocer al animal en el rancho:',
        style: TextStyle(fontSize: 15, color: Colors.grey[700], fontWeight: FontWeight.w500),
      ),
      const SizedBox(height: 16),

      // 1. IDENTIFICADOR PROPIO / DESCRIPCIÓN (Ej. Vaca Pinto, Becerro #4)
      _buildCampoTexto(
        controller: _identificadorController, 
        etiqueta: 'Identificador propio o descripción', 
        icono: Icons.label_important_outline,
        hint: 'Ej. Vaca Pinto del potrero norte, Becerro #4',
        esOpcional: true, // <-- PARA QUE PERMITA DEJARLO VACÍO
      ),
      const SizedBox(height: 14),

      // 2. NÚMERO DE ARETE
      _buildCampoTexto(
        controller: _areteController, 
        etiqueta: 'Número de Arete (Siniiga / Campaña)', 
        icono: Icons.tag,
        hint: 'Ej. 07 1234 5678',
        esOpcional: true, // <-- PARA QUE PERMITA DEJARLO VACÍO
      ),
      const SizedBox(height: 14),

      // 3. FIERRO O MARCA
      _buildCampoTexto(
        controller: _fierroController, 
        etiqueta: 'Fierro o Marca de quemar', 
        icono: Icons.local_fire_department_outlined,
        hint: 'Ej. Herradura grande, Marca RG',
        esOpcional: true, // <-- PARA QUE PERMITA DEJARLO VACÍO
      ),
      const SizedBox(height: 20),

      // 4. FOTO DEL ANIMAL, ARETE O FIERRO
      _buildBotonFoto('ganado', '4. FOTO DEL ANIMAL / FIERRO / ARETE'),
    ],
  );
}

  Widget _buildSeccionMedicamento() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('3. DATOS DE MEDICINA', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.blueGrey)),
        const SizedBox(height: 14),
        _buildCampoTexto(
          controller: _caducidadController, 
          etiqueta: 'Fecha de Caducidad (Ej. 12/2027)', 
          icono: Icons.calendar_today
        ),
        const SizedBox(height: 14),
        _buildCampoTexto(
          controller: _laboratorioController, 
          etiqueta: 'Laboratorio o Fórmula', 
          icono: Icons.science
        ),
      ],
    );
  }

  Widget _buildSeccionMaquinaria() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('3. GARANTÍA', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.blueGrey)),
        const SizedBox(height: 14),
        _buildCampoTexto(
          controller: _garantiaController, 
          etiqueta: 'Meses de Garantía (Ej. 3)', 
          icono: Icons.security,
          esNumero: true
        ),
      ],
    );
  }

  // ===========================================================================
  // GUARDADO ASÍNCRONO EN SQLITE + REGISTRO DE MOVIMIENTO INICIAL
  // ===========================================================================
  Future<void> _guardarProducto() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _guardando = true);

      try {
        final stockInicial = double.tryParse(_stockController.text.trim()) ?? 0.0;

        // 1. COMBINAMOS LOS 3 CAMPOS OPCIONALES DE GANADO AQUÍ:
        String? datosGanadoFinal;
        if (_categoriaSeleccionada == 'ganado') {
          final List<String> partes = [];
          if (_identificadorController.text.trim().isNotEmpty) {
            partes.add('ID: ${_identificadorController.text.trim()}');
          }
          if (_areteController.text.trim().isNotEmpty) {
            partes.add('Arete: ${_areteController.text.trim()}');
          }
          if (_fierroController.text.trim().isNotEmpty) {
            partes.add('Fierro: ${_fierroController.text.trim()}');
          }
          if (partes.isNotEmpty) {
            datosGanadoFinal = partes.join('  |  ');
          }
        }

        // 2. ¡NUEVO! UNIMOS TODAS LAS FOTOS TOMADAS SEPARADAS POR COMAS:
        final String? fotosParaGuardar = _rutasFotosGuardadas.isNotEmpty 
            ? _rutasFotosGuardadas.join(',') 
            : null;

        final nuevoProducto = Producto(
          nombre: _nombreController.text.trim(),
          categoria: _categoriaSeleccionada,
          precioCosto: double.tryParse(_costoController.text.trim()) ?? 0.0,
          precioPublico: double.tryParse(_publicoController.text.trim()) ?? 0.0,
          stock: stockInicial,
          esPorPeso: _esPorPeso,
          areteFierro: datosGanadoFinal,
          
          // 3. PASAMOS LA CADENA CON TODAS LAS RUTAS DE FOTO:
          fotoPath: fotosParaGuardar, // <-- Listo, guarda "foto1.jpg,foto2.jpg"
          
          fechaCaducidad: _categoriaSeleccionada == 'medicamento' ? _caducidadController.text.trim() : null,
          laboratorio: _categoriaSeleccionada == 'medicamento' ? _laboratorioController.text.trim() : null,
          garantiaMeses: _categoriaSeleccionada == 'maquinaria' ? (int.tryParse(_garantiaController.text.trim()) ?? 0) : 0,
        );

        // ... el resto de tus llamadas a db.insertarProducto y db.registrarMovimiento está perfecto ...

      // ... resto de tu guardado en DbHelper (está perfecto) ...

        final db = DbHelper();
        
        if (widget.productoAEditar != null) {
          // MODO EDICIÓN: Le asignamos el ID original y actualizamos en SQLite
          nuevoProducto.id = widget.productoAEditar!.id;
          await db.actualizarProducto(nuevoProducto);
        } else {
          // MODO CREACIÓN: Insertamos uno nuevo y registramos movimiento inicial
          final int idProducto = await db.insertarProducto(nuevoProducto);
          if (stockInicial > 0) {
            await db.registrarMovimiento(
              idProducto,
              'ENTRADA',
              stockInicial,
              'Inventario inicial al crear producto',
            );
          }
        }

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.productoAEditar != null 
                ? '¡CAMBIOS ACTUALIZADOS CON ÉXITO!' 
                : '¡PRODUCTO GUARDADO EN SQLITE CON ÉXITO!', 
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          )
        );
        
        Navigator.pop(context, true);
      } catch (e) {
        setState(() => _guardando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar en base de datos: $e', style: const TextStyle(fontSize: 16)),
            backgroundColor: Colors.red[800],
          )
        );
      }
    }
  }
}