import 'package:flutter/material.dart';
import 'tutorial.dart';

class ar_calibracion extends StatelessWidget {
  final String imagePath;
  final String tutorialId;

  // 2. Lo pedimos como obligatorio
  const ar_calibracion({
    super.key,
    required this.imagePath,
    required this.tutorialId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Escaneo de Área',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Banner verde de instrucciones
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF34C759),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Text(
                'Mueva el Celular Lentamente\npara Verificar su Entorno',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Retícula central
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.filter_center_focus,
                  color: Colors.white.withOpacity(0.8),
                  size: 100,
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 15,
                  runSpacing: 15,
                  children: List.generate(
                    12,
                    (index) => Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.white54,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- MAGIA: MINIATURA ANIMADA (HERO) ---
          Positioned(
            bottom: 40,
            left: 20,
            child: Hero(
              tag: imagePath,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  imagePath,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          // --------------------------------------

          // Botón Comprobar
          Positioned(
            bottom: 40,
            left: 100,
            right: 20,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF34C759),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    // 3. ¡AQUÍ ESTÁ LA SOLUCIÓN! Le pasamos el ID a la pantalla del tutorial
                    builder: (context) =>
                        TutorialExecutionScreen(tutorialId: tutorialId),
                  ),
                );
              },
              child: const Text(
                'Comprobar',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
