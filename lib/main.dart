import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Importamos Google Fonts
import 'screens/login.dart'; // Importamos tu pantalla de Login
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 2. AGREGAMOS EL PARÁMETRO 'options' DENTRO DE LOS PARÉNTESIS
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const FixARApp());
}

class FixARApp extends StatelessWidget {
  const FixARApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FixAR',
      theme: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
      ),
      home: const Login(),
    );
  }
}
