import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TutorialExecutionScreen extends StatefulWidget {
  final String? tutorialId;
  const TutorialExecutionScreen({super.key, this.tutorialId});

  @override
  State<TutorialExecutionScreen> createState() =>
      _TutorialExecutionScreenState();
}

class _TutorialExecutionScreenState extends State<TutorialExecutionScreen> {
  int _pasoActualIndex = 0;
  List<dynamic> _pasosCargados = [];
  bool _cargando = true;
  String _tituloTutorial = "";

  @override
  void initState() {
    super.initState();
    _cargarDatosTutorial();
  }

  Future<void> _cargarDatosTutorial() async {
    try {
      DocumentSnapshot doc;
      if (widget.tutorialId != null) {
        doc = await FirebaseFirestore.instance
            .collection('tutoriales')
            .doc(widget.tutorialId)
            .get();
      } else {
        // Carga el último tutorial creado para la demo
        QuerySnapshot query = await FirebaseFirestore.instance
            .collection('tutoriales')
            .orderBy('fecha_creacion', descending: true)
            .limit(1)
            .get();
        doc = query.docs.first;
      }

      final data = doc.data() as Map<String, dynamic>;
      setState(() {
        _tituloTutorial = data['titulo'] ?? "Tutorial FixAR";
        _pasosCargados = data['pasos'] ?? [];
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final pasoData = _pasosCargados[_pasoActualIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Text(
              _tituloTutorial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Center(
            child: Icon(
              Icons.view_in_ar,
              color: Colors.blue.withOpacity(0.5),
              size: 120,
            ),
          ),
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Paso ${_pasoActualIndex + 1} de ${_pasosCargados.length}',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    pasoData['instruccion'],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Lógica de botones Anterior/Siguiente...
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
