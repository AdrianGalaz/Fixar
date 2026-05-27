import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

class TutorialExecutionScreen extends StatefulWidget {
  final String tutorialId;

  const TutorialExecutionScreen({super.key, required this.tutorialId});

  @override
  State<TutorialExecutionScreen> createState() =>
      _TutorialExecutionScreenState();
}

class _TutorialExecutionScreenState extends State<TutorialExecutionScreen> {
  int _pasoActual = 0;
  bool _lanzandoAR = false;

  // ─────────────────────────────────────────────────────────────────────────
  // NÚCLEO DE LA SOLUCIÓN: Intent nativo directo a Scene Viewer (ARCore)
  //
  // Por qué funciona:
  //   model_viewer_plus abre AR dentro de un WebView que NO puede transferir
  //   el permiso de cámara al proceso nativo de ARCore (limitación de
  //   Android API 30+ / Scoped Storage). Al lanzar el Intent directamente
  //   desde Flutter (proceso nativo), el OS concede la cámara sin restricción.
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _lanzarARNativo(String modeloUrl) async {
    if (_lanzandoAR) return;
    setState(() => _lanzandoAR = true);

    try {
      // Normalizamos la URL: eliminamos parámetros de versión de Cloudinary
      // (/v1234567/) que pueden ser rechazados por las políticas de origen de ARCore.
      final urlLimpia = _normalizarUrl(modeloUrl);

      if (Platform.isAndroid) {
        await _lanzarSceneViewerAndroid(urlLimpia);
      } else if (Platform.isIOS) {
        await _lanzarQuickLookIOS(urlLimpia);
      } else {
        _mostrarError('AR solo está disponible en dispositivos móviles.');
      }
    } catch (e) {
      _mostrarError('No se pudo abrir el visor de AR: $e');
    } finally {
      if (mounted) setState(() => _lanzandoAR = false);
    }
  }

  // ── Android: Intent explícito a com.google.ar.core / Scene Viewer ────────
  Future<void> _lanzarSceneViewerAndroid(String modeloUrl) async {
    // Estrategia 1: android_intent_plus con Intent explícito
    // Esto garantiza que el Intent va directo al proceso nativo de ARCore,
    // evitando el sandbox del WebView.
    try {
      final intent = AndroidIntent(
        action: 'android.intent.action.VIEW',
        // Construimos la URI exacta que espera Scene Viewer
        data: Uri.encodeFull(
          'https://arvr.google.com/scene-viewer/1.0'
          '?file=$modeloUrl'
          '&mode=ar_preferred' // Preferir AR sobre 3D
          '&disable_occlusion=false' // Oclusión de objetos reales
          '&resizable=true',
        ),
        package: 'com.google.ar.core', // Target explícito: ARCore
        flags: <int>[
          Flag.FLAG_ACTIVITY_NEW_TASK, // Necesario para lanzar desde contexto no-Activity
          Flag.FLAG_ACTIVITY_SINGLE_TOP, // Evita instancias duplicadas
        ],
        arguments: {
          // Título que aparece en la UI de Scene Viewer
          'browser_fallback_url': modeloUrl,
        },
      );

      await intent.launch();
      return; // Éxito con estrategia 1
    } catch (e) {
      debugPrint('[FixAR] Intent explícito falló: $e — intentando fallback...');
    }

    // Estrategia 2: Intent implícito vía url_launcher (fallback)
    // Si el dispositivo no tiene ARCore pero sí un navegador compatible con WebXR
    await _lanzarConUrlLauncher(modeloUrl);
  }

  // ── iOS: Quick Look AR (nativo de Apple) ─────────────────────────────────
  Future<void> _lanzarQuickLookIOS(String modeloUrl) async {
    // iOS requiere archivo .usdz para Quick Look nativo.
    // Si el modelo es .glb, redirigimos a scene-viewer en modo web (WebXR).
    final uri = Uri.parse(
      'https://arvr.google.com/scene-viewer/1.0'
      '?file=$modeloUrl'
      '&mode=ar_preferred',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _mostrarError('Este dispositivo no soporta la vista de AR.');
    }
  }

  // ── Fallback universal: url_launcher en app externa ───────────────────────
  Future<void> _lanzarConUrlLauncher(String modeloUrl) async {
    final uri = Uri.parse(
      'https://arvr.google.com/scene-viewer/1.0'
      '?file=$modeloUrl'
      '&mode=ar_preferred',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _mostrarError(
        'No se encontró una app compatible con AR. '
        'Instala Google Play Services para AR desde la Play Store.',
      );
    }
  }

  // ── Normalización de URL de Cloudinary ───────────────────────────────────
  // Elimina segmentos de versión (/v1234567/) que pueden causar rechazos
  // por las políticas de seguridad de origen de ARCore.
  String _normalizarUrl(String url) {
    return url.replaceAllMapped(
      RegExp(r'(cloudinary\.com/[^/]+/raw/upload)/v\d+/'),
      (m) => '${m[1]}/',
    );
  }

  void _mostrarError(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
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

          final datos = snapshot.data!.data() as Map<String, dynamic>;
          final String titulo = datos['titulo'] ?? 'Tutorial';
          final List<dynamic> pasos = datos['pasos'] ?? [];

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

          final pasoDatos = pasos[_pasoActual] as Map<String, dynamic>;
          final String urlModelo = pasoDatos['modelo_url'] ?? '';
          final String instruccion =
              pasoDatos['instruccion'] ?? 'Sin instrucciones.';

          return Column(
            children: [
              // ── AppBar ──────────────────────────────────────────────────
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
                    const SizedBox(width: 40),
                  ],
                ),
              ),

              // ── Visor 3D + Botón AR nativo ──────────────────────────────
              Expanded(
                child: Stack(
                  children: [
                    // Visor 3D interno (ModelViewer sin AR nativo)
                    Container(
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
                                // ⚠️ AR DESACTIVADO en el WebView — usamos
                                //    nuestro botón nativo en su lugar.
                                ar: false,
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

                    // Botón AR nativo (superpuesto sobre el visor)
                    if (urlModelo.isNotEmpty)
                      Positioned(
                        bottom: 32,
                        right: 32,
                        child: _botonARNativo(urlModelo),
                      ),
                  ],
                ),
              ),

              // ── Panel de instrucciones y navegación ─────────────────────
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Botón Anterior
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
                              ? () => setState(() => _pasoActual--)
                              : null,
                          icon: const Icon(Icons.arrow_back),
                          label: const Text(
                            'Anterior',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),

                        // Botón Siguiente / Finalizar
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
                              ? () => setState(() => _pasoActual++)
                              : () => Navigator.pop(context),
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

  // ── Widget: Botón AR nativo ───────────────────────────────────────────────
  Widget _botonARNativo(String modeloUrl) {
    return GestureDetector(
      onTap: () => _lanzarARNativo(modeloUrl),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: _lanzandoAR
              ? const Color(0xFF34C759).withOpacity(0.7)
              : const Color(0xFF34C759),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF34C759).withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _lanzandoAR
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.view_in_ar, color: Colors.white, size: 22),
            const SizedBox(width: 8),
            Text(
              _lanzandoAR ? 'Abriendo AR...' : 'Ver en AR',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

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
