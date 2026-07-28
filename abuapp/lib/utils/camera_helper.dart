import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class CameraHelper {
  static final ImagePicker _picker = ImagePicker();

  // Abre la cámara, toma la foto, la comprime y la guarda en el teléfono
  static Future<String?> tomarFotoYComprimir(String nombrePrefijo) async {
    try {
      // 1. Abrimos la cámara con compresión nativa integrada (imageQuality: 50)
      final XFile? fotoTomada = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 50, // Reduce el peso a la mitad automáticamente
        maxWidth: 1024,   // Tamaño máximo ideal para pantallas móviles y leer documentos
      );

      if (fotoTomada == null) return null; // El usuario canceló la foto

      // 2. Buscamos la carpeta interna segura de nuestra aplicación
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String carpetaFotos = path.join(appDir.path, 'evidencias_pos');
      
      // Si no existe la carpeta "evidencias_pos", la creamos
      await Directory(carpetaFotos).create(recursive: true);

      // 3. Generamos un nombre único con fecha para que no se borren entre sí
      final String nombreArchivo = '${nombrePrefijo}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String rutaDestino = path.join(carpetaFotos, nombreArchivo);

      // 4. Copiamos la foto comprimida a nuestra carpeta segura y borramos el temporal
      final File imagenGuardada = await File(fotoTomada.path).copy(rutaDestino);
      
      // DEVOLVEMOS SOLO LA RUTA EN TEXTO PARA GUARDAR EN SQLITE
      return imagenGuardada.path;
    } catch (e) {
      print('Error al tomar foto: $e');
      return null;
    }
  }
}