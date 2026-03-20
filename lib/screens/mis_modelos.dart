import 'package:flutter/material.dart';

class MisModelos extends StatelessWidget {
  const MisModelos({super.key});

  @override
  Widget build(BuildContext context) {
    // Lista de ejemplo de tus modelos
    final List<Map<String, String>> misModelos = [
      {'nombre': 'Brazo Robótico', 'fecha': '12/03/2026'},
      {'nombre': 'Motor Trifásico', 'fecha': '10/03/2026'},
      {'nombre': 'Engranaje A1', 'fecha': '05/03/2026'},
      {'nombre': 'Sensor Proximidad', 'fecha': '01/03/2026'},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Mis Modelos 3D',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // Dos columnas
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            childAspectRatio: 0.8, // Proporción de la tarjeta
          ),
          itemCount: misModelos.length,
          itemBuilder: (context, index) {
            return _buildModelCard(
              misModelos[index]['nombre']!,
              misModelos[index]['fecha']!,
            );
          },
        ),
      ),
      // Botón para añadir uno nuevo
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF007AFF),
        child: const Icon(Icons.add_box_rounded, color: Colors.white),
        onPressed: () {
          // Aquí podrías navegar al Editor
        },
      ),
    );
  }

  Widget _buildModelCard(String nombre, String fecha) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Área de la "imagen" (usamos un icono mientras no tienes fotos)
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: const Icon(
                Icons.view_in_ar_rounded,
                size: 50,
                color: Color(0xFF007AFF),
              ),
            ),
          ),
          // Información del modelo
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  fecha,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
