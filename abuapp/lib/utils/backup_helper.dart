import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:share_plus/share_plus.dart';

class BackupHelper {
  
  // Extrae el archivo de SQLite del sistema y lo comparte por WhatsApp o correo
  static Future<bool> exportarBaseDeDatos() async {
    try {
      final String dbPath = path.join(await getDatabasesPath(), 'pos_ganadero.db');
      final File archivoDb = File(dbPath);

      if (await archivoDb.exists()) {
        // Usa share_plus para abrir el menú de enviar de Android/iOS
        await Share.shareXFiles(
          [XFile(dbPath)],
          text: 'Respaldo de Base de Datos - POS Ganadero (${DateTime.now().toString().substring(0, 10)})',
          subject: 'Respaldo de Seguridad POS',
        );
        return true;
      }
      return false;
    } catch (e) {
      print('Error al exportar respaldo: $e');
      return false;
    }
  }
}