import 'package:flutter/material.dart';
import 'screens/home/home_screen.dart';

void main() {
  // Aquí inicializaremos SQLite más adelante si es necesario
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'POS Ganadero y Agrícola',
      debugShowCheckedModeBanner: false, // Quita la etiqueta roja de "DEBUG" en la esquina
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          primary: Colors.green[700]!,
        ),
        useMaterial3: true,
      ),
      // AQUÍ ESTÁ LA CLAVE: Ahora la pantalla inicial es nuestro menú
      home: const HomeScreen(),
    );
  }
}