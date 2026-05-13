import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  // Lista para acumular los pasos genéricos del tutorial
  final List<Map<String, dynamic>> _pasosTutorial = [];

  // Variables temporales para el paso en edición
  String? _nombreArchivoTemporal;
  String? _urlModeloTemporal;
  bool _subiendoArchivo = false;
  bool _guardandoTutorial = false;

  final TextEditingController _instruccionController = TextEditingController();
  final TextEditingController _tituloTutorialController =
      TextEditingController();

  // Selecciona y sube el archivo .GLB a Firebase Storage
  Future<void> _seleccionarYSubirModelo() async {
    FilePickerResult? resultado = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['glb'],
    );

    if (resultado != null && resultado.files.single.path != null) {
      setState(() {
        _subiendoArchivo = true;
        _nombreArchivoTemporal = resultado.files.single.name;
      });

      try {
        File archivo = File(resultado.files.single.path!);
        String rutaStorage =
            'activos_tutoriales/${DateTime.now().millisecondsSinceEpoch}_$_nombreArchivoTemporal';
        Reference ref = FirebaseStorage.instance.ref().child(rutaStorage);

        await ref.putFile(archivo);
        String url = await ref.getDownloadURL();

        setState(() {
          _urlModeloTemporal = url;
          _subiendoArchivo = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Activo 3D subido correctamente'),
              backgroundColor: Color(0xFF007AFF), // Azul principal FixAR
            ),
          );
        }
      } catch (e) {
        setState(() {
          _subiendoArchivo = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al subir: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  // Consolida el paso actual en la lista local
  void _agregarPasoLocal() {
    if (_urlModeloTemporal == null ||
        _instruccionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Sube un modelo 3D y escribe la instrucción para este paso',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _pasosTutorial.add({
        'paso_index': _pasosTutorial.length + 1,
        'instruccion': _instruccionController.text.trim(),
        'modelo_url': _urlModeloTemporal,
      });

      // Limpiamos los campos para el siguiente paso
      _instruccionController.clear();
      _urlModeloTemporal = null;
      _nombreArchivoTemporal = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Paso ${_pasosTutorial.length} guardado. Listo para el siguiente.',
        ),
        backgroundColor: const Color(0xFF34C759), // Verde confirmación
      ),
    );
  }

  // Sube el tutorial completo a Firestore
  Future<void> _finalizarYGuardarTutorial() async {
    if (_pasosTutorial.isEmpty ||
        _tituloTutorialController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa el título y configura al menos un paso'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _guardandoTutorial = true;
    });

    try {
      await FirebaseFirestore.instance.collection('tutoriales').add({
        'titulo': _tituloTutorialController.text.trim(),
        'duracion': '${_pasosTutorial.length * 2} Minutos',
        'fecha_creacion': FieldValue.serverTimestamp(),
        'total_pasos': _pasosTutorial.length,
        'pasos': _pasosTutorial,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Tutorial publicado exitosamente!'),
            backgroundColor: Color(0xFF34C759), // Verde FixAR
          ),
        );
        Navigator.pop(context); // Regresa al Home
      }
    } catch (e) {
      setState(() {
        _guardandoTutorial = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al publicar: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _instruccionController.dispose();
    _tituloTutorialController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6), // Fondo idéntico al Home
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'FixAR',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Entrada de Título Genérico
            TextField(
              controller: _tituloTutorialController,
              decoration: InputDecoration(
                labelText: 'Título del Tutorial (Ej. Ensamblaje, Motor, etc.)',
                labelStyle: const TextStyle(color: Color(0xFF007AFF)),
                filled: true,
                fillColor: Colors.white,
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xFF007AFF),
                    width: 2,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            // Indicador de pasos configurados (Estilo Azul Home)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF007AFF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Pasos configurados: ${_pasosTutorial.length}',
                style: const TextStyle(
                  color: Color(0xFF007AFF),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 15),

            // Tarjeta central de configuración del paso actual
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Configurando Paso ${_pasosTutorial.length + 1}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Botón de Carga de Archivo (Azul Principal FixAR)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF007AFF), // Azul FixAR
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: _subiendoArchivo
                          ? null
                          : _seleccionarYSubirModelo,
                      icon: _subiendoArchivo
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.attach_file),
                      label: Text(
                        _subiendoArchivo
                            ? 'Subiendo activo...'
                            : (_nombreArchivoTemporal ??
                                  'Subir Modelo 3D (.GLB)'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Peso Máximo: 50MB',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 15),

                  const Text(
                    'A. Instrucción',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _instruccionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText:
                          'Escribe aquí las instrucciones que debe seguir el Usuario',
                      hintStyle: const TextStyle(fontSize: 14),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF007AFF)),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Botón para Confirmar Paso (Verde iOS / FixAR)
                  Center(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF34C759), // Verde FixAR
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: _agregarPasoLocal,
                      icon: const Icon(Icons.check),
                      label: const Text(
                        'Guardar Estado',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Center(
                    child: Text(
                      'Guarda el paso actual en la secuencia\ny limpia para el siguiente',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Botón de Publicación Final (Azul Principal)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007AFF), // Azul FixAR
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: _guardandoTutorial
                    ? null
                    : _finalizarYGuardarTutorial,
                child: _guardandoTutorial
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Finalizar y Publicar Tutorial',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
