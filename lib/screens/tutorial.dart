import 'package:flutter/material.dart';

class TutorialExecutionScreen extends StatefulWidget {
  const TutorialExecutionScreen({super.key});

  @override
  State<TutorialExecutionScreen> createState() =>
      _TutorialExecutionScreenState();
}

class _TutorialExecutionScreenState extends State<TutorialExecutionScreen> {
  // Simulamos los pasos del tutorial
  int _pasoActual = 1;
  final int _totalPasos = 5;

  void _siguientePaso() {
    if (_pasoActual < _totalPasos) {
      setState(() {
        _pasoActual++;
      });
    } else {
      // Si es el último paso, mostramos un mensaje de éxito
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('¡Tutorial Completado!')));
      Navigator.popUntil(
        context,
        (route) => route.isFirst,
      ); // Regresa al inicio
    }
  }

  void _pasoAnterior() {
    if (_pasoActual > 1) {
      setState(() {
        _pasoActual--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Simula la vista de la cámara
      body: Stack(
        children: [
          // 1. Botón para salir (Arriba a la izquierda)
          Positioned(
            top: 40,
            left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.8),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // 2. Modelo 3D Simulado (En el centro)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.view_in_ar, // Ícono de Cubo RA
                  color: Colors.blueAccent.withOpacity(0.7),
                  size: 150,
                ),
                const SizedBox(height: 20),
                Text(
                  'Modelo 3D del Paso $_pasoActual',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // 3. Tarjeta Inferior de Instrucciones y Navegación
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título del paso
                  Text(
                    'Paso $_pasoActual de $_totalPasos',
                    style: const TextStyle(
                      color: Color(0xFF007AFF), // Azul
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Instrucción textual (cambia según el paso)
                  Text(
                    _pasoActual == 1
                        ? 'Toma la herramienta adecuada y acércala a la pieza marcada en azul.'
                        : 'Gira la pieza en el sentido de las manecillas del reloj hasta que escuches un clic.',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Botones de Navegación (Anterior / Siguiente)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Botón Anterior
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade300,
                          foregroundColor: Colors.black87,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: _pasoAnterior,
                        icon: const Icon(Icons.arrow_back_ios, size: 16),
                        label: const Text('Anterior'),
                      ),

                      // Botón Siguiente / Finalizar
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF007AFF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: _siguientePaso,
                        child: Row(
                          children: [
                            Text(
                              _pasoActual == _totalPasos
                                  ? 'Finalizar'
                                  : 'Siguiente',
                            ),
                            const SizedBox(width: 5),
                            Icon(
                              _pasoActual == _totalPasos
                                  ? Icons.check
                                  : Icons.arrow_forward_ios,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
