import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class TutorialExecutionScreen extends StatefulWidget {
  final String tutorialId;

  const TutorialExecutionScreen({super.key, required this.tutorialId});

  @override
  State<TutorialExecutionScreen> createState() =>
      _TutorialExecutionScreenState();
}

class _TutorialExecutionScreenState extends State<TutorialExecutionScreen> {
  int _pasoActual = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),

      // 1. Nos conectamos a Firestore para traer el tutorial específico
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('tutoriales')
            .doc(widget.tutorialId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF007AFF)),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return _pantallaError(
              context,
              'El tutorial no existe o fue eliminado.',
            );
          }

          // 2. Extraemos la información del documento
          final datos = snapshot.data!.data() as Map<String, dynamic>;
          final String titulo = datos['titulo'] ?? 'Tutorial';
          final List<dynamic> pasos = datos['pasos'] ?? [];

          // --- PING DE ANALYTICS ---
          // Registramos silenciosamente que este usuario abrió este modelo
          FirebaseAnalytics.instance.logEvent(
            name: 'tutorial_iniciado',
            parameters: {
              'nombre_tutorial': titulo,
              'cantidad_pasos': pasos.length,
            },
          );

          if (pasos.isEmpty) {
            return _pantallaError(
              context,
              'Este tutorial no tiene pasos configurados.',
            );
          }

          // Obtenemos los datos exactos del paso en el que vamos
          final pasoDatos = pasos[_pasoActual] as Map<String, dynamic>;
          final String urlModelo = pasoDatos['modelo_url'] ?? '';
          final String instruccion =
              pasoDatos['instruccion'] ?? 'Sin instrucciones.';

          return Column(
            children: [
              // AppBar personalizado
              Container(
                padding: const EdgeInsets.only(
                  top: 50,
                  left: 10,
                  right: 10,
                  bottom: 10,
                ),
                color: Colors.white,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.black87,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        titulo,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(width: 40), // Balance visual
                  ],
                ),
              ),

              // --- ÁREA DEL VISUALIZADOR 3D / AR ---
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 10),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: urlModelo.isNotEmpty
                        ? ModelViewer(
                            backgroundColor: const Color(0xFFFFFFFF),
                            src: urlModelo,
                            alt: "Modelo 3D del paso",
                            ar: true,
                            arModes: const ['scene-viewer', 'quick-look'],
                            autoRotate: true,
                            cameraControls: true,
                          )
                        : const Center(
                            child: Text(
                              'No hay modelo 3D para este paso',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                  ),
                ),
              ),

              // --- ÁREA DE INSTRUCCIONES Y NAVEGACIÓN ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Paso ${_pasoActual + 1} de ${pasos.length}',
                      style: const TextStyle(
                        color: Color(0xFF007AFF),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      instruccion,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 25),

                    // Botones Anterior / Siguiente
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade200,
                            foregroundColor: Colors.black87,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: _pasoActual > 0
                              ? () => setState(() {
                                  _pasoActual--;
                                })
                              : null, // Se deshabilita si es el primer paso
                          icon: const Icon(Icons.arrow_back),
                          label: const Text(
                            'Anterior',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),

                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF007AFF),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: _pasoActual < pasos.length - 1
                              ? () => setState(() {
                                  _pasoActual++;
                                })
                              : () => Navigator.pop(
                                  context,
                                ), // Sale si es el último paso
                          child: Row(
                            children: [
                              Text(
                                _pasoActual < pasos.length - 1
                                    ? 'Siguiente'
                                    : 'Finalizar',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                _pasoActual < pasos.length - 1
                                    ? Icons.arrow_forward
                                    : Icons.check,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Pequeño widget para manejar errores de base de datos
  Widget _pantallaError(BuildContext context, String mensaje) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Center(
        child: Text(
          mensaje,
          style: const TextStyle(color: Colors.redAccent, fontSize: 16),
        ),
      ),
    );
  }
}
