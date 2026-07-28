import 'dart:io';

import 'package:flutter/material.dart';
import '../../models/producto_model.dart';
import '../../utils/camera_helper.dart';
// import '../../database/db_helper.dart'; // Descomentar cuando conectemos el guardado

class AgregarProductoScreen extends StatefulWidget {
  const AgregarProductoScreen({super.key});

  @override
  State<AgregarProductoScreen> createState() => _AgregarProductoScreenState();
}

class _AgregarProductoScreenState extends State<AgregarProductoScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Categoría seleccionada por defecto
  String _categoriaSeleccionada = 'plastico';
  bool _esPorPeso = false;

  // Controladores de texto
  final _nombreController = TextEditingController();
  final _costoController = TextEditingController();
  final _publicoController = TextEditingController();
  final _stockController = TextEditingController();
  
  // Controladores opcionales
  final _areteController = TextEditingController();
  final _caducidadController = TextEditingController();
  final _laboratorioController = TextEditingController();
  final _garantiaController = TextEditingController();

// Variable en tu State para guardar la ruta
String? _rutaFotoGuardada;

// WIDGET DEL BOTÓN GIGANTE DE FOTO
Widget _buildBotonFoto(String prefijo, String etiqueta) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(etiqueta, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      InkWell(
        onTap: () async {
          // Llamamos a nuestro helper de cámara
          final ruta = await CameraHelper.tomarFotoYComprimir(prefijo);
          if (ruta != null) {
            setState(() {
              _rutaFotoGuardada = ruta; // Guardamos la ruta para meterla a SQLite
            });
          }
        },
        child: Container(
          width: double.infinity,
          height: 80,
          decoration: BoxDecoration(
            color: _rutaFotoGuardada == null ? Colors.blue[50] : Colors.green[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _rutaFotoGuardada == null ? Colors.blue : Colors.green, 
              width: 2
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _rutaFotoGuardada == null ? Icons.camera_alt : Icons.check_circle, 
                size: 36, 
                color: _rutaFotoGuardada == null ? Colors.blue[800] : Colors.green[800]
              ),
              const SizedBox(width: 12),
              Text(
                _rutaFotoGuardada == null ? 'TOMAR FOTO (ARETE / FIERRO / INE)' : '¡FOTO GUARDADA CON ÉXITO!',
                style: TextStyle(
                  fontSize: 16, 
                  fontWeight: FontWeight.bold,
                  color: _rutaFotoGuardada == null ? Colors.blue[900] : Colors.green[900]
                ),
              ),
              if (_rutaFotoGuardada != null) ...[
                const SizedBox(width: 10),
                // Muestra una miniatura de 50x50 de la foto que acaba de tomar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.file(File(_rutaFotoGuardada!), width: 50, height: 50, fit: BoxFit.cover),
                )
              ]
            ],
          ),
        ),
      ),
    ],
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AGREGAR NUEVO PRODUCTO', 
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: Colors.blueGrey[900],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('1. ¿QUÉ TIPO DE PRODUCTO ES?', 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              
              // SELECTOR VISUAL GIGANTE DE CATEGORÍAS
              _buildSelectorCategorias(),
              const SizedBox(height: 24),

              const Text('2. DATOS BÁSICOS', 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              _buildCampoTexto(
                controller: _nombreController, 
                etiqueta: _categoriaSeleccionada == 'ganado' ? 'Nombre o Descripción (Ej. Becerro Pinto)' : 'Nombre del Producto',
                icono: Icons.label,
              ),
              const SizedBox(height: 16),

              // FILA DE PRECIOS
              Row(
                children: [
                  Expanded(
                    child: _buildCampoTexto(
                      controller: _costoController,
                      etiqueta: 'Precio Costo (\$)',
                      icono: Icons.arrow_downward,
                      esNumero: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildCampoTexto(
                      controller: _publicoController,
                      etiqueta: 'Precio Venta (\$)',
                      icono: Icons.attach_money,
                      esNumero: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // STOCK Y CHECKBOX DE PESO
              Row(
                children: [
                  Expanded(
                    child: _buildCampoTexto(
                      controller: _stockController,
                      etiqueta: _esPorPeso ? 'Kilos iniciales' : 'Existencias (Piezas)',
                      icono: Icons.inventory,
                      esNumero: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CheckboxListTile(
                      title: const Text('¿Se vende por Kilo?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      value: _esPorPeso,
                      onChanged: (val) {
                        setState(() { _esPorPeso = val ?? false; });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 3. CAMPOS DINÁMICOS SEGÚN LA CATEGORÍA
              if (_categoriaSeleccionada == 'ganado') _buildSeccionGanado(),
              if (_categoriaSeleccionada == 'medicamento') _buildSeccionMedicamento(),
              if (_categoriaSeleccionada == 'maquinaria') _buildSeccionMaquinaria(),

              const SizedBox(height: 32),

              // BOTÓN GIGANTE DE GUARDADO
              SizedBox(
                width: double.infinity,
                height: 65, // Muy alto y fácil de tocar
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.save, size: 30),
                  label: const Text('GUARDAR EN INVENTARIO', 
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  onPressed: _guardarProducto,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Componente: Selector visual de 4 botones
  Widget _buildSelectorCategorias() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2.2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
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
          // Si elige ganado, por defecto se vende por kilo
          _esPorPeso = (id == 'ganado'); 
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: seleccionado ? Colors.blue[800] : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: seleccionado ? Colors.blue : Colors.grey, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 8),
            Text(
              titulo,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: seleccionado ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Componente: Campo de texto grande y legible
  Widget _buildCampoTexto({required TextEditingController controller, required String etiqueta, required IconData icono, bool esNumero = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: esNumero ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      style: const TextStyle(fontSize: 18), // Letra grande al escribir
      decoration: InputDecoration(
        labelText: etiqueta,
        labelStyle: const TextStyle(fontSize: 16),
        prefixIcon: Icon(icono, size: 28),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
    );
  }

  // --- SECCIONES ESPECIALES DINÁMICAS ---

  Widget _buildSeccionGanado() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('3. DATOS DEL ANIMAL', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
        const SizedBox(height: 12),
        _buildCampoTexto(
          controller: _areteController, 
          etiqueta: 'Núm. Arete / Fierro / Identificación', 
          icono: Icons.fingerprint
        ),
      ],
    );
  }

  Widget _buildSeccionMedicamento() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('3. DATOS DE MEDICINA', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
        const SizedBox(height: 12),
        _buildCampoTexto(
          controller: _caducidadController, 
          etiqueta: 'Fecha de Caducidad (Ej. 12/2027)', 
          icono: Icons.calendar_today
        ),
        const SizedBox(height: 12),
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
        const Text('3. GARANTÍA', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
        const SizedBox(height: 12),
        _buildCampoTexto(
          controller: _garantiaController, 
          etiqueta: 'Meses de Garantía (Ej. 3)', 
          icono: Icons.security,
          esNumero: true,
        ),
      ],
    );
  }

  void _guardarProducto() {
    if (_formKey.currentState!.validate()) {
      final nuevoProducto = Producto(
        nombre: _nombreController.text,
        categoria: _categoriaSeleccionada,
        precioCosto: double.tryParse(_costoController.text) ?? 0.0,
        precioPublico: double.tryParse(_publicoController.text) ?? 0.0,
        stock: double.tryParse(_stockController.text) ?? 0.0,
        esPorPeso: _esPorPeso,
        areteFierro: _categoriaSeleccionada == 'ganado' ? _areteController.text : null,
        fechaCaducidad: _categoriaSeleccionada == 'medicamento' ? _caducidadController.text : null,
        laboratorio: _categoriaSeleccionada == 'medicamento' ? _laboratorioController.text : null,
        garantiaMeses: _categoriaSeleccionada == 'maquinaria' ? (int.tryParse(_garantiaController.text) ?? 0) : 0,
      );

      // AQUÍ LLAMAREMOS A SQLite:
      // await DbHelper().insertarProducto(nuevoProducto);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡PRODUCTO GUARDADO CON ÉXITO!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.green,
        )
      );
      
      // Limpiar o cerrar pantalla
      Navigator.pop(context);
    }
  }
}