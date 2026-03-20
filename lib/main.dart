import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Importamos Google Fonts
import 'screens/login.dart'; // Importamos tu pantalla de Login

void main() {
  runApp(const FixARApp());
}

class FixARApp extends StatelessWidget {
  const FixARApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FixAR',

      // --- AQUÍ ESTÁ EL TEMA CON LA NUEVA FUENTE ---
      theme: ThemeData(
        // Esto le dice a TODA la app que use la letra Poppins
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
      ),

      // ---------------------------------------------
      home: const Login(), // Arrancamos en la pantalla de Login
    );
  }
}
