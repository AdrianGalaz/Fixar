import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final List<Map<String, dynamic>> _pasosTutorial = [];

  String? _nombreArchivoTemporal;
  String? _urlModeloTemporal;
  bool _subiendoArchivo = false;
  bool _guardandoTutorial = false;

  final TextEditingController _instruccionController = TextEditingController();
  final TextEditingController _tituloTutorialController =
      TextEditingController();
  // NUEVO: Controlador para la duración manual
  final TextEditingController _duracionController = TextEditingController();

  Future<void> _seleccionarYSubirModelo() async {
    // 1. CAMBIO CLAVE: Pedimos cualquier archivo (FileType.any) para que Android no colapse
    FilePickerResult? resultado = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    if (resultado != null && resultado.files.single.path != null) {
      // 2. NUEVO: Validamos manualmente que el archivo termine en .glb o .gltf
      String nombreArchivo = resultado.files.single.name.toLowerCase();
      if (!nombreArchivo.endsWith('.glb') && !nombreArchivo.endsWith('.gltf')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Formato inválido. Por favor selecciona un modelo 3D (.glb)',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
        return; // Detenemos la función si no es un modelo
      }

      setState(() {
        _subiendoArchivo = true;
        _nombreArchivoTemporal = resultado.files.single.name;
      });

      try {
        File archivo = File(resultado.files.single.path!);

        // --- CONFIGURACIÓN CLOUDINARY ---
        var uri = Uri.parse(
          'https://api.cloudinary.com/v1_1/dusv1zfik/raw/upload',
        );
        var peticion = http.MultipartRequest('POST', uri);

        peticion.fields['upload_preset'] = 'fixar_modelos';
        peticion.files.add(
          await http.MultipartFile.fromPath('file', archivo.path),
        );

        var respuesta = await peticion.send();

        if (respuesta.statusCode == 200) {
          var datosRespuesta = await respuesta.stream.bytesToString();
          var jsonMap = json.decode(datosRespuesta);
          String urlSegura = jsonMap['secure_url'];

          setState(() {
            _urlModeloTemporal = urlSegura;
            _subiendoArchivo = false;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Activo 3D subido a la nube correctamente'),
                backgroundColor: Color(0xFF007AFF),
              ),
            );
          }
        } else {
          throw Exception(
            'Error del servidor de imágenes: ${respuesta.statusCode}',
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

  void _agregarPasoLocal() {
    if (_urlModeloTemporal == null ||
        _instruccionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sube un modelo 3D y escribe la instrucción'),
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

      _instruccionController.clear();
      _urlModeloTemporal = null;
      _nombreArchivoTemporal = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Paso ${_pasosTutorial.length} guardado.'),
        backgroundColor: const Color(0xFF34C759),
      ),
    );
  }

  Future<void> _finalizarYGuardarTutorial() async {
    // NUEVO: Validamos que también haya escrito la duración
    if (_pasosTutorial.isEmpty ||
        _tituloTutorialController.text.trim().isEmpty ||
        _duracionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completa título, duración y al menos un paso'),
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
        'duracion': _duracionController.text
            .trim(), // NUEVO: Toma el texto que escribiste
        'fecha_creacion': FieldValue.serverTimestamp(),
        'total_pasos': _pasosTutorial.length,
        'pasos': _pasosTutorial,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Tutorial publicado exitosamente!'),
            backgroundColor: Color(0xFF34C759),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _guardandoTutorial = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error de base de datos: $e'),
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
    _duracionController.dispose(); // NUEVO: Limpiar memoria
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Creador FixAR',
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

            // NUEVO: Campo de texto para la Duración
            TextField(
              controller: _duracionController,
              decoration: InputDecoration(
                labelText: 'Duración Estimada (Ej. 10 Minutos, 1 Hora)',
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

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF007AFF),
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

                  Center(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF34C759),
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
                ],
              ),
            ),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007AFF),
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
